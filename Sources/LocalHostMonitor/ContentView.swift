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

            Toggle("View all", isOn: $viewModel.showsAllResponses)
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(viewModel.sites.isEmpty)
                .help("Show hidden sites and localhost sites that return any HTTP status")

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
            return "No visible localhost sites"
        }

        return "No localhost sites"
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
                        .help("Show only when View all is enabled")

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

    var body: some View {
        EmojiPickerRepresentable(text: $text)
            .frame(width: 34, height: 34)
            .fixedSize()
            .help("Choose emoji")
    }
}

private struct EmojiPickerRepresentable: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> EmojiPickerNSView {
        let view = EmojiPickerNSView()
        view.onInsertText = { insertedText in
            text = insertedText
        }

        return view
    }

    func updateNSView(_ view: EmojiPickerNSView, context: Context) {
        view.emoji = text.isEmpty ? "😀" : text
        view.onInsertText = { insertedText in
            text = insertedText
        }
    }
}

private final class EmojiPickerNSView: NSView {
    var onInsertText: ((String) -> Void)?

    var emoji: String {
        get { button.title }
        set { button.title = newValue }
    }

    private let button = NSButton()
    private let textReceiver = EmojiTextReceiver()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 34, height: 34)
    }

    override func layout() {
        super.layout()
        button.frame = bounds
        textReceiver.frame = NSRect(x: -10, y: -10, width: 1, height: 1)
    }

    private func setupViews() {
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 20)
        button.target = self
        button.action = #selector(showCharacterPalette)
        button.toolTip = "Choose emoji"
        button.setAccessibilityLabel("Choose emoji")
        addSubview(button)

        textReceiver.isRichText = false
        textReceiver.isEditable = true
        textReceiver.isSelectable = true
        textReceiver.drawsBackground = false
        textReceiver.alphaValue = 0.01
        textReceiver.onInsertText = { [weak self] insertedText in
            self?.onInsertText?(insertedText)
        }
        addSubview(textReceiver)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @objc private func showCharacterPalette() {
        textReceiver.string = ""
        window?.makeFirstResponder(textReceiver)
        NSApplication.shared.orderFrontCharacterPalette(self)
    }
}

private final class EmojiTextReceiver: NSTextView {
    var onInsertText: ((String) -> Void)?

    override var intrinsicContentSize: NSSize {
        NSSize(width: 34, height: 34)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        handleInsertedText(insertString)
        super.insertText(insertString, replacementRange: replacementRange)
    }

    private func handleInsertedText(_ insertedText: Any) {
        if let attributedString = insertedText as? NSAttributedString {
            onInsertText?(attributedString.string)
        } else if let string = insertedText as? String {
            onInsertText?(string)
        }
    }
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
