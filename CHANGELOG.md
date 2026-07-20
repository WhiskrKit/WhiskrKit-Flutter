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
