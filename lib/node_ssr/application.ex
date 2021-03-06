defmodule NodeSsr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    count = conf(:count, 1)
    assets_path = conf(:assets_path, nil) || raise "Must provide a path to your assets/component directory"
    script_name = conf(:script_name, "ssr.js")


    children = [ NodeSsr.Watcher.child_spec(
      id: NodeSsr.Watcher,
      assets_path: assets_path,
      script_name: script_name,
      count: count,
      component_ext: conf(:component_ext, ".js"),
      component_path: conf(:component_path, "js/components"),
      log_prefix: conf(:log_prefix, "/tmp")
    )]


    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NodeSsr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    # clean up persisten term when exited
    :persistent_term.erase(:node_ssr_port)
    :ok
  end

  defp make_id(int) do
    String.to_atom("node_ssr_worker_#{int}")
  end

  defp conf(key, default), do: Application.get_env(:node_ssr, key, default)

end
