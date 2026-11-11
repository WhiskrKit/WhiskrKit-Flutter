/// A survey the user just submitted, delivered by
/// [FlutterWhiskrkit.onSurveyCompleted].
library;

/// The kind of question that was answered.
enum SurveyQuestionType {
  scaleRating,
  symbolRating,
  thumbsRating,
  textualSurvey,
  multipleChoice,
}

/// The value the user submitted for one question.
sealed class SurveyAnswerValue {
  const SurveyAnswerValue();
}

/// A scale or star rating.
final class ScoreValue extends SurveyAnswerValue {
  const ScoreValue(this.score);
  final int score;

  @override
  bool operator ==(Object other) => other is ScoreValue && other.score == score;
  @override
  int get hashCode => score.hashCode;
  @override
  String toString() => 'ScoreValue($score)';
}

/// A thumbs rating: `true` for thumbs up, `false` for thumbs down.
final class ThumbsValue extends SurveyAnswerValue {
  const ThumbsValue({required this.isUp});
  final bool isUp;

  @override
  bool operator ==(Object other) => other is ThumbsValue && other.isUp == isUp;
  @override
  int get hashCode => isUp.hashCode;
  @override
  String toString() => 'ThumbsValue(isUp: $isUp)';
}

/// Free text.
final class TextValue extends SurveyAnswerValue {
  const TextValue(this.text);
  final String text;

  @override
  bool operator ==(Object other) => other is TextValue && other.text == text;
  @override
  int get hashCode => text.hashCode;
  @override
  String toString() => 'TextValue($text)';
}

/// The ids of the selected multiple choice options.
final class ChoicesValue extends SurveyAnswerValue {
  const ChoicesValue(this.optionIds);
  final List<String> optionIds;

  @override
  bool operator ==(Object other) =>
      other is ChoicesValue &&
      other.optionIds.length == optionIds.length &&
      Iterable<int>.generate(
        optionIds.length,
      ).every((i) => other.optionIds[i] == optionIds[i]);
  @override
  int get hashCode => Object.hashAll(optionIds);
  @override
  String toString() => 'ChoicesValue($optionIds)';
}

/// One answered question.
class SurveyAnswer {
  const SurveyAnswer({
    required this.questionId,
    required this.questionType,
    required this.value,
  });

  final String questionId;
  final SurveyQuestionType questionType;
  final SurveyAnswerValue value;

  @override
  bool operator ==(Object other) =>
      other is SurveyAnswer &&
      other.questionId == questionId &&
      other.questionType == questionType &&
      other.value == value;
  @override
  int get hashCode => Object.hash(questionId, questionType, value);
  @override
  String toString() => 'SurveyAnswer($questionId, $questionType, $value)';
}

/// A submitted survey: its id and the answers given, ordered by question id.
/// Questions the user left unanswered are not included.
class SurveyCompletion {
  const SurveyCompletion({required this.surveyId, required this.answers});

  final String surveyId;
  final List<SurveyAnswer> answers;

  /// Builds a completion from the map the native plugins send. Answers with an
  /// unknown question or value type (from a newer native SDK) are skipped.
  /// Returns `null` when the map has no survey id.
  static SurveyCompletion? fromMap(Map<Object?, Object?> map) {
    final surveyId = map['surveyId'];
    if (surveyId is! String) return null;
    final rawAnswers = map['answers'];
    final answers = <SurveyAnswer>[];
    if (rawAnswers is List) {
      for (final raw in rawAnswers) {
        if (raw is! Map) continue;
        final answer = _answerFromMap(raw);
        if (answer != null) answers.add(answer);
      }
    }
    return SurveyCompletion(surveyId: surveyId, answers: answers);
  }

  static SurveyAnswer? _answerFromMap(Map<Object?, Object?> map) {
    final questionId = map['questionId'];
    final typeName = map['questionType'];
    if (questionId is! String || typeName is! String) return null;
    final type = SurveyQuestionType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) return null;

    final raw = map['value'];
    final SurveyAnswerValue? value = switch (map['valueType']) {
      'score' when raw is num => ScoreValue(raw.toInt()),
      'thumbs' when raw is bool => ThumbsValue(isUp: raw),
      'text' when raw is String => TextValue(raw),
      'choices' when raw is List => ChoicesValue(
        List.unmodifiable(raw.whereType<String>()),
      ),
      _ => null,
    };
    if (value == null) return null;
    return SurveyAnswer(
      questionId: questionId,
      questionType: type,
      value: value,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SurveyCompletion &&
      other.surveyId == surveyId &&
      other.answers.length == answers.length &&
      Iterable<int>.generate(
        answers.length,
      ).every((i) => other.answers[i] == answers[i]);
  @override
  int get hashCode => Object.hash(surveyId, Object.hashAll(answers));
  @override
  String toString() => 'SurveyCompletion($surveyId, $answers)';
}
