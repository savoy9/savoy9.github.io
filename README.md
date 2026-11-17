# Alex Dupler's field notebook

A small Jekyll site about Power BI, DAX, and data modeling, hosted at
<https://savoy9.github.io>. No JavaScript framework, CMS, analytics, or external fonts.

## Local preview

Install Ruby **3.4.12** (see `.ruby-version`) and Bundler **2.6.9**. On Windows,
use RubyInstaller with Devkit or run in WSL. Native gems may require build tools.

```sh
gem install bundler -v 2.6.9
bundle install
bundle exec jekyll serve --host 127.0.0.1
```

Open <http://127.0.0.1:4000>. Restart Jekyll after editing `_config.yml`.
`Gemfile.lock` pins the dependency graph; CI installs it without resolving new versions.
The only content plugins are the Atom feed, sitemap, and a small local Rouge lexer
for DAX syntax highlighting.
The social image uses `images/notebook.png` (1200 x 630); its editable, authored
source is `images/notebook.svg`. Keep a PNG export for social crawlers.
If your environment requires a private gem mirror, configure Bundler locally; never
commit credentials. JavaScript only enhances code examples with keyboard focus and
copy controls; the full content works without it. Copy controls require a secure
context (HTTPS or localhost).

## Writing and drafts

Published posts live in `_posts/YYYY-MM-DD-title.md`. Include front matter:

```yaml
---
layout: post
title: Your title
date: 2026-01-01
permalink: /Your-Stable-Route/
summary: A short, factual summary.
topics: [Power BI, DAX]
---
```

Only the two original series posts use `series_part`; leave it unset for standalone
posts. `archived: true` displays the 2019 archive notice; do not apply it to new
writing or imply an old post has been technically reviewed. Use fenced `dax` blocks,
meaningful image alt text, and visible figure
captions. Keep assets under `images/` and use `relative_url` for internal links.
Preserve existing case-sensitive permalinks and original publication dates.

Unpublished sources live in `_drafts/`, explicitly excluded from all builds,
including `--drafts`. They are **not private**: this is a public source repository.
For local draft preview, copy a draft into `_posts/` on a disposable local branch,
add valid front matter and `published: false`, and run `jekyll serve --unpublished`.
Do not commit that preview copy. Publishing requires an intentional move to
`_posts/`, a real publication date, metadata, and removal of `published: false`.
Never put unpublished Markdown in an ordinary `drafts/` directory.

The 2019 posts are an archive, not technically re-reviewed guidance. Their dates
and code semantics are preserved. The About page retains its original biography
with a status notice; updating the biography or validating current Power BI
behavior requires an editorial review.

## Production build and checks

```sh
bundle exec ruby tests/site_check_test.rb
bundle exec jekyll clean
JEKYLL_ENV=production bundle exec jekyll build --trace
bundle exec ruby scripts/check_site.rb
```

In PowerShell, set `$env:JEKYLL_ENV = "production"` before the build instead of
using the inline environment assignment. Jekyll cleans the destination on each
ordinary build; don't use `--incremental` for release checks.

The checker verifies local links/assets and fragments with exact case, required
routes/dates, HTTPS canonicals and social metadata, feed/sitemap URLs, accessible
document structure, no obsolete analytics, and absence of drafts and source-only
files. External links are not fetched in CI: remote uptime and historic product
claims require separate editorial review.

## GitHub Pages activation

The repository previously published directly from **master / (root)** using the
legacy Pages builder. Adding this workflow does **not** change that remote setting.
Before merging these publishing changes, an authorized owner must select
**Settings > Pages > Build and deployment > Source > GitHub Actions**, then run
**Build and publish notebook** on `master` after merging if needed. Until the source
is switched, the legacy builder may still publish unchecked changes pushed to
`master`. No custom domain is configured.
Do not publish this site through the old branch builder: it does not use this
lockfile or run the publication checks.

The workflow builds and checks pull requests without deployment credentials.
Only a successful checked `master` build can deploy the exact uploaded artifact.
The `github-pages` environment may require owner approval. Actions are pinned to
commit SHAs; review dependency/action updates deliberately, refresh the lockfile,
and rerun the build and checks. No replacement analytics is configured.

## Attribution

Originally based on [Jekyll Now](https://github.com/barryclark/jekyll-now) by
Barry Clark. The original MIT copyright and permission notice remains in `LICENSE`.
The 404 Constructocat illustration is credited in its alt text to
[Jason Costello](https://github.com/jasoncostello).
