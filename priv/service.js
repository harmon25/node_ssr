/**
 * barebones 0 dependency Node HTTP server with one job. Respond to post requests with a rendered component.
 *
 * When starting the service, must supply a render function that accepts two parameters - the component name, and props to be rendered.
 */

const http = require("http");
const dgram = require("dgram");
const cluster = require("cluster");
const numCPUs = require("os").cpus().length;

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
  if (cluster.isMaster) {
    console.log(`Master ${process.pid} is running`);

    // Fork workers.
    for (let i = 0; i < numCPUs; i++) {
      cluster.fork();
    }

    cluster.on("exit", (worker, code, signal) => {
      console.log(`worker ${worker.process.pid} died`);
    });
  } else {
    const { SIGNAL_PORT } = process.env;
    const client = dgram.createSocket("udp4");

    opts = { ...defaultOpts, ...opts };

    const server = http
      .createServer(requestHandler(render, opts))
      .listen(0, () => {
        const portStr = `${server.address().port}`;
         client.send(
          Buffer.from(portStr),
          parseInt(SIGNAL_PORT),
          "localhost",
          (err) => {
            client.close();
          }
        );
      });

    console.log(`Worker ${process.pid} started`);
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
