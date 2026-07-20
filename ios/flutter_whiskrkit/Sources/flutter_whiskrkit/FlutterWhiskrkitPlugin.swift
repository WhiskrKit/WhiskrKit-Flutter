import Flutter
import UIKit
import WhiskrKit

/// Flutter side of the WhiskrKit bridge.
///
/// A thin shim over the Swift-only WhiskrKit SDK: every method hops to the
/// main actor (matching the SDK's `@MainActor` isolation) and is
/// fire-and-forget, mirroring the SDK's silent-failure contract — the `result`
/// completes when the call is dispatched, never with a survey outcome.
/// Failures go to the native log (Console.app, subsystem WhiskrKit).
public class FlutterWhiskrkitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_whiskrkit", binaryMessenger: registrar.messenger())
    let instance = FlutterWhiskrkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]

    switch call.method {
    case "initialize":
      guard let apiKey = args?["apiKey"] as? String else {
        result(FlutterError(code: "bad-args", message: "initialize requires a String apiKey", details: nil))
        return
      }
      let withMockedSurveys = args?["withMockedSurveys"] as? Bool ?? false
      Task { @MainActor in
        WhiskrKit.shared.initialize(apiKey: apiKey, withMockedSurveys: withMockedSurveys)
        Self.attachToHostWindow()
      }
      result(nil)

    case "present":
      guard let surveyId = args?["surveyId"] as? String else {
        result(FlutterError(code: "bad-args", message: "present requires a String surveyId", details: nil))
        return
      }
      Task { @MainActor in
        Self.attachToHostWindow()
        WhiskrKit.shared.present(surveyId: surveyId)
      }
      result(nil)

    case "checkAndPresent":
      guard let surveyId = args?["surveyId"] as? String else {
        result(FlutterError(code: "bad-args", message: "checkAndPresent requires a String surveyId", details: nil))
        return
      }
      Task { @MainActor in
        Self.attachToHostWindow()
        WhiskrKit.shared.checkAndPresent(surveyId: surveyId)
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Registers the app's window as the survey attachment point. Safe to call
  /// repeatedly: the SDK treats a re-attach to the same scene as a no-op, so
  /// each trigger self-heals the attachment if the app's windows changed.
  /// A Flutter iOS app is a FlutterViewController inside a normal UIWindow,
  /// so the SDK's UIKit attachment works unchanged.
  @MainActor
  private static func attachToHostWindow() {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    guard let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first else {
      return
    }
    WhiskrKit.shared.attach(to: window)
  }
}
