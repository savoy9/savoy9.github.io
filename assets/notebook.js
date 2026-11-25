document.querySelectorAll("iframe[data-autosize]").forEach((frame) => {
  const fit = () => {
    try {
      const doc = frame.contentDocument;
      if (!doc || !doc.documentElement) return;
      const previous = frame.style.height;
      frame.style.height = "0px";
      const height = doc.documentElement.scrollHeight + 4 + "px";
      frame.style.height = height === previous ? previous : height;
    } catch (error) {
      // Cross-origin frames keep their fallback height.
    }
  };
  frame.addEventListener("load", () => {
    fit();
    if (window.ResizeObserver && frame.contentDocument) new ResizeObserver(fit).observe(frame.contentDocument.body);
  });
  window.addEventListener("resize", fit);
});

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

const lightboxLinks = document.querySelectorAll("a[data-lightbox]");
if (lightboxLinks.length && typeof HTMLDialogElement !== "undefined") {
  const dialog = document.createElement("dialog");
  dialog.className = "lightbox";
  dialog.innerHTML =
    '<div class="lightbox-bar"><span class="lightbox-caption"></span><button type="button" class="lightbox-close" aria-label="Close image">Close</button></div>' +
    '<div class="lightbox-body"><img alt=""></div>';
  document.body.append(dialog);
  const img = dialog.querySelector("img");
  const cap = dialog.querySelector(".lightbox-caption");
  const closeBtn = dialog.querySelector(".lightbox-close");
  let trigger = null;

  closeBtn.addEventListener("click", () => dialog.close());
  dialog.addEventListener("click", (event) => {
    if (event.target === dialog) dialog.close();
  });
  dialog.addEventListener("close", () => {
    trigger?.focus();
    trigger = null;
  });

  lightboxLinks.forEach((link) => {
    link.addEventListener("click", (event) => {
      event.preventDefault();
      trigger = link;
      const thumb = link.querySelector("img");
      img.src = link.href;
      img.alt = thumb ? thumb.alt : "";
      cap.textContent = link.dataset.lightbox || (thumb ? thumb.alt : "");
      dialog.showModal();
      closeBtn.focus();
    });
  });
}
