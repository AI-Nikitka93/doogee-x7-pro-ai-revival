param(
    [switch]$DryRun,
    [switch]$NoLaunch,
    [switch]$EnableSync,
    [switch]$ClearGoogleData
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Adb = Join-Path $ScriptRoot "tools\platform-tools\adb.exe"

$GooglePackages = @(
    "com.google.android.gsf",
    "com.google.android.gsf.login",
    "com.google.android.gms",
    "com.google.android.onetimeinitializer",
    "com.google.android.partnersetup",
    "com.google.android.configupdater",
    "com.google.android.syncadapters.contacts",
    "com.google.android.syncadapters.calendar",
    "com.android.vending"
)

$ClearPackages = @(
    "com.android.vending",
    "com.google.android.gms",
    "com.google.android.gsf",
    "com.google.android.gsf.login"
)

function Invoke-Adb {
    param([Parameter(Mandatory = $true)][string[]]$AdbArgs)
    if ($DryRun) {
        Write-Host "[dry-run] adb $($AdbArgs -join ' ')"
        return @()
    }
    & $Adb @AdbArgs
}

function Invoke-Root {
    param([Parameter(Mandatory = $true)][string]$Command)
    $escaped = $Command.Replace("'", "'\''")
    Invoke-Adb -AdbArgs @("shell", "su", "-c", "'$escaped'")
}

function Assert-Ready {
    if (-not (Test-Path $Adb)) {
        throw "adb.exe not found: $Adb"
    }

    Invoke-Adb -AdbArgs @("wait-for-device") | Out-Null
    $booted = (& $Adb shell getprop sys.boot_completed).Trim()
    if (-not $DryRun -and $booted -ne "1") {
        throw "Android is not fully booted yet: sys.boot_completed=$booted"
    }

    if (-not $DryRun) {
        $rootId = (& $Adb shell su -c id 2>&1) -join "`n"
        if ($rootId -notmatch "uid=0") {
            throw "Root is not available through Magisk su. Output: $rootId"
        }
    }
}

function Show-Versions {
    Write-Host ""
    Write-Host "=== Play stack versions ==="
    foreach ($pkg in @("com.google.android.gms", "com.android.vending")) {
        Write-Host ""
        Write-Host $pkg
        & $Adb shell dumpsys package $pkg | Select-String -Pattern "codePath=|versionCode=|versionName=|lastUpdateTime="
    }
}

Assert-Ready

Write-Host "Switching DOGE X7 Pro to PLAY mode: Google Play stack ON."
Write-Host "Sync stays disabled unless -EnableSync is passed."

foreach ($pkg in $GooglePackages) {
    Write-Host "Enabling $pkg"
    Invoke-Root "if pm path $pkg >/dev/null 2>&1; then pm enable $pkg; else echo missing:$pkg; fi"
}

if ($ClearGoogleData) {
    Write-Host "Clearing Google Play data because -ClearGoogleData was passed"
    foreach ($pkg in $ClearPackages) {
        Invoke-Root "if pm path $pkg >/dev/null 2>&1; then am force-stop $pkg >/dev/null 2>&1; pm clear $pkg; fi"
    }
}

if ($EnableSync) {
    Write-Host "Enabling global sync"
    Invoke-Root "settings put global auto_sync 1"
} else {
    Write-Host "Keeping global sync off for speed"
    Invoke-Root "settings put global auto_sync 0"
}

Invoke-Root "settings put global window_animation_scale 0; settings put global transition_animation_scale 0; settings put global animator_duration_scale 0"

if (-not $NoLaunch) {
    Write-Host "Launching Play Store"
    Invoke-Adb -AdbArgs @("shell", "am", "start", "-n", "com.android.vending/.AssetBrowserActivity") | Out-Host
}

Write-Host "PLAY mode applied."

if (-not $DryRun) {
    Show-Versions
}
