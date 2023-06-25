# Security Tester

**This is not an officially supported Google product**

A Flutter ported library to detect suspicious apps like Magisk manager, Xposed framework, Abnormal Environment, running emulator and much more. Written in Kotlin and Dart ❤️

## applist_detector_flutter

This is the plugin that is used to detect suspicious apps. it is considered the heart of this project.

To learn more visit README.md in [applist_detector_flutter](./applist_detector_flutter/README.md).

## Security Tester

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png"
     alt="Get it on Google Play"
     height="80">](https://play.google.com/store/apps/details?id=com.ahmed.security_tester)

You can use our app which is considered a direct UI implementation for this library. You can download it from [here](https://play.google.com/store/apps/details?id=com.ahmed.security_tester)

To learn more visit README.md in [security_tester_app](./security_tester_app/README.md).

## Features

A very simple Flutter app helps to detect suspicious apps like Magisk manager, Xposed framework, Abnormal Environment, running emulator and much more.

### Major Checks

These checks are borrowed from [applist_detector_flutter](./applist_detector_flutter) and are the most important checks.

- Search for suspicious files in filesystem.

- Check for abnormal environment for running suspicious apps like Magisk, Riru, or Zygisk.

- Check if the app is running on an emulator like Genymotion, Bluestacks, Windows subsystem for Android, etc.

> Note: This feature is **not 100% accurate**. but it is more accurate than the other libraries like [device_info_plus](https://pub.dev/packages/device_info_plus) or [safe_device](https://pub.dev/packages/safe_device).

- Check if the Xposed framework is installed/used.

- [Play Integrity API](https://developer.android.com/google/play/integrity) checker which helps protect your apps and games from potentially risky and fraudulent interactions, such as cheating and unauthorized access, allowing you to respond with appropriate actions to prevent attacks and reduce abuse.

### Additional Checks

These are minor checks and test for simple things like:

- Check if the app is running on external storage.

- Check if the app is running on a rooted device using [Rootbeer](https://github.com/scottyab/rootbeer).

- Detect Hooks using simple checks borrowed from [AntiDebug](https://github.com/weikaizhi/AntiDebug) and [jail-monkey](https://github.com/GantMan/jail-monkey) .

- Fetch the Telephone operator's name.

- View basic device info using [device_info_plus](https://pub.dev/packages/device_info_plus).

- View device CPI Info. See [The /proc Filesystem](https://www.kernel.org/doc/html/latest/filesystems/proc.html?highlight=smaps#id11)


### Credits

- [1nikolas/play-integrity-checker-app](https://github.com/1nikolas/play-integrity-checker-app)

- [1nikolas/play-integrity-checker-server](https://github.com/1nikolas/play-integrity-checker-server)

- [Dr-TSNG/ApplistDetector](https://github.com/Dr-TSNG/ApplistDetector)

- [byxiaorun/Ruru](https://github.com/byxiaorun/Ruru)

- [rootbeer](https://github.com/scottyab/rootbeer)

- [fluttercommunity/device_info_plus](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/device_info_plus/device_info_plus)

- [ufukhawk/safe_device](https://github.com/ufukhawk/safe_device)


## Disclaimer

Security Tester is intended to be used by individuals to make it easy to secure your app for a large extend and it is **NOT 100% bulletproof**. Security Tester is not intended to be used for any illegal or malicious activities. Use it only for good purposes. I am not responsible for any damage caused by Security Tester.

#### License

This library is distributed under Apache 2.0 license for more info see [LICENSE DETAILS](./LICENSE)
