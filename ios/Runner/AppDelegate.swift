import ActivityKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var liveActivityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GymplyLiveActivityPlugin") {
      setupLiveActivityChannel(messenger: registrar.messenger())
    }
  }

  private func setupLiveActivityChannel(messenger: FlutterBinaryMessenger) {
    if liveActivityChannel != nil { return }
    liveActivityChannel = FlutterMethodChannel(
      name: "dev.plotsklapps.gymply/live_activity",
      binaryMessenger: messenger
    )

    liveActivityChannel?.setMethodCallHandler { [weak self] call, result in
      if #available(iOS 16.2, *) {
        self?.handleLiveActivityCall(call: call, result: result)
      } else {
        result(false)
      }
    }
  }

  @available(iOS 16.2, *)
  private func handleLiveActivityCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "areActivitiesEnabled":
      result(ActivityAuthorizationInfo().areActivitiesEnabled)

    case "startActivity":
      guard let args = call.arguments as? [String: Any],
            let totalStartTimeMs = args["totalStartTimeMs"] as? Int64,
            let segmentLabel = args["segmentLabel"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        return
      }

      let segmentEndTimeMs = args["segmentEndTimeMs"] as? Int64
      LiveActivityManager.shared.start(
        totalStartTimeMs: totalStartTimeMs,
        segmentLabel: segmentLabel,
        segmentEndTimeMs: segmentEndTimeMs
      )
      result(true)

    case "updateActivity":
      guard let args = call.arguments as? [String: Any],
            let segmentLabel = args["segmentLabel"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        return
      }

      let segmentEndTimeMs = args["segmentEndTimeMs"] as? Int64
      LiveActivityManager.shared.update(
        segmentLabel: segmentLabel,
        segmentEndTimeMs: segmentEndTimeMs
      )
      result(true)

    case "stopActivity":
      LiveActivityManager.shared.end()
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

@available(iOS 16.2, *)
class LiveActivityManager {
  static let shared = LiveActivityManager()
  private var currentActivity: Activity<GymplyTimerAttributes>?

  func start(totalStartTimeMs: Int64, segmentLabel: String, segmentEndTimeMs: Int64?) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    // End any current activity
    end()

    let totalStartTime = Date(timeIntervalSince1970: Double(totalStartTimeMs) / 1000.0)
    let segmentEndTime: Date? = {
      if let ms = segmentEndTimeMs, ms > 0 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
      }
      return nil
    }()

    let attributes = GymplyTimerAttributes(workoutName: "GYMPLY")
    let initialContentState = GymplyTimerAttributes.ContentState(
      totalStartTime: totalStartTime,
      segmentLabel: segmentLabel,
      segmentEndTime: segmentEndTime
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: .init(state: initialContentState, staleDate: nil)
      )
      self.currentActivity = activity
    } catch {
      print("GYMPLY: Failed to start Live Activity: \(error)")
    }
  }

  func update(segmentLabel: String, segmentEndTimeMs: Int64?) {
    guard let activity = currentActivity else { return }
    let segmentEndTime: Date? = {
      if let ms = segmentEndTimeMs, ms > 0 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
      }
      return nil
    }()

    let updatedState = GymplyTimerAttributes.ContentState(
      totalStartTime: activity.content.state.totalStartTime,
      segmentLabel: segmentLabel,
      segmentEndTime: segmentEndTime
    )

    Task {
      await activity.update(.init(state: updatedState, staleDate: nil))
    }
  }

  func end() {
    guard let activity = currentActivity else { return }
    Task {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
    currentActivity = nil
  }
}
