import ActivityKit
import Foundation

public struct GymplyTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    public var totalStartTime: Date
    public var segmentLabel: String
    public var segmentEndTime: Date?
    public var exerciseName: String?

    public init(
      totalStartTime: Date,
      segmentLabel: String,
      segmentEndTime: Date? = nil,
      exerciseName: String? = nil
    ) {
      self.totalStartTime = totalStartTime
      self.segmentLabel = segmentLabel
      self.segmentEndTime = segmentEndTime
      self.exerciseName = exerciseName
    }
  }

  public var workoutName: String

  public init(workoutName: String = "GYMPLY") {
    self.workoutName = workoutName
  }
}
