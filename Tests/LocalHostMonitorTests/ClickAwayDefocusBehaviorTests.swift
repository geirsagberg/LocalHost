import AppKit
import XCTest
@testable import LocalHostMonitor

final class ClickAwayDefocusBehaviorTests: XCTestCase {
    func testPlainViewClickShouldDefocusTextFields() {
        XCTAssertTrue(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenClicking: NSView()
            )
        )
    }

    func testMissingHitViewShouldDefocusTextFields() {
        XCTAssertTrue(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenClicking: nil
            )
        )
    }

    func testTextInputClickDoesNotDefocusTextFields() {
        XCTAssertFalse(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenClicking: NSTextField()
            )
        )
    }

    func testControlClickDoesNotDefocusTextFields() {
        XCTAssertFalse(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenClicking: NSButton()
            )
        )
    }

    func testSubviewOfControlDoesNotDefocusTextFields() {
        let button = NSButton()
        let label = NSView()
        button.addSubview(label)

        XCTAssertFalse(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenClicking: label
            )
        )
    }

    func testEscapeKeyShouldDefocusActiveTextEditor() {
        XCTAssertTrue(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenPressingKeyCode: 53,
                firstResponder: NSTextView()
            )
        )
    }

    func testEscapeKeyShouldDefocusActiveTextField() {
        XCTAssertTrue(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenPressingKeyCode: 53,
                firstResponder: NSTextField()
            )
        )
    }

    func testEscapeKeyDoesNotDefocusWhenControlOwnsFocus() {
        XCTAssertFalse(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenPressingKeyCode: 53,
                firstResponder: NSButton()
            )
        )
    }

    func testNonEscapeKeyDoesNotDefocusActiveTextEditor() {
        XCTAssertFalse(
            ClickAwayDefocusBehavior.shouldDefocusTextFields(
                whenPressingKeyCode: 36,
                firstResponder: NSTextView()
            )
        )
    }
}
