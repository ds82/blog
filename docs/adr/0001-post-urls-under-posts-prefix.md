# Post URLs live under `/posts/<slug>/`

Post URLs are permanent once published, so the scheme was chosen up front. Every Post lives at `/posts/<slug>/`: no date in the path, and not at the root. Root-level slugs would share a namespace with Pages and site routes (`/about/`, `/tags/`, `/search/`). Year prefixes add noise without real benefit for a low-volume blog. A per-kind prefix also leaves room for a future content kind (e.g. `/notes/<slug>/`) to sit beside Posts without moving anything. `/blog/` was rejected because it repeats the subdomain.
