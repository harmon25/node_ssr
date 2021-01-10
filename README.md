# NodeSsr

Elixir Application for managing nodejs worker processes, whose responsibility is server side rendering.
Since this is an application - it can be used easily at compile time by simply calling `Application.ensure_all_started(:node_ssr)` before any calls to `NodeSsr.render/2` 

NodeSsr was designed to be used at compile time - but could be used to provide SSR at runtime for a Phoenix application.

Communication between nodejs and elixir is done through a basic [http server](https://nodejs.org/api/http.html#http_class_http_server) running in each nodejs SSR worker process.

Used by [ReactSurface](https://github.com/harmon25/react_surface) to provide the SSR macro.

Could be used to provide SSR for other frameworks like Vue based on how ReactSurface is implemented.

## Usage Instructions

Install node deps, create an SSR script(see example) in your assets directory, setup necessary config.exs values and run `NodeSsr.render/2` 

## Node dependencies

Requires babel (default phoenix setup is fine), and @babel/register as dev dependencies (if used at runtime might need to be actual deps)
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
   script_path: "#{File.cwd!()}/assets/ssr.js" # REQUIRED - this should do in most cases unless you rename or move the generated ssr.js script
```

Optional requirements:
``` elixir
  component_path: "js/components" # this is the default, relative path from assets.
  component_ext: ".js" # this is the default, to help with nodejs require statements.
  count: 1 # this is the number of node processes to launch - likely not necessary to have more than 1, unless rendering lots of components
```

## Example SSR script 

```javascript
#!/bin/env node

require("@babel/register")({ cwd: __dirname });
// starts local http service to perform Node SSR
const startService = require("elixir-node-ssr");
// a render function that takes a component name + props and returns a json response
const render = (componentName, props = {}) => {
  return {markup: "SOME JS GENERATED MARKUP", extra: {}, error: null}
}
const opts = {
  debug: false,
};

// starts listening on a random tcp port for render requests
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

