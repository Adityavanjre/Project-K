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

import CoreGraphics
internal import DanceUIGraph

/// A color or pattern to use when rendering a shape.
///
/// You don't use the `ShapeStyle` protocol directly. Instead, use one of
/// the concrete styles that DanceUI defines. To indicate a specific color
/// or pattern, you can use ``Color`` or the style returned by
/// ``ShapeStyle/image(_:sourceRect:scale:)``, or one of the gradient
/// types, like the one returned by
/// ``ShapeStyle/radialGradient(colors:center:startRadius:endRadius:)``.
/// To set a color that's appropriate for a given context on a given
/// platform, use one of the semantic styles, like ``ShapeStyle/background`` or
/// ``ShapeStyle/primary``.
///
/// You can use a shape style by:
/// * Filling a shape with a style with the ``Shape/fill(_:style:)`` modifier:
///
///     ```
///     Path { path in
///         path.move(to: .zero)
///         path.addLine(to: CGPoint(x: 50, y: 0))
///         path.addArc(
///             center: .zero,
///             radius: 50,
///             startAngle: .zero,
///             endAngle: .degrees(90),
///             clockwise: false)
///     }
///     .fill(.radial(
///         Gradient(colors: [.yellow, .red]),
///         center: .topLeading,
///         startRadius: 15,
///         endRadius: 80))
///     ```
///
///
/// * Tracing the outline of a shape with a style with either the
///   ``Shape/stroke(_:lineWidth:)`` or the ``Shape/stroke(_:style:)`` modifier:
///
///     ```
///     RoundedRectangle(cornerRadius: 10)
///         .stroke(.mint, lineWidth: 10)
///         .frame(width: 200, height: 50)
///     ```
///
///
/// * Styling the foreground elements in a view with the
///   ``View/foregroundStyle(_:)`` modifier:
///
///     ```
///     VStack(alignment: .leading) {
///         Text("Primary")
///             .font(.title)
///         Text("Secondary")
///             .font(.caption)
///             .foregroundStyle(.secondary)
///     }
///     ```
///
@available(iOS 13.0, *)
public protocol ShapeStyle {
    
    associatedtype ResolvedStyle: ShapeStyle = Never
    
    static func _makeView<ShapeType: Shape>(view: _GraphValue<_ShapeView<ShapeType, Self>>, inputs: _ViewInputs) -> _ViewOutputs
    
    func _apply(to shape: inout _ShapeStyle_Shape)
    
    static func _apply(to type: inout _ShapeStyle_ShapeType)
    
    func resolve(in environment: EnvironmentValues) -> Self.ResolvedStyle
}

@available(iOS 13.0, *)
extension ShapeStyle where Self.ResolvedStyle == Never {
    
    public func resolve(in environment: EnvironmentValues) -> Never {
        _danceuiPreconditionFailure("ShapeStyle.Resolved can not be Never.")
    }
    

    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        
    }
}

@available(iOS 13.0, *)
extension Never: ShapeStyle {
    
    public typealias ResolvedStyle = Never
    
    public static func _makeView<S>(view: _GraphValue<_ShapeView<S, Never>>, inputs: _ViewInputs) -> _ViewOutputs where S :Shape {
        _danceuiPreconditionFailure()
    }
}

@available(iOS 13.0, *)
extension ShapeStyle {
    
    public static func _makeView<ShapeType: Shape>(view: _GraphValue<_ShapeView<ShapeType, Self>>, inputs: _ViewInputs) -> _ViewOutputs {
        legacyMakeShapeView(view: view, inputs: inputs)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        if let value = ResolvedStyle.self as? Never.Type {
            return
        }
        
        let resolvedStyle = resolve(in: shape.environment)
        resolvedStyle._apply(to: &shape)
    }
    

    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        
    }
    
    internal func mapForegroundStyle<Style: ShapeStyle>(in styleShape: inout _ShapeStyle_Shape, body: (AnyShapeStyle) -> Style)  {
        switch styleShape.operation {
        case .multiLevel,
             .primaryStyle:
            _apply(to: &styleShape)
            if case .style(let resolvedStyle) = styleShape.result {
                let resultStyle = body(resolvedStyle)
                styleShape.result = .style(AnyShapeStyle(resultStyle))
            }
        default:
            break
        }
    }
    
    internal func copyForegroundStyle(in environment: EnvironmentValues) -> AnyShapeStyle {
        
        var shapeStyle = _ShapeStyle_Shape(operation: .multiLevel,
                                           result: .none,
                                           environment: environment,
                                           bounds: nil,
                                           role: .stroke,
                                           inRecursiveStyle: false)
        _apply(to: &shapeStyle)
        
        if case .style(let anyShapeStyle) = shapeStyle.result {
            return anyShapeStyle
        } else {
            return AnyShapeStyle(self)
        }
    }
    
    internal func primaryStyle(in environment: EnvironmentValues) -> AnyShapeStyle? {
        var resultStyle: AnyShapeStyle?
        var shapeStyle = _ShapeStyle_Shape(operation: .primaryStyle,
                                           result: .none,
                                           environment: environment,
                                           bounds: nil,
                                           role: .fill,
                                           inRecursiveStyle: false)
        _apply(to: &shapeStyle)
        
        if case .style(let anyShapeStyle) = shapeStyle.result {
            resultStyle = anyShapeStyle
        }
        
        return resultStyle
    }
    
    // TODO: _notImplemented ShapeStyle._fillingContainerShape unused
//    internal func _fillingContainerShape() -> some View {
//        ContainerRelativeShape().fill(self)
//    }
    
    // TODO: _notImplemented ShapeStyle.blendMode unused
//    internal func blendMode(value: BlendMode) -> some ShapeStyle {
//        _BlendModeShapeStyle(style: self, blendMode: value)
//    }
    
    // TODO: _notImplemented ShapeStyle.opacities(value: [Double]) unused
//    internal func opacities(value: [Double]) -> some ShapeStyle{
//        _OpacitiesShapeStyle(style: self, opacities: value)
//    }
    
    // TODO: _notImplemented ShapeStyle.opacities(value: Double...) unused
//    internal func opacities(value: Double...) -> some ShapeStyle {
//        opacities(value: value.map({$0}))
//    }
    
    public static func legacyMakeShapeView<ShapeType: Shape>(view: _GraphValue<_ShapeView<ShapeType, Self>>, inputs: _ViewInputs) -> _ViewOutputs {
        _ShapeView<ShapeType, Self>._makeView(view: view, inputs: inputs)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle {
    
    /// Maps a shape style's unit-space coordinates to the absolute coordinates
    /// of a given rectangle.
    ///
    /// Some shape styles have colors or patterns that vary
    /// with position based on ``UnitPoint`` coordinates. For example, you
    /// can create a ``LinearGradient`` using ``UnitPoint/top`` and
    /// ``UnitPoint/bottom`` as the start and end points:
    ///
    ///     let gradient = LinearGradient(
    ///         colors: [.red, .yellow],
    ///         startPoint: .top,
    ///         endPoint: .bottom)
    ///
    /// When rendering such styles, DanceUI maps the unit space coordinates to
    /// the absolute coordinates of the filled shape. However, you can tell
    /// DanceUI to use a different set of coordinates by supplying a rectangle
    /// to the `in(_:)` method. Consider two resizable rectangles using the
    /// gradient defined above:
    ///
    ///     HStack {
    ///         Rectangle()
    ///             .fill(gradient)
    ///         Rectangle()
    ///             .fill(gradient.in(CGRect(x: 0, y: 0, width: 0, height: 300)))
    ///     }
    ///     .onTapGesture { isBig.toggle() }
    ///     .frame(height: isBig ? 300 : 50)
    ///     .animation(.easeInOut)
    ///
    /// When `isBig` is true — defined elsewhere as a private ``State``
    /// variable — the rectangles look the same, because their heights
    /// match that of the modified gradient:
    ///
    ///
    /// When the user toggles `isBig` by tapping the ``HStack``, the
    /// rectangles shrink, but the gradients each react in a different way:
    ///
    ///
    /// DanceUI remaps the gradient of the first rectangle to the new frame
    /// height, so that you continue to see the full range of colors in a
    /// smaller area. For the second rectangle, the modified gradient retains
    /// a mapping to the full height, so you instead see only a small part of
    /// the overall gradient. Animation helps to visualize the difference.
    ///
    /// - Parameter rect: A rectangle that gives the absolute coordinates over
    ///   which to map the shape style.
    /// - Returns: A new shape style mapped to the coordinates given by `rect`.
    @inlinable
    public func `in`(_ rect: CGRect) -> some ShapeStyle {
        _AnchoredShapeStyle(style: self, bounds: rect)
    }
}

/// The foreground style in the current context.
///
/// You can also use ``ShapeStyle/foreground`` to construct this style.
@frozen
@available(iOS 13.0, *)
public struct ForegroundStyle: ShapeStyle {
    
    /// Creates a foreground style instance.
    @inlinable
    public init() {
        
    }
    
    internal static var shared: AnyShapeStyle {
        AnyShapeStyle(ForegroundStyle())
    }
    
    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        type.result = .none
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        if shape.inRecursiveStyle {
            LegacyContentStyle.sharedPrimary._apply(to: &shape)
        } else {
            shape.inRecursiveStyle = true
            let resolvedStyle = shape.environment.effectiveForegroundStyle
            resolvedStyle._apply(to: &shape)
            shape.inRecursiveStyle = false
        }
    }
    
    public static func _makeView<ShapeType>(view: _GraphValue<_ShapeView<ShapeType, ForegroundStyle>>, inputs: _ViewInputs) -> _ViewOutputs where ShapeType : Shape {
        legacyMakeShapeView(view: view, inputs: inputs)
    }
}

/// A 2D shape that you can use when drawing a view.
///
/// Shapes without an explicit fill or stroke get a default fill based on the
/// foreground color.
///
/// You can define shapes in relation to an implicit frame of reference, such as
/// the natural size of the view that contains it. Alternatively, you can define
/// shapes in terms of absolute coordinates.
@available(iOS 13.0, *)
public protocol Shape: Animatable, View {
    
    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    /// - Returns: A path that describes this shape.
    func path(in rect: CGRect) -> Path
    
    /// An indication of how to style a shape.
    ///
    /// DanceUI looks at a shape's role when deciding how to apply a
    /// ``ShapeStyle`` at render time. The ``Shape`` protocol provides a
    /// default implementation with a value of ``ShapeRole/fill``. If you
    /// create a composite shape, you can provide an override of this property
    /// to return another value, if appropriate.
    static var role: ShapeRole { get }
    
    /// Returns the size of the view that will render the shape, given
    /// a proposed size.
    ///
    /// Implement this method to tell the container of the shape how
    /// much space the shape needs to render itself, given a size
    /// proposal.
    ///
    /// See ``Layout/sizeThatFits(proposal:subviews:cache:)``
    /// for more details about how the layout system chooses the size of
    /// views.
    ///
    /// - Parameters:
    ///   - proposal: A size proposal for the container.
    ///
    /// - Returns: A size that indicates how much space the shape needs.
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
}

@available(iOS 13.0, *)
extension Shape {
    /// Declares the content and behavior of this view.
    public var body: _ShapeView<Self, ForegroundStyle> {
        .init(shape: self, style: ForegroundStyle())
    }
    
    /// An indication of how to style a shape.
    public static var role: ShapeRole {
        .fill
    }
    
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
}

@available(iOS 13.0, *)
// TODO: _notImplemented Shape.fillShadow unused
//extension Shape {
//    
//    internal func fillShadow(color: Color,
//                             radius: CGFloat,
//                             x: CGFloat,
//                             y: CGFloat) -> some View {
//        _ShadowView(shape: self,
//                    effect: _ShadowEffect(color: color,
//                                          radius: radius,
//                                          offset: CGSize(width: x, height: y)))
//    }
//}

extension ShapeStyle where Self : View, Self.Body == _ShapeView<Rectangle, Self> {
    
    /// A rectangular view that's filled with the shape style.
    ///
    /// For a ``ShapeStyle`` that also conforms to the ``View`` protocol, like
    /// ``Color`` or ``LinearGradient``, this default implementation of the
    /// ``View/body-swift.property`` property provides a visual representation
    /// for the shape style. As a result, you can use the shape style in a view
    /// hierarchy like any other view:
    ///
    ///     ZStack {
    ///         Color.cyan
    ///         Text("Hello!")
    ///     }
    ///     .frame(width: 200, height: 50)
    ///
    public var body: _ShapeView<Rectangle, Self> {
        _ShapeView<Rectangle, Self>(shape: Rectangle(), style: self)
    }
    
}

/// A style for rasterizing vector shapes.
@frozen
@available(iOS 13.0, *)
public struct FillStyle : Equatable {

    /// A Boolean value that indicates whether to use the even-odd rule when
    /// rendering a shape.
    ///
    /// When `isEOFilled` is `false`, the style uses the non-zero winding
    /// number rule.
    public var isEOFilled: Bool

    /// A Boolean value that indicates whether to apply antialiasing the edges
    /// of a shape.
    public var isAntialiased: Bool

    /// Creates a new style with the specified settings.
    ///
    /// - Parameters:
    ///   - eoFill: A Boolean value that indicates whether to use the even-od
    ///     rule for rendering a shape. Pass `false` to use the non-zero
    ///     winding number rule instead.
    ///   - antialiased: A Boolean value that indicates whether to use
    ///     antialiasing when rendering the edges of a shape.
    public init(eoFill: Bool = false, antialiased: Bool = true) {
        isEOFilled = eoFill
        isAntialiased = antialiased
    }
    
    internal var fillRule: CAShapeLayerFillRule {
        isEOFilled ? .evenOdd : .nonZero
    }
}

@frozen
@available(iOS 13.0, *)
public struct _ShapeView<Content, Style>: ShapeStyledLeafView, LeafViewLayout where Content: Shape, Style: ShapeStyle {
    
    public var shape: Content
    
    public var style: Style
    
    public var fillStyle: FillStyle
    
    @inlinable
    public init(shape: Content, style: Style, fillStyle: FillStyle = FillStyle() ) {
        self.shape = shape
        self.style = style
        self.fillStyle = fillStyle
    }
    
    internal func shape(size: CGSize, edgeInsets: EdgeInsets) -> (ShapeStyle_RenderedShape.Shape, CGRect) {
        let positioningRect = CGRect(origin: .zero, size: size).inset(by: edgeInsets)
        let renderRect = CGRect(origin: .zero, size: positioningRect.size)
        let path = self.shape.path(in: renderRect)
        let shapeRect = positioningRect.flushNullToZero()
        let renderedShape = ShapeStyle_RenderedShape.Shape(path: path,
                                                           fillStyle: self.fillStyle)
        return (renderedShape, shapeRect)
    }
    
    public static func _makeView(view: _GraphValue<_ShapeView<Content, Style>>, inputs: _ViewInputs) -> _ViewOutputs {
        
        let styleResolverAttribute: Attribute<_ShapeStyle_Shape.ResolvedStyle>
        
        if Style.self == ForegroundStyle.self {
            styleResolverAttribute = inputs.resolvedForegroundStyle(role: Content.role,
                                                                    mode: nil)
        } else {
            let style = view[{.of(&$0.style)}]
            let styleAttribute = OptionalAttribute(style.value)
            let mode = OptionalAttribute<ShapeStyle_ResolverMode>(nil)
            let animatableAttribute = AnimatableAttributeHelper<_ShapeStyle_Shape.ResolvedStyle>(phase: inputs.phase,
                                                                                                 time: inputs.time,
                                                                                                 transaction: inputs.transaction)
            
            let styleResolver = ShapeStyleResolver(style: styleAttribute,
                                                   mode: mode,
                                                   environment: inputs.environment,
                                                   role: Content.role,
                                                   animationsDisabled: inputs.base.disableAnimations,
                                                   helper: animatableAttribute)
            styleResolverAttribute = Attribute(styleResolver)
        }
        
        styleResolverAttribute.flags = .active
        
        var outputs: _ViewOutputs
        
        if MemoryLayout<Content.AnimatableData>.size == 0 {
            outputs = makeLeafView(view: view, inputs: inputs, style: styleResolverAttribute)
        } else {
            let shape = view[{.of(&$0.shape)}]
            let shapeAttribute = Content.makeAnimatable(value: shape, inputs: inputs.base)
            let fillStyleAttribute = view[{.of(&$0.fillStyle)}].value
            let animatedShape = _GraphValue(AnimatedShape.Init(shape: shapeAttribute, fillStyle: fillStyleAttribute))
            outputs = AnimatedShape.makeLeafView(view: animatedShape,
                                                     inputs: inputs,
                                                     style: styleResolverAttribute)
        }
        
        outputs.setLayout(inputs) {
            Attribute(LeafLayoutComputer(view: view.value))
        }
        return outputs
    }
    
    public static func _makeViewList(view: _GraphValue<_ShapeView<Content, Style>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        _ViewListOutputs.unaryViewList(view: view, inputs: inputs)
    }
    
    internal func spacing() -> Spacing {
        .zeroText
    }

    internal func sizeThatFits(in size: _ProposedSize) -> CGSize {
        shape.sizeThatFits(.init(size))
    }
}
