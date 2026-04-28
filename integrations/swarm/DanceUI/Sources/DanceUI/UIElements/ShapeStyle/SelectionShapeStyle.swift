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

/// A style used to visually indicate selection following platform conventional
/// colors and behaviors.
///
/// You can also use ``ShapeStyle/selection`` to construct this style.

@available(iOS 13.0, *)
public struct SelectionShapeStyle: Paint {
    
    /// Creates a selection shape style.
    public init() {
    }
    
    internal func resolvePaint(in environment: EnvironmentValues) -> Color.Resolved {
        let resolvedColor: Color.Resolved
        if !environment.isFocused,
           environment.isPlatformFocusSystemEnabled {
            resolvedColor = Color.gray.resolvePaint(in: environment)
        } else {
            resolvedColor = Color.accentColor.resolvePaint(in: environment)
        }
        return resolvedColor
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == SelectionShapeStyle {

    /// A style used to visually indicate selection following platform conventional
    /// colors and behaviors.
    ///
    /// For example:
    ///
    ///     ForEach(items) {
    ///        ItemView(value: item, isSelected: item.id == selectedID)
    ///     }
    ///
    ///     struct ItemView {
    ///         var value: item
    ///         var isSelected: Bool
    ///
    ///         var body: some View {
    ///             // construct the actual cell content
    ///                 .background(selectionBackground)
    ///         }
    ///         @ViewBuilder
    ///         private var selectionBackground: some View {
    ///             if isSelected {
    ///                 RoundedRectangle(cornerRadius: 8)
    ///                     .fill(.selection)
    ///             }
    ///         }
    ///     }
    ///
    /// On macOS and iPadOS this automatically reflects window key state and focus
    /// state, where the emphasized appearance will be used only when the window is
    /// key and the nearest focusable element is actually focused. On iPhone, this
    /// will always fill with the environment's accent color.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static var selection: SelectionShapeStyle {
        SelectionShapeStyle()
    }
}
