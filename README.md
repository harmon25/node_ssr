# NodeSsr

Elixir Application for managing nodejs http server cluster, and communicating to it from elixir.
Since this is an application - it can be used easily at compile time by simply calling `Application.ensure_all_started(:node_ssr)` before any calls to `NodeSsr.render/2`.

NodeSsr was designed to be used at compile time - but could be used to provide SSR at runtime for a Phoenix application.

IPC between Nodejs and Elixir is done through a simple nodejs http api running in a [nodejs cluster](https://nodejs.org/api/cluster.html#cluster_cluster).

## Usage Instructions

1. Install node dependencies alongside your assets
2. Create an SSR script(see example) in your assets directory
3. Setup necessary config.exs values 
4. Run `NodeSsr.render/2` 

## Node dependencies

Requires babel (default phoenix setup is fine), and @babel/register as `devDependencies` (if used at runtime might need to be actual `dependencies`)
```sh
npm i @babel/core @babel/register --save-dev
```

In package.json add the following dependency:

```
"elixir-node-ssr": "file:../deps/node_ssr"
```


## Configuration 
```elixir
config :node_ssr,
   assets_path: "#{File.cwd!()}/assets", # REQUIRED - This be the folder with assets, and a package.json file - passed to erlexec `:cd` option
   script_name: "test.js" # this is the name of the script to be invoked - defaults to "ssr.js", can change it here.
```

Optional requirements:
``` elixir
  component_path: "js/components" # this is the default, relative path to your components directory from assets/.
  component_ext: ".js" # this is the default, used with nodejs require statements
  count: 1 # this is the number of workers in the nodejs cluster - likely not necessary to have more than 1, unless rendering lots of components
```

## Example SSR script
This script is launched by `erlexec`, and should be able to resolve and render your components 

```javascript
#!/bin/env node

require("@babel/register")({ cwd: __dirname });
// starts local http service to perform Node SSR
const startService = require("elixir-node-ssr");
// a render function that takes a component name + props and returns a json response
// this should include rendered html as markup, and whatever else you like that can be serialized to JSON
const render = (componentName, props = {}) => {
  return {markup: "<h1>Hi From NodeJS</h1>", extra: {}, error: null}
}
const opts = {
  debug: false,
};

// service is forked by nodejs and runs one master, and N workers based on the `:count` optional application env option.
// if nil count is supplied runs as many workers as CPU cores.
startService(render, opts);
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `node_ssr` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:node_ssr, "~> 0.1.0"}
  ]
end
```

Via github

```elixir
def deps do
  [
    {:node_ssr, github: "harmon25/node_ssr", branch: "main"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/node_ssr](https://hexdocs.pm/node_ssr).

## Used by:

- [ReactSurface](https://github.com/harmon25/react_surface) to provide the SSR macro.
