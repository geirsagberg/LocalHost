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

        Toggle("View all entries", isOn: $viewModel.showsAllResponses)
            .disabled(viewModel.sites.isEmpty)

        Divider()

        if viewModel.visibleSitePresentations.isEmpty {
            Text("No localhost sites")
        } else {
            ForEach(viewModel.visibleSitePresentations) { presentation in
                Menu(presentation.menuTitle) {
                    Button {
                        viewModel.open(presentation)
                    } label: {
                        Label("Open", systemImage: "arrow.up.right.square")
                    }

                    Button {
                        viewModel.copyURL(presentation)
                    } label: {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }

                    Toggle("Hide in Default View", isOn: hiddenBinding(for: presentation))

                    Divider()

                    Button {
                        viewModel.killProcess(for: presentation)
                    } label: {
                        Label(
                            viewModel.isKilling(presentation) ? "Killing..." : "Kill Process",
                            systemImage: "stop.circle"
                        )
                    }
                    .disabled(viewModel.isKilling(presentation))
                }
            }
        }

        Divider()

        Button("Quit LocalHost") {
            NSApp.terminate(nil)
        }
    }

    private func hiddenBinding(for presentation: SitePresentation) -> Binding<Bool> {
        Binding(
            get: { viewModel.isHidden(presentation) },
            set: { viewModel.setHidden($0, for: presentation) }
        )
    }
}
