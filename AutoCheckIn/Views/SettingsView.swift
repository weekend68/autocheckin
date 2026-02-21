import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    private var buildInfo: String {
        if let execURL = Bundle.main.executableURL,
           let attrs = try? FileManager.default.attributesOfItem(atPath: execURL.path),
           let date = attrs[.modificationDate] as? Date {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm"
            return "Built \(f.string(from: date))"
        }
        return "v1.0"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // Slack Settings
                    GroupBox(label: Label("Slack", systemImage: "bubble.left.and.bubble.right")) {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("User Token")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                SecureField("xoxp-...", text: $viewModel.slackToken)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Channel")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    TextField("#general", text: $viewModel.slackChannel)
                                        .textFieldStyle(.roundedBorder)

                                    Button(action: { viewModel.testSlackConnection() }) {
                                        HStack(spacing: 4) {
                                            if viewModel.isTesting {
                                                ProgressView().scaleEffect(0.7)
                                            }
                                            Text("Test")
                                        }
                                    }
                                    .disabled(viewModel.isTesting)
                                }
                            }

                            if !viewModel.testResult.isEmpty {
                                Text(viewModel.testResult)
                                    .font(.caption)
                                    .foregroundColor(viewModel.testResult.contains("✅") ? .green : .red)
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxWidth: .infinity)

                    // WiFi Networks
                    GroupBox(label: Label("WiFi Networks", systemImage: "wifi")) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(viewModel.wifiEntries.enumerated()), id: \.element.id) { index, _ in
                                if index > 0 {
                                    Divider()
                                }
                                WiFiEntryRow(
                                    entry: $viewModel.wifiEntries[index],
                                    canDelete: viewModel.wifiEntries.count > 1,
                                    onDelete: { viewModel.removeWifiEntry(at: index) }
                                )
                            }

                            Button(action: { viewModel.addWifiEntry() }) {
                                Label("Add WiFi", systemImage: "plus.circle.fill")
                            }
                            .padding(.top, 6)
                        }
                        .padding(8)
                    }
                    .frame(maxWidth: .infinity)

                    // Weather Settings
                    GroupBox(label: Label("Weather", systemImage: "cloud.sun")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Append weather to message", isOn: $viewModel.weatherEnabled)

                            if viewModel.weatherEnabled {
                                Picker("Temperature unit", selection: $viewModel.temperatureUnit) {
                                    Text("Celsius (°C)").tag("celsius")
                                    Text("Fahrenheit (°F)").tag("fahrenheit")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }

            Divider()

            // Footer
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(buildInfo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()

                    Button("Clear auto check-in flag") {
                        viewModel.resetAutoCheckIns()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button("Cancel") {
                        dismiss()
                    }

                    Button("Save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
        }
        .frame(width: 520, height: 730)
    }
}

// MARK: - WiFi Entry Row

struct WiFiEntryRow: View {
    @Binding var entry: WiFiEntry
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Toggle("Auto check-in", isOn: $entry.isWork)
                    .font(.caption)

                Spacer()

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SSID")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Network name", text: $entry.ssid)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Message")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Check-in message", text: $entry.message)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
    }
}
