# ================================================================
#  TrashBoy.config.ps1  |  User Configuration  |  v0.1.4
#
#  This file is excluded from source control via .gitignore.
#  Your API keys and tokens stay private.
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
# ----------------------------------------------------------------
$PlexConfig = @{
    BaseUrl = 'http://plex:32400'
    Token   = 'NWSNjKA7xVXCgJavyKsR'
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
    BaseUrl           = 'http://plex.lan.chaosnetwork.org:8181'
    ApiKey            = '691e4ca40d8343adb267760854a4ff4c'
    MinWatchedPercent = 50
}

# ----------------------------------------------------------------
#  RADARR
#
#  ApiKey : Radarr > Settings > General > Security > API Key
# ----------------------------------------------------------------
$RadarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://mediafrenzy:7878'
    ApiKey  = '4b45948567dc46aea242abbe5196ba47'
}

# ----------------------------------------------------------------
#  SONARR
#
#  ApiKey : Sonarr > Settings > General > Security > API Key
# ----------------------------------------------------------------
$SonarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://mediafrenzy:8989'
    ApiKey  = '3f012d016bfb460189ce51db96041ab0'
}

# ----------------------------------------------------------------
#  LIDARR
#
#  ApiKey : Lidarr > Settings > General > Security > API Key
# ----------------------------------------------------------------
$LidarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://mediafrenzy:8686'
    ApiKey  = '6651f4e5e08f4d46be756565856d7baa'
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
#
#  Library names are case-sensitive and must match Plex exactly.
#  Run TrashBoy and choose Settings (option 3) to see all library
#  names Plex is currently reporting.
# ----------------------------------------------------------------
$LibraryMap = @{
    'TV Shows'       = 'Sonarr'
    'Movies'         = 'Radarr'
    'Documentaries'  = 'Radarr'
    'Holiday Movies' = 'Radarr'
    'Short Films'    = 'Radarr'
    'Music'          = 'Lidarr'
    'Comedy'         = 'Radarr'
#   'Music Videos'   = 'Radarr'   # Uncomment to include
#   'Anime'          = 'Sonarr'   # Uncomment to include
}

# ----------------------------------------------------------------
#  SCAN SETTINGS
#
#  MaxPlayCount : Default threshold -- items with this many plays
#                or fewer are flagged. TrashBoy will prompt you to
#                accept or override this at scan time.
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
    SortBy       = 'PlayCount'
}
