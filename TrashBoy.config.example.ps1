# ================================================================
#  TrashBoy.config.example.ps1  |  Configuration Template  |  v0.2.4
#
#  Copy this file to TrashBoy.config.ps1 and fill in your values.
#  TrashBoy.config.ps1 is excluded from source control via .gitignore
#  so your API keys and tokens stay private.
# ================================================================

# ----------------------------------------------------------------
#  PLEX
#
#  BaseUrl : URL used to reach your Plex Media Server.
#            Use http://localhost:32400 if running on the same machine.
#            Use http://HOSTNAME:32400 or http://IP:32400 for remote.
#
#  Token   : Your Plex authentication token (X-Plex-Token).
#
#  HOW TO FIND YOUR PLEX TOKEN:
#    1. Open Plex Web in a browser and sign in
#    2. Browse to any item in your library and click the (...) menu
#    3. Click "Get Info", then "View XML" at the bottom of the dialog
#    4. Your browser opens a URL ending in ?X-Plex-Token=YOURTOKEN
#    5. Copy the value after X-Plex-Token= -- that is your token
#
#  Alternative (Windows server):
#    Open %LOCALAPPDATA%\Plex Media Server\Preferences.xml
#    and look for the PlexOnlineToken attribute.
#
#  Official guide: https://support.plex.tv/articles/204059436
# ----------------------------------------------------------------
$PlexConfig = @{
    BaseUrl = 'http://localhost:32400'   # CHANGE ME
    Token   = 'YOUR_PLEX_TOKEN'          # CHANGE ME
}

# ----------------------------------------------------------------
#  TAUTULLI  (optional, but recommended)
#
#  When enabled, TrashBoy uses Tautulli as its play-data source
#  instead of Plex's built-in viewCount. Benefits:
#    - Play counts from ALL users, not just the server owner
#    - MinWatchedPercent threshold filters out accidental short plays
#    - Accurate last-played timestamps across all users
#
#  Set Enabled = $false to fall back to Plex viewCount only.
#
#  BaseUrl           : URL you use to access Tautulli in a browser.
#                      Default port is 8181.
#
#  ApiKey            : Tautulli > Settings > Web Interface >
#                      scroll to the bottom > API Key
#
#  MinWatchedPercent : A play only counts if the user watched at
#                      least this percentage of the item.
#                      Default 50. Set to 0 to count any play.
# ----------------------------------------------------------------
$TautulliConfig = @{
    Enabled           = $true
    BaseUrl           = 'http://localhost:8181'   # CHANGE ME
    ApiKey            = 'YOUR_TAUTULLI_API_KEY'   # CHANGE ME
    MinWatchedPercent = 50
}

# ----------------------------------------------------------------
#  RADARR
#
#  Enabled : $true to use Radarr for deletions, $false to skip.
#  ApiKey  : Radarr > Settings > General > Security > API Key
# ----------------------------------------------------------------
$RadarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:7878'   # CHANGE ME
    ApiKey  = 'YOUR_RADARR_API_KEY'    # CHANGE ME
}

# ----------------------------------------------------------------
#  SONARR
#
#  Enabled : $true to use Sonarr for deletions, $false to skip.
#  ApiKey  : Sonarr > Settings > General > Security > API Key
# ----------------------------------------------------------------
$SonarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:8989'   # CHANGE ME
    ApiKey  = 'YOUR_SONARR_API_KEY'    # CHANGE ME
}

# ----------------------------------------------------------------
#  LIDARR
#
#  Enabled : $true to use Lidarr for deletions, $false to skip.
#  ApiKey  : Lidarr > Settings > General > Security > API Key
# ----------------------------------------------------------------
$LidarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:8686'   # CHANGE ME
    ApiKey  = 'YOUR_LIDARR_API_KEY'    # CHANGE ME
}

# ----------------------------------------------------------------
#  LIBRARY MAP
#
#  Maps each Plex library name to the *arr service that manages it.
#  Valid values: 'Radarr', 'Sonarr', 'Lidarr'
#
#  HOW TO USE:
#    Active entry    -- 'Library Name' = 'Service'
#    Commented out   -- prefix with # to disable without deleting
#    Add new library -- copy any active line, change name and service
#    Unmapped        -- libraries not listed here are skipped entirely
#                       at scan time. Nothing is reported or deleted
#                       for libraries that are not in this map.
#
#  Library names are case-sensitive and must match Plex exactly.
#  Run TrashBoy and choose Settings (option 3) to see all library
#  names Plex is currently reporting, then copy them here exactly.
# ----------------------------------------------------------------
$LibraryMap = @{
    'TV Shows'       = 'Sonarr'
    'Movies'         = 'Radarr'
    'Documentaries'  = 'Radarr'   # Change to 'Sonarr' for TV-style documentary series
    'Holiday Movies' = 'Radarr'
    'Short Films'    = 'Radarr'
    'Music'          = 'Lidarr'
#   'Music Videos'   = 'Radarr'   # Uncomment to include
#   'Anime'          = 'Sonarr'   # Example -- add your own libraries below
}

# ----------------------------------------------------------------
#  SCAN SETTINGS
#
#  MaxPlayCount : Default threshold -- items with this many plays
#                or fewer are flagged. TrashBoy will prompt you to
#                accept or override this at scan time without
#                touching this file.
#                0 = never played. 1 = played once or never. Etc.
#                When Tautulli is enabled, only plays meeting
#                MinWatchedPercent count toward this total.
#
#  SortBy       : Default sort order for the report.
#                   PlayCount  -- fewest plays first, then oldest
#                   DateAdded  -- oldest additions first
#                   Title      -- alphabetical
#                   Size       -- largest items first
# ----------------------------------------------------------------
$ScanConfig = @{
    MaxPlayCount = 0
    SortBy       = 'PlayCount'   # PlayCount | DateAdded | Title | Size
}
