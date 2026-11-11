/// Flutter wrapper for WhiskrKit, the native in-app survey SDK.
///
/// Surveys render as fully native UI (toast, sheet, or fullscreen) presented
/// by the native WhiskrKit SDKs — this plugin only triggers presentation; no
/// survey UI lives in Flutter.
///
/// Calls are **fire-and-forget**, mirroring the native SDKs: they do not
/// report outcomes, and failures are logged natively rather than surfaced to
/// Dart. The one event is [FlutterWhiskrkit.onSurveyCompleted], which tells
/// you when the user submits a survey.
library;

import 'flutter_whiskrkit_platform_interface.dart';
import 'survey_completion.dart';

export 'survey_completion.dart';

/// Entry point of the WhiskrKit Flutter plugin.
///
/// ```dart
/// final whiskrkit = FlutterWhiskrkit();
/// await whiskrkit.initialize('your-api-key');
/// await whiskrkit.present('your-survey-id');
/// ```
class FlutterWhiskrkit {
  /// Initializes WhiskrKit with the provided API key.
  ///
  /// Must be called before any other WhiskrKit method, as early as possible
  /// (e.g. from your root widget's `initState`). On iOS this also attaches
  /// the survey overlay to your app's window; on Android it mounts the survey
  /// host over the current activity.
  ///
  /// WhiskrKit fails silently by design: if something is wrong (bad API key,
  /// no network), no survey appears and details go to the native log
  /// (Console.app / Logcat). There is no error callback.
  ///
  /// When [withMockedSurveys] is `true`, the SDK serves built-in mock surveys
  /// and logs submissions instead of calling the backend — use any string as
  /// the API key. Intended for development only.
  ///
  /// The returned [Future] completes when the call has been dispatched to the
  /// platform, **not** when initialization has finished doing anything
  /// observable.
  Future<void> initialize(String apiKey, {bool withMockedSurveys = false}) {
    return FlutterWhiskrkitPlatform.instance.initialize(
      apiKey,
      withMockedSurveys: withMockedSurveys,
    );
  }

  /// Imperatively presents a survey, bypassing eligibility checks.
  ///
  /// Use this for manual triggers: a feedback button, a push notification
  /// handler, or any other in-app event where you decide the survey should
  /// appear.
  ///
  /// Fire-and-forget: the returned [Future] completes when the call is
  /// dispatched — it does **not** report whether a survey was shown. If the
  /// survey ID is unknown or the SDK is not initialized, nothing appears and
  /// the reason is logged natively.
  Future<void> present(String surveyId) {
    return FlutterWhiskrkitPlatform.instance.present(surveyId);
  }

  /// Checks eligibility for a survey and presents it only if the user
  /// qualifies.
  ///
  /// Use this when the timing is yours (after a flow completes, a screen
  /// closes) but the targeting decision should stay with the backend. Unlike
  /// [present], this respects the eligibility rules configured in the
  /// WhiskrKit dashboard (session counts, cooldowns, repeat policies).
  ///
  /// Fire-and-forget: the returned [Future] completes when the call is
  /// dispatched — not eligible, unknown survey ID, and network failure all
  /// look the same from Dart: no survey appears.
  Future<void> checkAndPresent(String surveyId) {
    return FlutterWhiskrkitPlatform.instance.checkAndPresent(surveyId);
  }

  /// Sets a global attribute that is sent with every survey response submitted
  /// afterwards, for example the user's plan, to filter results in the
  /// dashboard. Attributes live in memory only, so set them again at launch.
  ///
  /// [value] must be a [String], a finite [num] or a [bool]; `null` removes
  /// the attribute. Any other type throws an [ArgumentError].
  ///
  /// Do not send personal data (emails, phone numbers, names, IBANs, card
  /// numbers): the server drops it. Limits: 20 attributes, keys of 1 to 64
  /// characters, text values up to 256 characters; the SDK trims the rest.
  Future<void> setAttribute(String key, Object? value) {
    if (value != null) _checkAttributeValue(key, value);
    return FlutterWhiskrkitPlatform.instance.setAttribute(key, value);
  }

  /// Sets several global attributes at once, merged into the current ones.
  /// See [setAttribute] for the allowed values.
  Future<void> setAttributes(Map<String, Object> attributes) {
    attributes.forEach(_checkAttributeValue);
    return FlutterWhiskrkitPlatform.instance.setAttributes(attributes);
  }

  /// Removes one global attribute.
  Future<void> removeAttribute(String key) {
    return FlutterWhiskrkitPlatform.instance.removeAttribute(key);
  }

  /// Removes all global attributes.
  Future<void> clearAttributes() {
    return FlutterWhiskrkitPlatform.instance.clearAttributes();
  }

  /// Emits each time the user submits a survey, with the survey id and the
  /// answers given (question id, question type and value).
  ///
  /// It fires as soon as the user submits, whether or not the response reaches
  /// the server (a failed submission is queued and retried natively), and
  /// never when a survey is dismissed without submitting. It also fires with
  /// mocked surveys. Listen before calling [initialize] to be sure not to miss
  /// an event.
  ///
  /// ```dart
  /// whiskrkit.onSurveyCompleted.listen((completion) {
  ///   analytics.log('survey_completed', completion.surveyId);
  /// });
  /// ```
  Stream<SurveyCompletion> get onSurveyCompleted =>
      FlutterWhiskrkitPlatform.instance.onSurveyCompleted;

  static void _checkAttributeValue(String key, Object value) {
    final ok =
        value is String || value is bool || (value is num && value.isFinite);
    if (!ok) {
      throw ArgumentError.value(
        value,
        key,
        'Attribute values must be a String, a finite num or a bool',
      );
    }
  }
}
