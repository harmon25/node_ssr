/**
 * barebones 0 dependency Node HTTP server with one job. Respond to post requests with a rendered component.
 *
 * When starting the service, must supply a render function that accepts two parameters - the component name, and props to be rendered.
 */

const http = require("http");
const dgram = require("dgram");
const cluster = require("cluster");

const defaultOpts = {
  debug: false,
};

/**
 * Starts the nodejs http listener, and messages pa
 *
 * @param {function} render
 * @param {Object} opts
 */
function start(render, opts = defaultOpts) {
  const { SIGNAL_PORT, NODE_WORKERS } = process.env;
  if (cluster.isMaster) {
    // this is the master code - run only once, which is proxying to the workers
    const numCPUs = require("os").cpus().length;
    const numWorkers = (NODE_WORKERS ? parseInt(NODE_WORKERS) : null) || numCPUs;

    // console.log(`Master ${process.pid} is running`);

    // Fork workers.
    for (let i = 0; i < numWorkers; i++) {
      cluster.fork();
    }

    cluster.on("exit", (worker, code, signal) => {
      console.log(`worker ${worker.process.pid} died`);
    });

    let clusterPort = null;

    cluster.on("listening", (worker, address) => {
      // when we have something listening, message back with the port.
      if (clusterPort === null) {
        clusterPort = address.port;
        console.log(`Listening on port: ${clusterPort}`);
        const client = dgram.createSocket("udp4");
        const msg = Buffer.from(`${address.port}`);
        client.send(msg, parseInt(SIGNAL_PORT), "localhost", (err) => {
          client.close();
        });
      }
    });
  } else {
    // this is the worker code, executing in each fork
    opts = { ...defaultOpts, ...opts };
    http.createServer(requestHandler(render, opts)).listen(0);
    // console.log(`Worker ${process.pid} started`);
  }
}

const contentTypeHeader = { "Content-Type": "application/json" };

function requestHandler(render, opts) {
  // return an async request handler.
  return async (req, res) => {
    const parsedURL = new URL(req.url, `http://${req.headers.host}`);
    // all requests need a response, define it.
    var resp;
    // render requests are posts - dont really care about URL path, just need component query param
    if (req.method === "POST") {
      // grab component name from query params
      const componentName = parsedURL.searchParams.get("component");

      try {
        if (componentName) {
          // grabs + decodes props from json body via promise.
          const props = await resolveBody(req);
          res.writeHead(200, contentTypeHeader);
          // calls supplied render function
          // the return of which is json encoded and returned to elixir as the json body of http request
          resp = await render(componentName, props);
        } else {
          resp = {
            error: "Must supply component query parameter",
            params: q,
          };
        }
      } catch (e) {
        // can check stderr log file to see this error output.
        console.error(e);
        res.writeHead(500, contentTypeHeader);
        resp = { error: e.message, params: q };
      }
      // can perform a health check with a get to the /
    } else if (req.method === "GET") {
      res.writeHead(200, contentTypeHeader);
      resp = { result: "OK", error: null };
    }
    let respString = JSON.stringify(resp);
    opts.debug && console.log(`SSR Response(${opts.port}):`, respString);
    return res.end(respString); //end the response, and send it.
  };
}

function resolveBody(req) {
  return new Promise((resolve, _reject) => {
    let data = [];
    req.on("data", (chunk) => {
      data.push(chunk);
    });
    req.on("end", () => {
      resolve(JSON.parse(data));
    });
  });
}

module.exports = start;
