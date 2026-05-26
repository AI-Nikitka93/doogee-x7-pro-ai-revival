param(
    [switch]$DryRun,
    [switch]$SkipHealth
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Adb = Join-Path $ScriptRoot "tools\platform-tools\adb.exe"

$GooglePackages = @(
    "com.android.vending",
    "com.google.android.gms",
    "com.google.android.gsf.login",
    "com.google.android.gsf",
    "com.google.android.onetimeinitializer",
    "com.google.android.partnersetup",
    "com.google.android.configupdater",
    "com.google.android.syncadapters.contacts",
    "com.google.android.syncadapters.calendar"
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

function Show-Health {
    Write-Host ""
    Write-Host "=== Quick health ==="
    & $Adb shell getprop ro.product.model
    & $Adb shell getprop ro.build.display.id
    & $Adb shell dumpsys meminfo | Select-String -Pattern "Total RAM|Free RAM|Used RAM|Lost RAM|ZRAM"
    & $Adb shell df | Select-String -Pattern "/data|/system|/cache"
    Write-Host ""
    Write-Host "Google package state:"
    foreach ($pkg in $GooglePackages) {
        $enabled = (& $Adb shell pm list packages -e $pkg) -join ""
        $disabled = (& $Adb shell pm list packages -d $pkg) -join ""
        if ($enabled -match [regex]::Escape($pkg)) {
            Write-Host "  ON  $pkg"
        } elseif ($disabled -match [regex]::Escape($pkg)) {
            Write-Host "  OFF $pkg"
        } else {
            Write-Host "  --  $pkg"
        }
    }
}

Assert-Ready

Write-Host "Switching DOGE X7 Pro to TURBO mode: Google Play stack OFF."
Write-Host "This is reversible. It disables packages for user 0, it does not delete APKs."

foreach ($pkg in $GooglePackages) {
    Write-Host "Disabling $pkg"
    Invoke-Root "if pm path $pkg >/dev/null 2>&1; then am force-stop $pkg >/dev/null 2>&1; pm disable-user --user 0 $pkg; else echo missing:$pkg; fi"
}

Write-Host "Applying speed settings"
Invoke-Root "settings put global window_animation_scale 0; settings put global transition_animation_scale 0; settings put global animator_duration_scale 0; settings put global wifi_scan_always_enabled 0; settings put global ble_scan_always_enabled 0; settings put secure screensaver_enabled 0; settings put system screen_off_timeout 120000; am kill-all >/dev/null 2>&1"

Write-Host "TURBO mode applied."

if (-not $DryRun -and -not $SkipHealth) {
    Show-Health
}
