defmodule NodeSsr.MixProject do
  use Mix.Project

  def project do
    [
      app: :node_ssr,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :hackney],
      mod: {NodeSsr.Application, []},
      env: [
        ports: [8080],
        module_paths: ["./assets/node_modules", "./assets"],
        log_prefix: "/tmp",
        component_path: "js/components",
        component_ext: ".js"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exexec, "~> 0.2.0"},
      {:httpoison, "~> 1.7"},
      {:jason, "~> 1.1"}
    ]
  end
end
