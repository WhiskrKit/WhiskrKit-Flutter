/// Flutter wrapper for WhiskrKit, the native in-app survey SDK.
///
/// Surveys render as fully native UI (toast, sheet, or fullscreen) presented
/// by the native WhiskrKit SDKs — this plugin only triggers presentation; no
/// survey UI lives in Flutter.
///
/// The API is deliberately **fire-and-forget**, mirroring the native SDKs:
/// calls do not report outcomes, and failures are logged natively rather than
/// surfaced to Dart.
library;

import 'flutter_whiskrkit_platform_interface.dart';

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
}
