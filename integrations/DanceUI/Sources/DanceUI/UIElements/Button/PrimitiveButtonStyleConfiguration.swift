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

/// The properties of a button.
@available(iOS 13.0, *)
public struct PrimitiveButtonStyleConfiguration {
    /// A type-erased label of a button.
    public struct Label : ViewAlias {
        /// The type of view representing the body of this view.
        ///
        /// When you create a custom view, Swift infers this type from your
        /// implementation of the required ``View/body-swift.property`` property.
        public typealias Body = Never
    }

    /// An optional semantic role describing the button's purpose.
    ///
    /// A value of `nil` means that the Button has no assigned role. If the
    /// button does have a role, use it to make adjustments to the button's
    /// appearance. The following example shows a custom style that uses
    /// bold text when the role is ``ButtonRole/cancel``,
    /// ``ShapeStyle/red`` text when the role is ``ButtonRole/destructive``,
    /// and adds no special styling otherwise:
    ///
    ///     struct MyButtonStyle: PrimitiveButtonStyle {
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             configuration.label
    ///                 .onTapGesture {
    ///                     configuration.trigger()
    ///                 }
    ///                 .font(
    ///                     configuration.role == .cancel ? .title2.bold() : .title2)
    ///                 .foregroundColor(
    ///                     configuration.role == .destructive ? Color.red : nil)
    ///         }
    ///     }
    ///
    /// You can create one of each button using this style to see the effect:
    ///
    ///     VStack(spacing: 20) {
    ///         Button("Cancel", role: .cancel) {}
    ///         Button("Delete", role: .destructive) {}
    ///         Button("Continue") {}
    ///     }
    ///     .buttonStyle(MyButtonStyle())
    ///
    public let role: ButtonRole?

    /// A view that describes the effect of calling the button's action.
    public let label: Label

    /// Performs the button's action.
    public func trigger() {
        action()
    }

    @inline(__always)
    internal let action: () -> Void
    
    // DanceUI addition
    public let name: String?

    @inline(__always)
    internal init(role: ButtonRole?, action: @escaping () -> Void, name: String?) {
        self.label = Label()
        self.action = action
        self.role = role
        self.name = name
    }
}
