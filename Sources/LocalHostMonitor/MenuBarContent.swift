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
                Menu(viewModel.menuTitle(for: site)) {
                    Button {
                        viewModel.open(site)
                    } label: {
                        Label("Open", systemImage: "arrow.up.right.square")
                    }

                    Button {
                        viewModel.copyURL(site)
                    } label: {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button {
                        viewModel.killProcess(for: site)
                    } label: {
                        Label(
                            viewModel.isKilling(site) ? "Killing..." : "Kill Process",
                            systemImage: "stop.circle"
                        )
                    }
                    .disabled(viewModel.isKilling(site))
                }
            }
        }

        Divider()

        Button("Quit LocalHost") {
            NSApp.terminate(nil)
        }
    }
}
