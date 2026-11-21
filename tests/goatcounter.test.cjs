const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { join } = require("node:path");
const { test } = require("node:test");
const { runInNewContext } = require("node:vm");

const site = "https://savoy9.github.io";
const endpoint = "https://notebook-test.goatcounter.com/count";

function scriptsLoaded({ origin = site, framed = false, target = endpoint,
  canonical = `${site}/Dax-Aggregations/` } = {}) {
  const scripts = [];
  const window = {};
  window.top = framed ? {} : window;
  runInNewContext(readFileSync(join(__dirname, "../assets/goatcounter.js"), "utf8"), {
    URL,
    console: { warn: () => {} },
    window,
    location: { origin },
    document: {
      currentScript: { dataset: { endpoint: target } },
      querySelector: () => canonical ? { href: canonical } : null,
      createElement: () => ({ dataset: {} }),
      head: { append: (script) => scripts.push(script) },
    },
  });
  return scripts;
}

test("a configured top-level blog page loads one counter for its canonical path", () => {
  const scripts = scriptsLoaded({ canonical: `${site}/Dax-Aggregations/?ignored=1#section` });
  assert.equal(scripts.length, 1);
  assert.equal(scripts[0].src, "https://gc.zgo.at/count.js");
  assert.equal(scripts[0].dataset.goatcounter, endpoint);
  assert.equal(JSON.parse(scripts[0].dataset.goatcounterSettings).path, "/Dax-Aggregations/");
});

test("previews, frames, and missing or unapproved count URLs never load a third-party script", () => {
  for (const options of [
    { origin: "http://localhost:4000" },
    { origin: "https://preview.example.test" },
    { framed: true },
    { target: "" },
    { target: "https://notebook-test.goatcounter.com.example.test/count" },
    { target: "http://notebook-test.goatcounter.com/count" },
    { canonical: "https://example.test/Dax-Aggregations/" },
    { canonical: null },
  ]) {
    assert.equal(scriptsLoaded(options).length, 0, JSON.stringify(options));
  }
});
