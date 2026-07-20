import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_whiskrkit_method_channel.dart';

abstract class FlutterWhiskrkitPlatform extends PlatformInterface {
  /// Constructs a FlutterWhiskrkitPlatform.
  FlutterWhiskrkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWhiskrkitPlatform _instance = MethodChannelFlutterWhiskrkit();

  /// The default instance of [FlutterWhiskrkitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterWhiskrkit].
  static FlutterWhiskrkitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterWhiskrkitPlatform] when
  /// they register themselves.
  static set instance(FlutterWhiskrkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize(String apiKey, {bool withMockedSurveys = false}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> present(String surveyId) {
    throw UnimplementedError('present() has not been implemented.');
  }

  Future<void> checkAndPresent(String surveyId) {
    throw UnimplementedError('checkAndPresent() has not been implemented.');
  }
}
