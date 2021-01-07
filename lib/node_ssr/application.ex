defmodule NodeSsr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ports = conf(:ports, nil) || raise "Must provide a port via application config"
    script_path = conf(:script_path, nil) || raise "Must provide a script path"
    mod_paths = conf(:module_paths, ["./assets/node_modules", "./assets"])
    log_prefix = conf(:log_prefix, "/tmp")

    children =
      Enum.map(ports, fn port ->
        [
          id: make_id(port),
          port: port,
          node_path: join_mod_paths(mod_paths),
          script_path: script_path,
          log_prefix: log_prefix,
          wait: conf(:wait, 500)
        ]
        |> NodeSsr.Watcher.child_spec()
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NodeSsr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp make_id(port) do
    String.to_atom("node_ssr_worker_#{port}")
  end

  defp conf(key, default), do: Application.get_env(:node_ssr, key, default)

  # if on windows path seperator is not a colon, it is a semicolon - but Exexec will not work on windows anyway...
  defp join_mod_paths(paths), do: Enum.join(paths, ":")
end
