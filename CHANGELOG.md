# Changelog

All notable changes to TrashBoy are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- CSV export of scan results
- Per-library play count threshold overrides
- Scheduled / unattended execution support (Windows Task Scheduler)
- Filter by minimum age (only flag items added more than N days ago)
- Size threshold filter (only flag items above a minimum file size)
- Pre-delete *arr match validation (warn before attempting deletion if
  an item is unlikely to match, e.g. raw torrent filenames)

---

## [0.2.4] - 2026-05-22

### Fixed
- **UTF-8 encoding corruption in Plex API responses** -- `Invoke-RestMethod`
  was misinterpreting non-ASCII characters in artist and title names returned
  by the Plex API, displaying `MÃ¶tley CrÃ¼e` instead of `Mötley Crüe`,
  `BjÃ¶rk` instead of `Björk`, etc. Root cause: PowerShell was decoding the
  response bytes as Latin-1 rather than UTF-8. Fixed by switching
  `Invoke-PlexApi` to `Invoke-WebRequest`, reading `RawContentStream` bytes
  directly, and decoding explicitly with
  `[System.Text.Encoding]::UTF8.GetString()` before passing to
  `ConvertFrom-Json`. This affects display in reports, logs, and Lidarr
  name matching for artists with special characters.

---

## [0.2.3] - 2026-05-22

### Fixed
- **Plex rescan crash after single-library deletion** -- `Sort-Object -Unique`
  on a pipeline with one item returns the item itself rather than a
  one-element array. Calling `.Count` on a plain string throws under
  `Set-StrictMode`. Wrapped the assignment in `@()` to guarantee an array
  regardless of how many sections are returned. Deletion itself succeeded;
  only the rescan notification was affected.

---

## [0.2.2] - 2026-05-22

### Changed
- **Scope selection prompt reworded** -- the first prompt in the delete
  flow previously read `Which items to delete:` with options like
  `All 3555 flagged item(s) from last scan`, which implied an immediate
  commitment. Now reads `Select scope -- you will review items and confirm
  before anything is deleted:` with options `All libraries -- N item(s)
  flagged` and `Choose a specific library`. Makes clear that choosing a
  scope is just the starting point of a review process, not a delete trigger.

---

## [0.2.1] - 2026-05-22

### Added
- **Manual item selection before deletion** -- after reviewing the flagged
  item list, the user can now choose between deleting all items or manually
  selecting a subset by number. Selection supports individual numbers,
  comma-separated lists, and ranges (e.g. `1,3,5-8,12`). `A` selects all.
  `M` returns to the menu. Invalid input is rejected with a clear error and
  re-prompted. The final delete confirmation (`YES`) reflects only the
  selected items.
- **`Select-ItemsForDeletion` helper** -- parses the comma/range selection
  input and returns the chosen subset of items.
- **`Show-ItemList` `ShowNumbers` parameter** -- when `$true`, each item row
  is prefixed with a sequential number (right-aligned, 4 chars) instead of
  the `│` tree character, enabling the selection prompt to work across
  library groups naturally.

### Changed
- Delete flow step labels updated: Step 2 header changed from
  `ITEMS QUEUED FOR DELETION` to `FLAGGED ITEMS` since items are not yet
  queued at that point -- the selection step comes after.

---

## [0.2.0] - 2026-05-22

### Changed
- **Delete flow redesigned -- items shown before any commitment**
  Previously the user chose a scope, chose a delete mode, then typed
  YES -- without ever seeing what was about to be deleted. The new flow is:
  1. Choose scope (all / by library)
  2. **Item list displayed** -- same grouped format as the scan report,
     showing every item that would be deleted with plays, dates, size,
     and service. Total reclaimable space shown at the top.
  3. Reminder that nothing is deleted until YES is typed
  4. Choose delete mode
  5. Type YES to confirm
  This applies to both the "all items" and "choose a library" paths.
- **`Show-ItemList` helper** -- item list display logic extracted into a
  reusable function used by both the scan report and the pre-delete
  preview. Accepts a `WriteToLog` flag so the same function works for
  both console-only display (delete preview) and log-writing display
  (scan report).

---

## [0.1.6] - 2026-05-22

### Fixed
- **Full strict mode audit** -- comprehensive pass over all Plex API property
  accesses in the scan functions. Every access that could throw under
  `Set-StrictMode -Version Latest` now uses `PSObject.Properties['name']`
  guards. Specific fixes:
  - `Get-ItemSizeBytes` -- `Media`, `Part`, and `size` all guarded
  - `$epData.MediaContainer.Metadata` in show Plex fallback block
  - `$epData2.MediaContainer.Metadata` in show size calculation
  - `$trackData.MediaContainer.Metadata` in artist Plex fallback block
  - `$trackData2.MediaContainer.Metadata` in artist size calculation
    (this was the crash at artist 679/723 "Unknown Artist")
- **Progress line collision with Tautulli cache load messages** --
  `Clear-Progress` now called before the "Loading Tautulli play data"
  and "N item(s) loaded" lines in `Get-TautulliSectionCache`, preventing
  the scan progress line and the cache message from overwriting each other.

---

## [0.1.5] - 2026-05-22

### Fixed
- **Strict mode crash in `Get-GuidValue`** -- `Where-Object { $_.id -like ... }`
  throws under `Set-StrictMode -Version Latest` when a Guid object in the
  collection does not have an `id` property. Fixed by adding
  `$_.PSObject.Properties['id']` guard inside the `Where-Object` filter, and
  a matching `$Item.PSObject.Properties['Guid']` guard on the outer check.

---

## [0.1.4] - 2026-05-22

### Fixed
- **Null DateTime crash in `Get-PlayInfo`** -- the `-PlexLastViewed` parameter
  was typed as `[DateTime]`, which PowerShell cannot bind `$null` to. Items
  that have never been played have no `lastViewedAt` field so `$null` was
  always passed for unwatched items. Changed to `[nullable[DateTime]]`.

### Changed
- **Scope menu shows mapped libraries only** -- the scan scope selection menu
  (option 1) previously listed all Plex libraries including unmapped ones.
  Selecting an unmapped library would scan nothing and produce an empty report.
  The menu now filters to mapped libraries only, matching what the scan
  itself will actually process.

---

## [0.1.3] - 2026-05-22

### Fixed
- **Strict mode `viewCount` crash** -- `Set-StrictMode -Version Latest` throws
  when accessing a property that doesn't exist on an object. Plex omits
  `viewCount`, `lastViewedAt`, and `year` entirely on items that have never
  been played rather than returning null. All property accesses in the movie,
  TV show, artist, episode, and track scan blocks now use
  `$obj.PSObject.Properties['propertyName']` safe-access checks before
  reading the value. This was the immediate crash on first scan run.

### Added
- **Skip unmapped libraries at scan time** -- libraries not present in
  `$LibraryMap` are now excluded before scanning begins. The library
  discovery output labels them `(unmapped -- will skip)` and a summary
  line lists which libraries were skipped and why. Previously unmapped
  libraries were scanned and then silently ignored at delete time, which
  wasted API calls and caused the strict mode crash on libraries like
  `Adult` that were never intended to be managed by TrashBoy.
- **`Holiday Movies` typo fixed** in personal config and example config --
  was `Holiday_Movies` (underscore), Plex reports it as `Holiday Movies`
  (space), so it was never matching.
- **`Comedy` library** added to personal config mapped to Radarr.
- **Full Plex token retrieval instructions** moved into both config files
  inside the `$PlexConfig` comment block -- no longer requires opening
  the main script or README.
- **Tautulli API key location** documented inline in both config files:
  `Tautulli > Settings > Web Interface > scroll to the bottom > API Key`
- **`*arr` API key locations** documented inline in both config files for
  each service: `Settings > General > Security > API Key`

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
