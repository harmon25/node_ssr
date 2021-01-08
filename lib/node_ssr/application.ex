defmodule NodeSsr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    count = conf(:count, 1)
    script_path = conf(:script_path, nil) || raise "Must provide a script path"
    mod_paths = conf(:module_paths, ["./assets/node_modules", "./assets"]) |> join_mod_paths()

    children =
      Enum.map(
        Range.new(1, count + 1),
        &NodeSsr.Watcher.child_spec(
          id: make_id(&1),
          node_path: mod_paths,
          script_path: script_path,
          component_ext: conf(:component_ext, ".js"),
          component_path: conf(:component_path, "js/components"),
          log_prefix: conf(:log_prefix, "/tmp")
        )
      )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NodeSsr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp make_id(int) do
    String.to_atom("node_ssr_worker_#{int}")
  end

  defp conf(key, default), do: Application.get_env(:node_ssr, key, default)

  # if on windows path seperator is not a colon, it is a semicolon - but Exexec will not work on windows anyway...
  defp join_mod_paths(paths), do: Enum.join(paths, ":")
end
