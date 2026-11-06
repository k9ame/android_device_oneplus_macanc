# OnePlus Ace 6T (macanc / PLR110) — AviumUI 16.2.2 port

Device tree for the **OnePlus Ace 6T** (`macanc`, `PLR110`, Qualcomm **SM8845**, board `canoe`),
ported to **AviumUI 16.2.2** (LineageOS 23.2 / Android 16).

## What this port adds

- **StrongBox (NXP javacard SE)** support using crDroid's prebuilt KeyMint3 service and libs.
  - The stock AOSP NXP transport cannot send C-APDU on this device; the crDroid transport is required.
- **Audio HAL fix**: the prebuilt `audiohalservice.qti` blob ships without its init rc, so the rc is
  copied from source as `audiohalservice_qti_macanc.rc`. Without it AudioService blocks boot.
- **165 Hz default refresh rate** via `OPlusFrameworksResTarget` overlay (panel supports 60/90/120/144/165).
- **Default wallpaper**: AOSP / crDroid stock wallpaper (overrides Avium's anime wallpaper),
  applied through a device-level `PRODUCT_PACKAGE_OVERLAYS` overlay.
- **Launcher icon shape**: iOS-like rounded rectangle (`square`) by default, and also applied to the
  app drawer (upstream only applied custom shapes to themed/workspace icons).
- **Mobile data enabled by default** (crDroid parity): overrides Lineage's
  `ro.com.android.mobiledata=false`, so a clean flash gets the default internet PDN (`ctlte`)
  without manually toggling mobile data. Only affects the initial settings database; existing
  installs keep their user choice.
- **Xime 3.4.3 input method preinstalled and set as default** (Rime-based Wubi/Pinyin), while
  keeping AOSP LatinIME available as a fallback. The APK is copied byte-identical so its v2
  signature is preserved and GitHub/F-Droid updates keep working.
- **WLAN QR scan**: a camera action in the Wi-Fi page toolbar opens the built-in scanner and adds
  a network from a standard `WIFI:` QR code (DPP QR codes are supported too).
- **Bluetooth RSSI sort**: the "Available devices" list is sorted by signal strength (new devices
  are inserted by RSSI, refreshes are throttled to 2 s to avoid constant jumping).
- **Side key (Plus Key)**: Settings → System → Side key. Configurable single/double/long-press
  actions: ringer cycle, Do Not Disturb, camera, flashlight, screenshot, media controls, assistant.
- **Double-tap to wake**: works from screen-off/AOD. The touch controller reports the gesture as
  key code 62 (`KEY_F4`); `keylayout/touchpanel.kl` maps it to `WAKEUP` so the framework wakes the
  device instead of ignoring it. Toggle: Settings → Display → Tap to wake.
- **KernelSU + SUSFS built-in kernel** (separate repo): BakaSU/SukiSU + SUSFS 2.3.0.
- **BakaSU manager 35257** prebuilt (`prebuilts/ksu/BakaSU.apk`), matching the kernel driver version.
- `tools/verify.sh`: unified PASS/WARN/FAIL verification script.

## Build

```bash
# 1. Sync AviumUI 16.2.2 sources
repo init -u ... -b ...
repo sync -j8

# 2. Re-apply local source patches (required after every repo sync)
bash device/oneplus/macanc/patches/apply.sh

# 3. Build
. build/envsetup.sh
lunch lineage_macanc-bp4a-userdebug
m bacon
```

## Kernel

The kernel is kept in a separate repo:

- `android_device_oneplus_macanc-kernel` (prebuilt `Image` + kernel modules)

Kernel version: `6.12.38-android16-5-g844001fb8721-ab14552068-4k`

Source and build recipe:

- Source: **OnePlusOSS/android_kernel_oneplus_sm8845**, branch `oneplus/sm8845_b_16.0.0_ace_6t`
  (ACK `android16-6.12`)
- Build script: `cctv18/oppo_oplus_realme_sm8850` → `local/builder_6.12.38.sh`
- Features: BakaSU/SukiSU KernelSU + SUSFS, LZ4/ZSTD, ADIOS, network config tweaks
- The kernel `LOCALVERSION` is intentionally kept identical to the stock COS build so the
  prebuilt `vendor_dlkm` / `system_dlkm` modules keep loading.

## Input method (IME)

- **Xime 3.4.3** (`com.kingzcheung.xime`), arm64-v8a, is preinstalled in `/system/app/Xime`.
- It is set as the default IME on first boot; AOSP LatinIME remains enabled as a fallback.
- The APK is copied **byte-identical** (`LOCAL_REPLACE_PREBUILT_APK_INSTALLED`) to preserve its
  original v2 signature, so updates from GitHub / F-Droid continue to install normally.
- Source: https://github.com/ximeiorg/Xime (GPL-3.0). See `prebuilts/ime/README.md`.

## Verification

```bash
bash device/oneplus/macanc/tools/verify.sh --report
```

Covers: boot, SELinux, display refresh rate, audio, camera, sensors, Wi-Fi/BT/NFC, telephony/GNSS,
StrongBox (C-APDU / shared secret), KernelSU/SUSFS, thermal, USB. A manual checklist is printed at the end.

## Local patches

`patches/apply.sh` is idempotent and re-applies:

- `hardware/nxp/keymint`: disable the AOSP KM300 StrongBox module / transport install, use crDroid prebuilts.
- `packages/apps/Launcher3`: default icon shape `square` + apply custom shape to app-drawer icons.
- `vendor/lineage`: enable mobile data by default (`ro.com.android.mobiledata=true`).
- `frameworks/base`: default input method = Xime on first boot; AOSP LatinIME stays enabled as a fallback.
- `packages/apps/Settings`: add a WLAN toolbar QR-scan action (camera → add Wi-Fi network).
- `packages/apps/Settings`: sort Bluetooth available devices by RSSI, with a 2 s refresh throttle.
- `frameworks/base`: side-key controller + `PhoneWindowManager` interception (scan code 735 / `KEYCODE_ASSIST`).
- `packages/apps/Settings`: side key settings page (single / double / long press).

`keylayout/touchpanel.kl` is part of this device tree (installed to
`/vendor/usr/keylayout/touchpanel.kl` by `device.mk`); it needs no patch step.

## Notes / licensing

- `prebuilts/nxp/` contains **proprietary NXP/OnePlus binaries extracted from crDroid**.
  They are included here for reproducibility; redistribution may be subject to NXP/OnePlus terms.
- `prebuilts/ksu/BakaSU.apk` is GPL-3.0 (BakaSU / KernelSU). Source: https://github.com/Baka-SU/BakaSU
- `prebuilts/ime/Xime.apk` is GPL-3.0 (Xime). Source: https://github.com/ximeiorg/Xime
- Device tree: Apache-2.0 (LineageOS style).

## Credits

- LineageOS / AviumUI
- crDroid (StrongBox KeyMint3 prebuilts)
- OnePlusOSS (SM8845 kernel source)
- cctv18 (6.12 OPlus kernel build script)
- BakaSU / ReSukiSU / SukiSU / KernelSU
- OnePlus-SM8850-Development (device tree / prebuilt kernel base)
