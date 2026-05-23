# Changelog

All notable changes to TrashBoy are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- CSV export of scan results
- Per-library play count threshold overrides
- Interactive item-by-item review before deletion (queue-and-confirm flow)
- Scheduled / unattended execution support (Windows Task Scheduler)
- Filter by minimum age (only flag items added more than N days ago)

---

## [0.1.2] - 2026-05-22

### Added
- **Plex library rescan after deletion** -- after a successful delete run
  (files deleted), TrashBoy automatically sends a light refresh request to
  Plex for each affected library section. This is a batch operation: one
  request per unique library section, fired after all deletions complete,
  regardless of how many items were removed from that section.
  Rescan is skipped automatically when files are kept on disk, since Plex
  has nothing new to discover. A `[RESCAN]` log entry is written for each
  section refreshed, and `[RESCAN FAILED]` if the Plex API call fails.
- **`PlexSectionId`** field added to all scan result objects (movies, TV
  shows, artists) so the delete function knows which Plex section to refresh
  without a second API call.
- **`$deletedItems` tracking** in `Invoke-Delete` -- successfully deleted
  items are collected during the loop and used for the batch rescan at the
  end, keeping the rescan logic entirely separate from the per-item loop.
- **README.md** -- initial public README covering prerequisites, how it
  works, setup, configuration, data sources, Plex rescan behaviour, file
  reference, log files, troubleshooting, and planned features.
- **LICENSE** -- GNU General Public License v3, matching FolderBoy.

---

## [0.1.1] - 2026-05-22

### Added
- **Runtime `MaxPlayCount` override** -- at the start of each scan TrashBoy
  now prompts `Max play count threshold [N] -- press Enter to accept, or type
  a number to override`. Press Enter to use the config default; type any
  non-negative integer to override for that run only without touching the
  config file. The report header notes when an override is active.
- **`TrashBoy.config.ps1`** populated from existing config values plus new
  `$TautulliConfig` block (Tautulli URL: `plex.lan.chaosnetwork.org:8181`).
  Lidarr API key trailing `Y` typo corrected.
- **`$LibraryMap` usage comments** explain active entries, how to comment out
  libraries without deleting them, and how to add new ones. Example commented
  entries (`Music Videos`, `Anime`) shown as templates.
- **Config version header** updated to v0.1.1 in both `TrashBoy.config.ps1`
  and `TrashBoy.config.example.ps1`.

### Changed
- `MaxViewCount` renamed to `MaxPlayCount` in config files to match the
  rename introduced in v0.1.0. Backward-compatible key promotion retained
  in the main script.

---

## [0.1.0] - 2026-05-22

### Added
- **Tautulli integration** (optional play data source). When
  `TautulliConfig.Enabled = $true`, TrashBoy uses Tautulli's watch history
  as its source of truth for play counts instead of Plex's built-in
  `viewCount`. Advantages over Plex-only mode:
  - Counts plays from **all users** on the server, not just the owner
  - `MinWatchedPercent` threshold (default 50%) -- a play is only counted
    if the user watched at least that percentage of the item, so accidental
    starts or brief previews do not count as watches
  - Accurate `last played` timestamps across all users
  - Movies: validated against `MinWatchedPercent` via `get_history`
  - TV shows / artists: uses show/artist-level aggregate play count from
    `get_library_media_info` (covers all episodes/tracks across all users)
  - Paginated `get_library_media_info` fetch (1,000 items per page) handles
    large libraries without truncation
  - Falls back to Plex `viewCount` automatically if Tautulli is unreachable
- **`$TautulliConfig`** block added to config template with `Enabled`,
  `BaseUrl`, `ApiKey`, and `MinWatchedPercent` settings.
- **Tautulli connection check** at startup -- shown in the connection widget
  alongside Plex and the *arr apps. If enabled but unreachable, TrashBoy
  warns and falls back to Plex mode for that session.
- **Play data source banner** in scan output and report header so it is
  always clear whether results came from Tautulli or Plex viewCount.
- **Tautulli status in main menu** connection widget -- shows OK/UNREACHABLE
  and the active `MinWatchedPercent` value when connected.
- **`$TautulliCache`** -- Tautulli `get_library_media_info` results are
  cached per section ID within a session to avoid redundant API calls when
  rescanning the same library.
- **Plex token retrieval instructions** added to both the script header
  and the config example file. Short version: Plex Web > any item >
  (...) > Get Info > View XML > copy token from URL.
- Renamed `MaxViewCount` → `MaxPlayCount` throughout (config, output,
  session log) to reflect that Tautulli counts qualifying plays rather
  than raw Plex view counts. Backward-compatible: old `MaxViewCount` key
  in config is automatically promoted to `MaxPlayCount` at startup.

### Changed
- Connection check widget now shows Tautulli between Plex and the *arr apps.
- Settings tool (option 3) now shows Tautulli config alongside Plex config.
- Report columns renamed from `Views` → `Plays` and `LastViewed` → `LastPlayed`.

---

## [0.0.1] - 2026-05-22

### Added
- Initial release.
- **Scan Libraries (Tool 1)** -- queries Plex for unwatched or rarely watched
  media across all configured libraries. Scope can be narrowed to a single
  library via an interactive menu. Results grouped by library, sorted by play
  count (then date added), with size, last-played date, and *arr service shown
  per item. Total reclaimable space displayed in summary.
- **Delete Unwatched (Tool 2)** -- takes results from the last scan and removes
  items via the appropriate *arr API (Sonarr, Radarr, or Lidarr). Two delete
  modes: remove from *arr only (files stay on disk), or remove from *arr and
  delete all files. Scope can be narrowed to a single library. Requires an
  explicit YES confirmation before any deletions occur.
- **Settings (Tool 3)** -- displays current config (Plex URL, thresholds,
  *arr connection details, library map) without requiring the user to open the
  config file.
- **Config file separation** -- all user settings live in `TrashBoy.config.ps1`
  (excluded from source control). `TrashBoy.config.example.ps1` provides a
  commented template. Main script validates required variables at startup and
  exits with clear guidance if any are missing or the file cannot be loaded.
- **Connection check at startup** -- tests Plex and all enabled *arr APIs on
  launch. Results shown in the main menu status widget throughout the session.
- **Library map** (`$LibraryMap`) -- maps Plex library names to their managing
  *arr service. Libraries not in the map are scanned and reported but skipped
  during deletion.
- **Scan settings** (`$ScanConfig`) -- `MaxPlayCount` threshold (default 0 =
  never watched) and `SortBy` option (PlayCount, DateAdded, Title, Size).
- **GUID-based *arr matching** -- deletion uses TMDB, TVDB, IMDb, or MusicBrainz
  IDs sourced from Plex metadata for reliable cross-app matching, with title
  fallback.
- **TV shows** evaluated at series level: if any episode exceeds `MaxPlayCount`
  the entire series is excluded from results.
- **Music** evaluated at artist level: if any track exceeds `MaxPlayCount` the
  entire artist is excluded from results.
- **Session log** -- a timestamped entry with elapsed time is added after each
  tool run and displayed in the main menu.
- **Logs folder** -- each scan and delete run writes a timestamped log to
  `Logs\TrashBoy_*.log` alongside the script.
- `TrashBoy.bat` launcher for double-click execution.
