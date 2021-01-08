const start  = require("../priv/service");

const testRenderer = (componentName, props) => {
  return { markup: "TESTING", error: null, props, extra: null, name: componentName };
};

const opts = {
  debug: false,
};

start(testRenderer, opts);
