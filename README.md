# TrashBoy — Plex Unwatched Media Cleanup

**Version: 0.1.2** &nbsp;·&nbsp; *Working title — may eventually be merged into [FolderBoy](https://github.com/sfaith/FolderBoy)*

A PowerShell tool that identifies unwatched or rarely watched media across your Plex libraries and removes it cleanly through [Sonarr](https://sonarr.tv), [Radarr](https://radarr.video), and [Lidarr](https://lidarr.audio). Optionally uses [Tautulli](https://tautulli.com) for accurate, multi-user play history.

---

## How It Works

TrashBoy has three jobs:

1. **Discover** — queries Plex for every item in your libraries and checks play counts
2. **Report** — displays flagged items grouped by library, sorted by play count, with size and last-played date
3. **Delete** — removes confirmed items through the appropriate \*arr API, then tells Plex to rescan the affected libraries

TrashBoy never deletes files directly. All deletions go through Sonarr, Radarr, or Lidarr. If you also want the files removed from disk, that instruction is passed to the \*arr app — TrashBoy itself only makes the API call.

---

## Prerequisites

| Component | Requirement |
|---|---|
| **Operating system** | Windows 10, Windows 11, or Windows Server 2016 or later |
| **PowerShell** | 5.1 or later — built into all supported Windows versions |
| **Plex Media Server** | Running and reachable over the network |
| **Tautulli** | Optional but strongly recommended — v2 or later |
| **Sonarr** | v3 or later, if you manage TV shows |
| **Radarr** | v3 or later, if you manage movies |
| **Lidarr** | v1 or later, if you manage music |

All three \*arr apps are optional — set `Enabled = $false` for any app you don't use.

---

## Tools

### 1. Scan Libraries
Queries Plex (and Tautulli if enabled) for media with a play count at or below your configured threshold. You can scan all libraries at once or narrow to a specific one. At the start of each scan you are prompted to accept the configured threshold or enter a one-time override — useful for exploratory runs without touching the config file.

Results are grouped by library and show:
- Title and year
- Play count (from Tautulli across all users, or Plex owner-only)
- Date added and days since added
- Last played date
- File size
- Which \*arr service manages the item

### 2. Delete Unwatched
Takes the results from the last scan and removes items through their \*arr app. You choose the scope (all flagged items, or a single library) and the delete mode before anything happens.

**Delete modes:**
- **Remove from \*arr only** — the \*arr app forgets the item, files stay on disk. Useful for stopping re-downloads without reclaiming space.
- **Remove from \*arr + delete files** — permanent. Files are gone from disk. This is the mode you want for reclaiming space.

After all deletions complete, TrashBoy sends a light rescan request to Plex for each affected library section in a single batch — one request per library, not per item. Rescan is skipped automatically when files are not deleted, since Plex has nothing new to discover.

### 3. Settings
Displays your current configuration — Plex URL, Tautulli status, play count threshold, \*arr connection details, and the full library map — without requiring you to open the config file.

---

## Setup

### 1. Download the files

Place these files in the same folder:

| File | Purpose |
|---|---|
| `TrashBoy.ps1` | Main script — do not edit |
| `TrashBoy.config.example.ps1` | Configuration template |
| `TrashBoy.bat` | Optional one-click launcher |

### 2. Create your config file

Copy `TrashBoy.config.example.ps1` and rename the copy to `TrashBoy.config.ps1`. This file is gitignored — your API keys and tokens stay off GitHub.

### 3. Fill in your settings

Open `TrashBoy.config.ps1` and fill in your values. See [Configuration](#configuration) below. At minimum you need your Plex token and at least one \*arr API key.

### 4. Run TrashBoy

Double-click `TrashBoy.bat`, or run directly in PowerShell:

```powershell
.\TrashBoy.ps1
```

If you see an execution policy error, use the `.bat` launcher (which bypasses it automatically), or run once as administrator:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

**Recommended first run:** choose **Scan Libraries → All libraries**, review the report, then decide whether to delete anything. Never delete without reviewing a scan first.

---

## Configuration

All settings live in `TrashBoy.config.ps1`. The main script loads this file automatically at startup and validates it before doing anything else.

### Plex

```powershell
$PlexConfig = @{
    BaseUrl = 'http://localhost:32400'
    Token   = 'YOUR_PLEX_TOKEN'
}
```

See [Finding Your Plex Token](#finding-your-plex-token) below.

### Tautulli

```powershell
$TautulliConfig = @{
    Enabled           = $true
    BaseUrl           = 'http://localhost:8181'
    ApiKey            = 'YOUR_TAUTULLI_API_KEY'
    MinWatchedPercent = 50
}
```

Set `Enabled = $false` to fall back to Plex's built-in `viewCount`. See [Data Sources](#data-sources) for why Tautulli is recommended.

`MinWatchedPercent` controls what counts as a play. A value of `50` means a user must have watched at least half the item for it to count. Set to `0` to count any play regardless of length.

Find your Tautulli API key at **Settings → Web Interface → API Key**.

### \*arr apps

```powershell
$RadarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:7878'
    ApiKey  = 'YOUR_RADARR_API_KEY'
}
```

Same structure for `$SonarrConfig` and `$LidarrConfig`. Find API keys at **Settings → General → Security → API Key** in each app. Set `Enabled = $false` for any app you don't use.

### Library Map

```powershell
$LibraryMap = @{
    'TV Shows'       = 'Sonarr'
    'Movies'         = 'Radarr'
    'Documentaries'  = 'Radarr'
    'Holiday_Movies' = 'Radarr'
    'Short Films'    = 'Radarr'
    'Music'          = 'Lidarr'
#   'Music Videos'   = 'Radarr'   # Uncomment to include
#   'Anime'          = 'Sonarr'   # Add your own libraries here
}
```

Maps each Plex library name to the \*arr service that manages it. Rules:

- Library names are **case-sensitive** and must match Plex exactly
- Comment out a line with `#` to exclude a library without deleting it
- Add new libraries by copying any active line and changing the name and service
- Libraries not listed are scanned and reported but **skipped during deletion**
- Run **Settings (option 3)** to see all library names Plex is currently reporting

Valid service values: `'Radarr'`, `'Sonarr'`, `'Lidarr'`

### Scan Settings

```powershell
$ScanConfig = @{
    MaxPlayCount = 0
    SortBy       = 'PlayCount'
}
```

`MaxPlayCount` is the default threshold — items with this many plays or fewer are flagged. You can override this value interactively at scan time without touching the config.

`SortBy` options: `PlayCount` (default), `DateAdded`, `Title`, `Size`

---

## Finding Your Plex Token

1. Open Plex Web in a browser and sign in
2. Browse to any item in your library
3. Click the `(...)` menu → **Get Info** → **View XML** at the bottom of the dialog
4. Your browser opens a URL ending in `?X-Plex-Token=YOURTOKEN`
5. Copy the value after `X-Plex-Token=` — that is your token

**Alternative (Windows server):** open `%LOCALAPPDATA%\Plex Media Server\Preferences.xml` and look for the `PlexOnlineToken` attribute.

Official guide: https://support.plex.tv/articles/204059436

---

## Data Sources

### Tautulli (recommended)

When Tautulli is enabled and reachable, TrashBoy uses it as the authoritative source for play data:

| Feature | Plex only | With Tautulli |
|---|---|---|
| Tracks plays by | Server owner only | All users on your server |
| Short plays counted? | Yes, always | Configurable via `MinWatchedPercent` |
| Last played date | Owner only | Any user, any device |
| Data source | `viewCount` on item | `get_library_media_info` API |

Tautulli data is fetched per library section and cached for the duration of a scan session to avoid redundant API calls.

If Tautulli is enabled in the config but unreachable at startup, TrashBoy warns you and falls back to Plex `viewCount` automatically for that session.

### Plex viewCount (fallback)

When Tautulli is disabled or unavailable, TrashBoy reads `viewCount` directly from the Plex API. This is the owner account's play count only, with no completion threshold.

---

## Plex Library Rescan

After a successful delete run (with files deleted), TrashBoy automatically notifies Plex to rescan each affected library section. This is a batch operation — one lightweight refresh request per library, sent after all deletions are complete, regardless of how many items were removed from that library.

The rescan is skipped when files are kept on disk, since Plex has nothing new to discover.

You will see a `[RESCAN]` entry in the log for each library refreshed:

```
[RESCAN]   'Movies' (section 2)
[RESCAN]   'TV Shows' (section 1)
```

---

## File Reference

| File | Committed | Description |
|---|---|---|
| `TrashBoy.ps1` | ✅ Yes | Main script |
| `TrashBoy.config.example.ps1` | ✅ Yes | Config template with placeholders |
| `TrashBoy.bat` | ✅ Yes | One-click launcher |
| `README.md` | ✅ Yes | This file |
| `CHANGELOG.md` | ✅ Yes | Version history |
| `LICENSE` | ✅ Yes | GNU GPL v3 |
| `.gitignore` | ✅ Yes | Excludes config and log files |
| `TrashBoy.config.ps1` | ❌ No (gitignored) | Your config with real API keys |
| `Logs\` | ❌ No (gitignored) | Runtime logs |

---

## Log Files

Every scan and delete run writes a timestamped log to the `Logs\` subfolder next to `TrashBoy.ps1`.

| Run | Log filename |
|---|---|
| Scan | `TrashBoy_Scan_YYYYMMDD_HHMMSS.log` |
| Delete | `TrashBoy_Delete_YYYYMMDD_HHMMSS.log` |

---

## Troubleshooting

**Config file not found**
Copy `TrashBoy.config.example.ps1` to `TrashBoy.config.ps1` and fill in your values. TrashBoy prints setup instructions if the file is missing.

**"Could not reach API" at startup**
Confirm the `BaseUrl` matches what you use to access the app in a browser. Check the app is running and reachable from the machine running TrashBoy. Copy the API key fresh from Settings → General in the app.

**Plex token errors**
Tokens obtained via the Get Info → View XML method are temporary. If TrashBoy loses Plex access after a while, retrieve a fresh token. For a permanent token, follow the third-party app authentication guide in the Plex developer forum.

**Item shows 0 plays in Tautulli but I know I watched it**
Check that Tautulli was running and logging when you watched it — Tautulli can only record plays it observed in real time. It cannot import historical plays from before it was installed. Also check that history logging is enabled for the relevant library and user in Tautulli's settings.

**No match found warnings during delete**
TrashBoy matches items to \*arr using GUIDs (TMDB ID, TVDB ID, IMDb ID, MusicBrainz ID) sourced from Plex metadata, with a title fallback. If neither matches, the item is skipped. This usually means Plex and the \*arr app have different metadata for the item. Check the match manually in the \*arr UI.

**Execution policy error**
Use the `.bat` launcher, or run once as administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Screenshots

*Coming soon.*

---

## Planned Features

- CSV export of scan results
- Interactive item-by-item review before deletion (queue-and-confirm flow)
- Per-library play count threshold overrides
- Filter by minimum age (only flag items added more than N days ago)
- Scheduled / unattended execution via Windows Task Scheduler
- Potential merge with [FolderBoy](https://github.com/sfaith/FolderBoy) — TBD

---

## Contributing

Pull requests welcome. If you hit a matching failure, API error, or unexpected deletion, open an issue and include the relevant section of the log file from `Logs\`.

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for full text.

---

## References

- [Tautulli](https://tautulli.com) — monitoring and tracking for Plex Media Server
- [Tautulli API Reference](https://docs.tautulli.com/extending-tautulli/api-reference)
- [Finding your Plex token](https://support.plex.tv/articles/204059436)
- [Sonarr](https://sonarr.tv) | [Radarr](https://radarr.video) | [Lidarr](https://lidarr.audio)
- [FolderBoy](https://github.com/sfaith/FolderBoy) — companion tool for \*arr library management
