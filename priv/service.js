/**
 * barebones 0 dependency Node HTTP server with one job. Respond to post requests with a rendered component.
 *
 * When starting the service, must supply a render function that accepts two parameters - the component name, and props to be rendered.
 */

const http = require("http");
const dgram = require("dgram");


const defaultOpts = {
  debug: false,
};

function start(render, opts = defaultOpts) {
  const { SIGNAL_PORT } = process.env;
  const client = dgram.createSocket("udp4");

  opts = { ...defaultOpts, ...opts };

  const server = http
    .createServer(requestHandler(render, opts))
    .listen({ port: 0 }, () => {
      const portStr = `${server.address().port}`
      const message = Buffer.from(portStr);
      console.log("Starting ssr service on port: ", portStr);
      client.send(message, parseInt(SIGNAL_PORT), "localhost", (err) => {
        client.close();
      });
    });
}

const contentTypeHeader = { "Content-Type": "application/json" };

function requestHandler(render, opts) {
  const { componentBase, componentExt } = opts;
  // return an async request handler.
  return async (req, res) => {
    const parsedURL = new URL(req.url, `http://${req.headers.host}`);
    // all requests need a response, make it.
    var resp;
    // render requests are posts.
    if (req.method === "POST") {
      // grab component name from query params
      const componentName = parsedURL.searchParams.get("component");

      try {
        if (componentName) {
          // grabs + decodes props from json body via promise.
          const props = await resolveBody(req);
          res.writeHead(200, contentTypeHeader);
          resp = render(componentName, props);
        } else {
          resp = {
            error: "Must supply component query parameter",
            params: q,
          };
        }
      } catch (e) {
        console.error(e);
        res.writeHead(500, contentTypeHeader);
        resp = { error: e.message, params: q };
      }
      // can perform a health check with a get to the /
    } else if (req.method === "GET") {
      res.writeHead(200, contentTypeHeader);
      resp = { message: "OK" };
    }
    let respString = JSON.stringify(resp);
    opts.debug && console.log(`SSR Response(${opts.port}):`, respString);
    return res.end(respString); //end the response
  };
}

function resolveBody(req) {
  return new Promise((resolve, reject) => {
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
