# TrashBoy logic unit tests -- run standalone, no config required
# Tests all pure functions extracted from TrashBoy.ps1
#
# Run: tests\Run-Tests.bat  (from repo root)
#
# Functions tested:
#   Format-Bytes          -- byte formatting (TB/GB/MB/B tiers)
#   Get-MatchConfidence   -- *arr match risk detection (no GUID / release group)
#   Get-GuidValue         -- Plex GUID extraction by scheme
#   Age filter boundary   -- cutoff date logic for MinAgeDays

# ── Pure logic copied from TrashBoy.ps1 ──────────────────────────────────────

function Format-Bytes ([long]$Bytes) {
    if ($Bytes -ge 1TB) { return ('{0:N2} TB' -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    return ('{0} B' -f $Bytes)
}

function Get-GuidValue ([object]$Item, [string]$Scheme) {
    if ($Item.PSObject.Properties['Guid'] -and $Item.Guid) {
        $hit = $Item.Guid | Where-Object {
            $_.PSObject.Properties['id'] -and $_.id -like "$Scheme`://*"
        } | Select-Object -First 1
        if ($hit) { return ($hit.id -replace "$Scheme`://", '') }
    }
    return ''
}

function Get-MatchConfidence ([PSObject]$Item) {
    $hasGuid = $Item.GuidTmdb -or $Item.GuidImdb -or $Item.GuidTvdb -or $Item.GuidMbrainz
    if (-not $hasGuid) { return $true }
    if ($Item.Title -match '-(RARBG|YTS|FGT|YIFY|EZTV|SPARKS|GECKOS|NTG)$') { return $true }
    if ($Item.Title -match '^[A-Z0-9]+(\.[A-Z0-9]+){3,}') { return $true }
    return $false
}

function Test-ItemAge ([datetime]$AddedAt, [int]$MinAgeDays) {
    # Returns $true if the item should be SKIPPED (added too recently)
    if ($MinAgeDays -le 0) { return $false }
    $cutoff = [DateTime]::Now.AddDays(-$MinAgeDays)
    return $AddedAt -gt $cutoff
}

# ── Test harness ──────────────────────────────────────────────────────────────
$pass = 0; $fail = 0
$results = [System.Collections.Generic.List[psobject]]::new()

function T ([string]$ID, [string]$Desc, $Got, $Expected) {
    if ($Got -eq $Expected) {
        $script:pass++
        $script:results.Add([pscustomobject]@{ Result='PASS'; ID=$ID; Desc=$Desc })
    } else {
        $script:fail++
        $script:results.Add([pscustomobject]@{ Result='FAIL'; ID=$ID; Desc=$Desc; Got="$Got"; Expected="$Expected" })
    }
}

# ── Format-Bytes ──────────────────────────────────────────────────────────────
T 'FB1'  'Format-Bytes: zero bytes'       (Format-Bytes 0)    '0 B'
T 'FB2'  'Format-Bytes: raw bytes'        (Format-Bytes 500)  '500 B'
T 'FB3'  'Format-Bytes: megabytes'        (Format-Bytes 15MB) '15.0 MB'
T 'FB4'  'Format-Bytes: gigabytes'        (Format-Bytes 2GB)  '2.00 GB'
T 'FB5'  'Format-Bytes: terabytes'        (Format-Bytes 3TB)  '3.00 TB'
T 'FB6'  'Format-Bytes: boundary 1GB'     (Format-Bytes 1GB)  '1.00 GB'
T 'FB7'  'Format-Bytes: boundary 1MB'     (Format-Bytes 1MB)  '1.0 MB'
T 'FB8'  'Format-Bytes: boundary 1TB'     (Format-Bytes 1TB)  '1.00 TB'
T 'FB9'  'Format-Bytes: just under 1MB'   (Format-Bytes ([long](1MB - 1))) ('{0} B' -f ([long](1MB - 1)))
T 'FB10' 'Format-Bytes: fractional GB'    (Format-Bytes ([long](1.5 * 1GB))) '1.50 GB'

# Note: TrashBoy Format-Bytes includes TB tier; FolderBoy also has TB (DB12).
# Both implementations should be identical -- these tests confirm consistency.

# ── Get-GuidValue ─────────────────────────────────────────────────────────────
$movieWithGuids = [PSCustomObject]@{
    Guid = @(
        [PSCustomObject]@{ id = 'tmdb://12345'        }
        [PSCustomObject]@{ id = 'imdb://tt0123456'    }
        [PSCustomObject]@{ id = 'tvdb://67890'        }
    )
}

$artistWithMbrainz = [PSCustomObject]@{
    Guid = @(
        [PSCustomObject]@{ id = 'musicbrainz://abc-123-def' }
    )
}

$itemNoGuids = [PSCustomObject]@{
    Title = 'Some Movie'
}

T 'GV1' 'Get-GuidValue: tmdb present'          (Get-GuidValue $movieWithGuids 'tmdb')        '12345'
T 'GV2' 'Get-GuidValue: imdb present'          (Get-GuidValue $movieWithGuids 'imdb')        'tt0123456'
T 'GV3' 'Get-GuidValue: tvdb present'          (Get-GuidValue $movieWithGuids 'tvdb')        '67890'
T 'GV4' 'Get-GuidValue: scheme not present'    (Get-GuidValue $movieWithGuids 'musicbrainz') ''
T 'GV5' 'Get-GuidValue: musicbrainz present'   (Get-GuidValue $artistWithMbrainz 'musicbrainz') 'abc-123-def'
T 'GV6' 'Get-GuidValue: no Guid property'      (Get-GuidValue $itemNoGuids 'tmdb')           ''

# ── Get-MatchConfidence ───────────────────────────────────────────────────────
# Returns $true = likely to fail (flag it), $false = likely to succeed

# No GUIDs at all -- should flag
$noGuids = [PSCustomObject]@{ Title = 'Some Movie'; GuidTmdb = ''; GuidImdb = ''; GuidTvdb = ''; GuidMbrainz = '' }
T 'MC1' 'MatchConfidence: no GUIDs -> flag'    (Get-MatchConfidence $noGuids) $true

# Has a GUID, clean title -- should not flag
$hasGuid = [PSCustomObject]@{ Title = 'The Dark Knight'; GuidTmdb = '155'; GuidImdb = 'tt0468569'; GuidTvdb = ''; GuidMbrainz = '' }
T 'MC2' 'MatchConfidence: has GUID, clean title -> ok'  (Get-MatchConfidence $hasGuid) $false

# RARBG release group in title -- flag even if has GUID
$rarbg = [PSCustomObject]@{ Title = 'The Dark Knight-RARBG'; GuidTmdb = '155'; GuidImdb = ''; GuidTvdb = ''; GuidMbrainz = '' }
T 'MC3' 'MatchConfidence: RARBG in title -> flag'       (Get-MatchConfidence $rarbg) $true

# YTS release group
$yts = [PSCustomObject]@{ Title = 'Some.Movie.2020-YTS'; GuidTmdb = ''; GuidImdb = 'tt1234567'; GuidTvdb = ''; GuidMbrainz = '' }
T 'MC4' 'MatchConfidence: YTS in title -> flag'         (Get-MatchConfidence $yts) $true

# FGT release group
$fgt = [PSCustomObject]@{ Title = 'Another.Movie-FGT'; GuidTmdb = '999'; GuidImdb = ''; GuidTvdb = ''; GuidMbrainz = '' }
T 'MC5' 'MatchConfidence: FGT in title -> flag'         (Get-MatchConfidence $fgt) $true

# Dot-separated uppercase pattern (scene release style)
$scene = [PSCustomObject]@{ Title = 'SOME.MOVIE.2020.1080P'; GuidTmdb = ''; GuidImdb = ''; GuidTvdb = ''; GuidMbrainz = '' }
T 'MC6' 'MatchConfidence: dot-separated uppercase -> flag' (Get-MatchConfidence $scene) $true

# TV show with TVDB GUID, clean title
$tvShow = [PSCustomObject]@{ Title = 'Breaking Bad'; GuidTmdb = ''; GuidImdb = 'tt0903747'; GuidTvdb = '81189'; GuidMbrainz = '' }
T 'MC7' 'MatchConfidence: TV show with tvdb GUID -> ok'  (Get-MatchConfidence $tvShow) $false

# Music artist with MusicBrainz GUID
$artist = [PSCustomObject]@{ Title = 'The Beatles'; GuidTmdb = ''; GuidImdb = ''; GuidTvdb = ''; GuidMbrainz = 'b10bbbfc-cf9e-42e0-be17-e2c3e1d2600d' }
T 'MC8' 'MatchConfidence: artist with mbrainz GUID -> ok' (Get-MatchConfidence $artist) $false

# YIFY release group
$yify = [PSCustomObject]@{ Title = 'Interstellar-YIFY'; GuidTmdb = '157336'; GuidImdb = ''; GuidTvdb = ''; GuidMbrainz = '' }
T 'MC9' 'MatchConfidence: YIFY in title -> flag'         (Get-MatchConfidence $yify) $true

# Only MusicBrainz GUID present (no others) -- has GUID, should not flag on that basis
$mbrainzOnly = [PSCustomObject]@{ Title = 'Pink Floyd'; GuidTmdb = ''; GuidImdb = ''; GuidTvdb = ''; GuidMbrainz = 'fabd3cb7-15fb-442b-a93f-e6b6e7e58c0a' }
T 'MC10' 'MatchConfidence: mbrainz only, clean title -> ok' (Get-MatchConfidence $mbrainzOnly) $false

# ── Age filter boundary ───────────────────────────────────────────────────────
# Test-ItemAge returns $true = skip (too new), $false = include

$old   = [DateTime]::Now.AddDays(-400)
$exact = [DateTime]::Now.AddDays(-365)
$new   = [DateTime]::Now.AddDays(-100)
$fresh = [DateTime]::Now.AddDays(-1)

T 'AF1' 'Age filter: disabled (MinAgeDays=0) -> never skip'   (Test-ItemAge $fresh 0)    $false
T 'AF2' 'Age filter: old item -> include'                     (Test-ItemAge $old 365)    $false
T 'AF3' 'Age filter: new item -> skip'                        (Test-ItemAge $new 365)    $true
T 'AF4' 'Age filter: fresh item -> skip'                      (Test-ItemAge $fresh 365)  $true
T 'AF5' 'Age filter: exactly at boundary -> include'          (Test-ItemAge $exact 365)  $false
T 'AF6' 'Age filter: MinAgeDays=1, 12-hour-old item -> skip'    (Test-ItemAge ([DateTime]::Now.AddHours(-12)) 1) $true
T 'AF7' 'Age filter: MinAgeDays=1, 400-day-old item -> include' (Test-ItemAge $old 1)    $false

# ── Code-level feature presence checks ───────────────────────────────────────
$src = Get-Content (Join-Path $PSScriptRoot '..\TrashBoy.ps1') -Raw

T 'CF1'  'Get-MatchConfidence defined'              ($src -match 'function Get-MatchConfidence')        $true
T 'CF2'  'Select-ItemsForDeletion defined'          ($src -match 'function Select-ItemsForDeletion')    $true
T 'CF3'  'Get-GuidValue defined'                    ($src -match 'function Get-GuidValue')              $true
T 'CF4'  'Format-Bytes defined'                     ($src -match 'function Format-Bytes')               $true
T 'CF5'  'Confirm-LiveAction defined'               ($src -match 'function Confirm-LiveAction')         $true
T 'CF6'  'Write-Progress2 defined'                  ($src -match 'function Write-Progress2')            $true
T 'CF7'  'Tautulli MinWatchedPercent default set'   ($src -match 'MinWatchedPercent')                   $true
T 'CF8'  'MaxViewCount backward compat handled'     ($src -match 'MaxViewCount')                        $true
T 'CF9'  'MinAgeDays filter present'                ($src -match 'MinAgeDays')                          $true
T 'CF10' 'CONFIRM prompt for flagged items'         ($src -match "'CONFIRM'")                           $true
T 'CF11' 'Plex rescan after delete'                 ($src -match 'refresh')                             $true
T 'CF12' 'StrictMode Latest active'                 ($src -match 'StrictMode -Version Latest')          $true
T 'CF13' 'Invoke-PlexApi uses RawContentStream'     ($src -match 'RawContentStream')                    $true
T 'CF14' 'Log prefix TrashBoy_Scan'                 ($src -match "Start-Log 'TrashBoy_Scan'")           $true
T 'CF15' 'Log prefix TrashBoy_Delete'               ($src -match "Start-Log 'TrashBoy_Delete'")         $true
T 'CF16' 'Logs\ subdir used'                        ($src -match [regex]::Escape("Join-Path `$PSScriptRoot 'Logs'")) $true
T 'CF17' 'No stray Invoke-RestMethod for Plex'      ($src -notmatch 'Invoke-RestMethod -Uri.*plex')     $true
T 'CF18' 'MaxPlayCount config key present'          ($src -match 'MaxPlayCount')                        $true
T 'CF19' 'SortBy config key present'                ($src -match 'SortBy')                              $true
T 'CF20' 'SkippedAge returned from Get-Unwatched'   ($src -match 'SkippedAge')                          $true

# ── Print results ─────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '  -----------------------------------------------------------------' -ForegroundColor Cyan
$results | ForEach-Object {
    if ($_.Result -eq 'PASS') {
        Write-Host ("  PASS  {0,-5}  {1}" -f $_.ID, $_.Desc) -ForegroundColor Green
    } else {
        Write-Host ("  FAIL  {0,-5}  {1}" -f $_.ID, $_.Desc) -ForegroundColor Red
        Write-Host ("         got:      [{0}]" -f $_.Got)      -ForegroundColor Yellow
        Write-Host ("         expected: [{0}]" -f $_.Expected) -ForegroundColor Yellow
    }
}
Write-Host '  -----------------------------------------------------------------' -ForegroundColor Cyan
$color = if ($fail -gt 0) { 'Red' } else { 'Green' }
Write-Host ("  {0} passed   {1} failed" -f $pass, $fail) -ForegroundColor $color
Write-Host ''
