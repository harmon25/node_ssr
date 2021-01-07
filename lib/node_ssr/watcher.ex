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
      {"SIGNAL_PORT", udp_port}
    ]

    exec_opts = [
      stderr: stderr_path(opts),
      stdout: stdout_path(opts),
      env: env
    ]

    Logger.info("Starting node ssr server at http://localhost:#{opts[:port]}")

    {:ok, pid, os_pid} =
      [node_exe, opts[:script_path], opts[:port]]
      |> Exexec.run_link(exec_opts)

    # wait for up to 1 second to recieve an 'OK' packet
    result =
      :gen_udp.recv(socket, 32, 1000)
      |> case do
        {:ok, {_addr, _port, 'OK'}} ->
          # close udp socket.
          :gen_udp.close(socket)
          Logger.info("Confirmed Node process is listening - starting...")
          # closing temporary socket.
          {:ok, %{pid: pid, port: opts[:port], os_pid: os_pid}}

        _ ->
          {:stop, "Node process failed to start..."}
      end

    result
  end

  defp stdout_path(opts) do
    Path.join([opts[:log_prefix], "stdout_#{opts[:id]}"])
  end

  defp stderr_path(opts) do
    Path.join([opts[:log_prefix], "stderr_#{opts[:id]}"])
  end
end
