# Applist Detector Flutter

A Flutter ported library to detect suspicious apps like Magisk manager, Xposed framework, Abnormal Environment, running emulator and much more. Written in Kotlin and Dart ❤️ **This is not an officially supported Google product**

|   |   |   |   |
|---|---|---|---|
| ![security tester app logo](./screenshots/1.jpg) | ![displaying syscall file detection](./screenshots/2.jpg) | ![displaying pm Conventional apis](./screenshots/3.jpg)  | ![displaying emulator detection](./screenshots/4.jpg)  |

| Security Tester | |
|---|---|
| <img src="./screenshots/icon_512x512.png" alt="app logo" style="max-height: 150px;"> | You can use our app [Security Tester](../security_tester_app) which is a direct UI implementation/Example for this library.

### Platform Support

| Android | iOS | MacOS | Web | Linux | Windows |
| :-----: | :-: | :---: | :-: | :---: | :-----: |
|   ✅    | ❌  |  ❌   | ❌  |  ❌   |   ❌    |


### Features

- Check for suspicious files in the files in the system.

- Check for suspicious Settings props like debug props, vpn usage, etc.

- Check for abnormal environment for running suspicious apps like Magisk, Riru, or Zygisk.

- Check if the app is running on an emulator like Genymotion, Bluestacks, Windows subsystem for android, etc.
    > Note: This feature is not 100% accurate. but it is more accurate than the other libraries like [device_info_plus](https://pub.dev/packages/device_info_plus) or [safe_device](https://pub.dev/packages/safe_device).

- Check if the Xposed framework is installed.

- [Play Integrity API](https://developer.android.com/google/play/integrity) Checker which helps protect your apps and games from potentially risky and fraudulent interactions, such as cheating and unauthorized access, allowing you to respond with appropriate actions to prevent attacks and reduce abuse.


### Credits

- [1nikolas/play-integrity-checker-app](https://github.com/1nikolas/play-integrity-checker-app)

- [1nikolas/play-integrity-checker-server](https://github.com/1nikolas/play-integrity-checker-server)

- [Dr-TSNG/ApplistDetector](https://github.com/Dr-TSNG/ApplistDetector)

- [byxiaorun/Ruru](https://github.com/byxiaorun/Ruru)

- [rootbeer](https://github.com/scottyab/rootbeer)

- [fluttercommunity/device_info_plus](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/device_info_plus/device_info_plus)

- [ufukhawk/safe_device](https://github.com/ufukhawk/safe_device)


### Contribution

Feel free to contribute to this project by creating issues or pull requests. Any help is appreciated ❤️. Check out the [CONTRIBUTING.md](./CONTRIBUTING.md) file for more info.

#### Disclaimer

This tool is intended to be used by individuals to make it easy to secure your app for a large extend and it is **NOT 100% bulletproof**. If you are looking for a 100% secure solution, this is not the right tool for you. This tool is not intended to be used for any illegal or malicious activities. Use it only for good purposes. I am not responsible for any damage caused by this tool.

#### License

This library is distributed under Apache 2.0 license for more info see [LICENSE DETAILS](./LICENSE)
