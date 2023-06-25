import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'applist_detector_flutter_method_channel.dart';
import 'models/models.dart';

typedef PlayIntegrityUriBuilder = Uri Function(String token);

abstract class ApplistDetectorFlutterPlatform extends PlatformInterface {
  /// Constructs a ApplistDetectorFlutterPlatform.
  ApplistDetectorFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static ApplistDetectorFlutterPlatform _instance =
      MethodChannelApplistDetectorFlutter();

  /// The default instance of [ApplistDetectorFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelApplistDetectorFlutter].
  static ApplistDetectorFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ApplistDetectorFlutterPlatform] when
  /// they register themselves.
  static set instance(ApplistDetectorFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<DetectorResult> abnormalEnvironment() {
    throw UnimplementedError('abnormalEnvironment() has not been implemented.');
  }

  Future<DetectorResult> pmCommand({Set<String> packages = const {}}) {
    throw UnimplementedError('pmCommand() has not been implemented.');
  }

  Future<DetectorResult> pmConventionalAPIs({Set<String> packages = const {}}) {
    throw UnimplementedError('pmConventionalAPIs() has not been implemented.');
  }

  Future<DetectorResult> pmSundryAPIs({Set<String> packages = const {}}) {
    throw UnimplementedError('pmConventionalAPIs() has not been implemented.');
  }

  Future<DetectorResult> pmQueryIntentActivities(
      {Set<String> packages = const {}}) {
    throw UnimplementedError(
        'pmQueryIntentActivities() has not been implemented.');
  }

  Future<DetectorResult> fileDetection({
    Set<String> packages = const {},
    bool useSysCall = false,
  }) {
    throw UnimplementedError('fileDetection() has not been implemented.');
  }

  Future<DetectorResult> xposedFramework() {
    throw UnimplementedError('xposedFramework() has not been implemented.');
  }

  Future<DetectorResult> xposedModules({bool lspatch = false}) {
    throw UnimplementedError('xposedModules() has not been implemented.');
  }

  Future<DetectorResult> magiskApp() {
    throw UnimplementedError('magiskApp() has not been implemented.');
  }

  Future<DetectorResult> settingsProps() {
    throw UnimplementedError(
        'isDeveloperModeEnabled() has not been implemented.');
  }

  Future<DetectorResult> emulatorCheck() {
    throw UnimplementedError('isEmulator() has not been implemented.');
  }

  Future<String> checkPlayIntegrityApi(String nonce) {
    throw UnimplementedError(
        'checkPlayIntegrityApi() has not been implemented.');
  }

  Future<DetectorResult> checkRootBeer() {
    throw UnimplementedError('checkRootBeer() has not been implemented.');
  }
}
