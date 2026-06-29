import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var viewModel: SitesViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Window") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button(viewModel.isScanning ? "Refreshing..." : "Refresh") {
            Task { await viewModel.refresh() }
        }
        .disabled(viewModel.isScanning)

        Toggle("View all responses", isOn: $viewModel.showsAllResponses)
            .disabled(viewModel.sites.isEmpty)

        Divider()

        if viewModel.visibleSites.isEmpty {
            Text("No localhost sites")
        } else {
            ForEach(viewModel.visibleSites) { site in
                Button(viewModel.menuTitle(for: site)) {
                    viewModel.open(site)
                }
            }
        }

        Divider()

        Button("Quit LocalHost") {
            NSApp.terminate(nil)
        }
    }
}
