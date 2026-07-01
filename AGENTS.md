# AGENTS.md

Guidance for coding agents working in this repository.

## Project

This is The Aleph Project / Mooneghan Chronicles, a Hakyll static site built in
Haskell. Content is written mostly as Org-mode files and compiled into `_site/`.

## Commands

Use `just` for routine work:

- `just build` - build the static site with `cabal run blog build`
- `just clean` - remove generated Hakyll output and cache
- `just rebuild` - clean, then build
- `just serve` - rebuild and serve at `http://127.0.0.1:8000`
- `just watch` - watch files and rebuild during development

The executable is defined in `TheAlephProject.cabal` as `blog`.

## Layout

- `src/Main.hs` - Hakyll routing and compilation rules
- `src/Mooneghan/Contexts.hs` - shared template contexts and site metadata
- `index.org`, `about/`, `posts/` - source content
- `templates/` - Hakyll HTML/XML templates
- `static/css/`, `static/js/`, `static/images/`, `static/assets/` - static assets

## Working Rules

- Keep generated files out of commits: `_site/`, `_cache/`, `dist-newstyle/`,
  `.wrangler/`, and `image-edits/` are local/generated or tool state.
- Do not commit Cloudflare/Wrangler cache data. `.wrangler/cache/` can contain
  account identifiers and project metadata.
- Before changing templates or routes, check the corresponding contexts in
  `src/Mooneghan/Contexts.hs`.
- Prefer existing CSS files and template structure over introducing new
  frontend conventions.
- Validate Haskell changes with `just build` when practical.

