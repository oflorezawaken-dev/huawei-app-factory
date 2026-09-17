import SwiftUI
import UIKit

/// A "Done" button above the keyboard.
///
/// `decimalPad` has no return key, so on every solver screen the keyboard
/// stayed up and covered the results the user had just asked for, with no way
/// to dismiss it except leaving the screen.
///
/// The button resigns first responder application-wide rather than through a
/// `@FocusState` on the form: a focus state declared here is not the one the
/// individual `TextField`s are bound to, so clearing it leaves the keyboard
/// exactly where it was -- which is what the first version of this did, and
/// the screenshot walk caught it by asserting the keyboard was gone.
struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                         to: nil, from: nil, for: nil)
                    }
                    .accessibilityIdentifier("keyboard.done")
                }
            }
    }
}

extension View {
    func keyboardDoneToolbar() -> some View { modifier(KeyboardDoneToolbar()) }
}
