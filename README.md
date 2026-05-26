# DOOGEE X7 Pro AI Revival

[English](README.md) | [Русский](README.ru.md)

Old Android hardware, restored with Codex as a technical copilot.

This repository documents a practical experiment: an almost unusable DOOGEE X7 Pro was recovered, rooted, cleaned up, and turned into a script-controlled test phone. The phone is still old hardware, but it is no longer a dead drawer device.

## What Was Done

- Reflashed the stock Android 6.0 firmware with SP Flash Tool.
- Restored normal boot and ADB access.
- Installed Magisk root through a patched boot image.
- Disabled vendor bloatware, OTA/FOTA services, duplicate utilities, and heavy background apps.
- Restored Google Play Store by updating Google Play services to a compatible modern build.
- Built two operating modes:
  - `Turbo mode`: Google Play stack is disabled for maximum responsiveness.
  - `Play mode`: Google Play stack is enabled only when the store is needed.
- Added PowerShell scripts for switching modes and checking device health.
- Investigated the FM radio limitation and confirmed that the MTK FM stack still requires the real headset/antenna state before powering the FM chip.

## Repository Scope

This repo intentionally contains only documentation and helper scripts.

It does not include:

- stock firmware images;
- patched boot images;
- APK files;
- SP Flash Tool binaries;
- USB drivers;
- private serial numbers or local recovery logs.

Those files are either third-party binaries, device-specific recovery material, or private local artifacts. The public value here is the process, the safety notes, and the repeatable script pattern.

## Scripts

### Turbo Mode

Disables the minimal Google Play stack for user `0`, force-stops the packages, reapplies speed settings, and keeps the operation reversible.

```powershell
powershell -ExecutionPolicy Bypass -File .\TURBO_OFF_GOOGLE.ps1
```

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File .\TURBO_OFF_GOOGLE.ps1 -DryRun -SkipHealth
```

### Play Mode

Re-enables the minimal Google Play stack and keeps global sync disabled by default for speed.

```powershell
powershell -ExecutionPolicy Bypass -File .\PLAY_MARKET_ON.ps1
```

Do not launch the store after switching:

```powershell
powershell -ExecutionPolicy Bypass -File .\PLAY_MARKET_ON.ps1 -NoLaunch
```

### Health Check

Collects a read-only report: model, build, root state, battery, storage, RAM, top processes, ZRAM, low-memory killer settings, Wi-Fi, headset switch, Google package state, and Play Store versions.

```powershell
powershell -ExecutionPolicy Bypass -File .\PHONE_HEALTH_CHECK.ps1 -SaveReport
```

## Device Baseline

- Device: DOOGEE X7 Pro
- Platform: MediaTek MT6737M
- Android: 6.0
- RAM class: 2 GB
- Recovered build: `DOOGEE-X7pro-Android6.0-20161230`
- Root: Magisk

## Why Two Modes

On this class of hardware, modern Google Play services are expensive. They are useful when installing apps, but they consume a lot of RAM and keep background processes alive.

The practical solution is not pretending the phone can behave like a modern device. The practical solution is mode switching:

- keep Google disabled for daily lightweight use;
- enable Google only when Play Store is needed;
- switch back to Turbo mode after installing or updating apps.

## Safety Notes

This is not a universal flashing guide. MediaTek flashing can brick devices or damage NVRAM/IMEI data when done incorrectly.

Key rules from this experiment:

- prefer `Download Only` in SP Flash Tool;
- do not use `Format All + Download` unless you know exactly why;
- preserve NVRAM/NVDATA;
- keep original firmware and boot image backups;
- verify root and boot state after each risky step;
- never publish private device serials, local logs, APKs, firmware dumps, or patched boot images.

## Documentation

- [Technical notes](docs/technical-notes.md)
- [Social posts](docs/social-posts.md)

## Result

The phone did not become a flagship. It became something more useful for this experiment: a recovered, rooted, documented, script-controlled Android test device.

Codex was used as the technical copilot for research, command planning, log interpretation, reversible package changes, script creation, and documentation.
