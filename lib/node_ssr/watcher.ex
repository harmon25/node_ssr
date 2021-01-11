defmodule NodeSsr.Watcher do
  @moduledoc """
  GenServer that launches an external nodejs process via `Exexec` and ensures they are shutdown with the erlangvm.
  """
  use GenServer
  require Logger

  def child_spec(args) do
    %{id: args[:id], start: {__MODULE__, :start_link, [args]}}
  end

  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # bit bummed about dialyzer warning here...`Function init/1 has no local return`?
  @impl true
  def init(opts) do
    node_exe = opts[:node_exe] || System.find_executable("node")

    # open a temporary udp socket for IPC between nodejs process and this gen_server
    {:ok, socket} = :gen_udp.open(0, active: false)
    # figure out what random port was selected
    {:ok, udp_port} = :inet.port(socket)

    # could open this up via an option to allow passing more into the node env.
    env = [
      {"NODE_PATH", opts[:node_path]},
      {"COMPONENT_PATH", opts[:component_path]},
      {"COMPONENT_EXT", opts[:component_ext]},
      # this is used in the node process to message back when it is ready for http calls
      {"SIGNAL_PORT", "#{udp_port}"},
      # how many workers to fork in node cluster
      {"NODE_WORKERS", "#{opts[:count]}"}
    ]

    {:ok, pid, os_pid} =
      [node_exe, opts[:script_path]]
      |> :exec.run_link(
        stderr: stderr_path(opts),
        stdout: stdout_path(opts),
        env: env
      )

    # wait for up to 1.5 seconds to receive a udp packet on the random port from the launched nodejs process.
    # the packet contains the random tcp port that was opened by nodejs.
    :gen_udp.recv(socket, 32, 1500)
    |> case do
      {:ok, {_addr, _port, tcp_port}} ->
        port_int = List.to_integer(tcp_port)
        :ok = add_port({port_int, self()})
        # close udp socket.
        :gen_udp.close(socket)
        Logger.debug("Confirmed Node process is listening on #{port_int}")
        {:ok, %{pid: pid, port: port_int, os_pid: os_pid}}

      _ ->
        :exec.stop(pid)
        {:stop, "Node process failed to start..."}
    end
  end

  @impl true
  def handle_info({:EXIT, _from, reason}, state) do
    IO.inspect("exiting")
    remove_port(state.port)
    # see GenServer docs for other return types
    {:stop, reason, state}
  end

  @impl true
  def terminate(state, reason) do
    Logger.debug("Terminated #{__MODULE__} on port #{state.port}, reason: #{reason}")
    :exec.stop(state.pid)
    remove_port(state.port)
    :normal
  end

  defp add_port(new_port) do
    # using persistent term for shared state to track all the opened tcp ports - is only ever written here
    ports = :persistent_term.get(:node_ssr_ports, [])
    :persistent_term.put(:node_ssr_ports, [new_port | ports])
  end

  defp remove_port(old_port) do
    # using persistent term for shared state to track all the opened tcp ports - is only ever written here
    ports = :persistent_term.get(:node_ssr_ports, [])
    :persistent_term.put(:node_ssr_ports, Enum.filter(ports, &(elem(&1, 0) !== old_port)))
  end

  defp stdout_path(opts) do
    Path.join([opts[:log_prefix], "node_ssr_stdout"])
  end

  defp stderr_path(opts) do
    Path.join([opts[:log_prefix], "node_ssr_stderr"])
  end
end
