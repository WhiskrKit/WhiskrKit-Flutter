## 0.3.0

Mirrors native SDK version 0.3.0. No changes to the Dart API.

- Requires whiskrkit-swift 0.3.0 and whiskrkit-android 0.3.0. Those versions
  render the rating metric the server sends with scale questions (NPS, CSAT,
  CES or custom): fixed colors per metric with an outline on the selected
  score, translated end labels under the scale, stars for 1 to 5 ratings shown
  as stars, and buttons that grow with the text size. No app changes are
  needed. Scale questions from a server without metrics show the neutral
  selected color instead of the old red to green gradient.
- The native SDKs now send `X-WhiskrKit-SDK` with their platform and version,
  for example `ios/0.3.0`. It names the native SDK, not this plugin.

### Fixed

- On iOS, deselecting a scale rating (tapping the selected score again) no
  longer submits the old score. Fixed in whiskrkit-swift 0.3.0.

## 0.2.0

Mirrors native SDK version 0.2.0.

- `setAttribute`, `setAttributes`, `removeAttribute` and `clearAttributes`:
  attach string, number or bool values to every survey response submitted
  afterwards. Invalid values throw an `ArgumentError`.
- `onSurveyCompleted`: a stream of `SurveyCompletion`s, emitted when the user
  submits a survey, with the survey id and each answer's question id, question
  type and value. It fires whether or not the response reaches the server, and
  not when a survey is dismissed without submitting.
- Android minSdk is now 24 (was 26), following whiskrkit-android 0.2.0, which
  also needs only Jetpack Compose 1.10.
- Requires whiskrkit-swift 0.2.0 and whiskrkit-android 0.2.0. Those versions
  also bring translated built-in strings that follow the survey's language and
  the "Powered by WhiskrKit" line on the Free plan, with no changes needed in
  the app.
- The example app's Gradle wrapper is now 9.3.1, the minimum for current
  Flutter versions.

## 0.1.0

Initial release, mirroring native SDK version 0.1.x.

- `initialize(apiKey, {withMockedSurveys})` — initializes the SDK; attaches
  the native survey host automatically (UIKit window attachment on iOS,
  `WhiskrKitHost` in a `ComposeView` overlay on Android).
- `present(surveyId)` — imperative presentation, bypassing eligibility.
- `checkAndPresent(surveyId)` — eligibility-checked presentation.
- Fire-and-forget by design, matching the native SDKs: no events, no error
  callbacks; failures are logged natively.
- Requires iOS 17+ (whiskrkit-swift 0.1.9 via Swift Package Manager) and
  Android minSdk 26+ (whiskrkit-android 0.1.1 from Maven Central).
