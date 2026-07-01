import AppKit
import SwiftUI
import LocalHostMonitorCore

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

        Toggle("Show hidden sites", isOn: $viewModel.includesHiddenSites)
            .disabled(viewModel.sites.isEmpty)

        Toggle("Show non-OK sites", isOn: $viewModel.includesNonOKSites)
            .disabled(viewModel.sites.isEmpty)

        Divider()

        if viewModel.visibleSitePresentations.isEmpty {
            Text(viewModel.emptyStateTitle)
        } else {
            ForEach(viewModel.visibleSitePresentations) { presentation in
                Button {
                    viewModel.open(presentation)
                } label: {
                    Text(presentation.menuTitle)
                }
            }
        }

        Divider()

        Button("Quit LocalHost") {
            NSApp.terminate(nil)
        }
    }

}
