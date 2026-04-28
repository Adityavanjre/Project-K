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

/// A button style that doesn't style or decorate its content while idle, but
/// may apply a visual effect to indicate the pressed, focused, or enabled state
/// of the button.
///
/// You can also use ``PrimitiveButtonStyle/plain`` to construct this style.
@available(iOS 13.0, *)
public struct PlainButtonStyle: PrimitiveButtonStyle {
    /// Creates a plain button style.
    public init() {}
    
    /// Creates a view that represents the body of a button.
    ///
    /// The system calls this method for each ``Button`` instance in a view
    /// hierarchy where this style is the current button style.
    ///
    /// - Parameter configuration : The properties of the button.
    public func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(buttonStyleRepresentation)
    }
}


@available(iOS 13.0, *)
extension PlainButtonStyle: ButtonStyleConvertible {
    internal var buttonStyleRepresentation: some ButtonStyle { PlainButtonStyleBase() }
}

@available(iOS 13.0, *)
extension PrimitiveButtonStyle where Self == PlainButtonStyle {
    /// A button style that doesn't style or decorate its content while idle,
    /// but may apply a visual effect to indicate the pressed, focused, or
    /// enabled state of the button.
    ///
    /// To apply this style to a button, or to a view that contains buttons, use
    /// the ``View/buttonStyle(_:)-5sii2`` modifier.
    @_alwaysEmitIntoClient
    public static var plain: PlainButtonStyle { PlainButtonStyle() }
}

@available(iOS 13.0, *)
private struct PlainButtonStyleBase: ButtonStyle {
    @Environment(\.isEnabled)
    private var isEnabled: Bool
    
    fileprivate func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
        }
        .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1.0) : 0.5)
    }
}
