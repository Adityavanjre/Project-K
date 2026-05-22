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

/// A view that arranges its subviews in a vertical line.
///
/// Unlike ``LazyVStack``, which only renders the views when your app needs to
/// display them, a `VStack` renders the views all at once, regardless
/// of whether they are on- or offscreen. Use the regular `VStack` when you have
/// a small number of subviews or don't want the delayed rendering behavior
/// of the "lazy" version.
///
/// The following example shows a simple vertical stack of 10 text views:
///
///     var body: some View {
///         VStack(
///             alignment: .leading,
///             spacing: 10
///         ) {
///             ForEach(
///                 1...10,
///                 id: \.self
///             ) {
///                 Text("Item \($0)")
///             }
///         }
///     }
///
///
/// > Note: If you need a vertical stack that conforms to the ``Layout``
/// protocol, like when you want to create a conditional layout using
/// ``AnyLayout``, use ``VStackLayout`` instead.
@frozen
@available(iOS 13.0, *)
public struct VStack<Content: View> : UnaryView, PrimitiveView {
    
    public typealias Body = Never
    
    @usableFromInline
    internal var _tree: _VariadicView.Tree<_VStackLayout, Content>
    
    @inlinable
    public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        _tree = .init(
            root: _VStackLayout(alignment: alignment, spacing: spacing), content: content())
    }
    
    public static func _makeView(view: _GraphValue<VStack<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        typealias Tree = _VariadicView.Tree<_VStackLayout, Content>
        
        return Tree._makeView(
            view: view[{.of(&$0._tree)}],
            inputs: inputs
        )
    }
}
