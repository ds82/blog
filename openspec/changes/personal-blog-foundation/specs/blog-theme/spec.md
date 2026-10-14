# Spec Delta

## Purpose

Defines how the blog looks and behaves visually: it renders with Dennis's personal design system (colors, fonts, radii, shadows), defaults to dark mode with a reader toggle, and stays readable and accessible on all screen sizes.

## ADDED Requirements

### Requirement: Design-system tokens
The theme SHALL take every color, font family, radius, and shadow it uses from the design system's tokens (the `--background`, `--foreground`, `--primary`, `--card`, `--border`, `--muted-foreground`, … variables in both light and dark modes) and SHALL NOT hard-code color values that bypass them.

#### Scenario: Token values applied
- **WHEN** a page is rendered in dark mode
- **THEN** the page background is the dark `background` token (`#1a1a1a`), body text is the dark `foreground` token, and links/accents use the `primary` token (`#df6035`)

#### Scenario: Light-mode links stay readable
- **WHEN** a page is rendered in light mode
- **THEN** inline prose links use the `secondary` token rather than `primary`, so they meet WCAG AA contrast

#### Scenario: Token update propagates
- **WHEN** an updated copy of the design system's token CSS replaces the theme's copy
- **THEN** the rebuilt site reflects the new token values without other stylesheet edits

### Requirement: Design-system typography
Body and UI text SHALL use the Outfit font and code SHALL use Fira Code, both served from the site itself with their licences included in the output.

#### Scenario: Fonts self-hosted
- **WHEN** a page with prose and a code block is loaded
- **THEN** prose renders in Outfit and code in Fira Code, both loaded from the site's own origin

### Requirement: Dark mode by default
Pages SHALL render in dark mode for a reader who has not chosen a mode, regardless of operating system preference.

#### Scenario: First visit
- **WHEN** a reader with no stored preference opens any page
- **THEN** the page renders with the dark token values

#### Scenario: OS prefers light
- **WHEN** a reader whose operating system is set to light opens a page for the first time
- **THEN** the page still renders in dark mode

### Requirement: Light/dark toggle
Every page SHALL offer a keyboard-accessible control that switches between light and dark mode. The choice SHALL persist across pages and visits in that browser and SHALL be applied before first paint so the page does not flash the other mode.

#### Scenario: Switch to light
- **WHEN** a reader activates the toggle while in dark mode
- **THEN** the page switches to the light token values and the control's accessible label reflects the new state

#### Scenario: Preference persists
- **WHEN** a reader who chose light mode navigates to another page or returns later
- **THEN** that page renders in light mode from the first paint

#### Scenario: Storage unavailable
- **WHEN** browser storage is blocked
- **THEN** the page still renders in dark mode and the toggle still switches mode for the current page

### Requirement: Usable without JavaScript
All content and navigation SHALL be readable and usable with JavaScript disabled; only the mode toggle and search may depend on it.

#### Scenario: JavaScript disabled
- **WHEN** a reader with JavaScript disabled opens a post
- **THEN** the post renders fully in dark mode with working navigation

### Requirement: Token-colored code highlighting
Fenced code blocks with a language SHALL be syntax-highlighted with colors drawn from the design-system tokens, meeting WCAG AA contrast in both modes, with the block styled as a design-system surface (radius, border, monospace font).

#### Scenario: Highlighting follows mode
- **WHEN** a reader toggles the mode on a post containing a Rust code block
- **THEN** the code block's background and token colors switch to the matching mode's palette and remain legible

### Requirement: Design-system components
Recurring UI elements SHALL follow the design system's component specs: post previews as cards, tags as badges, and the mode toggle and pagination links as buttons, including their hover and keyboard-focus states.

#### Scenario: Focus visible
- **WHEN** a keyboard user tabs to a link, tag badge, or button
- **THEN** a visible focus ring in the `ring` token color is shown

### Requirement: Responsive layout
The layout SHALL be readable from 320 px wide phone screens to wide desktop screens: prose limited to a comfortable line length, no horizontal page scrolling, and wide code blocks scrolling within themselves.

#### Scenario: Narrow viewport
- **WHEN** a post with a long code line is viewed at 320 px width
- **THEN** the page does not scroll horizontally and the code block scrolls within its own box

### Requirement: Accessibility baseline
Pages SHALL use semantic landmarks (header, nav, main, footer), declare the document language, provide a skip-to-content link, and keep text and interactive elements at WCAG AA contrast against their backgrounds in both modes.

#### Scenario: Skip link
- **WHEN** a keyboard user presses Tab once on a fresh page load
- **THEN** a "Skip to content" link becomes visible and moves focus to the main content when activated
