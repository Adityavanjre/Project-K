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

/// A view that overlays its subviews, aligning them in both axes.
///
/// The `ZStack` assigns each successive subview a higher z-axis value than
/// the one before it, meaning later subviews appear "on top" of earlier ones.
///
/// The following example creates a `ZStack` of 100 x 100 point ``Rectangle``
/// views filled with one of six colors, offsetting each successive subview
/// by 10 points so they don't completely overlap:
///
///     let colors: [Color] =
///         [.red, .orange, .yellow, .green, .blue, .purple]
///
///     var body: some View {
///         ZStack {
///             ForEach(0..<colors.count) {
///                 Rectangle()
///                     .fill(colors[$0])
///                     .frame(width: 100, height: 100)
///                     .offset(x: CGFloat($0) * 10.0,
///                             y: CGFloat($0) * 10.0)
///             }
///         }
///     }
///
///
/// The `ZStack` uses an ``Alignment`` to set the x- and y-axis coordinates of
/// each subview, defaulting to a ``Alignment/center`` alignment. In the following
/// example, the `ZStack` uses a ``Alignment/bottomLeading`` alignment to lay
/// out two subviews, a red 100 x 50 point rectangle below, and a blue 50 x 100
/// point rectangle on top. Because of the alignment value, both rectangles
/// share a bottom-left corner with the `ZStack` (in locales where left is the
/// leading side).
///
///     var body: some View {
///         ZStack(alignment: .bottomLeading) {
///             Rectangle()
///                 .fill(Color.red)
///                 .frame(width: 100, height: 50)
///             Rectangle()
///                 .fill(Color.blue)
///                 .frame(width:50, height: 100)
///         }
///         .border(Color.green, width: 1)
///     }
///
///
/// > Note: If you need a version of this stack that conforms to the ``Layout``
/// protocol, like when you want to create a conditional layout using
/// ``AnyLayout``, use ``ZStackLayout`` instead.
@frozen
@available(iOS 13.0, *)
public struct ZStack<Content: View> : UnaryView, PrimitiveView {
    
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never
    
    @usableFromInline
    internal var _tree: _VariadicView.Tree<_ZStackLayout, Content>
    
    /// Creates an instance with the given alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack on both
    ///     the x- and y-axes.
    ///   - content: A view builder that creates the content of this stack.
    @inlinable
    public init(alignment: Alignment = .center, @ViewBuilder content: () -> Content) {
        _tree = .init(root: _ZStackLayout(alignment: alignment), content: content())
    }
    
    public static func _makeView(view: _GraphValue<ZStack<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        typealias Tree = _VariadicView.Tree<_ZStackLayout, Content>
        
        return Tree._makeView(
            view: view[{.of(&$0._tree)}],
            inputs: inputs
        )
    }
}
