# Spec Delta

## Purpose

Publishes the blog automatically to GitHub Pages at https://blog.dennis.io whenever `main` changes, and only when the build and its checks pass.

## ADDED Requirements

### Requirement: Publish on push to main
Every push to the `main` branch SHALL trigger a build that, when successful, publishes the result as the live site. A maintainer SHALL also be able to trigger the same build and publish manually. Pushes to other branches SHALL NOT publish.

#### Scenario: Push publishes
- **WHEN** a commit that changes a Post is pushed to `main`
- **THEN** a publish run starts automatically and, once it succeeds, `https://blog.dennis.io` serves the changed Post

#### Scenario: Manual run
- **WHEN** a maintainer starts the publish run by hand without pushing
- **THEN** the current `main` is built, checked and published

#### Scenario: Other branch
- **WHEN** a commit is pushed to a branch other than `main`
- **THEN** no publish run starts

### Requirement: Checks gate publishing
A publish run SHALL build the site and run the project's checks before publishing. If the build or any check fails, the run SHALL fail visibly and SHALL NOT change the live site.

#### Scenario: Failing check
- **WHEN** a Post without a Description is pushed to `main`
- **THEN** the run fails at the check step, nothing is published, and the previously published site stays live

### Requirement: Pinned, verified build tool
Publish runs SHALL build with the same Zola version the project pins for local builds (0.23.6), and SHALL refuse to build if the downloaded tool does not match its published checksum.

#### Scenario: Version matches local builds
- **WHEN** a publish run builds the site
- **THEN** its log shows `zola 0.23.6`

#### Scenario: Tampered download
- **WHEN** the downloaded Zola archive does not match the pinned sha256 checksum
- **THEN** the run fails before building

### Requirement: Latest push wins
When publish runs overlap, the site SHALL end up reflecting the newest commit on `main`, and an older run SHALL NOT overwrite a newer publish.

#### Scenario: Two quick pushes
- **WHEN** two commits are pushed to `main` in quick succession
- **THEN** the site ends up showing the second commit's content

### Requirement: Served at the custom domain over HTTPS
The published site SHALL be reachable at `https://blog.dennis.io/` with a valid certificate, and plain HTTP requests SHALL redirect to HTTPS.

#### Scenario: HTTPS
- **WHEN** a reader opens `https://blog.dennis.io/`
- **THEN** the home page loads with a valid certificate, and its stylesheets and fonts load from the same origin

#### Scenario: HTTP redirect
- **WHEN** a reader opens `http://blog.dennis.io/`
- **THEN** they are redirected to `https://blog.dennis.io/`

### Requirement: Not-found responses use the site's 404 page
Requests for paths that do not exist SHALL return HTTP 404 with the site's own `404.html`.

#### Scenario: Unknown path
- **WHEN** a reader opens `https://blog.dennis.io/does-not-exist/`
- **THEN** the response status is 404 and the body is the site's styled "Page not found" page

### Requirement: Least-privilege publishing
The publish run SHALL have only the permissions it needs to read the repository and publish to Pages, and SHALL NOT be able to push to the repository.

#### Scenario: No write access to code
- **WHEN** the publish run's permissions are inspected
- **THEN** repository contents are read-only and only the Pages and identity-token permissions are writable
