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
extension View {

    /// Adds an accessibility scroll action to the view. Actions allow
    /// assistive technologies, such as the VoiceOver, to interact with the
    /// view by invoking the action.
    ///
    /// For example, this is how a scroll action to trigger
    /// a refresh could be added to a view.
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             ContentView()
    ///         }
    ///         .accessibilityScrollAction { edge in
    ///             if edge == .top {
    ///                 // Refresh content
    ///             }
    ///         }
    ///     }
    ///
    public func accessibilityScrollAction(_ handler: @escaping (Edge) -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityAction(AccessibilityScrollAction(), handler)
    }
    
}

@available(iOS 13.0, *)
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {

    /// Adds an accessibility scroll action to the view. Actions allow
    /// assistive technologies, such as the VoiceOver, to interact with the
    /// view by invoking the action.
    ///
    /// For example, this is how a scroll action to trigger
    /// a refresh could be added to a view.
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             ContentView()
    ///         }
    ///         .accessibilityScrollAction { edge in
    ///             if edge == .top {
    ///                 // Refresh content
    ///             }
    ///         }
    ///     }
    ///
    public func accessibilityScrollAction(_ handler: @escaping (Edge) -> Void) -> ModifiedContent<Content, Modifier> {
        accessibilityAction(AccessibilityScrollAction(), handler)
    }
    
}

@available(iOS 13.0, *)
internal struct AccessibilityScrollAction: AccessibilityValueAction {
    
    internal typealias Value = Edge
    
}
