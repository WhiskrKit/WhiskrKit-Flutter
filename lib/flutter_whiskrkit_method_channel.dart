import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_whiskrkit_platform_interface.dart';
import 'survey_completion.dart';

/// An implementation of [FlutterWhiskrkitPlatform] that uses method channels.
///
/// Calls go to the native plugins on `flutter_whiskrkit`. The native plugins
/// call back on the same channel with `onSurveyCompleted` when the user
/// submits a survey.
class MethodChannelFlutterWhiskrkit extends FlutterWhiskrkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_whiskrkit');

  final _completions = StreamController<SurveyCompletion>.broadcast();
  bool _listening = false;

  /// Starts receiving calls from the native side. Done on first use rather
  /// than in the constructor, because the default instance can be created
  /// before the Flutter binding exists.
  void _listen() {
    if (_listening) return;
    _listening = true;
    methodChannel.setMethodCallHandler(_handleNativeCall);
  }

  @visibleForTesting
  Future<void> handleNativeCallForTesting(MethodCall call) =>
      _handleNativeCall(call);

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onSurveyCompleted') return;
    final arguments = call.arguments;
    if (arguments is! Map) return;
    final completion = SurveyCompletion.fromMap(arguments);
    if (completion != null) _completions.add(completion);
  }

  @override
  Future<void> initialize(String apiKey, {bool withMockedSurveys = false}) {
    _listen();
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

  @override
  Future<void> setAttribute(String key, Object? value) {
    return methodChannel.invokeMethod<void>('setAttribute', {
      'key': key,
      'value': value,
    });
  }

  @override
  Future<void> setAttributes(Map<String, Object> attributes) {
    return methodChannel.invokeMethod<void>('setAttributes', {
      'attributes': attributes,
    });
  }

  @override
  Future<void> removeAttribute(String key) {
    return methodChannel.invokeMethod<void>('removeAttribute', {'key': key});
  }

  @override
  Future<void> clearAttributes() {
    return methodChannel.invokeMethod<void>('clearAttributes');
  }

  @override
  Stream<SurveyCompletion> get onSurveyCompleted {
    _listen();
    return _completions.stream;
  }
}
