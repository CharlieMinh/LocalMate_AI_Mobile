[CmdletBinding()]
param(
    [string]$AvdName = 'LocalMate_Pixel',
    [string]$SystemImage = 'system-images;android-35;google_apis;x86_64',
    [string]$DeviceProfile = 'pixel_8',
    # Optional --dart-define-from-file; without it the app runs in mock mode.
    [string]$ConfigFile = '',
    # Only boot and place the emulator; start the app from VS Code (F5) instead.
    [switch]$NoRun
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sdk = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk')) |
    Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $sdk) { throw 'Android SDK not found. Set ANDROID_HOME or install it under %LOCALAPPDATA%\Android\Sdk.' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$avdManager = Join-Path $sdk 'cmdline-tools\latest\bin\avdmanager.bat'
if (-not (Test-Path -LiteralPath $emulator)) {
    throw "Emulator missing. Run: sdkmanager --install emulator `"$SystemImage`""
}

$existingAvds = @(& $emulator -list-avds 2>$null)
if ($AvdName -notin $existingAvds) {
    Write-Host "Creating emulator $AvdName ($DeviceProfile, $SystemImage)..."
    # Through cmd with explicit quotes: the .bat would otherwise split the package id at each ';'.
    'no' | & cmd /c "`"$avdManager`" create avd -n $AvdName -k `"$SystemImage`" -d $DeviceProfile" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'avdmanager failed; is the system image installed?' }
    # Lets the PC keyboard type into text fields.
    $avdConfig = Join-Path $env:USERPROFILE ".android\avd\$AvdName.avd\config.ini"
    (Get-Content -LiteralPath $avdConfig) -replace '^hw\.keyboard\s*=.*$', 'hw.keyboard=yes' |
        Set-Content -LiteralPath $avdConfig
    if (-not (Select-String -LiteralPath $avdConfig -Pattern '^hw\.keyboard=' -Quiet)) {
        Add-Content -LiteralPath $avdConfig 'hw.keyboard=yes'
    }
}

$serial = (& $adb devices) | Select-String '^(emulator-\d+)\s+device' |
    ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1
if (-not $serial) {
    Write-Host "Starting $AvdName..."
    Start-Process -FilePath $emulator -ArgumentList @('-avd', $AvdName, '-no-boot-anim') -WindowStyle Normal
    & $adb wait-for-device
    $serial = (& $adb devices) | Select-String '^(emulator-\d+)\s+device' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1
}
Write-Host "Waiting for $serial to finish booting..."
$deadline = (Get-Date).AddMinutes(4)
while (((& $adb -s $serial shell getprop sys.boot_completed 2>$null) -join '').Trim() -ne '1') {
    if ((Get-Date) -gt $deadline) { throw 'Emulator did not boot within 4 minutes.' }
    Start-Sleep -Seconds 2
}

# Dock the phone against the right edge so the editor keeps the rest of the screen.
Add-Type -Namespace LocalMate -Name Win32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
Add-Type -AssemblyName System.Windows.Forms
$window = Get-Process -Name 'qemu-system-*' -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
if ($window) {
    $rect = New-Object LocalMate.Win32+RECT
    [void][LocalMate.Win32]::GetWindowRect($window.MainWindowHandle, [ref]$rect)
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $x = $area.Right - ($rect.Right - $rect.Left)
    # SWP_NOSIZE | SWP_NOZORDER: move only, the emulator manages its own scale.
    [void][LocalMate.Win32]::SetWindowPos($window.MainWindowHandle, [IntPtr]::Zero, $x, $area.Top, 0, 0, 0x0005)
}

if ($NoRun) {
    Write-Host "Emulator $serial ready. Press F5 in VS Code; saving a .dart file hot-reloads the app."
    return
}
Push-Location $repositoryRoot
try {
    $runArguments = @('run', '-d', $serial)
    if ($ConfigFile) {
        if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) { throw "Config file not found: $ConfigFile" }
        $runArguments += "--dart-define-from-file=$ConfigFile"
    }
    Write-Host 'r = hot reload, R = hot restart, q = quit.'
    & flutter @runArguments
}
finally {
    Pop-Location
}
