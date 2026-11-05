#!/usr/bin/env bash
# OnePlus Ace 6T (macanc) / Avium 统一功能验证脚本
#
# 用法：
#   bash device/oneplus/macanc/tools/verify.sh            # 交互式，输出到屏幕
#   bash device/oneplus/macanc/tools/verify.sh --report   # 同时保存报告文件
#   ADB="adb -s <serial>" bash .../verify.sh
#
# 说明：
#   - 只做只读检查，不会修改设备。
#   - 需要 root 的项会在未 root 时标记 SKIP。
#   - 自动项覆盖“能起来/关键 HAL 是否在跑”，无法自动判定的人工项见脚本末尾清单。

set -u
ADB=${ADB:-adb}
REPORT=0
[ "${1:-}" = "--report" ] && REPORT=1

PASS=0; WARN=0; FAIL=0; SKIP=0
ok()   { printf "  \033[32m[ OK ]\033[0m %s\n" "$*"; PASS=$((PASS+1)); }
warn() { printf "  \033[33m[WARN]\033[0m %s\n" "$*"; WARN=$((WARN+1)); }
bad()  { printf "  \033[31m[FAIL]\033[0m %s\n" "$*"; FAIL=$((FAIL+1)); }
skip() { printf "  \033[90m[SKIP]\033[0m %s\n" "$*"; SKIP=$((SKIP+1)); }
sec()  { printf "\n\033[1m== %s ==\033[0m\n" "$*"; }

sh() { $ADB shell "$@" 2>/dev/null | tr -d '\r'; }
prop() { sh getprop "$1"; }

# 输出同时写报告
if [ "$REPORT" = 1 ]; then
    LOG="verify-report-$(date +%Y%m%d-%H%M%S).txt"
    exec > >(tee "$LOG") 2>&1
    echo "报告文件: $LOG"
fi

sec "设备连接"
if ! $ADB get-state >/dev/null 2>&1; then
    bad "adb 未连接"
    exit 1
fi
ok "adb: $($ADB devices | sed -n 2p)"

sec "系统启动"
BOOT=$(prop sys.boot_completed)
[ "$BOOT" = "1" ] && ok "sys.boot_completed=1" || bad "sys.boot_completed=${BOOT:-<空>}（未完成启动）"
BANIM=$(prop init.svc.bootanim)
[ "$BANIM" = "stopped" ] && ok "bootanim 已停止" || warn "bootanim=$BANIM"
echo "     build.type       = $(prop ro.build.type)"
echo "     build.display.id = $(prop ro.build.display.id)"
echo "     fingerprint      = $(prop ro.build.fingerprint)"
echo "     security_patch   = $(prop ro.build.version.security_patch)"

sec "SELinux / 完整性"
ENF=$(sh getenforce)
[ "$ENF" = "Enforcing" ] && ok "SELinux=Enforcing" || warn "SELinux=$ENF"
DENY=$(sh logcat -d 2>/dev/null | grep -c "avc: denied")
if [ "${DENY:-0}" -eq 0 ]; then ok "logcat 无 avc denied"; else warn "logcat 有 $DENY 条 avc denied（检查是否影响功能）"; fi
CRASH=$(sh logcat -d -b crash 2>/dev/null | grep -cE "FATAL EXCEPTION|Fatal signal")
[ "${CRASH:-0}" -eq 0 ] && ok "无应用/system 崩溃记录" || warn "crash buffer 有 $CRASH 条记录"

sec "显示 / 刷新率"
SPECS=$(sh dumpsys display 2>/dev/null | grep -a -m1 -oE "mDisplayModeSpecs=\{[^}]*\}")
MAXFPS=$(echo "$SPECS" | sed -n 's/.*primary=physical: ([0-9.]* \([0-9.]*\)).*/\1/p')
MODES=$(sh dumpsys display 2>/dev/null | grep -a -m1 -oE "mActiveModeId=[0-9]+")
PEAKSET=$(sh settings get system peak_refresh_rate)
echo "     允许的上限: ${MAXFPS:-未知}Hz  当前模式: ${MODES:-未知}  设置 peak=${PEAKSET:-null}"
# 判断依据用「允许的上限」，而不是 SurfaceFlinger 会随场景波动的当前值
if [ -n "$MAXFPS" ] && awk "BEGIN{exit !($MAXFPS >= 90)}"; then
    ok "刷新率上限 >= 90Hz（${MAXFPS}Hz，来自 ROM 默认配置）"
else
    warn "刷新率上限偏低（${MAXFPS:-未知}Hz）：检查 config_defaultPeakRefreshRate"
fi

sec "音频"
if sh ps -A 2>/dev/null | grep -q "vendor.audio-hal-aidl\|audiohalservice.qti"; then
    ok "audio HAL 进程在运行"
else
    bad "audio HAL 未运行（检查 /vendor/etc/init 下 audiohalservice_qti*.rc）"
fi
if sh dumpsys media.audio_flinger 2>/dev/null | grep -q "Output thread"; then
    ok "AudioFlinger 已初始化"
else
    warn "AudioFlinger 输出线程信息为空"
fi

sec "相机"
CAM=$(sh dumpsys media.camera 2>/dev/null | grep -cE "Camera [0-9]+ device|Number of camera devices")
if [ "${CAM:-0}" -gt 0 ]; then ok "相机服务已枚举设备"; else bad "相机服务未枚举到设备"; fi

sec "传感器"
SENS=$(sh dumpsys sensorservice 2>/dev/null | grep -cE "^0x[0-9a-f]+|Sensor List")
if [ "${SENS:-0}" -gt 0 ]; then ok "sensorservice 有传感器列表"; else warn "未读到传感器列表"; fi

sec "无线"
WIFI=$(sh cmd wifi status 2>/dev/null | head -3)
[ -n "$WIFI" ] && ok "Wi-Fi 服务可用" || warn "Wi-Fi 状态读取失败"
sh dumpsys wifi 2>/dev/null | grep -qi "Wi-Fi is enabled" && ok "Wi-Fi 已启用" || warn "Wi-Fi 未启用或状态未知"
BT=$(sh dumpsys bluetooth_manager 2>/dev/null | grep -m1 -iE "enabled:|state:")
[ -n "$BT" ] && ok "Bluetooth 服务可用（$BT）" || warn "Bluetooth 状态读取失败"
NFC=$(sh dumpsys nfc 2>/dev/null | head -2)
[ -n "$NFC" ] && ok "NFC 服务可用" || warn "NFC 状态读取失败"

sec "通信 / 定位"
TEL=$(sh dumpsys telephony.registry 2>/dev/null | grep -m1 -iE "mServiceState|mDataConnectionState")
[ -n "$TEL" ] && ok "Telephony 已注册（$TEL）" || warn "Telephony 状态读取失败（可能无 SIM）"

# 移动数据默认值（仅影响首次创建 settings 数据库；已有数据分区保留用户选择）
MOBILE_DEFAULT=$(prop ro.com.android.mobiledata)
if [ "$MOBILE_DEFAULT" = "true" ]; then
    ok "移动数据默认开启（ro.com.android.mobiledata=true）"
else
    warn "移动数据默认关闭（ro.com.android.mobiledata=${MOBILE_DEFAULT:-未设置}）；新刷机后需手动打开"
fi
DATA1=$(sh settings get global mobile_data1 2>/dev/null)
if [ "$DATA1" = "1" ]; then
    ok "订阅 1 移动数据开关已开启（mobile_data1=1）"
else
    warn "订阅 1 移动数据开关未开启（mobile_data1=${DATA1:-null}）"
fi
if sh dumpsys connectivity 2>/dev/null | grep -q "extra: ctlte"; then
    ok "默认互联网 PDN 已建立（ctlte）"
else
    warn "未检测到默认互联网 PDN（ctlte）；可能无 SIM、未开数据或仅 IMS PDN"
fi

sh dumpsys location 2>/dev/null | grep -qi "gps" && ok "Location/GNSS 服务可用" || warn "GNSS 状态未知"
sh ps -A 2>/dev/null | grep -qi "gnss" && ok "GNSS 进程在运行" || warn "GNSS 进程未找到"

sec "安全 / StrongBox（重点）"
APDU=$(sh logcat -d 2>/dev/null | grep -c "Error in sending C-APDU")
if [ "${APDU:-0}" -eq 0 ]; then ok "无 C-APDU 通信错误"; else bad "出现 $APDU 次 C-APDU 错误（StrongBox/SE 通信异常）"; fi
sh logcat -d 2>/dev/null | grep -q "Shared secret negotiation concluded successfully" \
    && ok "StrongBox 共享密钥协商成功" || warn "未看到 StrongBox 协商成功日志（可能本次启动还未触发）"
SB=$(sh logcat -d 2>/dev/null | grep -c "vendor.keymint-strongbox")
[ "${SB:-0}" -gt 0 ] && ok "StrongBox 服务有运行日志" || warn "未看到 StrongBox 服务日志"

sec "KernelSU / Root"
KSU_MOD=$(sh ls /sys/module/kernelsu 2>/dev/null)
if [ -n "$KSU_MOD" ]; then
    ok "内核已内置 kernelsu"
    KSU_VER=$(sh cat /sys/module/kernelsu/version 2>/dev/null)
    [ -n "$KSU_VER" ] && echo "     kernelsu version = $KSU_VER"
else
    warn "未检测到 /sys/module/kernelsu（当前可能还是原厂预编译内核）"
fi
if sh pm list packages 2>/dev/null | grep -q "com.resukisu.resukisu"; then
    ok "ReSukiSU 管理器已安装"
else
    warn "ReSukiSU 管理器未安装（com.resukisu.resukisu）"
fi
if sh su -c id 2>/dev/null | grep -q "uid=0"; then
    ok "su 可用（uid=0）"
else
    warn "su 不可用（需要先在 ReSukiSU 管理器里授权 shell）"
fi

sec "温控 / 电源"
THERM=$(sh dumpsys thermalservice 2>/dev/null | grep -m1 -iE "Thermal Status|mStatus")
[ -n "$THERM" ] && ok "Thermal 服务可用（$THERM）" || warn "Thermal 状态读取失败"
sh dumpsys power 2>/dev/null | grep -qi "mWakefulness=Awake" && ok "PowerManager: 屏幕唤醒" || warn "设备可能处于休眠"

sec "USB / 充电"
USB=$(prop sys.usb.state)
[ -z "$USB" ] && USB="$(prop sys.usb.config) (config)"
[ -n "$USB" ] && ok "USB 状态: $USB" || warn "USB 状态为空"

echo
printf "\033[1m结果: OK=%d WARN=%d FAIL=%d SKIP=%d\033[0m\n" "$PASS" "$WARN" "$FAIL" "$SKIP"
[ "$FAIL" -gt 0 ] && echo "存在 FAIL 项，请先处理。" || echo "自动检查通过（WARN 需人工确认）。"

cat <<'EOF'

================= 需要人工验证的项 =================
1. 显示：设置里把刷新率设为 165Hz，滑动桌面/设置观察是否顺滑；切换 60/120/165 对比。
2. 触摸：全屏四角与边缘滑动、长按、双击唤醒。
3. 指纹：录入 + 解锁（多次，含湿手/角度）。
4. 相机：前后摄拍照、录像、闪光灯、变焦、人像；第三方相机 App。
5. 通话：主副卡拨号/接听/免提/听筒/录音；VoLTE。
6. 移动数据：4G/5G 开关、飞行模式、热点。
7. Wi-Fi：2.4G/5G/6G、WPA3、热点。
8. 蓝牙：耳机（A2DP/LE Audio）、传输文件。
9. NFC：刷卡/读标签（如有条件）。
10. 定位：室外 GPS 首次定位时间。
11. 音频：扬声器/听筒/耳机/蓝牙，通话录音，杜比/音效开关。
12. 充电：有线快充功率、无线充（如有）、OTG。
13. 振动：强度、铃声振动。
14. 传感器：自动亮度、旋转、距离感应（通话贴耳息屏）、指南针。
15. 待机：息屏 30 分钟耗电、深睡（dumpsys batterystats）。
16. 稳定性：连续使用 30 分钟 + 重启 3 次，观察是否卡开机动画/重启。
====================================================
EOF
