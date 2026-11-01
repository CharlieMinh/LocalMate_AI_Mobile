[CmdletBinding()]
param(
    [string]$ConfigFile = 'config/dart_defines.production.local.json',
    [switch]$SplitPerAbi
)

$ErrorActionPreference = 'Stop'

# Same rule as the Gradle release gate: a domain name, never an IP literal or a local name.
# A numeric last label also catches loopback shorthands such as 127.1 or 127.0.0.2.
function Test-PublicDomain([string]$HostName) {
    $labels = $HostName.ToLowerInvariant().TrimEnd('.').Split('.')
    return $labels.Count -ge 2 -and -not ($labels -contains '') -and
        $labels[-1] -cmatch '^[a-z][a-z0-9-]*$' -and $labels[-1] -ne 'localhost'
}
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location $repositoryRoot
try {
    if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
        throw 'Copy config/dart_defines.production.example.json to a .local.json file and fill the confirmed production API origin.'
    }
    $defines = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
    $allowedKeys = @('APP_ENV', 'API_BASE_URL', 'GOOGLE_SERVER_CLIENT_ID')
    $unknownKeys = @($defines.PSObject.Properties.Name | Where-Object { $_ -cnotin $allowedKeys })
    if ($unknownKeys.Count -gt 0) {
        throw 'The app config must contain only APP_ENV, API_BASE_URL and GOOGLE_SERVER_CLIENT_ID. Keep server credentials out of APKs.'
    }
    if ($defines.APP_ENV -cne 'production') {
        throw 'APP_ENV must be production for a distribution build.'
    }
    $api = $null
    if (-not [uri]::TryCreate([string]$defines.API_BASE_URL, [UriKind]::Absolute, [ref]$api) -or
        $api.Scheme -ne 'https' -or $api.IsLoopback -or -not (Test-PublicDomain $api.IdnHost) -or
        $api.UserInfo -or $api.Query -or $api.Fragment -or $api.AbsolutePath -ne '/') {
        throw 'Supply the confirmed public HTTPS backend origin, without /api, credentials or a query string.'
    }
    if (-not (Test-Path -LiteralPath 'android/key.properties' -PathType Leaf)) {
        throw 'Private release signing has not been configured. See docs/ANDROID_RELEASE.md.'
    }
    # Read-only probe prevents accidentally distributing an APK pointed at a website.
    Write-Host 'Checking the public backend contract...'
    $masterData = Invoke-RestMethod -Uri ($api.GetLeftPart([UriPartial]::Authority) + '/api/master-data') -TimeoutSec 20
    # HTML or an unrelated object must fail here; @($null).Count would otherwise report one station.
    $stations = $null
    if ($masterData -is [System.Management.Automation.PSCustomObject] -and
        $masterData.PSObject.Properties['metroStations']) {
        $stations = $masterData.metroStations
    }
    if ($stations -isnot [array] -or $stations.Count -eq 0 -or $stations -contains $null) {
        throw 'The backend did not return metroStations from /api/master-data.'
    }
    Write-Host "Backend contract available: $($stations.Count) stations."
    & flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    $buildArguments = @('build', 'apk', '--release', '--no-pub', "--dart-define-from-file=$ConfigFile")
    if ($SplitPerAbi) { $buildArguments += '--split-per-abi' }
    & flutter @buildArguments
    if ($LASTEXITCODE -ne 0) { throw 'Release build failed; do not distribute an older APK.' }
    Write-Host 'Signed APK output: build/app/outputs/flutter-apk/'
    Write-Host 'Verify its signature and test on a physical Android device before distribution.'
}
finally {
    Pop-Location
}
