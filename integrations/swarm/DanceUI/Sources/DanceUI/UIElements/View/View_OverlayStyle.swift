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
    /// Layers the specified style in front of this view.
    ///
    /// Use this modifier to layer a type that conforms to the ``ShapeStyle``
    /// protocol, like a ``Color``or ``HierarchicalShapeStyle``,
    /// in front of a view. For example, you can overlay the
    /// ``ShapeStyle/red`` over a ``Circle``:
    ///
    ///     struct CoveredCircle: View {
    ///         var body: some View {
    ///             Circle()
    ///                 .frame(width: 300, height: 200)
    ///                 .overlay(.ultraThinMaterial)
    ///         }
    ///     }
    ///
    /// DanceUI anchors the style to the view's bounds. For the example above,
    /// the overlay fills the entirety of the circle's frame (which happens
    /// to be wider than the circle is tall):
    ///
    ///
    /// DanceUI also limits the style's extent to the view's
    /// container-relative shape.
    ///
    ///     CoveredCircle()
    ///         .containerShape(RoundedRectangle(cornerRadius: 30))
    ///
    /// The overlay takes on the specified container shape:
    ///
    /// By default, the overlay ignores safe area insets on all edges, but you
    /// can provide a specific set of edges to ignore, or an empty set to
    /// respect safe area insets on all edges:
    ///
    ///     Rectangle()
    ///         .overlay(
    ///             .secondary,
    ///             ignoresSafeAreaEdges: []) // Ignore no safe area insets.
    ///
    /// If you want to specify a ``View`` or a stack of views as the overlay
    /// rather than a style, use ``View/overlay(alignment:content:)`` instead.
    /// If you want to specify a ``Shape``, use
    /// ``View/overlay(_:in:fillStyle:)``.
    ///
    /// - Parameters:
    ///   - style: An instance of a type that conforms to ``ShapeStyle`` that
    ///     DanceUI layers in front of the modified view.
    ///   - edges: The set of edges for which to ignore safe area insets
    ///     when adding the overlay. The default value is ``Edge/Set/all``.
    ///     Specify an empty set to respect safe area insets on all edges.
    ///
    /// - Returns: A view with the specified style drawn in front of it.
    @inlinable
    public func overlay<S>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View where S: ShapeStyle {
        modifier(_OverlayStyleModifier(style: style, ignoresSafeAreaEdges: edges))
    }


    /// Layers a shape that you specify in front of this view.
    ///
    /// Use this modifier to layer a type that conforms to the ``Shape``
    /// protocol --- like a ``Rectangle``, ``Circle``, or ``Capsule`` --- in
    /// front of a view. Specify a ``ShapeStyle`` that's used to fill the shape.
    /// For example, you can overlay the outline of one rectangle in front of
    /// another:
    ///
    ///     Rectangle()
    ///         .frame(width: 200, height: 100)
    ///         .overlay(.teal, in: Rectangle().inset(by: 10).stroke(lineWidth: 5))
    ///
    /// The example above uses the ``InsettableShape/inset(by:)`` method to
    /// slightly reduce the size of the overlaid rectangle, and the
    /// ``Shape/stroke(lineWidth:)`` method to fill only the shape's outline.
    /// This creates an inset border:
    ///
    ///
    /// This modifier is a convenience method for layering a shape over a view.
    /// To handle the more general case of overlaying a ``View`` --- or a stack
    /// of views --- with control over the position, use
    /// ``View/overlay(alignment:content:)`` instead. To cover a view with a
    /// ``ShapeStyle``, use ``View/overlay(_:ignoresSafeAreaEdges:)``.
    ///
    /// - Parameters:
    ///   - style: A ``ShapeStyle`` that DanceUI uses to the fill the shape
    ///     that you specify.
    ///   - shape: An instance of a type that conforms to ``Shape`` that
    ///     DanceUI draws in front of the view.
    ///   - fillStyle: The ``FillStyle`` to use when drawing the shape.
    ///     The default style uses the nonzero winding number rule and
    ///     antialiasing.
    ///
    /// - Returns: A view with the specified shape drawn in front of it.
    @inlinable
    public func overlay<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S: ShapeStyle, T: Shape {
        modifier(_OverlayShapeModifier(style: style, shape: shape, fillStyle: fillStyle))
    }
}
