import ActivityKit
import SwiftUI
import WidgetKit

struct GymplyLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: GymplyTimerAttributes.self) { context in
      // Lock Screen and Notification Center Banner View
      VStack(alignment: .leading, spacing: 8) {
        // Row 1: TOTAL TIME (Always shown)
        HStack {
          Image("GymplyIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
              .foregroundColor(Color(red: 252/255, green: 176/255, blue: 117/255))
            Spacer()
            Text(timerInterval: Date.now...endTime, countsDown: true)
              .font(.system(size: 16, weight: .bold, design: .monospaced))
              .foregroundColor(.white)
          }
        }
      }
      .padding(16)
      .activityBackgroundTint(Color.black.opacity(0.92))
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded Dynamic Island (Full-Width Bottom Region)
        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            Image("GymplyIcon")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 20, height: 20)
              .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
          .padding(.horizontal, 16)
        }
      } compactLeading: {
        Image("GymplyIcon")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 16, height: 16)
          .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
      } compactTrailing: {
        Text(timerInterval: context.state.totalStartTime...Date.distantFuture, countsDown: false)
          .font(.system(size: 12, weight: .bold, design: .monospaced))
          .foregroundColor(.white)
          .frame(width: 44)
      } minimal: {
        Image("GymplyIcon")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 16, height: 16)
          .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
      }
    }
  }
}
