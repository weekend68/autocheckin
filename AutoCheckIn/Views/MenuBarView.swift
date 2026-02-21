import SwiftUI

struct MenuBarView: View {
    @StateObject var viewModel: WiFiMonitorViewModel

    var body: some View {
        VStack(spacing: 0) {
            MenuButton(
                icon: "paperplane.fill",
                title: "Check in to Slack",
                action: { viewModel.checkInToSlack() }
            )

            MenuButton(
                icon: "doc.text",
                title: "View log",
                action: { viewModel.openLogFile() }
            )

            MenuButton(
                icon: "gear",
                title: "Settings",
                action: { openSettings() }
            )

            Divider()
                .padding(.vertical, 0)

            MenuButton(
                icon: "xmark.circle",
                title: "Quit",
                action: { NSApplication.shared.terminate(nil) }
            )
            .foregroundColor(.red)
        }
        .frame(minWidth: 220, maxWidth: 260)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func openSettings() {
        let settingsView = SettingsView(viewModel: SettingsViewModel())
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "AutoCheckIn — Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating

        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Menu Button Component

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 20, alignment: .center)
                Text(title)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.primary.opacity(0.0))
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
