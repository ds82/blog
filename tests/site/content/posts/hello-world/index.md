+++
title = "Hello, world: how this blog is built"
date = 2026-10-01
updated = 2026-10-12
description = "A tour of the pieces behind blog.dennis.io: Zola, a design-system theme and a few small scripts."

[taxonomies]
tags = ["zola", "rust"]

[extra]
toc = true
social_image = "social.png"
+++

This blog is a static site built with [Zola](https://www.getzola.org). This first post doubles as a test page: it uses every element the theme has to style.

## Why a static site

A static site is a folder of files. Any web server can serve it, it has no database to patch, and it loads fast.

### What Zola brings

Zola is a single binary with templates, Sass, search indexes and feeds built in. There is no `node_modules` folder in sight.

## Code

Here is some Rust, to check the highlighting colors:

```rust
use std::collections::HashMap;

/// Counts how often each word appears.
fn word_counts(text: &str) -> HashMap<&str, usize> {
    let mut counts = HashMap::new();
    for word in text.split_whitespace() {
        *counts.entry(word).or_insert(0) += 1;
    }
    counts
}

fn main() {
    let counts = word_counts("the quick brown fox jumps over the lazy dog");
    println!("'the' appears {} times", counts["the"]); // 2
}
```

And a shell session with a deliberately long line that has to scroll inside its box on small screens:

```sh
zola build && python3 -m http.server --directory public 8000 # then open http://localhost:8000/ and check that every page, feed and search result loads
```

## Everything else

- A list item with `inline code`
- A second item with a [link to the About page](@/pages/about.md)

> A blockquote, for the occasional quote worth highlighting.

| Element | Styled |
|---------|--------|
| Tables  | yes    |
| Images  | later  |

That's it for now.
