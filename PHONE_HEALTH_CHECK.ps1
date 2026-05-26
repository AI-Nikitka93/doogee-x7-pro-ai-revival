param(
    [switch]$SaveReport
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Adb = Join-Path $ScriptRoot "tools\platform-tools\adb.exe"
$ReportLines = New-Object System.Collections.Generic.List[string]

function Add-Section {
    param([string]$Title)
    $line = ""
    $ReportLines.Add($line) | Out-Null
    $ReportLines.Add("=== $Title ===") | Out-Null
}

function Add-Cmd {
    param(
        [string]$Title,
        [string[]]$AdbArgs,
        [string]$Pattern = "",
        [int]$First = 0
    )
    Add-Section $Title
    $ReportLines.Add("adb $($AdbArgs -join ' ')") | Out-Null
    try {
        $out = & $Adb @AdbArgs 2>&1
        if ($Pattern) {
            $out = $out | Select-String -Pattern $Pattern
        }
        if ($First -gt 0) {
            $out = $out | Select-Object -First $First
        }
        foreach ($line in $out) {
            $ReportLines.Add([string]$line) | Out-Null
        }
    } catch {
        $ReportLines.Add("ERROR: $($_.Exception.Message)") | Out-Null
    }
}

if (-not (Test-Path $Adb)) {
    throw "adb.exe not found: $Adb"
}

& $Adb wait-for-device | Out-Null

Add-Section "Device"
$ReportLines.Add("ADB: $Adb") | Out-Null
$ReportLines.Add("Model: $((& $Adb shell getprop ro.product.model).Trim())") | Out-Null
$ReportLines.Add("Build: $((& $Adb shell getprop ro.build.display.id).Trim())") | Out-Null
$ReportLines.Add("Android: $((& $Adb shell getprop ro.build.version.release).Trim())") | Out-Null
$ReportLines.Add("Boot completed: $((& $Adb shell getprop sys.boot_completed).Trim())") | Out-Null
$ReportLines.Add("Root: $((& $Adb shell su -c id 2>&1) -join ' ')") | Out-Null

Add-Cmd "Battery" @("shell", "dumpsys", "battery")
Add-Cmd "Storage" @("shell", "df")
Add-Cmd "RAM summary" @("shell", "dumpsys", "meminfo") "Total RAM|Free RAM|Used RAM|Lost RAM|ZRAM|com.google.android.gms|com.android.vending|launcher|system" 120
Add-Cmd "Top processes" @("shell", "top", "-n", "1", "-m", "20")
Add-Cmd "ZRAM" @("shell", "su", "-c", "'cat /proc/swaps; cat /sys/block/zram0/disksize 2>/dev/null; cat /sys/block/zram0/comp_algorithm 2>/dev/null'")
Add-Cmd "Low memory killer" @("shell", "su", "-c", "'cat /sys/module/lowmemorykiller/parameters/minfree 2>/dev/null'")
Add-Cmd "Animations" @("shell", "settings", "get", "global", "window_animation_scale")
Add-Cmd "Wi-Fi" @("shell", "dumpsys", "wifi") "^Wi-Fi is|mWifiInfo:" 10
Add-Cmd "Headset switch" @("shell", "su", "-c", "'cat /sys/class/switch/h2w/state 2>/dev/null'")

Add-Section "Google package state"
$GooglePackages = @(
    "com.android.vending",
    "com.google.android.gms",
    "com.google.android.gsf",
    "com.google.android.gsf.login",
    "com.google.android.onetimeinitializer",
    "com.google.android.partnersetup",
    "com.google.android.configupdater",
    "com.google.android.syncadapters.contacts",
    "com.google.android.syncadapters.calendar"
)

foreach ($pkg in $GooglePackages) {
    $enabled = (& $Adb shell pm list packages -e $pkg) -join ""
    $disabled = (& $Adb shell pm list packages -d $pkg) -join ""
    if ($enabled -match [regex]::Escape($pkg)) {
        $ReportLines.Add("ON  $pkg") | Out-Null
    } elseif ($disabled -match [regex]::Escape($pkg)) {
        $ReportLines.Add("OFF $pkg") | Out-Null
    } else {
        $ReportLines.Add("--  $pkg") | Out-Null
    }
}

Add-Cmd "Play services version" @("shell", "dumpsys", "package", "com.google.android.gms") "codePath=|versionCode=|versionName=|lastUpdateTime=" 20
Add-Cmd "Play Store version" @("shell", "dumpsys", "package", "com.android.vending") "codePath=|versionCode=|versionName=|lastUpdateTime=" 20

$text = $ReportLines -join [Environment]::NewLine
Write-Output $text

if ($SaveReport) {
    $work = Join-Path $ScriptRoot "work"
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $work "phone_health_$stamp.txt"
    Set-Content -LiteralPath $path -Value $text -Encoding UTF8
    Write-Host ""
    Write-Host "Saved report: $path"
}
