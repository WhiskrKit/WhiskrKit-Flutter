import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_whiskrkit_platform_interface.dart';

/// An implementation of [FlutterWhiskrkitPlatform] that uses method channels.
class MethodChannelFlutterWhiskrkit extends FlutterWhiskrkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_whiskrkit');

  @override
  Future<void> initialize(String apiKey, {bool withMockedSurveys = false}) {
    return methodChannel.invokeMethod<void>('initialize', {
      'apiKey': apiKey,
      'withMockedSurveys': withMockedSurveys,
    });
  }

  @override
  Future<void> present(String surveyId) {
    return methodChannel.invokeMethod<void>('present', {'surveyId': surveyId});
  }

  @override
  Future<void> checkAndPresent(String surveyId) {
    return methodChannel.invokeMethod<void>('checkAndPresent', {
      'surveyId': surveyId,
    });
  }
}
