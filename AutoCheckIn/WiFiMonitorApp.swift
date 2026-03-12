import SwiftUI

@main
struct WiFiMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = WiFiMonitorViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Image(systemName: viewModel.locationPermissionDenied ? "exclamationmark.triangle.fill" : "person.wave.2")
        }
    }
}
