use Mix.Config

config :node_ssr,
  ports: [8080],
  wait: 500, # how long to sleep for nodejs service to start.
  script_path: "#{File.cwd!()}/priv/test.js",
  module_paths: ["./assets/node_modules", "./assets"],
  log_prefix: "/tmp"
