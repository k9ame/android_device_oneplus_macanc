#!/usr/bin/env bash
# repo sync 之后重新应用本机型需要的源码修改：
#  1. hardware/nxp/keymint：停用 AOSP 的 StrongBox 实现，改用 prebuilts/nxp（来自 crDroid）
#  2. packages/apps/Launcher3：图标默认形状 square（iOS 风格圆角矩形，介于圆形和直角之间），
#     并让应用抽屉图标也应用自定义形状（原逻辑只对 FLAG_THEMED 图标生效）
#  3. vendor/lineage：移动数据默认开启（覆盖 Lineage 的 ro.com.android.mobiledata=false）
#  4. frameworks/base：SettingsProvider 首次建库时把 Xime 设为默认输入法，
#     同时保留 AOSP LatinIME 为可选输入法
#  5. packages/apps/Settings：WLAN 页面工具栏增加“扫描二维码”入口，
#     调用已有的 DPP/ZXing Wi-Fi 扫码界面
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

apply_patch() {
    local repo="$1"
    local patch="$2"
    local name="$3"
    if git -C "$ROOT/$repo" apply --check "$patch" 2>/dev/null; then
        git -C "$ROOT/$repo" apply "$patch"
        echo "patched $name"
    elif git -C "$ROOT/$repo" apply --reverse --check "$patch" 2>/dev/null; then
        echo "$name already patched"
    else
        echo "ERROR: 无法应用 $name 补丁，请检查源码状态" >&2
        exit 1
    fi
}

apply_patch "hardware/nxp/keymint" \
    "$ROOT/device/oneplus/macanc/patches/hardware_nxp_keymint.patch" \
    "hardware/nxp/keymint"

apply_patch "packages/apps/Launcher3" \
    "$ROOT/device/oneplus/macanc/patches/launcher3_icon_shape.patch" \
    "packages/apps/Launcher3"

apply_patch "vendor/lineage" \
    "$ROOT/device/oneplus/macanc/patches/lineage_telephony_mobile_data.patch" \
    "vendor/lineage telephony (mobile data default on)"

apply_patch "frameworks/base" \
    "$ROOT/device/oneplus/macanc/patches/settingsprovider_default_ime.patch" \
    "frameworks/base SettingsProvider (default IME = Xime)"

apply_patch "packages/apps/Settings" \
    "$ROOT/device/oneplus/macanc/patches/settings_wifi_qr_scan.patch" \
    "packages/apps/Settings (WLAN QR scan menu)"
