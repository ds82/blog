# blog.dennis.io

Dennis's personal blog: dated writing, published as a static site in the look of his personal design system.

## Content

**Post**:
A dated, tagged piece of writing; the only kind of listed content for now. Other kinds (e.g. Notes) may be added later as their own sections.
_Avoid_: Article, entry, blog post

**Page**:
A fixed, undated piece of content outside the post stream (About, Search). It is not listed, not in the Feed and not searchable. A Description is optional.
_Avoid_: Static page, post (for these)

**Draft**:
A Post that is written but marked as not published. It doesn't appear anywhere on the built site.

**Slug**:
The URL-safe name of a Post, taken from its folder name. It is permanent once published.

**Tag**:
A lowercase, kebab-case label on a Post (e.g. `home-lab`). It is the only way to group Posts.
_Avoid_: Category, topic, label

**Description**:
A hand-written one-line teaser that every Post must have. It is shown on listing cards and used as the page's meta/social description.
_Avoid_: Excerpt, teaser, abstract

**Summary**:
The opening part of a Post's body. It is not used as a teaser; the Description is.

**Updated date**:
An optional second date on a Post, marking when it was last revised. It is shown to readers, but Posts are always ordered by their publication date.

**Post language**:
English by default. A single Post can be marked German, which changes only that Post's declared language; the site's own interface stays English. Dates are always shown as ISO dates (`2026-10-01`), whatever the language.

**Introduction**:
The short text about Dennis at the top of the first page of the home page, above the list of Posts.

**Social image**:
The preview image shown when a link is shared. A Post may set its own; otherwise the site's default one is used. It is used only in link previews, never shown on the site itself.
_Avoid_: OG image, cover, hero image

**Feed**:
The Atom feed of all published Posts with their full content. Each Tag also has its own Feed.
_Avoid_: RSS (as a name for it)

## Presentation

**Design system**:
Dennis's shared design tokens and fonts (`~/code/design-system`). The blog's look comes only from them.

**Theme**:
The Zola theme `astro-kip`, which renders the site in the Design system's look. It is kept separate from the content.

**Mode**:
Dark or light rendering. Dark is the default; the reader can switch it, and the operating system's setting is ignored.
_Avoid_: Theme (for this)
