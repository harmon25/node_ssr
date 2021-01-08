const start  = require("./service");

const testRender = (path, props) => {
  return { markup: "TESTING", error: null, props, extra: null };
};

const opts = {
  debug: false,
};

start(testRender, opts);
