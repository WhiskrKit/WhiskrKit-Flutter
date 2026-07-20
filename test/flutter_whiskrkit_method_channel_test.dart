import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whiskrkit/flutter_whiskrkit_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterWhiskrkit platform = MethodChannelFlutterWhiskrkit();
  const MethodChannel channel = MethodChannel('flutter_whiskrkit');

  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize invokes the platform with apiKey and flag', () async {
    await platform.initialize('api-key-123', withMockedSurveys: true);

    expect(log, hasLength(1));
    expect(log.single.method, 'initialize');
    expect(log.single.arguments, {
      'apiKey': 'api-key-123',
      'withMockedSurveys': true,
    });
  });

  test('present invokes the platform with the survey id', () async {
    await platform.present('welcome-toast');

    expect(log.single.method, 'present');
    expect(log.single.arguments, {'surveyId': 'welcome-toast'});
  });

  test('checkAndPresent invokes the platform with the survey id', () async {
    await platform.checkAndPresent('choice-survey');

    expect(log.single.method, 'checkAndPresent');
    expect(log.single.arguments, {'surveyId': 'choice-survey'});
  });
}
