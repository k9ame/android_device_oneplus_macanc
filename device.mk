#
# Copyright (C) 2021-2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# 默认壁纸：AOSP/crDroid 原生壁纸（覆盖 Avium overlay 里的二次元壁纸）
PRODUCT_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay-wallpaper

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxxhdpi

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_module_config_primary.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/audio_module_config_primary.xml \
    $(LOCAL_PATH)/configs/audio/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    $(LOCAL_PATH)/configs/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml

# Boot animation
TARGET_SCREEN_HEIGHT := 2800
TARGET_SCREEN_WIDTH := 1272

# Display
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/display/displayconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630946700822127507.xml

# Audio HAL：audiohalservice.qti 使用 prebuilt blob（不含 rc），
# 必须从源码把 init rc 复制进 vendor，否则 init 不会启动音频 HAL，
# system_server 的 AudioService 会卡住导致 sys.boot_completed 永远不置位。
# 用不同文件名安装，避免与 Soong 里同名的 prebuilt/源码模块安装目标冲突。
PRODUCT_COPY_FILES += \
    hardware/qcom-caf/sm8850/audio/primary-hal/hal/service/audiohalservice_qti.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/audiohalservice_qti_macanc.rc

# Keymint（StrongBox 使用 prebuilts/nxp 中来自 crDroid 的兼容版本）
# 注意：prebuilt 库必须显式列在 PRODUCT_PACKAGES 里，否则没人依赖它 Soong 不会安装，
# StrongBox 服务会因 dlopen 失败而崩溃，导致 keystore2 等待、init_user0 挂死、无法开机。
PRODUCT_PACKAGES += \
    android.hardware.security.keymint3-service.strongbox.nxp \
    android.hardware.weaver-service.nxp \
    libjc_keymint3.nxp \
    libjc_keymint_transport_nxp_override

# KernelSU 管理器（BakaSU 35257，版本与内核驱动 35257 匹配）
# 内核镜像由 device/oneplus/macanc-kernel 提供（已内置 KSU + SUSFS）。
# targetSdk 37 + 压缩 JNI 的预签名 APK 无法走 android_app_import 校验，
# 用 prebuilts/ksu/Android.mk 的 LOCAL_REPLACE_PREBUILT_APK_INSTALLED 原样拷贝，保留 v2 签名。
PRODUCT_PACKAGES += \
    BakaSU

# 输入法：Xime 3.4.3（Rime 五笔/拼音）
# 原样拷贝预签名 APK（保留 v2 签名），这样 GitHub/F-Droid 的更新仍可安装。
# 默认输入法由 frameworks/base SettingsProvider 补丁写入；AOSP LatinIME 保留。
PRODUCT_PACKAGES += \
    Xime

# LiveDisplay
$(call soong_config_set_bool,OPLUS_LINEAGE_LIVEDISPLAY_HAL,ENABLE_SE,false)

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay-lineage

PRODUCT_PACKAGES += \
    OPlusFrameworksResTarget \
    OPlusSettingsProviderResTarget \
    OPlusSettingsResTarget \
    OPlusSystemUIResTarget \
    OPlusWifiResTarget

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Touch features
$(call soong_config_set_bool,OPLUS_LINEAGE_TOUCH_HAL,ENABLE_GM,true)

# Vibrator
PRODUCT_PACKAGES += \
    android.hardware.vibrator.service.oplus-richtap

# Inherit from the common OEM chipset makefile.
$(call inherit-product, device/oneplus/sm8850-common/common.mk)

# Inherit from the proprietary files makefile.
$(call inherit-product, vendor/oneplus/macanc/macanc-vendor.mk)
