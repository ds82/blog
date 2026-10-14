// Light/dark toggle. Dark is the default (class="dark" ships in the HTML); an
// inline snippet in <head> applies a stored "light" choice before first paint.
(function () {
  "use strict";

  var root = document.documentElement;
  var button = document.getElementById("theme-toggle");
  if (!button) return;

  function isDark() {
    return root.classList.contains("dark");
  }

  function updateButton() {
    button.setAttribute("aria-label", isDark() ? "Switch to light mode" : "Switch to dark mode");
    button.title = button.getAttribute("aria-label");
  }

  button.addEventListener("click", function () {
    root.classList.toggle("dark");
    try {
      localStorage.setItem("theme", isDark() ? "dark" : "light");
    } catch (e) {
      // Storage blocked: the switch still applies to this page.
    }
    updateButton();
  });

  updateButton();
  button.hidden = false;
})();
