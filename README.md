# Stadius

A self-contained CMS built with [Lapis](https://leafo.net/lapis/) and OpenResty. Flat JSON files, no database.

## Quick start

```bash
# Build and run with Docker
docker build -t stadius-dev .
docker run -d --name stadius -p 8080:8080 \
  -v $(pwd):/app \
  stadius-dev:latest \
  openresty -c /app/nginx.conf.compiled -p /app
```

Visit `http://localhost:8080`. Default admin login: `stadius-admin` / `default`.

## Production deploy

```bash
docker compose up -d
```

Set `SESSION_SECRET` in `docker-compose.yml` to a random string.

## What it does

**Content**
- Articles with Markdown editing, tags, visibility (public/private), sorting, search
- Events with RSVP tracking, date picker, organiser, location
- Campaigns with progress bars (percentage or count-based)
- Custom pages with HTML or Markdown content type
- Media library with upload, compression, metadata, and a picker in editors

**Users & permissions**
- Roles: admin, editor, subscriber, reader
- Granular permissions per role for every admin page
- User management with inline editing, subscription dates, join tracking
- Roles refresh from database on every request — no re-login needed

**Design**
- Public-facing serif theme (Fanwood + M Plus 2)
- Admin dark theme with sidebar navigation
- Feather icons throughout the backend
- Toggle switches, progress bars, responsive layouts
- Mobile: icon-only admin sidebar, hamburger public nav

**Features**
- Newsletter signup with CSV export
- Site settings (name, timezone, favicon, logo, contact info, social links, footer links)
- Plugin system with hooks and shortcodes
- Image uploads: auto-resize (3000×3000 max), convert to JPG, compress (quality 85)
- Sortable article listings, tag filtering, search

## Project structure

```
controllers/    Request handlers (MVC)
models/         Data layer (flat JSON files)
modules/        Shared utilities (markdown, images, icons, hooks, JSON)
views/          etlua templates
static/         CSS, fonts, uploaded files
data/           JSON stores (users, articles, events, etc.)
plugins/        Hook-based plugin system
```

## Data

Everything is stored in `data/` as pretty-printed JSON. Back up that folder and `static/uploads/` — that's the entire site state.

## License

MIT
