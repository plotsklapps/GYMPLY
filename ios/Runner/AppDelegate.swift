import AVFoundation
import ActivityKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var liveActivityChannel: FlutterMethodChannel?
  private var audioChannel: FlutterMethodChannel?

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
      setupAudioChannel(messenger: registrar.messenger())
    }
  }

  private func setupAudioChannel(messenger: FlutterBinaryMessenger) {
    if audioChannel != nil { return }
    audioChannel = FlutterMethodChannel(
      name: "dev.plotsklapps.gymply/audio",
      binaryMessenger: messenger
    )

    audioChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "playTimerBell":
        NativeTimerBellPlayer.shared.playTimerBell()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
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
            let totalStartTimeNum = args["totalStartTimeMs"] as? NSNumber,
            let segmentLabel = args["segmentLabel"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        return
      }

      let totalStartTimeMs = totalStartTimeNum.int64Value
      let segmentDetail = args["segmentDetail"] as? String
      let segmentStartTimeMs = (args["segmentStartTimeMs"] as? NSNumber)?.int64Value
      let segmentEndTimeMs = (args["segmentEndTimeMs"] as? NSNumber)?.int64Value
      let staleDateMs = (args["staleDateMs"] as? NSNumber)?.int64Value
      let exerciseName = args["exerciseName"] as? String

      LiveActivityManager.shared.start(
        totalStartTimeMs: totalStartTimeMs,
        segmentLabel: segmentLabel,
        segmentDetail: segmentDetail,
        segmentStartTimeMs: segmentStartTimeMs,
        segmentEndTimeMs: segmentEndTimeMs,
        staleDateMs: staleDateMs,
        exerciseName: exerciseName
      )
      result(true)

    case "updateActivity":
      guard let args = call.arguments as? [String: Any],
            let segmentLabel = args["segmentLabel"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        return
      }

      let totalStartTimeMs = (args["totalStartTimeMs"] as? NSNumber)?.int64Value
      let segmentDetail = args["segmentDetail"] as? String
      let segmentStartTimeMs = (args["segmentStartTimeMs"] as? NSNumber)?.int64Value
      let segmentEndTimeMs = (args["segmentEndTimeMs"] as? NSNumber)?.int64Value
      let staleDateMs = (args["staleDateMs"] as? NSNumber)?.int64Value
      let exerciseName = args["exerciseName"] as? String

      LiveActivityManager.shared.update(
        totalStartTimeMs: totalStartTimeMs,
        segmentLabel: segmentLabel,
        segmentDetail: segmentDetail,
        segmentStartTimeMs: segmentStartTimeMs,
        segmentEndTimeMs: segmentEndTimeMs,
        staleDateMs: staleDateMs,
        exerciseName: exerciseName
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

  func start(
    totalStartTimeMs: Int64,
    segmentLabel: String,
    segmentDetail: String?,
    segmentStartTimeMs: Int64?,
    segmentEndTimeMs: Int64?,
    staleDateMs: Int64?,
    exerciseName: String?
  ) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    // End any current activity
    end()

    let totalStartTime = Date(timeIntervalSince1970: Double(totalStartTimeMs) / 1000.0)
    let segmentStartTime: Date? = {
      if let ms = segmentStartTimeMs, ms > 0 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
      }
      return nil
    }()
    let segmentEndTime: Date? = {
      if let ms = segmentEndTimeMs, ms > 0 {
        let date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
        return date > Date() ? date : nil
      }
      return nil
    }()
    let staleDate: Date? = {
      if let ms = staleDateMs, ms > 0 {
        let date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
        return date > Date() ? date : nil
      }
      return segmentEndTime
    }()

    let attributes = GymplyTimerAttributes(workoutName: "GYMPLY")
    let initialContentState = GymplyTimerAttributes.ContentState(
      totalStartTime: totalStartTime,
      segmentLabel: segmentLabel,
      segmentDetail: segmentDetail,
      segmentStartTime: segmentStartTime,
      segmentEndTime: segmentEndTime,
      exerciseName: exerciseName
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: .init(state: initialContentState, staleDate: staleDate)
      )
      self.currentActivity = activity
    } catch {
      print("GYMPLY: Failed to start Live Activity: \(error)")
    }
  }

  func update(
    totalStartTimeMs: Int64?,
    segmentLabel: String,
    segmentDetail: String?,
    segmentStartTimeMs: Int64?,
    segmentEndTimeMs: Int64?,
    staleDateMs: Int64?,
    exerciseName: String?
  ) {
    guard let activity = currentActivity else { return }
    let totalStartTime: Date = {
      if let ms = totalStartTimeMs, ms > 0 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
      }
      return activity.content.state.totalStartTime
    }()

    let segmentStartTime: Date? = {
      if let ms = segmentStartTimeMs, ms > 0 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
      }
      return nil
    }()

    let segmentEndTime: Date? = {
      if let ms = segmentEndTimeMs, ms > 0 {
        let date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
        return date > Date() ? date : nil
      }
      return nil
    }()

    let staleDate: Date? = {
      if let ms = staleDateMs, ms > 0 {
        let date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
        return date > Date() ? date : nil
      }
      return segmentEndTime
    }()

    let updatedState = GymplyTimerAttributes.ContentState(
      totalStartTime: totalStartTime,
      segmentLabel: segmentLabel,
      segmentDetail: segmentDetail,
      segmentStartTime: segmentStartTime,
      segmentEndTime: segmentEndTime,
      exerciseName: exerciseName
    )

    Task {
      await activity.update(.init(state: updatedState, staleDate: staleDate))
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

final class NativeTimerBellPlayer: NSObject, AVAudioPlayerDelegate {
  static let shared = NativeTimerBellPlayer()
  private var player: AVAudioPlayer?

  func playTimerBell() {
    guard let url = Bundle.main.url(forResource: "timerbell", withExtension: "wav") else {
      print("GYMPLY: timerbell.wav not found in main bundle")
      return
    }

    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playback,
        mode: .default,
        options: [.mixWithOthers, .duckOthers]
      )
      try session.setActive(true)

      player?.stop()
      let newPlayer = try AVAudioPlayer(contentsOf: url)
      newPlayer.delegate = self
      newPlayer.prepareToPlay()
      self.player = newPlayer
      newPlayer.play()
    } catch {
      print("GYMPLY: Failed to play timerbell: \(error)")
      deactivateSession()
    }
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    guard player === self.player else { return }
    self.player = nil
    deactivateSession()
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    guard player === self.player else { return }
    self.player = nil
    deactivateSession()
  }

  private func deactivateSession() {
    do {
      try AVAudioSession.sharedInstance().setActive(
        false,
        options: .notifyOthersOnDeactivation
      )
    } catch {
      print("GYMPLY: Failed to deactivate AVAudioSession: \(error)")
    }
  }
}
