import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whiskrkit/flutter_whiskrkit.dart';
import 'package:flutter_whiskrkit/flutter_whiskrkit_platform_interface.dart';
import 'package:flutter_whiskrkit/flutter_whiskrkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterWhiskrkitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWhiskrkitPlatform {
  final calls = <String>[];

  @override
  Future<void> initialize(String apiKey, {bool withMockedSurveys = false}) {
    calls.add('initialize($apiKey, $withMockedSurveys)');
    return Future.value();
  }

  @override
  Future<void> present(String surveyId) {
    calls.add('present($surveyId)');
    return Future.value();
  }

  @override
  Future<void> checkAndPresent(String surveyId) {
    calls.add('checkAndPresent($surveyId)');
    return Future.value();
  }
}

void main() {
  final FlutterWhiskrkitPlatform initialPlatform =
      FlutterWhiskrkitPlatform.instance;

  test('$MethodChannelFlutterWhiskrkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterWhiskrkit>());
  });

  test('initialize forwards the API key, mocked surveys off by default',
      () async {
    final plugin = FlutterWhiskrkit();
    final fakePlatform = MockFlutterWhiskrkitPlatform();
    FlutterWhiskrkitPlatform.instance = fakePlatform;

    await plugin.initialize('api-key-123');
    expect(fakePlatform.calls, ['initialize(api-key-123, false)']);
  });

  test('initialize forwards withMockedSurveys when set', () async {
    final plugin = FlutterWhiskrkit();
    final fakePlatform = MockFlutterWhiskrkitPlatform();
    FlutterWhiskrkitPlatform.instance = fakePlatform;

    await plugin.initialize('any-key', withMockedSurveys: true);
    expect(fakePlatform.calls, ['initialize(any-key, true)']);
  });

  test('present forwards the survey id', () async {
    final plugin = FlutterWhiskrkit();
    final fakePlatform = MockFlutterWhiskrkitPlatform();
    FlutterWhiskrkitPlatform.instance = fakePlatform;

    await plugin.present('welcome-toast');
    expect(fakePlatform.calls, ['present(welcome-toast)']);
  });

  test('checkAndPresent forwards the survey id', () async {
    final plugin = FlutterWhiskrkit();
    final fakePlatform = MockFlutterWhiskrkitPlatform();
    FlutterWhiskrkitPlatform.instance = fakePlatform;

    await plugin.checkAndPresent('choice-survey');
    expect(fakePlatform.calls, ['checkAndPresent(choice-survey)']);
  });
}
