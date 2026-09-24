import ActivityKit
import SwiftUI
import WidgetKit

public struct GymplyTimerLiveActivity: Widget {
  public init() {}

  public var body: some WidgetConfiguration {
    ActivityConfiguration(for: GymplyTimerAttributes.self) { context in
      // Lock Screen and Notification Center Banner View
      VStack(alignment: .leading, spacing: 8) {
        // Row 1: TOTAL TIME (Always shown)
        HStack {
          Image(systemName: "figure.strengthtraining.traditional")
            .foregroundColor(.yellow)
          Text("GYMPLY.")
            .font(.system(size: 13, weight: .black))
            .foregroundColor(.white)
          Spacer()
          Text("TOTAL TIME:")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.gray)
          Text(timerInterval: context.state.totalStartTime...Date.distantFuture, countsDown: false)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
        }

        // Row 2: Active Segment (REST or INTERVAL or STOPWATCH)
        if let endTime = context.state.segmentEndTime, !context.state.segmentLabel.isEmpty {
          Divider().background(Color.white.opacity(0.2))
          HStack {
            Text(context.state.segmentLabel)
              .font(.system(size: 16, weight: .heavy))
              .foregroundColor(context.state.segmentLabel == "REST" ? .green : .orange)
            Spacer()
            Text(timerInterval: Date.now...endTime, countsDown: true)
              .font(.system(size: 22, weight: .black, design: .monospaced))
              .foregroundColor(context.state.segmentLabel == "REST" ? .green : .orange)
          }
        }
      }
      .padding(16)
      .activityBackgroundTint(Color.black.opacity(0.92))
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded Dynamic Island
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 2) {
            Text("TOTAL TIME")
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(.gray)
            Text(timerInterval: context.state.totalStartTime...Date.distantFuture, countsDown: false)
              .font(.system(size: 14, weight: .bold, design: .monospaced))
              .foregroundColor(.white)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          if let endTime = context.state.segmentEndTime, !context.state.segmentLabel.isEmpty {
            VStack(alignment: .trailing, spacing: 2) {
              Text(context.state.segmentLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(context.state.segmentLabel == "REST" ? .green : .orange)
              Text(timerInterval: Date.now...endTime, countsDown: true)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(context.state.segmentLabel == "REST" ? .green : .orange)
            }
          }
        }
      } compactLeading: {
        Image(systemName: "figure.strengthtraining.traditional")
          .foregroundColor(.yellow)
      } compactTrailing: {
        if let endTime = context.state.segmentEndTime, !context.state.segmentLabel.isEmpty {
          Text(timerInterval: Date.now...endTime, countsDown: true)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(context.state.segmentLabel == "REST" ? .green : .orange)
            .frame(width: 44)
        } else {
          Text(timerInterval: context.state.totalStartTime...Date.distantFuture, countsDown: false)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .frame(width: 44)
        }
      } minimal: {
        Image(systemName: "figure.strengthtraining.traditional")
          .foregroundColor(.yellow)
      }
    }
  }
}
