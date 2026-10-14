# Spec Delta

## Purpose

Defines what the blog publishes and how readers reach it: Posts, listings, Tags, Feeds, fixed Pages, identity, and the self-contained static output served at blog.dennis.io.

## ADDED Requirements

### Requirement: Self-contained static build
Building the site SHALL produce one output folder of static files that any static web server can serve without server-side processing, and the output SHALL load no runtime assets (CSS, fonts, scripts, images) from third-party hosts.

#### Scenario: Build produces servable output
- **WHEN** the site is built from a clean checkout with the documented build command
- **THEN** the build succeeds and the output folder contains `index.html` and every page, feed, and asset the site links to

#### Scenario: No third-party runtime requests
- **WHEN** any generated page is loaded in a browser
- **THEN** every stylesheet, font, script, and image it requests is served from the same origin

### Requirement: Canonical site URL
All absolute URLs in the generated output (canonical links, feed entries, sitemap, Social image URLs) SHALL use `https://blog.dennis.io` as their origin.

#### Scenario: Feed and canonical links use the production origin
- **WHEN** the site is built for production
- **THEN** the feed's entry links and each page's canonical link start with `https://blog.dennis.io/`

### Requirement: Blog posts
Each Post SHALL be authored as Markdown with a title, a publication date, a Description and optional Tags, and SHALL be published at `/posts/<slug>/`, where the slug is the Post's folder name. Posts marked as Draft SHALL NOT appear in the production output.

#### Scenario: Post page rendered
- **WHEN** a Post with a title, date, Description, and Markdown body exists
- **THEN** the output contains `/posts/<slug>/index.html` showing the title, the date, its Tags, and the rendered body

#### Scenario: Draft excluded
- **WHEN** a Post is marked as Draft and the site is built for production
- **THEN** no page, listing entry, feed entry, or search entry exists for that Post

### Requirement: Description required on Posts
Every Post SHALL have a non-empty Description. The project's check SHALL fail when a Post lacks one.

#### Scenario: Missing Description
- **WHEN** a published Post has no Description and the check is run
- **THEN** the check fails and names the Post

### Requirement: ISO dates
Every date shown to readers SHALL be formatted as `YYYY-MM-DD`, regardless of the Post's language, and SHALL be marked up with a machine-readable `datetime` attribute.

#### Scenario: Date format
- **WHEN** a Post dated 1 October 2026 is rendered on its page and on a listing card
- **THEN** both show `2026-10-01` inside a `<time datetime="2026-10-01">` element

### Requirement: Updated date
A Post MAY carry an Updated date. When present, the Post page SHALL show it as "Updated YYYY-MM-DD" next to the publication date. Listings SHALL remain ordered by publication date.

#### Scenario: Updated shown, order unchanged
- **WHEN** an older Post is given an Updated date later than a newer Post's publication date
- **THEN** its page shows "Updated <date>" and the home page still lists the newer Post first

### Requirement: Post language
A Post SHALL be English unless it is marked German, in which case the Post's content SHALL be declared as German (`lang="de"`) while the site's interface stays English.

#### Scenario: German Post
- **WHEN** a Post is marked German
- **THEN** its article content carries `lang="de"`, and the page's navigation, labels, and date format are unchanged

### Requirement: Post listing on the home page
The home page SHALL list published Posts newest first, showing each Post's title, date, reading time, Description, and Tags, with the title linking to the Post. When there are more Posts than fit on one page, the listing SHALL be paginated with links between pages.

#### Scenario: Newest first
- **WHEN** two Posts are published with different dates
- **THEN** the home page lists the more recent Post above the older one

#### Scenario: Card shows the Description
- **WHEN** a Post's body begins with text different from its Description
- **THEN** the listing card shows the Description, not the body text

#### Scenario: Pagination
- **WHEN** the number of Posts exceeds the page size
- **THEN** the home page shows the first page of Posts and links to the next page, which lists the remaining Posts

### Requirement: Introduction
The first page of the home page SHALL show a short Introduction above the Post listing. Subsequent pages of the listing SHALL NOT show it.

#### Scenario: Introduction only on page 1
- **WHEN** the listing spans two pages
- **THEN** the Introduction appears on `/` and not on `/page/2/`

### Requirement: Reading aids
Each Post page SHALL show its estimated reading time, give every heading an anchor link, and link to the previous and next Post by publication date where they exist. A Post that asks for a table of contents SHALL show one linking to its headings; other Posts SHALL NOT.

#### Scenario: Heading anchors
- **WHEN** a reader hovers or focuses a heading in a Post
- **THEN** an anchor link to that heading is available

#### Scenario: Previous and next
- **WHEN** three Posts exist and a reader opens the middle one
- **THEN** the page links to the older Post and to the newer Post

#### Scenario: Opt-in table of contents
- **WHEN** one Post asks for a table of contents and another does not
- **THEN** only the first Post's page shows a table of contents

### Requirement: Tags
Posts SHALL be taggable. The site SHALL provide a page listing all Tags with their Post counts, and a page per Tag listing the Posts carrying it, newest first. Tags shown on a Post or listing SHALL link to their tag page.

#### Scenario: Tag page lists tagged posts
- **WHEN** two Posts carry the Tag `rust` and one does not
- **THEN** the `rust` tag page lists exactly the two tagged Posts

#### Scenario: Tags index
- **WHEN** a reader opens the tags index page
- **THEN** every Tag in use is listed with the number of Posts carrying it and links to its tag page

### Requirement: Atom feed
The site SHALL publish an Atom Feed of published Posts, newest first, with each entry carrying the full Post content, the author "Dennis Sänger", and the Post's Updated date when present. Every page SHALL advertise the Feed via a feed autodiscovery link.

#### Scenario: Feed contains full posts
- **WHEN** the site is built with published Posts
- **THEN** the output contains a valid Atom Feed with one entry per published Post, each with title, date, absolute link, author, and the full rendered content

#### Scenario: Feed autodiscovery
- **WHEN** any page's HTML head is inspected
- **THEN** it contains a `link` element of type `application/atom+xml` pointing to the Feed

### Requirement: Per-tag feeds
Each Tag SHALL have its own Atom Feed containing only the Posts carrying that Tag, advertised on that Tag's page.

#### Scenario: Tag feed
- **WHEN** the site is built and a Post carries the Tag `rust`
- **THEN** `/tags/rust/atom.xml` exists and contains that Post and no untagged Posts

### Requirement: About page
The site SHALL have a static About Page authored in Markdown, reachable from the main navigation on every page, and excluded from listings, Feeds, and search.

#### Scenario: About reachable
- **WHEN** a reader clicks "About" in the site navigation
- **THEN** the About Page renders with the site's layout

### Requirement: Not-found page
The build SHALL produce a styled `404.html` page that links back to the home page, for the web server to serve on unknown paths.

#### Scenario: 404 page generated
- **WHEN** the site is built
- **THEN** the output root contains `404.html` using the site's layout with a link to the home page

### Requirement: Page metadata
Every page SHALL have a `<title>` ending in "blog.dennis.io", a meta description, and Open Graph title, description, URL, and image tags. A Post's description SHALL be its Description; a Page without a Description SHALL fall back to the site description.

#### Scenario: Post metadata
- **WHEN** a Post is rendered
- **THEN** its `<title>` contains the Post title and "blog.dennis.io", and its meta description and `og:description` contain the Post's Description

#### Scenario: Page fallback
- **WHEN** the About Page has no Description
- **THEN** its meta description is the site description

### Requirement: Social image
Every page SHALL reference a Social image via `og:image` as an absolute URL. A Post that sets its own Social image SHALL use it; all other pages SHALL use the site's default Social image. The Social image SHALL NOT be displayed on the site itself.

#### Scenario: Default image
- **WHEN** a Post without its own Social image is rendered
- **THEN** its `og:image` is the absolute URL of the default Social image

#### Scenario: Per-post override
- **WHEN** a Post sets its own Social image
- **THEN** its `og:image` points to that image and the image does not appear in the page body

### Requirement: Author identity
Every page footer SHALL show "© <year> Dennis Sänger" and a link to `https://github.com/ds82` marked `rel="me"`.

#### Scenario: Footer identity
- **WHEN** any page is rendered
- **THEN** its footer contains "Dennis Sänger" (with the umlaut) and a `rel="me"` link to `https://github.com/ds82`

### Requirement: Favicon
Every page SHALL link a favicon served by the site, so browsers do not request a missing icon.

#### Scenario: Favicon present
- **WHEN** any page is loaded
- **THEN** its head links an SVG favicon and a PNG touch icon, both present in the output, and `/favicon.ico` does not return 404
