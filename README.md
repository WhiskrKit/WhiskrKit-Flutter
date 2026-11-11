![WhiskrKit logo](https://whiskrkit.eu/WhiskrKit_logo.png)
# WhiskrKit for Flutter - The purr-fect feedback toolkit for modern apps.

![version](https://img.shields.io/badge/version-0.1.0-blue) ![MIT](https://img.shields.io/badge/license-MIT-green)

WhiskrKit provides a flexible and easy-to-use API for presenting questionnaires and
feedback forms in your Flutter applications. This is the Flutter wrapper for
[WhiskrKit for iOS](https://whiskrkit.eu) and the [Android SDK](https://whiskrkit.eu);
all three talk to the same backend and share the same survey templates.

Surveys render as fully native UI (toast, sheet, or fullscreen) presented by the native
WhiskrKit SDKs — this plugin only triggers presentation, no survey UI lives in Flutter.
It is a thin bridge by design: it exposes exactly what the native SDKs expose. Like them,
it is **fire-and-forget** — calls do not report outcomes, and failures are logged natively
rather than surfaced to Dart (see [Design notes](#design-notes)).

## Requirements

- iOS 17+
- Android minSdk 24+

## Installation

```sh
flutter pub add flutter_whiskrkit
```

### iOS

The native WhiskrKit SDK is a Swift package, and this plugin declares it as a
Swift Package Manager dependency. Flutter resolves it automatically when Swift
Package Manager support is enabled (default in current Flutter; otherwise run
`flutter config --enable-swift-package-manager`).

Set your app's iOS deployment target to **17.0** (in
`ios/Runner.xcodeproj`).

<details>
<summary>Using CocoaPods instead of SwiftPM?</summary>

If your app has SwiftPM support disabled, the WhiskrKit Swift package must be
supplied via the [`cocoapods-spm`](https://github.com/trinhngocthuyen/cocoapods-spm)
plugin (`gem install cocoapods-spm`). In `ios/Podfile`:

```ruby
plugin 'cocoapods-spm'

target 'Runner' do
  spm_pkg "WhiskrKit",
          :url => "https://github.com/whiskrkit/whiskrkit-swift.git",
          :version => "0.2.0"
  # ...
end
```
</details>

### Android

The `eu.whiskrkit:whiskrkit-android` dependency resolves from Maven Central —
no extra setup. Just make sure your app's `minSdkVersion` is 24 or higher
(`android/app/build.gradle`).

## Quick start

```dart
import 'package:flutter_whiskrkit/flutter_whiskrkit.dart';

final whiskrkit = FlutterWhiskrkit();

// Once, at startup — e.g. in your root widget's initState.
await whiskrkit.initialize('your-api-key');

// Manual trigger (bypasses eligibility rules): a feedback button,
// a push notification handler, etc.
await whiskrkit.present('your-survey-id');

// Backend-controlled targeting, your timing: checks eligibility rules
// configured in the dashboard and presents only if the user qualifies.
await whiskrkit.checkAndPresent('your-survey-id');
```

During development you can use the SDK's built-in mock surveys without a
backend:

```dart
await whiskrkit.initialize('any-string', withMockedSurveys: true);
await whiskrkit.present('welcome-toast');
```

## API reference

| Method | Parameters | Returns | Platforms |
| --- | --- | --- | --- |
| `initialize(apiKey, {withMockedSurveys})` | `String apiKey`, `bool withMockedSurveys = false` | `Future<void>` | iOS, Android |
| `present(surveyId)` | `String surveyId` | `Future<void>` | iOS, Android |
| `checkAndPresent(surveyId)` | `String surveyId` | `Future<void>` | iOS, Android |
| `setAttribute(key, value)` | `String key`, `String`/`num`/`bool` value, `null` removes | `Future<void>` | iOS, Android |
| `setAttributes(attributes)` | `Map<String, Object>` | `Future<void>` | iOS, Android |
| `removeAttribute(key)` | `String key` | `Future<void>` | iOS, Android |
| `clearAttributes()` | — | `Future<void>` | iOS, Android |
| `onSurveyCompleted` | — | `Stream<SurveyCompletion>` | iOS, Android |

The returned futures complete when the call has been **dispatched to the
platform** — never with a survey outcome. `initialize` must be called before
`present` and `checkAndPresent`; calls made without it are silent no-ops
(logged natively).

### Attributes

Attach context about the current user or session to every survey response
submitted afterwards, such as the user's plan or an experiment variant. They're
stored with each response; see [Attributes](https://whiskrkit.eu/docs/attributes/) for what to send and what
not. Attributes live in memory only, so set them again at launch.

```dart
await whiskrkit.setAttribute('plan', 'pro');
await whiskrkit.setAttribute('sessions', 3);
await whiskrkit.setAttributes({'tier': 'gold', 'beta': true}); // merges
await whiskrkit.setAttribute('plan', null);                     // removes one
await whiskrkit.clearAttributes();
```

Values are strings, finite numbers or bools; anything else throws an
`ArgumentError`. Limits: 20 attributes, keys of 1 to 64 characters, text
values up to 256 characters; the native SDK trims the rest. Do not send
personal data (emails, phone numbers, names, IBANs, card numbers): the server
drops it See [Privacy](https://whiskrkit.eu/docs/attributes/#privacy).

### Survey completion

`onSurveyCompleted` emits each time the user submits a survey, with the survey
id and the submitted answers:

```dart
whiskrkit.onSurveyCompleted.listen((completion) {
  analytics.log('survey_completed', completion.surveyId);
  for (final answer in completion.answers) {
    switch (answer.value) {
      case ScoreValue(:final score):
        print('${answer.questionId}: $score');
      case ThumbsValue(:final isUp):
        print('${answer.questionId}: ${isUp ? 'up' : 'down'}');
      case TextValue(:final text):
        print('${answer.questionId}: $text');
      case ChoicesValue(:final optionIds):
        print('${answer.questionId}: $optionIds');
    }
  }
});
```

Each `SurveyAnswer` has a `questionId`, a `questionType` (`scaleRating`,
`symbolRating`, `thumbsRating`, `textualSurvey` or `multipleChoice`) and a
`value`. Unanswered questions are left out. It fires as soon as the user
submits, whether or not the response reaches the server (a failed submission
is queued and retried natively), never when a survey is dismissed without
submitting, and also with mocked surveys.

## Design notes

**Fire-and-forget, silent failure.** The native WhiskrKit SDKs deliberately
never surface errors to the host app: the SDK keeps its own record of shown
and completed surveys for eligibility and repeat-policy decisions, and
failures (bad API key, unknown survey ID, no network) simply mean no survey
appears. The plugin mirrors that contract, so there are no error codes. The
one event is `onSurveyCompleted`, which the native SDKs also expose. When
debugging, watch the native logs: Console.app (subsystem `WhiskrKit`) on iOS,
Logcat (tag `WhiskrKit`) on Android.

**How attachment works.** Native apps attach WhiskrKit with a SwiftUI view
modifier or a Compose host composable. The plugin does the equivalent
automatically on `initialize`: on iOS it registers your app's window via the
SDK's UIKit attachment point (`WhiskrKit.attach(to:)`), and on Android it
mounts the SDK's `WhiskrKitHost` composable in an overlay over the current
activity. While no survey is on screen the overlay is invisible and passes all
touches through.

## Platform differences

- **Presentation styles** — both platforms render toast (called *banner* in
  the Android SDK), sheet, and fullscreen surveys. The style comes from the
  survey's dashboard configuration, not from the caller.
- **iPad placement (`SheetPlacement` / `ToastPlacement`)** — an iOS-only
  concept controlling where sheet panels and toasts sit on wide screens. The
  plugin leaves the SDK defaults (`bottomCentered`, safe in any layout) in
  place; there is no Android equivalent.
- **Trigger buffering** — on Android, a `present()` fired before the host
  exists is buffered and delivered once it appears; on iOS it is a no-op.
  Calling `initialize` first (which attaches the host) makes this moot.

## Example app

`example/` contains a manual test harness: initialize with mocked surveys, an
editable survey ID with per-style presets, and buttons for both triggers.

```sh
cd example
flutter run
```

## Related packages

- React Native: [`react-native-whiskrkit`](https://www.npmjs.com/package/react-native-whiskrkit)
- iOS (native): [`whiskrkit-swift`](https://github.com/whiskrkit/whiskrkit-swift)
- Android (native): `eu.whiskrkit:whiskrkit-android` on Maven Central

## License

MIT
