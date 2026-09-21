import SwiftUI

struct FireSensorView: View {
    @ObservedObject var viewModel: FireSensorViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                fireVisual
                statusGrid
                controls
                eventLog
            }
            .padding()
            .background(Color(white: 0.94))
            .navigationTitle("Linger V0 Harness")
        }
    }

    private var fireVisual: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(fireColor.opacity(0.20))
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(fireColor, lineWidth: 4)
                    .frame(width: 140, height: 140)

                Text(fireEmoji)
                    .font(.system(size: 44))
            }

            Text(viewModel.fireState.rawValue.capitalized)
                .font(.title3.weight(.semibold))
                .foregroundColor(fireColor)

            if viewModel.fireState == .warning {
                Text("Grace: \(viewModel.graceRemaining)s")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statusGrid: some View {
        VStack(spacing: 10) {
            metricRow("Session", viewModel.isSessionRunning ? "Running" : "Stopped")
            metricRow("Lifecycle", viewModel.appLifecycle)
            metricRow("Orientation", viewModel.orientation.rawValue)
            metricRow("Motion magnitude", String(format: "%.3f", viewModel.motionMagnitude))
            metricRow("Moving", viewModel.isDeviceMoving ? "Yes" : "No")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var controls: some View {
        Button(action: viewModel.toggleSession) {
            Text(viewModel.isSessionRunning ? "Stop Session" : "Start Session")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isSessionRunning ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Events")
                .font(.headline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.events) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Text(timeFormatter.string(from: event.timestamp))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                                .frame(width: 85, alignment: .leading)

                            Text(event.message)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 240)
            .padding(8)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundColor(.primary)
        }
    }

    private var fireColor: Color {
        switch viewModel.fireState {
        case .burning: return .orange
        case .warning: return .yellow
        case .extinguished: return .gray
        }
    }

    private var fireEmoji: String {
        switch viewModel.fireState {
        case .burning: return "🔥"
        case .warning: return "⚠️"
        case .extinguished: return "💨"
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }
}
