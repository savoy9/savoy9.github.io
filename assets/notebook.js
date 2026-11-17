document.querySelectorAll("pre").forEach((pre, index) => {
  pre.tabIndex = 0;
  pre.setAttribute("aria-label", "Code example " + (index + 1));
  if (!navigator.clipboard || !window.isSecureContext) return;

  const toolbar = document.createElement("div");
  toolbar.className = "code-toolbar";
  const label = document.createElement("span");
  label.textContent = "DAX / Example " + (index + 1);
  const button = document.createElement("button");
  button.type = "button";
  button.textContent = "Copy code";
  button.setAttribute("aria-label", "Copy code example " + (index + 1));
  const status = document.createElement("span");
  status.setAttribute("role", "status");
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(pre.querySelector("code").textContent);
      status.textContent = "Copied";
    } catch (error) {
      status.textContent = "Copy failed. Select the code and copy it manually.";
      console.error("Could not copy code example", error);
    }
  });
  toolbar.append(label, status, button);
  const highlight = pre.closest(".highlight") || pre;
  highlight.before(toolbar);
});
