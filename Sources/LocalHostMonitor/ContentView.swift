import SwiftUI
import LocalHostMonitorCore

struct ContentView: View {
    @ObservedObject var viewModel: SitesViewModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(viewModel: viewModel)
            Divider()

            if viewModel.visibleSites.isEmpty {
                EmptyStateView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.visibleSites) { site in
                            SiteRow(site: site, viewModel: viewModel)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct HeaderView: View {
    @ObservedObject var viewModel: SitesViewModel

    var body: some View {
        HStack(spacing: 12) {
            Text("LocalHost")
                .font(.system(size: 22, weight: .semibold))

            Text(viewModel.siteCountText)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 34)

            Spacer()

            Toggle("View all", isOn: $viewModel.showsAllResponses)
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(viewModel.sites.isEmpty)
                .help("Show localhost sites that return any HTTP status")

            if viewModel.isScanning {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 24, height: 24)
            }

            if let lastScanDate = viewModel.lastScanDate {
                Text(Self.timeFormatter.string(from: lastScanDate))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isScanning)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

private struct EmptyStateView: View {
    @ObservedObject var viewModel: SitesViewModel

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isScanning)
            .help("Refresh")
        }
        .padding(32)
    }

    private var title: String {
        if !viewModel.sites.isEmpty && !viewModel.showsAllResponses {
            return "No 200 OK localhost sites"
        }

        return "No localhost sites"
    }
}

private struct SiteRow: View {
    let site: LocalhostSite
    @ObservedObject var viewModel: SitesViewModel

    var body: some View {
        HStack(spacing: 10) {
            TextField("", text: emojiBinding)
                .font(.system(size: 20))
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(width: 44)
                .help("Emoji")

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    TextField("Title", text: titleBinding)
                        .font(.system(size: 14, weight: .semibold))
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.resetTitleOverride(for: site)
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.borderless)
                    .help("Use inferred title")
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Button {
                    viewModel.clearEmoji(for: site)
                } label: {
                    Image(systemName: "circle.slash")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .help("Clear emoji")

                Button {
                    viewModel.resetEmoji(for: site)
                } label: {
                    Image(systemName: "sparkles")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .help("Automatic emoji")

                Button {
                    viewModel.copyURL(site)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .help("Copy URL")

                Button {
                    viewModel.open(site)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.borderless)
                .help("Open")
            }
            .frame(width: 112, alignment: .trailing)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
        )
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { viewModel.title(for: site) },
            set: { viewModel.setTitleOverride(for: site, title: $0) }
        )
    }

    private var emojiBinding: Binding<String> {
        Binding(
            get: { viewModel.emojiFieldText(for: site) },
            set: { viewModel.setEmojiFieldText(for: site, value: $0) }
        )
    }

    private var subtitle: String {
        var parts = [site.displayURLString, "HTTP \(site.httpStatusCode)"]
        if let processName = site.processName, !processName.isEmpty {
            parts.append(processName)
        }
        if let pid = site.pid {
            parts.append("PID \(pid)")
        }

        return parts.joined(separator: "  ")
    }
}
