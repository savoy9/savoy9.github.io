(() => {
  if (location.origin !== "https://savoy9.github.io" || window.top !== window) return;

  const endpoint = document.currentScript.dataset.endpoint;
  if (!/^https:\/\/[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.goatcounter\.com\/count$/.test(endpoint)) {
    console.warn("GoatCounter is disabled: expected an HTTPS goatcounter.com count endpoint.");
    return;
  }

  const link = document.querySelector('link[rel="canonical"][href]');
  if (!link) return;
  const canonical = new URL(link.href);
  if (canonical.origin !== location.origin) return;

  const script = document.createElement("script");
  script.async = true;
  script.src = "https://gc.zgo.at/count.js";
  script.dataset.goatcounter = endpoint;
  script.dataset.goatcounterSettings = JSON.stringify({
    path: canonical.pathname,
    no_events: true,
    referrer: "",
  });
  document.head.append(script);
})();
