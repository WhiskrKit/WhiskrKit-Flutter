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
///
/// The one call in the other direction is `onSurveyCompleted`, sent on the same
/// channel when the user submits a survey.
public class FlutterWhiskrkitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_whiskrkit", binaryMessenger: registrar.messenger())
    let instance = FlutterWhiskrkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    Task { @MainActor in
      WhiskrKit.shared.onSurveyCompleted = { completion in
        channel.invokeMethod("onSurveyCompleted", arguments: SurveyCompletionMapper.map(completion))
      }
    }
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

    case "setAttribute":
      guard let key = args?["key"] as? String else {
        result(FlutterError(code: "bad-args", message: "setAttribute requires a String key", details: nil))
        return
      }
      let raw = args?["value"]
      let value = AttributeConversion.value(raw)
      if value == nil, let raw, !(raw is NSNull) {
        result(FlutterError(code: "bad-args", message: "Attribute values must be a String, a finite number or a bool", details: nil))
        return
      }
      Task { @MainActor in
        WhiskrKit.shared.setAttribute(key, value)
      }
      result(nil)

    case "setAttributes":
      guard let raw = args?["attributes"] as? [String: Any] else {
        result(FlutterError(code: "bad-args", message: "setAttributes requires a map of attributes", details: nil))
        return
      }
      let attributes = raw.compactMapValues(AttributeConversion.value)
      Task { @MainActor in
        WhiskrKit.shared.setAttributes(attributes)
      }
      result(nil)

    case "removeAttribute":
      guard let key = args?["key"] as? String else {
        result(FlutterError(code: "bad-args", message: "removeAttribute requires a String key", details: nil))
        return
      }
      Task { @MainActor in
        WhiskrKit.shared.removeAttribute(key)
      }
      result(nil)

    case "clearAttributes":
      Task { @MainActor in
        WhiskrKit.shared.clearAttributes()
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

/// Turns a value from the Flutter codec into a WhiskrKit attribute value.
enum AttributeConversion {
  static func value(_ raw: Any?) -> AttributeValue? {
    switch raw {
    case let string as String:
      return .string(string)
    case let number as NSNumber:
      // Dart bools and numbers both arrive as NSNumber; only a CFBoolean is a bool.
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        return .bool(number.boolValue)
      }
      let double = number.doubleValue
      return double.isFinite ? .number(double) : nil
    default:
      return nil
    }
  }
}

/// Turns a survey completion into the map the Dart side reads.
enum SurveyCompletionMapper {
  static func map(_ completion: SurveyCompletion) -> [String: Any] {
    [
      "surveyId": completion.surveyId,
      "answers": completion.answers.map { answer -> [String: Any] in
        var map: [String: Any] = [
          "questionId": answer.questionId,
          "questionType": answer.questionType.rawValue,
        ]
        switch answer.value {
        case .score(let score):
          map["valueType"] = "score"
          map["value"] = score
        case .thumbs(let isUp):
          map["valueType"] = "thumbs"
          map["value"] = isUp
        case .text(let text):
          map["valueType"] = "text"
          map["value"] = text
        case .choices(let ids):
          map["valueType"] = "choices"
          map["value"] = ids
        }
        return map
      },
    ]
  }
}
