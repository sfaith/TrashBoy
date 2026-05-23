# ================================================================
#  TrashBoy.config.ps1  |  User Configuration  |  v0.1.1
#
#  This file is excluded from source control via .gitignore.
#  Your API keys and tokens stay private.
#
#  See TrashBoy.config.example.ps1 for full documentation.
# ================================================================

# ----------------------------------------------------------------
#  PLEX
# ----------------------------------------------------------------
$PlexConfig = @{
    BaseUrl = 'http://mediacircus:32400'
    Token   = 'YOUR_PLEX_TOKEN'   # CHANGE ME -- see header of TrashBoy.ps1 for how to find this
}

# ----------------------------------------------------------------
#  TAUTULLI  (optional, but recommended)
#
#  Set Enabled = $false to fall back to Plex viewCount only.
#  ApiKey : Tautulli > Settings > Web Interface > API Key
#  MinWatchedPercent : plays below this % completion are not counted
# ----------------------------------------------------------------
$TautulliConfig = @{
    Enabled           = $true
    BaseUrl           = 'http://plex.lan.chaosnetwork.org:8181'
    ApiKey            = 'YOUR_TAUTULLI_API_KEY'   # CHANGE ME
    MinWatchedPercent = 50
}

# ----------------------------------------------------------------
#  RADARR
# ----------------------------------------------------------------
$RadarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://mediafrenzy:7878'
    ApiKey  = '4b45948567dc46aea242abbe5196ba47'
}

# ----------------------------------------------------------------
#  SONARR
# ----------------------------------------------------------------
$SonarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://mediafrenzy:8989'
    ApiKey  = '3f012d016bfb460189ce51db96041ab0'
}

# ----------------------------------------------------------------
#  LIDARR
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
#
#  Libraries not listed here will appear in scan reports but will be
#  skipped during deletion (no *arr service to call).
#
#  Library names are case-sensitive and must match Plex exactly.
#  Run TrashBoy and choose Settings (option 3) to see all libraries
#  Plex is currently reporting.
# ----------------------------------------------------------------
$LibraryMap = @{
    'TV Shows'       = 'Sonarr'
    'Movies'         = 'Radarr'
    'Documentaries'  = 'Radarr'   # Change to 'Sonarr' for TV-style documentary series
    'Holiday_Movies' = 'Radarr'
    'Short Films'    = 'Radarr'
    'Music'          = 'Lidarr'
#   'Music Videos'   = 'Radarr'   # Uncomment to include
#   'Anime'          = 'Sonarr'   # Example -- add your own libraries below
}

# ----------------------------------------------------------------
#  SCAN SETTINGS
#
#  MaxPlayCount : Default threshold -- items with this many plays or
#                fewer are flagged as unwatched. TrashBoy will prompt
#                you to accept or override this value at scan time.
#                0 = never played, 1 = played once or never, etc.
#                When Tautulli is enabled, only plays meeting
#                MinWatchedPercent are counted toward this total.
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
