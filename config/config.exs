use Mix.Config

config :node_ssr,
  count: 1,
  assets_path: "#{File.cwd!()}/test",
  script_name: "test.js"
