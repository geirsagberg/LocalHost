import SwiftUI

@main
struct LocalHostMonitorApp: App {
    @StateObject private var viewModel = SitesViewModel()

    var body: some Scene {
        WindowGroup("LocalHost", id: "main") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 640, minHeight: 420)
        }
        .defaultSize(width: 760, height: 500)

        MenuBarExtra("LocalHost", systemImage: "network") {
            MenuBarContent(viewModel: viewModel)
        }
    }
}
