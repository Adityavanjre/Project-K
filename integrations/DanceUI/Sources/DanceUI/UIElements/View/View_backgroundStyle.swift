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
    
    /// Sets the view's background to the default background style.
    ///
    /// This modifier behaves like ``View/background(_:ignoresSafeAreaEdges:)``,
    /// except that it always uses the ``ShapeStyle/background`` shape style.
    /// For example, you can add a background to a ``Label``:
    ///
    ///     ZStack {
    ///         Color.teal
    ///         Label("Flag", systemImage: "flag.fill")
    ///             .padding()
    ///             .background()
    ///     }
    ///
    /// Without the background modifier, the teal color behind the label shows
    /// through the label. With the modifier, the label's text and icon appear
    /// backed by a region filled with a color that's appropriate for light
    /// or dark appearance:
    ///
    ///
    /// If you want to specify a ``View`` or a stack of views as the background,
    /// use ``View/background(alignment:content:)`` instead.
    /// To specify a ``Shape`` or ``InsettableShape``, use
    /// ``View/background(_:in:fillStyle:)-89n7j`` or
    /// ``View/background(_:in:fillStyle:)-20tq5``, respectively.
    ///
    /// - Parameters:
    ///   - edges: The set of edges for which to ignore safe area insets
    ///     when adding the background. The default value is ``Edge/Set/all``.
    ///     Specify an empty set to respect safe area insets on all edges.
    ///
    /// - Returns: A view with the ``ShapeStyle/background`` shape style
    ///   drawn behind it.
    @inlinable
    public func background(ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View {
        modifier(_BackgroundStyleModifier(style: .background, ignoresSafeAreaEdges: edges))
    }

    /// Sets the view's background to a style.
    ///
    /// Use this modifier to place a type that conforms to the ``ShapeStyle``
    /// protocol --- like a ``Color``, ``Material``, or
    /// ``HierarchicalShapeStyle`` --- behind a view. For example, you can add
    /// the ``ShapeStyle/regularMaterial`` behind a ``Label``:
    ///
    ///     struct FlagLabel: View {
    ///         var body: some View {
    ///             Label("Flag", systemImage: "flag.fill")
    ///                 .padding()
    ///                 .background(.regularMaterial)
    ///         }
    ///     }
    ///
    /// DanceUI anchors the style to the view's bounds. For the example above,
    /// the background fills the entirety of the label's frame, which includes
    /// the padding:
    ///
    ///
    /// DanceUI limits the background style's extent to the modified view's
    /// container-relative shape. You can see this effect if you constrain the
    /// `FlagLabel` view with a ``View/containerShape(_:)`` modifier:
    ///
    ///     FlagLabel()
    ///         .containerShape(RoundedRectangle(cornerRadius: 16))
    ///
    /// The background takes on the specified container shape:
    ///
    ///
    /// By default, the background ignores safe area insets on all edges, but
    /// you can provide a specific set of edges to ignore, or an empty set to
    /// respect safe area insets on all edges:
    ///
    ///     Rectangle()
    ///         .background(
    ///             .regularMaterial,
    ///             ignoresSafeAreaEdges: []) // Ignore no safe area insets.
    ///
    /// If you want to specify a ``View`` or a stack of views as the background,
    /// use ``View/background(alignment:content:)`` instead.
    /// To specify a ``Shape`` or ``InsettableShape``, use
    /// ``View/background(_:in:fillStyle:)-89n7j`` or
    /// ``View/background(_:in:fillStyle:)-20tq5``, respectively.
    ///
    /// - Parameters:
    ///   - style: An instance of a type that conforms to ``ShapeStyle`` that
    ///     DanceUI draws behind the modified view.
    ///   - edges: The set of edges for which to ignore safe area insets
    ///     when adding the background. The default value is ``Edge/Set/all``.
    ///     Specify an empty set to respect safe area insets on all edges.
    ///
    /// - Returns: A view with the specified style drawn behind it.
    @inlinable
    public func background<S>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View where S : ShapeStyle {
        modifier(_BackgroundStyleModifier(style: style, ignoresSafeAreaEdges: edges))
    }
    
    
    /// Sets the view's background to an insettable shape filled with the
    /// default background style.
    ///
    /// This modifier behaves like ``View/background(_:in:fillStyle:)-20tq5``,
    /// except that it always uses the ``ShapeStyle/background`` shape style
    /// to fill the specified insettable shape. For example, you can use
    /// a ``RoundedRectangle`` as a background on a ``Label``:
    ///
    ///     ZStack {
    ///         Color.teal
    ///         Label("Flag", systemImage: "flag.fill")
    ///             .padding()
    ///             .background(in: RoundedRectangle(cornerRadius: 8))
    ///     }
    ///
    /// Without the background modifier, the fill color shows
    /// through the label. With the modifier, the label's text and icon appear
    /// backed by a shape filled with a color that's appropriate for light
    /// or dark appearance:
    ///
    ///
    /// To create a background with other ``View`` types --- or with a stack
    /// of views --- use ``View/background(alignment:content:)`` instead.
    /// To add a ``ShapeStyle`` as a background, use
    /// ``View/background(_:ignoresSafeAreaEdges:)``.
    ///
    /// - Parameters:
    ///   - shape: An instance of a type that conforms to ``InsettableShape``
    ///     that DanceUI draws behind the view using the
    ///     ``ShapeStyle/background`` shape style.
    ///   - fillStyle: The ``FillStyle`` to use when drawing the shape.
    ///     The default style uses the nonzero winding number rule and
    ///     antialiasing.
    ///
    /// - Returns: A view with the specified insettable shape drawn behind it.
    @inlinable
    public func background<S>(in shape: S, fillStyle: FillStyle = FillStyle()) -> some View where S : Shape {
        modifier(_BackgroundShapeModifier(style: .background, shape: shape, fillStyle: fillStyle))
    }
    
    /// Sets the view's background to a shape filled with a style.
    ///
    /// Use this modifier to layer a type that conforms to the ``Shape``
    /// protocol behind a view. Specify the ``ShapeStyle`` that's used to
    /// fill the shape. For example, you can create a ``Path`` that outlines
    /// a trapezoid:
    ///
    ///     let trapezoid = Path { path in
    ///         path.move(to: .zero)
    ///         path.addLine(to: CGPoint(x: 90, y: 0))
    ///         path.addLine(to: CGPoint(x: 80, y: 50))
    ///         path.addLine(to: CGPoint(x: 10, y: 50))
    ///     }
    ///
    /// Then you can use that shape as a background for a ``Label``:
    ///
    ///     Label("Flag", systemImage: "flag.fill")
    ///         .padding()
    ///         .background(.teal, in: trapezoid)
    ///
    /// The ``ShapeStyle/teal`` color fills the shape:
    ///
    ///
    /// This modifier and ``View/background(_:in:fillStyle:)-20tq5`` are
    /// convenience methods for placing a single shape behind a view. To
    /// create a background with other ``View`` types --- or with a stack
    /// of views --- use ``View/background(alignment:content:)`` instead.
    /// To add a ``ShapeStyle`` as a background, use
    /// ``View/background(_:ignoresSafeAreaEdges:)``.
    ///
    /// - Parameters:
    ///   - style: A ``ShapeStyle`` that DanceUI uses to the fill the shape
    ///     that you specify.
    ///   - shape: An instance of a type that conforms to ``Shape`` that
    ///     DanceUI draws behind the view.
    ///   - fillStyle: The ``FillStyle`` to use when drawing the shape.
    ///     The default style uses the nonzero winding number rule and
    ///     antialiasing.
    ///
    /// - Returns: A view with the specified shape drawn behind it.
    @inlinable
    public func background<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S: ShapeStyle, T: Shape {
        modifier(_BackgroundShapeModifier(style: style, shape: shape, fillStyle: fillStyle))
    }
    
    /// Sets the view's background to an insettable shape filled with the
    /// default background style.
    ///
    /// This modifier behaves like ``View/background(_:in:fillStyle:)-20tq5``,
    /// except that it always uses the ``ShapeStyle/background`` shape style
    /// to fill the specified insettable shape. For example, you can use
    /// a ``RoundedRectangle`` as a background on a ``Label``:
    ///
    ///     ZStack {
    ///         Color.teal
    ///         Label("Flag", systemImage: "flag.fill")
    ///             .padding()
    ///             .background(in: RoundedRectangle(cornerRadius: 8))
    ///     }
    ///
    /// Without the background modifier, the fill color shows
    /// through the label. With the modifier, the label's text and icon appear
    /// backed by a shape filled with a color that's appropriate for light
    /// or dark appearance:
    ///
    ///
    /// To create a background with other ``View`` types --- or with a stack
    /// of views --- use ``View/background(alignment:content:)`` instead.
    /// To add a ``ShapeStyle`` as a background, use
    /// ``View/background(_:ignoresSafeAreaEdges:)``.
    ///
    /// - Parameters:
    ///   - shape: An instance of a type that conforms to ``InsettableShape``
    ///     that DanceUI draws behind the view using the
    ///     ``ShapeStyle/background`` shape style.
    ///   - fillStyle: The ``FillStyle`` to use when drawing the shape.
    ///     The default style uses the nonzero winding number rule and
    ///     antialiasing.
    ///
    /// - Returns: A view with the specified insettable shape drawn behind it.

    @inlinable
    public func background<S>(in shape: S, fillStyle: FillStyle = FillStyle()) -> some View where S: InsettableShape {
        modifier(_InsettableBackgroundShapeModifier(style: .background, shape: shape, fillStyle: fillStyle))
    }
    
    /// Sets the view's background to an insettable shape filled with a style.
    ///
    /// Use this modifier to layer a type that conforms to the
    /// ``InsettableShape`` protocol --- like a ``Rectangle``, ``Circle``, or
    /// ``Capsule`` --- behind a view. Specify the ``ShapeStyle`` that's used to
    /// fill the shape. For example, you can place a ``RoundedRectangle``
    /// behind a ``Label``:
    ///
    ///     Label("Flag", systemImage: "flag.fill")
    ///         .padding()
    ///         .background(.teal, in: RoundedRectangle(cornerRadius: 8))
    ///
    /// The ``ShapeStyle/teal`` color fills the shape:
    ///
    ///
    /// This modifier and ``View/background(_:in:fillStyle:)-89n7j`` are
    /// convenience methods for placing a single shape behind a view. To
    /// create a background with other ``View`` types --- or with a stack
    /// of views --- use ``View/background(alignment:content:)`` instead.
    /// To add a ``ShapeStyle`` as a background, use
    /// ``View/background(_:ignoresSafeAreaEdges:)``.
    ///
    /// - Parameters:
    ///   - style: A ``ShapeStyle`` that DanceUI uses to the fill the shape
    ///     that you specify.
    ///   - shape: An instance of a type that conforms to ``InsettableShape``
    ///     that DanceUI draws behind the view.
    ///   - fillStyle: The ``FillStyle`` to use when drawing the shape.
    ///     The default style uses the nonzero winding number rule and
    ///     antialiasing.
    ///
    /// - Returns: A view with the specified insettable shape drawn behind it.
    @inlinable
    public func background<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S: ShapeStyle, T: InsettableShape {
        modifier(_InsettableBackgroundShapeModifier(style: style, shape: shape, fillStyle: fillStyle))
    }
}
