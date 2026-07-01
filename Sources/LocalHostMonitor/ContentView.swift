import AppKit
import SwiftUI
import LocalHostMonitorCore

struct ContentView: View {
    @ObservedObject var viewModel: SitesViewModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(viewModel: viewModel)
            Divider()

            if viewModel.visibleSitePresentations.isEmpty {
                EmptyStateView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.visibleSitePresentations) { presentation in
                            SiteRow(presentation: presentation, viewModel: viewModel)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .defocusesTextFieldsOnClickAway()
        .alert(item: $viewModel.alertMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("OK"))
            )
        }
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

            Toggle("Show hidden", isOn: $viewModel.includesHiddenSites)
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(viewModel.sites.isEmpty)
                .help("Show explicitly hidden localhost sites")

            Toggle("Show non-OK", isOn: $viewModel.includesNonOKSites)
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(viewModel.sites.isEmpty)
                .help("Show localhost sites that return non-OK HTTP status")

            if let lastScanDate = viewModel.lastScanDate {
                Text("Updated \(Self.timeFormatter.string(from: lastScanDate))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 18, height: 18)
                }
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
            if isLoadingInitialSites {
                ProgressView()
                    .controlSize(.large)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            if let message = viewModel.emptyStateMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isLoadingInitialSites {
                HStack(spacing: 8) {
                    ForEach(viewModel.emptyStateRecoveryActions) { action in
                        Button(action.title) {
                            recover(from: action)
                        }
                        .buttonStyle(.bordered)
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
            }
        }
        .padding(32)
    }

    private var title: String {
        viewModel.emptyStateTitle
    }

    private var isLoadingInitialSites: Bool {
        viewModel.isLoadingInitialSites
    }

    private func recover(from action: DefaultViewRecoveryAction) {
        switch action {
        case .showHidden:
            viewModel.includesHiddenSites = true
        case .showNonOK:
            viewModel.includesNonOKSites = true
        }
    }
}

private struct SiteRow: View {
    let presentation: SitePresentation
    @ObservedObject var viewModel: SitesViewModel

    var body: some View {
        HStack(spacing: 10) {
            EmojiPickerButton(text: emojiBinding)
                .frame(width: 34, height: 34)
                .fixedSize()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    TextField("Title", text: titleBinding)
                        .font(.system(size: 14, weight: .semibold))
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.resetTitleOverride(for: presentation)
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.borderless)
                    .help("Use inferred title")
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Link(destination: presentation.site.url) {
                        Text(presentation.urlText)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .foregroundStyle(Color(nsColor: .linkColor))
                    .help("Open \(presentation.urlText)")
                    .layoutPriority(1)

                    Button {
                        viewModel.copyURL(presentation)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.borderless)
                    .help("Copy URL")

                    MetadataBadge(text: presentation.statusText)

                    if presentation.isHidden {
                        MetadataBadge(text: "Hidden")
                    }

                    if let processName = presentation.processName {
                        MetadataBadge(text: processName)
                    }

                    if let pidText = presentation.pidText {
                        MetadataBadge(text: pidText)
                    }
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    viewModel.open(presentation)
                } label: {
                    Label("Open Website", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .help("Open \(presentation.urlText)")

                HStack(spacing: 4) {
                    Toggle("Hide", isOn: hiddenBinding)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .fixedSize()
                        .help("Show when Show hidden is enabled")

                    if viewModel.isKilling(presentation) {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 96, height: 24)
                            .help("Killing process")
                    } else {
                        Button {
                            viewModel.killProcess(for: presentation)
                        } label: {
                            Label("Kill Process", systemImage: "stop.circle")
                                .frame(width: 96)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundStyle(.red)
                        .help("Kill process")
                    }
                }
            }
            .frame(width: 206, alignment: .trailing)
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
            get: { viewModel.title(for: presentation) },
            set: { viewModel.setTitleOverride(for: presentation, title: $0) }
        )
    }

    private var emojiBinding: Binding<String> {
        Binding(
            get: { viewModel.emojiFieldText(for: presentation) },
            set: { viewModel.setEmojiFieldText(for: presentation, value: $0) }
        )
    }

    private var hiddenBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isHidden(presentation) },
            set: { viewModel.setHidden($0, for: presentation) }
        )
    }

}

private struct MetadataBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.22))
            )
            .fixedSize(horizontal: true, vertical: false)
    }
}

private struct EmojiPickerButton: View {
    @Binding var text: String
    @State private var isShowingPicker = false

    var body: some View {
        Button {
            isShowingPicker = true
        } label: {
            Text(text.isEmpty ? "😀" : text)
                .font(.system(size: 20))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(EmojiSquareButtonStyle())
        .fixedSize()
        .help("Choose emoji")
        .popover(isPresented: $isShowingPicker, arrowEdge: .leading) {
            EmojiPickerPopover(
                selectedEmoji: $text,
                isShowingPicker: $isShowingPicker
            )
        }
    }
}

private struct EmojiSquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        configuration.isPressed
                            ? Color.accentColor.opacity(0.24)
                            : Color(nsColor: .controlBackgroundColor)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
            )
    }
}

private struct EmojiPickerPopover: View {
    @Binding var selectedEmoji: String
    @Binding var isShowingPicker: Bool

    private let columns = Array(repeating: GridItem(.fixed(30), spacing: 4), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Self.choices, id: \.self) { emoji in
                Button {
                    selectedEmoji = emoji
                    isShowingPicker = false
                } label: {
                    Text(emoji)
                        .font(.system(size: 18))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            emoji == selectedEmoji
                                ? Color.accentColor.opacity(0.22)
                                : Color.clear
                        )
                )
                .help(emoji)
            }
        }
        .padding(8)
    }

    private static let choices = [
        "😀", "😎", "🤓", "🥳", "🤖", "👀", "🧠", "💡",
        "🌐", "🚀", "🧭", "🧪", "🛠️", "✨", "⚡️", "📡",
        "🪄", "🔭", "🧩", "🗺️", "📍", "💻", "🖥️", "🧱",
        "🎛️", "📦", "🔌", "🧰", "🏗️", "🕹️", "🧵", "📊",
        "🟢", "🔵", "🟣", "🟠", "⭐️", "🔥", "💎", "🍋",
        "✅", "🚧", "🧯", "🔒", "🧲", "🎯", "🏷️", "📌"
    ]
}

private struct ClickAwayDefocusModifier: ViewModifier {
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard monitor == nil else {
                    return
                }

                monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
                    clearTextFocusIfNeeded(for: event)
                    return event
                }
            }
            .onDisappear {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                }
                monitor = nil
            }
    }

    private func clearTextFocusIfNeeded(for event: NSEvent) {
        guard let window = event.window,
              let contentView = window.contentView else {
            return
        }

        let location = contentView.convert(event.locationInWindow, from: nil)
        if contentView.hitTest(location)?.isTextInputView == true {
            return
        }

        if window.firstResponder is NSTextView || window.firstResponder is NSTextField {
            window.makeFirstResponder(nil)
        }
    }
}

private extension View {
    func defocusesTextFieldsOnClickAway() -> some View {
        modifier(ClickAwayDefocusModifier())
    }
}

private extension NSView {
    var isTextInputView: Bool {
        var view: NSView? = self

        while let currentView = view {
            if currentView is NSTextField || currentView is NSTextView {
                return true
            }

            view = currentView.superview
        }

        return false
    }
}
