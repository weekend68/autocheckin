import SwiftUI

@main
struct WiFiMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = WiFiMonitorViewModel()

    var body: some Scene {
        MenuBarExtra("", systemImage: viewModel.locationPermissionDenied ? "exclamationmark.triangle.fill" : "person.wave.2") {
            MenuBarView(viewModel: viewModel)
        }
    }
}
