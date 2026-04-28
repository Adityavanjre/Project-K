// Copyright (c) 2025 ByteDance Ltd. and/or its affiliates
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// A control into which the user securely enters private text.
///
/// Use a `SecureField` when you want behavior similar to a ``TextField``, but
/// you don't want the user's text to be visible. Typically, you use this for
/// entering passwords and other sensitive information.
///
/// A `SecureField` uses a binding to a string value, and a closure that
/// executes when the user commits their edits, such as by pressing the
/// Return key. The field updates the bound string on every keystroke or
/// other edit, so you can read its value at any time from another control,
/// such as a Done button.
///
/// The following example shows a `SecureField` bound to the string `password`.
/// If the user commits their edit in the secure field, the `onCommit` closure
/// sends the password string to a `handleLogin()` method.
///
///     @State private var username: String = ""
///     @State private var password: String = ""
///
///     var body: some View {
///         TextField(
///             "User name (email address)",
///             text: $username)
///             .autocapitalization(.none)
///             .disableAutocorrection(true)
///             .border(Color(UIColor.separator))
///         SecureField(
///             "Password",
///             text: $password
///         ) {
///             handleLogin(username: username, password: password)
///         }
///         .border(Color(UIColor.separator))
///     }
///
///
/// ### SecureField prompts
///
/// A secure field may be provided an explicit prompt to guide users on what
/// text they should provide. The context in which a secure field appears
/// determines where and when a prompt and label may be used. For example, a
/// form on macOS will always place the label alongside the leading edge of
/// the field and will use a prompt, when available, as placeholder text within
/// the field itself. In the same context on iOS, the prompt or label will
/// be used as placeholder text depending on whether a prompt is provided.
///
///     Form {
///         TextField(text: $username, prompt: Text("Required")) {
///             Text("Username")
///         }
///         SecureField(text: $username, prompt: Text("Required")) {
///             Text("Password")
///        }
///     }
///
@available(iOS 13.0, *)
public struct SecureField<Label>: View where Label: View {
    
    internal var text: Binding<String>

    internal var onCommit: () -> Void

    internal var label: Label

    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that DanceUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    public var body: some View {
        TextField(self.text, isSecure: true, onEditingChanged: { _ in }, onCommit: self.onCommit, label: { self.label })
    }

}

@available(iOS 13.0, *)
extension SecureField where Label == Text {


    // TODO: not implemented: internal init<S: StringProtocol>(_ title: S, text: Binding<String>, prompt: Text?)
    //
    // The implementation of SecureField depends on TextField. TextField is not currently
    // adapted to iOS15. This function depends on the implementation of TextField in iOS15,
    // so it cannot be implemented currently.
    //
}

@available(iOS 13.0, *)
extension SecureField {


    // TODO: not implemented: internal init(_ text: Binding<String>, prompt: Text?, onCommit: (() -> ())?, @ViewBuilder label: () -> Label)
    //
    // The implementation of SecureField depends on TextField. TextField is not currently
    // adapted to iOS15. This function depends on the implementation of TextField in iOS15,
    // so it cannot be implemented currently.
    //
        
}

@available(iOS 13.0, *)
extension SecureField where Label == Text {

    /// Creates a secure field with a prompt generated from a `Text`.
    ///
    /// Use the ``View/onSubmit(of:_:)`` modifier to invoke an action
    /// whenever the user submits this secure field.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of `self`, describing
    ///     its purpose.
    ///   - text: The text to display and edit
    ///   - prompt: A `Text` representing the prompt of the secure field
    ///     which provides users with guidance on what to type into the secure
    ///     field.
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>) {
        self.text = text
        self.label = Text(titleKey)
        self.onCommit = {  }
    }

    /// Creates a secure field with a prompt generated from a `Text`.
    ///
    /// Use the ``View/onSubmit(of:_:)`` modifier to invoke an action
    /// whenever the user submits this secure field.
    ///
    /// - Parameters:
    ///   - title: The title of `self`, describing its purpose.
    ///   - text: The text to display and edit.
    ///   - prompt: A `Text` representing the prompt of the secure field
    ///     which provides users with guidance on what to type into the secure
    ///     field.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, text: Binding<String>) {
        self.text = text
        self.label = Text(title)
        self.onCommit = {  }
    }
}

@available(iOS 13.0, *)
extension SecureField where Label == Text {

    /// Creates an instance.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of `self`, describing
    ///     its purpose.
    ///   - text: The text to display and edit.
    ///   - onCommit: The action to perform when the user performs an action
    ///     (usually pressing the Return key) while the secure field has focus.
    public init(_ titleKey: LocalizedStringKey, text: Binding<String>, onCommit: @escaping () -> Void) {
        self.text = text
        self.label = Text(titleKey)
        self.onCommit = onCommit
    }

    /// Creates an instance.
    ///
    /// - Parameters:
    ///   - title: The title of `self`, describing its purpose.
    ///   - text: The text to display and edit.
    ///   - onCommit: The action to perform when the user performs an action
    ///     (usually pressing the Return key) while the secure field has focus.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, text: Binding<String>, onCommit: @escaping () -> Void) {
        self.text = text
        self.label = Text(title)
        self.onCommit = onCommit
    }
}
