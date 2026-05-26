# Technical Notes

These notes summarize the public, non-private part of the DOOGEE X7 Pro recovery experiment.

## Starting Point

The phone was almost unusable:

- Android booted into Google Play related errors.
- The launcher and menus were extremely slow.
- A factory reset did not fix the issue.
- Recovery/fastboot/preloader modes were confusing and inconsistent from the outside.

## Recovery Path

1. Identified the phone as a DOOGEE X7 Pro on a MediaTek MT6737M platform.
2. Prepared Windows ADB/Fastboot and MediaTek preloader access.
3. Flashed a compatible stock Android 6.0 firmware with SP Flash Tool.
4. Booted Android and confirmed ADB access.
5. Installed Magisk, patched the stock boot image, and flashed only the patched boot partition.
6. Verified root through Magisk `su`.
7. Disabled heavy and unnecessary packages with reversible `pm disable-user --user 0`.
8. Updated Google Play services so the modern Play Store could launch.
9. Created two mode-switch scripts:
   - Play Store on demand;
   - Google-free Turbo mode for normal lightweight use.

## Google Play Stack

The restored Play setup used a modern compatible Google Play services APK variant for Android 6.0 and ARM64/ARMv7. After installation, Play Store opened to the Google sign-in screen.

The tradeoff is RAM: on this device, Google Play services and Play Store together can hold several hundred MB of memory across multiple processes. That is why the scripts treat Google as an on-demand mode instead of a permanent background dependency.

## FM Radio Finding

The phone includes the standard MediaTek FM Radio package:

- package: `com.android.fmradio`
- normal activity: `.FmActivity`
- hidden engineering activity: `.FmEmActivity`
- hidden CIT activity: `.FMRadioCITActivity`

Attempts to spoof headset state through `AudioService` and `HEADSET_PLUG` broadcasts were not enough. The FM service reached the power-up path but stopped with the equivalent of:

```text
handlePowerUp, earphone is not ready
```

The real blocker is the kernel/headset state. Without a physical 3.5 mm plug or a deeper system patch, the FM chip does not power up. A cut-down 3.5 mm plug or old headphones remain the practical antenna workaround.

## What Is Reversible

The public scripts use reversible package state changes:

```text
pm disable-user --user 0 <package>
pm enable <package>
```

They do not remove APKs from `/system`, do not format partitions, and do not touch NVRAM.

## What Is Not Published

The local workspace contained sensitive or redistributable artifacts that are intentionally excluded:

- firmware zip;
- patched boot image;
- stock boot image;
- APKs;
- SP Flash Tool;
- Windows USB drivers;
- private serial numbers;
- verbose local flash logs.

The public repo is a case study and script set, not a firmware mirror.

