// Client-side search over Posts, using the elasticlunr index Zola builds
// (search_index.<lang>.json) and the elasticlunr.min.js Zola ships with it.
(function () {
  "use strict";

  var script = document.currentScript;
  var indexUrl = script.dataset.index;
  var libUrl = script.dataset.elasticlunr;
  var MAX_RESULTS = 10;
  var EXCERPT_LENGTH = 180;

  var input = document.getElementById("search-input");
  var status = document.getElementById("search-status");
  var results = document.getElementById("search-results");
  var form = input && input.form;
  if (!input || !status || !results) return;

  var indexPromise = null;

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      var s = document.createElement("script");
      s.src = src;
      s.onload = resolve;
      s.onerror = function () { reject(new Error("Could not load " + src)); };
      document.head.appendChild(s);
    });
  }

  function loadIndex() {
    if (!indexPromise) {
      indexPromise = Promise.all([
        loadScript(libUrl),
        fetch(indexUrl).then(function (r) {
          if (!r.ok) throw new Error("Could not load the search index");
          return r.json();
        }),
      ]).then(function (parts) {
        return window.elasticlunr.Index.load(parts[1]);
      });
    }
    return indexPromise;
  }

  // Only Posts are results; the index also holds section entries.
  function isPost(url) {
    try {
      return /^\/posts\/[^/]+\/?$/.test(new URL(url, location.href).pathname);
    } catch (e) {
      return false;
    }
  }

  function excerpt(body, terms) {
    var text = (body || "").replace(/\s+/g, " ").trim();
    var lower = text.toLowerCase();
    var at = -1;
    for (var i = 0; i < terms.length && at < 0; i++) {
      at = lower.indexOf(terms[i]);
    }
    var start = Math.max(0, at - 40);
    var snippet = text.slice(start, start + EXCERPT_LENGTH);
    return (start > 0 ? "… " : "") + snippet + (start + EXCERPT_LENGTH < text.length ? " …" : "");
  }

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  }

  function render(query, hits, index) {
    results.replaceChildren();
    if (!query) {
      status.textContent = "";
      return;
    }
    if (hits.length === 0) {
      status.textContent = "No results for “" + query + "”.";
      return;
    }
    status.textContent = hits.length + (hits.length === 1 ? " result" : " results") + " for “" + query + "”.";
    var terms = query.toLowerCase().split(/\s+/).filter(Boolean);
    hits.forEach(function (hit) {
      var doc = index.documentStore.getDoc(hit.ref);
      var li = el("li");
      var card = el("article", "card post-card");
      var title = el("h2", "card-title");
      var link = el("a", "", doc.title);
      link.href = hit.ref;
      title.appendChild(link);
      card.appendChild(title);
      if (doc.description) card.appendChild(el("p", "card-description", doc.description));
      card.appendChild(el("p", "search-excerpt", excerpt(doc.body, terms)));
      li.appendChild(card);
      results.appendChild(li);
    });
  }

  function search(query) {
    query = query.trim();
    var url = new URL(location.href);
    if (query) url.searchParams.set("q", query);
    else url.searchParams.delete("q");
    history.replaceState(null, "", url);

    if (!query) {
      render("", [], null);
      return;
    }
    status.textContent = "Searching…";
    loadIndex().then(function (index) {
      if (input.value.trim() !== query) return; // a newer query is running
      var hits = index
        .search(query, {
          fields: { title: { boost: 3 }, description: { boost: 2 }, body: { boost: 1 } },
          bool: "AND",
          expand: true,
        })
        .filter(function (hit) { return isPost(hit.ref); })
        .slice(0, MAX_RESULTS);
      render(query, hits, index);
    }).catch(function () {
      status.textContent = "Search is unavailable right now.";
    });
  }

  var timer = null;
  input.addEventListener("input", function () {
    clearTimeout(timer);
    timer = setTimeout(function () { search(input.value); }, 150);
  });
  if (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      search(input.value);
    });
  }

  var initial = new URLSearchParams(location.search).get("q");
  if (initial) {
    input.value = initial;
    search(initial);
  } else {
    // Start loading early so the first keystroke is fast.
    input.addEventListener("focus", loadIndex, { once: true });
  }
})();
