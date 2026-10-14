# Spec Delta

## Purpose

Lets readers find posts by full-text search entirely in the browser, without a search server, so the site remains a static folder.

## ADDED Requirements

### Requirement: Search index generation
The build SHALL generate a static search index covering the title, description, and body text of every published post, and SHALL exclude drafts.

#### Scenario: Index built
- **WHEN** the site is built with published posts
- **THEN** the output contains a search index file that includes each published post's title and URL

#### Scenario: German Post indexed
- **WHEN** a Post marked German contains the word `Steuererklärung`
- **THEN** searching for `Steuererklärung` finds that Post

### Requirement: Search page
The site SHALL provide a search page, linked from the main navigation, with a labelled search input that shows matching posts (title linking to the post, plus a short excerpt) as the reader types, without a page reload or server request beyond static files.

#### Scenario: Matching query
- **WHEN** a reader types a word that appears in a post's body
- **THEN** that post appears in the results with its title linking to the post

#### Scenario: No matches
- **WHEN** a reader types a query that matches no post
- **THEN** the page shows a "no results" message

### Requirement: Shareable search query
The search page SHALL read an initial query from the `q` URL parameter and run it on load.

#### Scenario: Query from URL
- **WHEN** a reader opens `/search/?q=zola`
- **THEN** the input contains `zola` and results for it are shown

### Requirement: Search without JavaScript
With JavaScript disabled, the search page SHALL tell the reader that search needs JavaScript and point them to the tags index instead.

#### Scenario: JavaScript disabled
- **WHEN** a reader with JavaScript disabled opens the search page
- **THEN** a message explains search requires JavaScript and links to the tags page
