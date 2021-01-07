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

    exec_opts = [
      stderr: stderr_path(opts),
      stdout: stdout_path(opts),
      env: [{"NODE_PATH", opts[:node_path]}]
    ]

    Logger.info("Starting node ssr server at http://localhost:#{opts[:port]}")

    {:ok, pid, os_pid} =
      [node_exe, opts[:script_path], opts[:port]]
      |> Exexec.run_link(exec_opts)

    # sleep for 500ms to allow the service to be responsive
    Process.sleep(opts[:wait])
    {:ok, %{pid: pid, port: opts[:port], os_pid: os_pid}}
  end

  defp stdout_path(opts) do
    Path.join([opts[:log_prefix], "stdout_#{opts[:id]}"])
  end

  defp stderr_path(opts) do
    Path.join([opts[:log_prefix], "stderr_#{opts[:id]}"])
  end
end
