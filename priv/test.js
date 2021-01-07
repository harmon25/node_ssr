const start  = require("./service");

const testRender = (path, props) => {
  return { markup: "TESTING", error: null, props, extra: null };
};

const opts = {
  port: process.argv[2] ? parseInt(process.argv[2]) : 8080,
  debug: false,
};

start(testRender, opts);
