import 'dart:async';

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

  @override
  Future<void> setAttribute(String key, Object? value) {
    calls.add('setAttribute($key, $value)');
    return Future.value();
  }

  @override
  Future<void> setAttributes(Map<String, Object> attributes) {
    calls.add('setAttributes($attributes)');
    return Future.value();
  }

  @override
  Future<void> removeAttribute(String key) {
    calls.add('removeAttribute($key)');
    return Future.value();
  }

  @override
  Future<void> clearAttributes() {
    calls.add('clearAttributes()');
    return Future.value();
  }

  final completions = StreamController<SurveyCompletion>.broadcast();

  @override
  Stream<SurveyCompletion> get onSurveyCompleted => completions.stream;
}

void main() {
  final FlutterWhiskrkitPlatform initialPlatform =
      FlutterWhiskrkitPlatform.instance;

  test('$MethodChannelFlutterWhiskrkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterWhiskrkit>());
  });

  test(
    'initialize forwards the API key, mocked surveys off by default',
    () async {
      final plugin = FlutterWhiskrkit();
      final fakePlatform = MockFlutterWhiskrkitPlatform();
      FlutterWhiskrkitPlatform.instance = fakePlatform;

      await plugin.initialize('api-key-123');
      expect(fakePlatform.calls, ['initialize(api-key-123, false)']);
    },
  );

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

  group('attributes', () {
    late FlutterWhiskrkit plugin;
    late MockFlutterWhiskrkitPlatform fakePlatform;

    setUp(() {
      plugin = FlutterWhiskrkit();
      fakePlatform = MockFlutterWhiskrkitPlatform();
      FlutterWhiskrkitPlatform.instance = fakePlatform;
    });

    test('forwards strings, numbers, bools and null', () async {
      await plugin.setAttribute('plan', 'pro');
      await plugin.setAttribute('sessions', 3);
      await plugin.setAttribute('ratio', 0.5);
      await plugin.setAttribute('beta', true);
      await plugin.setAttribute('plan', null);
      expect(fakePlatform.calls, [
        'setAttribute(plan, pro)',
        'setAttribute(sessions, 3)',
        'setAttribute(ratio, 0.5)',
        'setAttribute(beta, true)',
        'setAttribute(plan, null)',
      ]);
    });

    test('rejects other types and non-finite numbers', () {
      expect(() => plugin.setAttribute('n', double.nan), throwsArgumentError);
      expect(
        () => plugin.setAttribute('n', double.infinity),
        throwsArgumentError,
      );
      expect(() => plugin.setAttribute('l', <int>[1]), throwsArgumentError);
      expect(fakePlatform.calls, isEmpty);
    });

    test('setAttributes forwards the map and rejects bad values', () async {
      await plugin.setAttributes({'tier': 'gold', 'seats': 4});
      expect(fakePlatform.calls, ['setAttributes({tier: gold, seats: 4})']);
      expect(
        () => plugin.setAttributes({'ok': 'yes', 'bad': DateTime(2026)}),
        throwsArgumentError,
      );
      expect(fakePlatform.calls, hasLength(1));
    });

    test('removeAttribute and clearAttributes forward', () async {
      await plugin.removeAttribute('tier');
      await plugin.clearAttributes();
      expect(fakePlatform.calls, [
        'removeAttribute(tier)',
        'clearAttributes()',
      ]);
    });
  });

  test('onSurveyCompleted relays the platform stream', () async {
    final plugin = FlutterWhiskrkit();
    final fakePlatform = MockFlutterWhiskrkitPlatform();
    FlutterWhiskrkitPlatform.instance = fakePlatform;

    const completion = SurveyCompletion(surveyId: 's1', answers: []);
    final next = plugin.onSurveyCompleted.first;
    fakePlatform.completions.add(completion);
    expect(await next, completion);
  });
}
