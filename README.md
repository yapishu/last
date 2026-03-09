# %last

## `|install ~matwet %last`

A universal social scrobbler for Urbit. Record what you're listening to, watching, playing, or reading — and see what your pals are up to.

<img width="638" height="342" alt="image" src="https://github.com/user-attachments/assets/04945408-bf9e-4ec9-be0a-ce977106730c" />

## Features

- **Universal scrobbles** — not just music: any verb/name pair (listening, watching, playing, reading, etc.)
- **Social feed** — see scrobbles from mutual pals, filterable by verb
- **Reactions** — like and comment on scrobbles (yours and friends')
- **Stats** — total counts, breakdown by verb, top items
- **Webhook** — POST scrobbles from external services (basic auth, Last.fm-compatible fields)
- **Public feed** — unauthenticated, CORS-enabled JSON feed for embedding
- **S3 upload** — attach images via S3 (uses system `%storage` config)
- **Pals integration** — discovers mutuals via `%pals` and `%contacts` (won't crash without them)
- **Peer subscriptions** — mutuals subscribe to each other's scrobble feeds over Urbit
- **Dark UI** — clean, minimal interface with Inter font

## Structure

```
desk/                     Urbit desk (deployed to ship)
  app/last.hoon             Main agent — API, state, subscriptions, webhook
  sur/last.hoon             Types: scrobble, reaction, state-0, action, update
  mar/last-action.hoon      JSON<->noun action mark
  mar/last-update.hoon      Update mark for subscription facts
  lib/                      Standard libraries (server, dbug, etc.)

ui/                       Frontend source (Vite)
  index.html                SPA entry point
  js/api.js                 API client (LastAPI)
  js/app.js                 UI — feed, friends, stats, settings views
  js/s3.js                  S3 upload with AWS Sig V4 (Web Crypto API)
  css/app.css               Styles
  vite.config.js            Vite config — uses vite-plugin-singlefile
```

## Development

### Frontend

```sh
cd ui
npm install
npm run dev
```

Build uses `vite-plugin-singlefile` to inline all JS/CSS into a single `index.html` for glob distribution.

```sh
npm run build    # outputs to ui/dist/
```

## API

All endpoints under `/apps/last/api`. Authenticated endpoints require an Eyre session cookie.

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/feed` | Eyre | Your scrobbles with reactions |
| GET | `/peers` | Eyre | Mutual pals' scrobbles (triggers subscriptions) |
| GET | `/stats` | Eyre | Total, by-verb counts, top 10 items |
| GET | `/pals` | Eyre | List of mutual pals |
| GET | `/settings` | Eyre | Ship name, public flag |
| GET | `/s3-config` | Eyre | S3 credentials from system `%storage` |
| GET | `/public/feed` | None | Public feed (CORS enabled) |
| POST | `/` | Eyre | Poke with action JSON |
| POST | `/webhook` | Basic | Scrobble from external services |

### Actions (POST `/`)

```json
{"action": "scrobble", "sid": "0v...", "verb": "listening", "name": "Album Name", "image": "", "source": "manual"}
{"action": "delete", "sid": "0v..."}
{"action": "set-public", "public": true}
{"action": "react", "target": "~ship", "sid": "0v...", "type": "like", "text": ""}
{"action": "react", "target": "~ship", "sid": "0v...", "type": "comment", "text": "nice!"}
```

### Webhook (POST `/webhook`)

Accepts JSON or form-encoded bodies. Authenticated with Basic Auth (username: anything, password: your ship's `+code`).

**Native format (JSON):**
```json
{"verb": "listening", "name": "Radiohead - OK Computer", "image": "https://..."}
```

**Last.fm-compatible (JSON or form-encoded):**
```json
{"artist": "Radiohead", "track": "Paranoid Android"}
```
```
artist=Radiohead&track=Paranoid+Android&timestamp=1234567890
```

When `artist` and `track` are provided without `name`, they are combined as `"Artist - Track"` with verb defaulting to `"listening"`.

## Notes

- S3 upload requires HTTPS or localhost (Web Crypto API).
- The agent is self-contained: it works with `%pals` and `%contacts` when present but does not depend on them.
- Frontend is distributed as a glob via docket.
