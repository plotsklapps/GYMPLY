import ActivityKit
import Foundation

public struct GymplyTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    public var totalStartTime: Date
    public var segmentLabel: String
    public var segmentEndTime: Date?

    public init(
      totalStartTime: Date,
      segmentLabel: String,
      segmentEndTime: Date? = nil
    ) {
      self.totalStartTime = totalStartTime
      self.segmentLabel = segmentLabel
      self.segmentEndTime = segmentEndTime
    }
  }

  public var workoutName: String

  public init(workoutName: String = "GYMPLY") {
    self.workoutName = workoutName
  }
}
