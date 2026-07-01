import AppKit

enum ClickAwayDefocusBehavior {
    private static let escapeKeyCode: UInt16 = 53

    static func shouldDefocusTextFields(whenClicking hitView: NSView?) -> Bool {
        guard let hitView else {
            return true
        }

        return !hitView.isTextInputOrControl
    }

    static func shouldDefocusTextFields(whenPressing event: NSEvent, in window: NSWindow) -> Bool {
        shouldDefocusTextFields(
            whenPressingKeyCode: event.keyCode,
            firstResponder: window.firstResponder
        )
    }

    static func shouldDefocusTextFields(
        whenPressingKeyCode keyCode: UInt16,
        firstResponder: NSResponder?
    ) -> Bool {
        keyCode == escapeKeyCode && firstResponder?.isTextEditingResponder == true
    }

    static func defocusTextFields(in window: NSWindow) {
        window.endEditing(for: nil)
        window.makeFirstResponder(nil)
    }
}

private extension NSView {
    var isTextInputOrControl: Bool {
        var view: NSView? = self

        while let currentView = view {
            if currentView is NSTextField
                || currentView is NSTextView
                || currentView is NSControl {
                return true
            }

            view = currentView.superview
        }

        return false
    }
}

private extension NSResponder {
    var isTextEditingResponder: Bool {
        self is NSTextField || self is NSTextView
    }
}
