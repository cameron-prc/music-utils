# Music Schema Design Notes

## Purpose

Sync playlists from Spotify to Navidrome. The local DB acts as the join layer between the two systems: `spotify_id` ↔ local record ↔ `subsonic_id`.

## Entities

- **Artist** — name
- **Album** — title, release_date
- **Track** — title, album_id (nullable), track_number (nullable)
- **Playlist** — name

## Join Tables

| Table | Columns | Notes |
|---|---|---|
| `album_artists` | album_id, artist_id, position | position 1 = primary artist |
| `track_artists` | track_id, artist_id, position | position 1 = primary artist |
| `playlist_tracks` | playlist_id, track_id, position | defines playback order |

## External IDs

External IDs are stored in per-entity junction tables rather than as columns on the entity tables. This avoids schema migrations whenever a new integration is added — new sources are rows, not columns.

| Table | Columns | Notes |
|---|---|---|
| `track_external_ids` | track_id, source, external_id, synced_at | FK to tracks |
| `album_external_ids` | album_id, source, external_id, synced_at | FK to albums |
| `artist_external_ids` | artist_id, source, external_id, synced_at | FK to artists |
| `playlist_external_ids` | playlist_id, source, external_id, synced_at | FK to playlists |

`source` is a string (e.g. `'spotify'`, `'musicbrainz'`, `'youtube'`, `'local'`, `'navidrome'`). Unique index on `(entity_id, source)` enforces one ID per source per entity. `synced_at` follows the same null = never synced convention as before.

## Key Decisions

- **Primary artist** is modeled via `position: 1` on join tables — no redundant boolean flag.
- **Track belongs to album** via `album_id` directly on `tracks` (not a join table) — a track belongs to at most one album. Compilations that reuse tracks are represented as playlists.
- **track_number** and **album_id** are nullable to support standalone singles.
- Unique index on `[parent_id, position]` in all join tables enforces ordering integrity at the DB level.
- **subsonic_id** on tracks (not file path) — stable across file moves, and available directly from the Navidrome Subsonic API.
- **synced_at timestamps** — null means the entity has never been synced from that source; populated means the last successful sync time. Used to distinguish unsynced from synced records.
- **External IDs in junction tables** — see External IDs section. Avoids rebuilding entity tables (SQLite has no real ALTER TABLE) each time an integration is added.

## Compilation Albums

Convention: use **"Various Artists"** as the album artist (matching iTunes/MusicBrainz/Beets).

Preferred approach: create a real `Artist` record with `name: "Various Artists"` and assign it `position: 1` in `album_artists`. No schema changes required. Individual track artists are stored normally via `track_artists`.
