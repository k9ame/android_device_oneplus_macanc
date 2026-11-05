LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := Xime
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_SRC_FILES := Xime.apk
# Xime 3.4.3 是 targetSdk 35 + 压缩 JNI 的 v2 签名 APK。
# 走 Soong android_app_import 会被 preprocessed 校验拒绝；走普通
# BUILD_PREBUILT 又会被解压 JNI/zipalign 破坏签名。这里原样拷贝，
# 保留原始签名，GitHub/F-Droid 的增量更新才能继续安装。
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/Xime.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_DEX_PREOPT := false
LOCAL_ENFORCE_USES_LIBRARIES := false
LOCAL_MODULE_PATH := $(TARGET_OUT_APPS)
include $(BUILD_PREBUILT)
