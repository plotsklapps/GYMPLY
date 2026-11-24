import ActivityKit
import SwiftUI
import WidgetKit

struct GymplyLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: GymplyTimerAttributes.self) { context in
      // Lock Screen and Notification Center Banner View
      VStack(alignment: .leading, spacing: 8) {
        // Row 1: TOP (Icon + GYMPLY + Total Timer)
        HStack(alignment: .center) {
          // 1. Icoon & GYMPLY (links geclusterd)
          HStack(spacing: 8) {
            Image("GymplyIcon")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 22, height: 22)
              .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            Text("GYMPLY.")
              .font(.system(size: 16, weight: .black))
              .foregroundColor(.white)
          }

          Spacer()

          // 2. Timer (Strak Rechts uitgelijnd)
          Text(timerInterval: context.state.totalStartTime...Date.distantFuture, countsDown: false)
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .multilineTextAlignment(.trailing)
        }

        // Row 2: BOTTOM (Exercise Name & Active Timers)
        VStack(spacing: 4) {
          if let exerciseName = context.state.exerciseName, !exerciseName.isEmpty {
            Text(exerciseName)
              .font(.system(size: 16, weight: .black))
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
          }

          if let endTime = context.state.segmentEndTime, !context.state.segmentLabel.isEmpty {
            HStack(spacing: 6) {
              Text(context.state.segmentLabel)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 252/255, green: 176/255, blue: 117/255))

              Text(timerInterval: Date.now...endTime, countsDown: true)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
      }
      .padding(16)
      .activityBackgroundTint(Color.black.opacity(0.92))
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded Dynamic Island
        DynamicIslandExpandedRegion(.leading) {
          Image("GymplyIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 22, height: 22)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .padding(.leading, 8)
        }
        DynamicIslandExpandedRegion(.trailing) {
            Text(timerInterval: context.state.totalStartTime...Date.distantFuture, countsDown: false)
              .font(.system(size: 16, weight: .bold, design: .monospaced))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity, alignment: .trailing)
              .padding(.trailing, 8)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 4) {
            if let exerciseName = context.state.exerciseName, !exerciseName.isEmpty {
              Text(exerciseName)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            }
            Text("GYMPLY. Tap to open app.")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.gray)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
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
