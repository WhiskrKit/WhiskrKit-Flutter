import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whiskrkit/flutter_whiskrkit_method_channel.dart';
import 'package:flutter_whiskrkit/survey_completion.dart';

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

  test('attribute calls carry their arguments', () async {
    await platform.setAttribute('plan', 'pro');
    await platform.setAttribute('plan', null);
    await platform.setAttributes({'tier': 'gold', 'beta': true});
    await platform.removeAttribute('tier');
    await platform.clearAttributes();

    expect(log.map((c) => c.method), [
      'setAttribute',
      'setAttribute',
      'setAttributes',
      'removeAttribute',
      'clearAttributes',
    ]);
    expect(log[0].arguments, {'key': 'plan', 'value': 'pro'});
    expect(log[1].arguments, {'key': 'plan', 'value': null});
    expect(log[2].arguments, {
      'attributes': {'tier': 'gold', 'beta': true},
    });
    expect(log[3].arguments, {'key': 'tier'});
  });

  group('onSurveyCompleted', () {
    Future<void> sendFromNative(Object? arguments) async {
      final data = const StandardMethodCodec().encodeMethodCall(
        MethodCall('onSurveyCompleted', arguments),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('flutter_whiskrkit', data, (_) {});
    }

    test('parses every answer type from the native map', () async {
      final next = platform.onSurveyCompleted.first;
      await sendFromNative({
        'surveyId': 's1',
        'answers': [
          {
            'questionId': 's1-q1',
            'questionType': 'scaleRating',
            'valueType': 'score',
            'value': 9,
          },
          {
            'questionId': 's1-q2',
            'questionType': 'thumbsRating',
            'valueType': 'thumbs',
            'value': false,
          },
          {
            'questionId': 's1-q3',
            'questionType': 'textualSurvey',
            'valueType': 'text',
            'value': 'Great',
          },
          {
            'questionId': 's1-q4',
            'questionType': 'multipleChoice',
            'valueType': 'choices',
            'value': ['a', 'c'],
          },
        ],
      });

      expect(
        await next,
        const SurveyCompletion(
          surveyId: 's1',
          answers: [
            SurveyAnswer(
              questionId: 's1-q1',
              questionType: SurveyQuestionType.scaleRating,
              value: ScoreValue(9),
            ),
            SurveyAnswer(
              questionId: 's1-q2',
              questionType: SurveyQuestionType.thumbsRating,
              value: ThumbsValue(isUp: false),
            ),
            SurveyAnswer(
              questionId: 's1-q3',
              questionType: SurveyQuestionType.textualSurvey,
              value: TextValue('Great'),
            ),
            SurveyAnswer(
              questionId: 's1-q4',
              questionType: SurveyQuestionType.multipleChoice,
              value: ChoicesValue(['a', 'c']),
            ),
          ],
        ),
      );
    });

    test('skips answers with an unknown question or value type', () {
      final completion = SurveyCompletion.fromMap({
        'surveyId': 's',
        'answers': [
          {
            'questionId': 'a',
            'questionType': 'futureType',
            'valueType': 'score',
            'value': 1,
          },
          {
            'questionId': 'b',
            'questionType': 'symbolRating',
            'valueType': 'futureValue',
            'value': 1,
          },
          {
            'questionId': 'c',
            'questionType': 'symbolRating',
            'valueType': 'score',
            'value': 'x',
          },
          {
            'questionId': 'd',
            'questionType': 'symbolRating',
            'valueType': 'score',
            'value': 4,
          },
        ],
      });
      expect(completion?.answers, const [
        SurveyAnswer(
          questionId: 'd',
          questionType: SurveyQuestionType.symbolRating,
          value: ScoreValue(4),
        ),
      ]);
    });

    test('ignores a map without a survey id', () {
      expect(SurveyCompletion.fromMap({'answers': []}), isNull);
    });
  });
}
