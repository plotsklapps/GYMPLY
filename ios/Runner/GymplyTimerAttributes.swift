import ActivityKit
import Foundation

public struct GymplyTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    public var totalStartTime: Date
    public var segmentLabel: String
    public var segmentDetail: String?
    public var segmentStartTime: Date?
    public var segmentEndTime: Date?
    public var exerciseName: String?

    public init(
      totalStartTime: Date,
      segmentLabel: String,
      segmentDetail: String? = nil,
      segmentStartTime: Date? = nil,
      segmentEndTime: Date? = nil,
      exerciseName: String? = nil
    ) {
      self.totalStartTime = totalStartTime
      self.segmentLabel = segmentLabel
      self.segmentDetail = segmentDetail
      self.segmentStartTime = segmentStartTime
      self.segmentEndTime = segmentEndTime
      self.exerciseName = exerciseName
    }
  }

  public var workoutName: String

  public init(workoutName: String = "GYMPLY") {
    self.workoutName = workoutName
  }
}
