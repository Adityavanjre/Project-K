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

@available(iOS 13.0, *)
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a `.default` action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction(_ actionKind: AccessibilityActionKind = .default, _ handler: @escaping () -> Void) -> ModifiedContent<Content, Modifier> {
        accessibilityAction(AccessibilityVoidAction(kind: actionKind), handler)
    }

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a custom action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction(named: Text("New Message")) {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction(named name: Text, _ handler: @escaping () -> Void) -> ModifiedContent<Content, Modifier> {
        accessibilityAction(AccessibilityVoidAction(kind: AccessibilityActionKind(named: name)), handler)
    }

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a custom action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction(named: "New Message") {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction(named nameKey: LocalizedStringKey, _ handler: @escaping () -> Void) -> ModifiedContent<Content, Modifier> {
        accessibilityAction(AccessibilityVoidAction(kind: AccessibilityActionKind(named: Text(nameKey))), handler)
    }

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a custom action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction(named: "New Message") {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction<S: StringProtocol>(named name: S, _ handler: @escaping () -> Void) -> ModifiedContent<Content, Modifier> {
        accessibilityAction(AccessibilityVoidAction(kind: AccessibilityActionKind(named: Text(name))), handler)
    }
    
}

@available(iOS 13.0, *)
extension View {

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a `.default` action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction(_ actionKind: AccessibilityActionKind = .default, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityAction(AccessibilityVoidAction(kind: actionKind), handler)
    }

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a custom action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction(named: Text("New Message")) {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction(named name: Text, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityAction(AccessibilityVoidAction(kind: AccessibilityActionKind(named: name)), handler)
    }

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a custom action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction(named: "New Message") {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction(named nameKey: LocalizedStringKey, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityAction(AccessibilityVoidAction(kind: AccessibilityActionKind(named: Text(nameKey))), handler)
    }

    /// Adds an accessibility action to the view. Actions allow assistive technologies,
    /// such as the VoiceOver, to interact with the view by invoking the action.
    ///
    /// For example, this is how a custom action to compose
    /// a new email could be added to a view.
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .accessibilityAction(named: "New Message") {
    ///                 // Handle action
    ///             }
    ///     }
    ///
    public func accessibilityAction<S>(named name: S, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol {
        accessibilityAction(AccessibilityVoidAction(kind: AccessibilityActionKind(named: Text(name))), handler)
    }
    
}
