# Xime 3.4.3 (arm64-v8a)

预编译输入法 APK，随设备树一起内置到 `/system/app/Xime/Xime.apk`。

| 项目 | 值 |
|---|---|
| 包名 | `com.kingzcheung.xime` |
| 版本 | 3.4.3 (`versionCode 20261029`) |
| IME 组件 | `com.kingzcheung.xime/.service.XimeInputMethodService` |
| APK SHA-256 | `095b0bc4008d8932521a44059cccfde648d6d22b572203acc93ff9520204dfbf` |
| 签名证书 SHA-256 | `48f3d427d35d44631bb38da8f48800efdf7ba3b2e115e6ba6ec3a1651e7910c7` |
| 源码 | https://github.com/ximeiorg/Xime |
| 下载 | https://gitcode.com/ximeiorg/Xime/releases/download/v3.4.3/Xime-3.4.3-arm64-v8a.apk |
| 许可 | GPL-3.0 |

## 为什么原样拷贝

Xime 是 `targetSdk 35`、仅 v2 签名、JNI `.so` 压缩存放的 APK：

- Soong `android_app_import` + `preprocessed: true` 会拒绝压缩 JNI；
- 普通 `BUILD_PREBUILT` 会解压 JNI / zipalign，破坏 v2 签名。

因此 `Android.mk` 使用：

```make
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/Xime.apk
```

APK 会**逐字节原样**安装，签名保持不变。这样 GitHub / F-Droid 发布的同签名更新仍可正常覆盖安装，不会出现 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`。

## 默认输入法

默认输入法由 `frameworks/base` 的 `SettingsProvider` 补丁在首次创建 secure settings 数据库时写入：

- `default_input_method = com.kingzcheung.xime/.service.XimeInputMethodService`
- `enabled_input_methods = Xime:com.android.inputmethod.latin/.LatinIME`

AOSP LatinIME 仍然保留并启用，用户可以在设置里随时切换。用户后续手动切换的输入法不会被覆盖。
