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
    
    /// Sets a view's foreground elements to use a given style.
    ///
    /// Use this method to style
    /// foreground content like text, shapes, and template images
    /// (including symbols):
    ///
    ///     HStack {
    ///         Image(systemName: "triangle.fill")
    ///         Text("Hello, world!")
    ///         RoundedRectangle(cornerRadius: 5)
    ///             .frame(width: 40, height: 20)
    ///     }
    ///     .foregroundStyle(.teal)
    ///
    /// The example above creates a row of ``ShapeStyle/teal`` foreground
    /// elements:
    ///
    ///
    /// You can use any style that conforms to the ``ShapeStyle`` protocol,
    /// like the ``ShapeStyle/teal`` color in the example above, or the
    /// ``ShapeStyle/linearGradient(colors:startPoint:endPoint:)`` gradient
    /// shown below:
    ///
    ///     Text("Gradient Text")
    ///         .font(.largeTitle)
    ///         .foregroundStyle(
    ///             .linearGradient(
    ///                 colors: [.yellow, .blue],
    ///                 startPoint: .top,
    ///                 endPoint: .bottom
    ///             )
    ///         )
    ///
    ///
    /// > Tip: If you want to fill a single ``Shape`` instance with a style,
    /// use the ``Shape/fill(style:)`` shape modifier instead because it's more
    /// efficient.
    ///
    /// DanceUI creates a context-dependent render for a given style.
    /// For example, a ``Color`` that you load from an asset catalog
    /// can have different light and dark appearances, while some styles
    /// also vary by platform.
    ///
    /// Hierarchical foreground styles like ``ShapeStyle/secondary``
    /// don't impose a style of their own, but instead modify other styles.
    /// In particular, they modify the primary
    /// level of the current foreground style to the degree given by
    /// the hierarchical style's name.
    /// To find the current foreground style to modify, DanceUI looks for
    /// the innermost containing style that you apply with the
    /// `foregroundStyle(_:)` or the ``View/foregroundColor(_:)`` modifier.
    /// If you haven't specified a style, DanceUI uses the default foreground
    /// style, as in the following example:
    ///
    ///     VStack(alignment: .leading) {
    ///         Label("Primary", systemImage: "1.square.fill")
    ///         Label("Secondary", systemImage: "2.square.fill")
    ///             .foregroundStyle(.secondary)
    ///     }
    ///
    ///
    /// If you add a foreground style on the enclosing
    /// ``VStack``, the hierarchical styling responds accordingly:
    ///
    ///     VStack(alignment: .leading) {
    ///         Label("Primary", systemImage: "1.square.fill")
    ///         Label("Secondary", systemImage: "2.square.fill")
    ///             .foregroundStyle(.secondary)
    ///     }
    ///     .foregroundStyle(.blue)
    ///
    ///
    /// When you apply a custom style to a view, the view disables the vibrancy
    /// effect for foreground elements in that view, or in any of its child
    /// views, that it would otherwise gain from adding a background material
    /// --- for example, using the ``View/background(_:ignoresSafeAreaEdges:)``
    /// modifier. However, hierarchical styles applied to the default foreground
    /// don't disable vibrancy.
    ///
    /// - Parameter style: The color or pattern to use when filling in the
    ///   foreground elements. To indicate a specific value, use ``Color`` or
    ///   ``ShapeStyle/image(_:sourceRect:scale:)``, or one of the gradient
    ///   types, like
    ///   ``ShapeStyle/linearGradient(colors:startPoint:endPoint:)``. To set a
    ///   style that’s relative to the containing view's style, use one of the
    ///   semantic styles, like ``ShapeStyle/primary``.
    ///
    /// - Returns: A view that uses the given foreground style.
    @inlinable
    public func foregroundStyle<S>(_ style: S) -> some View where S: ShapeStyle {
        modifier(_ForegroundStyleModifier(style: style))
    }
    
    /// Sets the primary and secondary levels of the foreground
    /// style in the child view.
    ///
    /// DanceUI uses these styles when rendering child views
    /// that don't have an explicit rendering style, like images,
    /// text, shapes, and so on.
    ///
    /// Symbol images within the view hierarchy use the
    /// ``SymbolRenderingMode/palette`` rendering mode when you apply this
    /// modifier, if you don't explicitly specify another mode.
    ///
    /// - Parameters:
    ///   - primary: The primary color or pattern to use when filling in
    ///     the foreground elements. To indicate a specific value, use ``Color``
    ///     or ``ShapeStyle/image(_:sourceRect:scale:)``, or one of the gradient
    ///     types, like
    ///     ``ShapeStyle/linearGradient(colors:startPoint:endPoint:)``. To set a
    ///     style that’s relative to the containing view's style, use one of the
    ///     semantic styles, like ``ShapeStyle/primary``.
    ///   - secondary: The secondary color or pattern to use when
    ///     filling in the foreground elements.
    ///
    /// - Returns: A view that uses the given foreground styles.
    @inlinable
    public func foregroundStyle<S1, S2>(_ primary: S1,
                                        _ secondary: S2) -> some View where S1: ShapeStyle, S2: ShapeStyle {
        modifier(_ForegroundStyleModifier2(primary: primary,
                                           secondary: secondary))
    }
    
    /// Sets the primary, secondary, and tertiary levels of
    /// the foreground style.
    ///
    /// DanceUI uses these styles when rendering child views
    /// that don't have an explicit rendering style, like images,
    /// text, shapes, and so on.
    ///
    /// Symbol images within the view hierarchy use the
    /// ``SymbolRenderingMode/palette`` rendering mode when you apply this
    /// modifier, if you don't explicitly specify another mode.
    ///
    /// - Parameters:
    ///   - primary: The primary color or pattern to use when filling in
    ///     the foreground elements. To indicate a specific value, use ``Color``
    ///     or ``ShapeStyle/image(_:sourceRect:scale:)``, or one of the gradient
    ///     types, like
    ///     ``ShapeStyle/linearGradient(colors:startPoint:endPoint:)``. To set a
    ///     style that’s relative to the containing view's style, use one of the
    ///     semantic styles, like ``ShapeStyle/primary``.
    ///   - secondary: The secondary color or pattern to use when
    ///     filling in the foreground elements.
    ///   - tertiary: The tertiary color or pattern to use when
    ///     filling in the foreground elements.
    ///
    /// - Returns: A view that uses the given foreground styles.
    @inlinable
    public func foregroundStyle<S1, S2, S3>(_ primary: S1,
                                            _ secondary: S2,
                                            _ tertiary: S3) -> some View where S1: ShapeStyle, S2: ShapeStyle, S3: ShapeStyle {
            modifier(_ForegroundStyleModifier3(primary: primary, secondary: secondary, tertiary: tertiary))
    }
}
