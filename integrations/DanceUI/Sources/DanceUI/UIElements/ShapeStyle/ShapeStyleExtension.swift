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

// Color
@available(iOS 13.0, *)
extension ShapeStyle where Self == Color {
    
    /// A context-dependent red color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var red: Color {
        .red
    }

    /// A context-dependent orange color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var orange: Color {
        .orange
    }

    /// A context-dependent yellow color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var yellow: Color {
        .yellow
    }

    /// A context-dependent green color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var green: Color {
        .green
    }

    /// A context-dependent blue color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var blue: Color {
        .blue
    }

    /// A context-dependent purple color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var purple: Color {
        .purple
    }

    /// A context-dependent pink color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var pink: Color {
        .pink
    }

    /// A white color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var white: Color {
        .white
    }

    /// A context-dependent gray color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var gray: Color {
        .gray
    }

    /// A black color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var black: Color {
        .black
    }

    /// A clear color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var clear: Color {
        .clear
    }
    
    /// A context-dependent mint color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var mint: Color {
        .mint
    }

    /// A context-dependent teal color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var teal: Color {
        .teal
    }

    /// A context-dependent cyan color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var cyan: Color {
        .cyan
    }
    
    /// A context-dependent indigo color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var indigo: Color {
        .indigo
    }
    
    /// A context-dependent brown color suitable for use in UI elements.
    @_alwaysEmitIntoClient
    public static var brown: Color {
        .brown
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == LinearGradient {
    /// A linear gradient.
    ///
    /// The gradient applies the color function along an axis, as defined by its
    /// start and end points. The gradient maps the unit space points into the
    /// bounding rectangle of each shape filled with the gradient.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func linearGradient(_ gradient: Gradient,
                                      startPoint: UnitPoint,
                                      endPoint: UnitPoint) -> LinearGradient {
        LinearGradient(gradient: gradient,
                       startPoint: startPoint,
                       endPoint: endPoint)
    }

    /// A linear gradient defined by a collection of colors.
    ///
    /// The gradient applies the color function along an axis, as defined by its
    /// start and end points. The gradient maps the unit space points into the
    /// bounding rectangle of each shape filled with the gradient.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func linearGradient(colors: [Color],
                                      startPoint: UnitPoint,
                                      endPoint: UnitPoint) -> LinearGradient {
        LinearGradient(colors: colors,
                       startPoint: startPoint,
                       endPoint: endPoint)
    }

    /// A linear gradient defined by a collection of color stops.
    ///
    /// The gradient applies the color function along an axis, as defined by its
    /// start and end points. The gradient maps the unit space points into the
    /// bounding rectangle of each shape filled with the gradient.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func linearGradient(stops: [Gradient.Stop],
                                      startPoint: UnitPoint,
                                      endPoint: UnitPoint) -> LinearGradient {
        LinearGradient(stops: stops,
                       startPoint: startPoint,
                       endPoint: endPoint)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == _AnyLinearGradient {
    /// A linear gradient.
    ///
    /// The gradient applies the color function along an axis, as
    /// defined by its start and end points. The gradient maps the unit
    /// space points into the bounding rectangle of each shape filled
    /// with the gradient.
    ///
    /// For example, a linear gradient used as a background:
    ///
    ///     ContentView()
    ///         .background(.linearGradient(.red.gradient,
    ///             startPoint: .top, endPoint: .bottom))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func linearGradient(_ gradient: AnyGradient,
                                      startPoint: UnitPoint,
                                      endPoint: UnitPoint) -> _AnyLinearGradient {
        _AnyLinearGradient(gradient: gradient,
                           startPoint: startPoint,
                           endPoint: endPoint)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == RadialGradient {

    /// A radial gradient.
    ///
    /// The gradient applies the color function as the distance from a center
    /// point, scaled to fit within the defined start and end radii. The
    /// gradient maps the unit space center point into the bounding rectangle of
    /// each shape filled with the gradient.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func radialGradient(_ gradient: Gradient,
                                      center: UnitPoint,
                                      startRadius: CGFloat,
                                      endRadius: CGFloat) -> RadialGradient {
        RadialGradient(gradient: gradient,
                       center: center,
                       startRadius: startRadius,
                       endRadius: endRadius)
    }

    /// A radial gradient defined by a collection of colors.
    ///
    /// The gradient applies the color function as the distance from a center
    /// point, scaled to fit within the defined start and end radii. The
    /// gradient maps the unit space center point into the bounding rectangle of
    /// each shape filled with the gradient.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func radialGradient(colors: [Color],
                                      center: UnitPoint,
                                      startRadius: CGFloat,
                                      endRadius: CGFloat) -> RadialGradient {
        RadialGradient(colors: colors,
                       center: center,
                       startRadius: startRadius,
                       endRadius: endRadius)
    }

    /// A radial gradient defined by a collection of color stops.
    ///
    /// The gradient applies the color function as the distance from a center
    /// point, scaled to fit within the defined start and end radii. The
    /// gradient maps the unit space center point into the bounding rectangle of
    /// each shape filled with the gradient.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func radialGradient(stops: [Gradient.Stop],
                                      center: UnitPoint,
                                      startRadius: CGFloat,
                                      endRadius: CGFloat) -> RadialGradient {
        RadialGradient(stops: stops,
                       center: center,
                       startRadius: startRadius,
                       endRadius: endRadius)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == _AnyRadialGradient {
    /// A radial gradient.
    ///
    /// The gradient applies the color function as the distance from a
    /// center point, scaled to fit within the defined start and end
    /// radii. The gradient maps the unit space center point into the
    /// bounding rectangle of each shape filled with the gradient.
    ///
    /// For example, a radial gradient used as a background:
    ///
    ///     ContentView()
    ///         .background(.radialGradient(.red.gradient, endRadius: 100))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func radialGradient(_ gradient: AnyGradient,
                                      center: UnitPoint = .center,
                                      startRadius: CGFloat = 0,
                                      endRadius: CGFloat) -> _AnyRadialGradient {
        _AnyRadialGradient(gradient: gradient,
                           center: center,
                           startRadius: startRadius,
                           endRadius: endRadius)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == AngularGradient {

    /// An angular gradient, which applies the color function as the angle
    /// changes between the start and end angles, and anchored to a relative
    /// center point within the filled shape.
    ///
    /// An angular gradient is also known as a "conic" gradient. If
    /// `endAngle - startAngle > 2π`, the gradient only draws the last complete
    /// turn. If `endAngle - startAngle < 2π`, the gradient fills the missing
    /// area with the colors defined by gradient stop locations at `0` and `1`,
    /// transitioning between the two halfway across the missing area.
    ///
    /// For example, an angular gradient used as a background:
    ///
    ///     let gradient = Gradient(colors: [.red, .yellow])
    ///
    ///     ContentView()
    ///         .background(.angularGradient(gradient))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    ///
    /// - Parameters:
    ///   - gradient: The gradient to use for filling the shape, providing the
    ///     colors and their relative stop locations.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - startAngle: The angle that marks the beginning of the gradient.
    ///   - endAngle: The angle that marks the end of the gradient.
    @_alwaysEmitIntoClient
    public static func angularGradient(_ gradient: Gradient,
                                       center: UnitPoint,
                                       startAngle: Angle,
                                       endAngle: Angle) -> AngularGradient {
        AngularGradient(gradient: gradient,
                        center: center,
                        startAngle: startAngle,
                        endAngle: endAngle)
    }

    /// An angular gradient defined by a collection of colors.
    ///
    /// For more information on how to use angular gradients, see
    /// ``ShapeStyle/angularGradient(_:center:startAngle:endAngle:)-h0q0``.
    ///
    /// - Parameters:
    ///   - colors: The colors of the gradient, evenly spaced along its full
    ///     length.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - startAngle: The angle that marks the beginning of the gradient.
    ///   - endAngle: The angle that marks the end of the gradient.
    @_alwaysEmitIntoClient
    public static func angularGradient(colors: [Color],
                                       center: UnitPoint,
                                       startAngle: Angle,
                                       endAngle: Angle) -> AngularGradient {
        AngularGradient(colors: colors,
                        center: center, 
                        startAngle: startAngle,
                        endAngle: endAngle)
    }

    /// An angular gradient defined by a collection of color stops.
    ///
    /// For more information on how to use angular gradients, see
    /// ``ShapeStyle/angularGradient(_:center:startAngle:endAngle:)-h0q0``.
    ///
    /// - Parameters:
    ///   - stops: The color stops of the gradient, defining each component
    ///     color and their relative location along the gradient's full length.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - startAngle: The angle that marks the beginning of the gradient.
    ///   - endAngle: The angle that marks the end of the gradient.
    @_alwaysEmitIntoClient
    public static func angularGradient(stops: [Gradient.Stop],
                                       center: UnitPoint,
                                       startAngle: Angle,
                                       endAngle: Angle) -> AngularGradient {
        AngularGradient(stops: stops,
                        center: center,
                        startAngle: startAngle,
                        endAngle: endAngle)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == AngularGradient {

    /// A conic gradient that completes a full turn, optionally starting from
    /// a given angle and anchored to a relative center point within the filled
    /// shape.
    ///
    /// For example, a conic gradient used as a background:
    ///
    ///     let gradient = Gradient(colors: [.red, .yellow])
    ///
    ///     ContentView()
    ///         .background(.conicGradient(gradient))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    ///
    /// - Parameters:
    ///   - gradient: The gradient to use for filling the shape, providing the
    ///     colors and their relative stop locations.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - angle: The angle to offset the beginning of the gradient's full
    ///     turn.
    @_alwaysEmitIntoClient
    public static func conicGradient(_ gradient: Gradient,
                                     center: UnitPoint,
                                     angle: Angle = .zero) -> AngularGradient {
        AngularGradient(gradient: gradient,
                        center: center,
                        angle: angle)
    }

    /// A conic gradient defined by a collection of colors that completes a full
    /// turn.
    ///
    /// For more information on how to use angular gradients, see
    /// ``ShapeStyle/conicGradient(_:center:angle:)-2adxx``.
    ///
    /// - Parameters:
    ///   - colors: The colors of the gradient, evenly spaced along its full
    ///     length.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - angle: The angle to offset the beginning of the gradient's full
    ///     turn.
    @_alwaysEmitIntoClient
    public static func conicGradient(colors: [Color],
                                     center: UnitPoint,
                                     angle: Angle = .zero) -> AngularGradient {
        AngularGradient(colors: colors,
                        center: center,
                        angle: angle)
    }

    /// A conic gradient defined by a collection of color stops that completes a
    /// full turn.
    ///
    /// For more information on how to use angular gradients, see
    /// ``ShapeStyle/conicGradient(_:center:angle:)-2adxx``.
    ///
    /// - Parameters:
    ///   - stops: The color stops of the gradient, defining each component
    ///     color and their relative location along the gradient's full length.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - angle: The angle to offset the beginning of the gradient's full
    ///     turn.
    @_alwaysEmitIntoClient
    public static func conicGradient(stops: [Gradient.Stop],
                                     center: UnitPoint,
                                     angle: Angle = .zero) -> AngularGradient {
        AngularGradient(stops: stops,
                        center: center,
                        angle: angle)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == EllipticalGradient {
    
    /// A radial gradient that draws an ellipse.
    ///
    /// The gradient maps its coordinate space to the unit space square
    /// in which its center and radii are defined, then stretches that
    /// square to fill its bounding rect, possibly also stretching the
    /// circular gradient to have elliptical contours.
    ///
    /// For example, an elliptical gradient used as a background:
    ///
    ///     let gradient = Gradient(colors: [.red, .yellow])
    ///
    ///     ContentView()
    ///         .background(.ellipticalGradient(gradient))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func ellipticalGradient(_ gradient: Gradient,
                                          center: UnitPoint = .center, startRadiusFraction: CGFloat = 0, 
                                          endRadiusFraction: CGFloat = 0.5) -> EllipticalGradient {
        .init(
            gradient: gradient, center: center,
            startRadiusFraction: startRadiusFraction,
            endRadiusFraction: endRadiusFraction)
    }
    
    
    /// A radial gradient that draws an ellipse defined by a collection of
    /// colors.
    ///
    /// The gradient maps its coordinate space to the unit space square
    /// in which its center and radii are defined, then stretches that
    /// square to fill its bounding rect, possibly also stretching the
    /// circular gradient to have elliptical contours.
    ///
    /// For example, an elliptical gradient used as a background:
    ///
    ///     .background(.elliptical(colors: [.red, .yellow]))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func ellipticalGradient(colors: [Color],
                                          center: UnitPoint = .center, 
                                          startRadiusFraction: CGFloat = 0,
                                          endRadiusFraction: CGFloat = 0.5) -> EllipticalGradient {
        .init(
            colors: colors, center: center,
            startRadiusFraction: startRadiusFraction,
            endRadiusFraction: endRadiusFraction)
    }
    
    
    /// A radial gradient that draws an ellipse defined by a collection of
    /// color stops.
    ///
    /// The gradient maps its coordinate space to the unit space square
    /// in which its center and radii are defined, then stretches that
    /// square to fill its bounding rect, possibly also stretching the
    /// circular gradient to have elliptical contours.
    ///
    /// For example, an elliptical gradient used as a background:
    ///
    ///     .background(.ellipticalGradient(stops: [
    ///         .init(color: .red, location: 0.0),
    ///         .init(color: .yellow, location: 0.9),
    ///         .init(color: .yellow, location: 1.0),
    ///     ]))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func ellipticalGradient(stops: [Gradient.Stop],
                                          center: UnitPoint = .center, 
                                          startRadiusFraction: CGFloat = 0, 
                                          endRadiusFraction: CGFloat = 0.5) -> EllipticalGradient {
        .init(
            stops: stops, center: center,
            startRadiusFraction: startRadiusFraction,
            endRadiusFraction: endRadiusFraction)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == _AnyEllipticalGradient {
    
    /// A radial gradient that draws an ellipse.
    ///
    /// The gradient maps its coordinate space to the unit space square
    /// in which its center and radii are defined, then stretches that
    /// square to fill its bounding rect, possibly also stretching the
    /// circular gradient to have elliptical contours.
    ///
    /// For example, an elliptical gradient used as a background:
    ///
    ///     ContentView()
    ///         .background(.ellipticalGradient(.red.gradient))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static func ellipticalGradient(_ gradient: AnyGradient,
                                          center: UnitPoint = .center,
                                          startRadiusFraction: CGFloat = 0,
                                          endRadiusFraction: CGFloat = 0.5) -> _AnyEllipticalGradient {
        _AnyEllipticalGradient(gradient: gradient,
                               center: center,
                               startRadiusFraction: startRadiusFraction,
                               endRadiusFraction: endRadiusFraction)
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == _AnyAngularGradient {
    /// An angular gradient, which applies the color function as the
    /// angle changes between the start and end angles, and anchored to
    /// a relative center point within the filled shape.
    ///
    /// An angular gradient is also known as a "conic" gradient. If
    /// `endAngle - startAngle > 2π`, the gradient only draws the last complete
    /// turn. If `endAngle - startAngle < 2π`, the gradient fills the missing
    /// area with the colors defined by gradient stop locations at `0` and `1`,
    /// transitioning between the two halfway across the missing area.
    ///
    /// For example, an angular gradient used as a background:
    ///
    ///     ContentView()
    ///         .background(.angularGradient(.red.gradient))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    ///
    /// - Parameters:
    ///   - gradient: The gradient to use for filling the shape, providing the
    ///     colors and their relative stop locations.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - startAngle: The angle that marks the beginning of the gradient.
    ///   - endAngle: The angle that marks the end of the gradient.
    @_alwaysEmitIntoClient
    public static func angularGradient(_ gradient: AnyGradient,
                                       center: UnitPoint = .center,
                                       startAngle: Angle,
                                       endAngle: Angle) -> _AnyAngularGradient {
            _AnyAngularGradient(gradient: gradient,
                                center: center,
                                startAngle: startAngle,
                                endAngle: endAngle)
    }
    
    /// A conic gradient that completes a full turn, optionally starting from
    /// a given angle and anchored to a relative center point within the filled
    /// shape.
    ///
    /// For example, a conic gradient used as a background:
    ///
    ///     let gradient = Gradient(colors: [.red, .yellow])
    ///
    ///     ContentView()
    ///         .background(.conicGradient(gradient))
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    ///
    /// - Parameters:
    ///   - gradient: The gradient to use for filling the shape, providing the
    ///     colors and their relative stop locations.
    ///   - center: The relative center of the gradient, mapped from the unit
    ///     space into the bounding rectangle of the filled shape.
    ///   - angle: The angle to offset the beginning of the gradient's full
    ///     turn.
    @_alwaysEmitIntoClient
    public static func conicGradient(_ gradient: AnyGradient,
                                     center: UnitPoint = .center,
                                     angle: Angle = .zero) -> _AnyAngularGradient {
        _AnyAngularGradient(gradient: gradient,
                            center: center,
                            startAngle: angle,
                            endAngle: angle + .radians(2 * Double.pi))
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == HierarchicalShapeStyle {

    /// A shape style that maps to the first level of the current content style.
    ///
    /// This hierarchical style maps to the first level of the current
    /// foreground style, or to the first level of the default foreground style
    /// if you haven't set a foreground style in the view's environment. You
    /// typically set a foreground style by supplying a non-hierarchical style
    /// to the ``View/foregroundStyle(_:)`` modifier.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static var primary: HierarchicalShapeStyle {
        .primary
    }

    /// A shape style that maps to the second level of the current content style.
    ///
    /// This hierarchical style maps to the second level of the current
    /// foreground style, or to the second level of the default foreground style
    /// if you haven't set a foreground style in the view's environment. You
    /// typically set a foreground style by supplying a non-hierarchical style
    /// to the ``View/foregroundStyle(_:)`` modifier.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static var secondary: HierarchicalShapeStyle {
        .secondary
    }

    /// A shape style that maps to the third level of the current content
    /// style.
    ///
    /// This hierarchical style maps to the third level of the current
    /// foreground style, or to the third level of the default foreground style
    /// if you haven't set a foreground style in the view's environment. You
    /// typically set a foreground style by supplying a non-hierarchical style
    /// to the ``View/foregroundStyle(_:)`` modifier.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static var tertiary: HierarchicalShapeStyle {
        .tertiary
    }

    /// A shape style that maps to the fourth level of the current content
    /// style.
    ///
    /// This hierarchical style maps to the fourth level of the current
    /// foreground style, or to the fourth level of the default foreground style
    /// if you haven't set a foreground style in the view's environment. You
    /// typically set a foreground style by supplying a non-hierarchical style
    /// to the ``View/foregroundStyle(_:)`` modifier.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``.
    @_alwaysEmitIntoClient
    public static var quaternary: HierarchicalShapeStyle {
        .quaternary
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == ForegroundStyle {
    
    /// The foreground style in the current context.
    ///
    /// Access this value to get the style DanceUI uses for foreground elements,
    /// like text, symbols, and shapes, in the current context. Use the
    /// ``View/foregroundStyle(_:)`` modifier to set a new foreground style for
    /// a given view and its child views.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle`
    @_alwaysEmitIntoClient
    public static var foreground: ForegroundStyle {
        ForegroundStyle()
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == BackgroundStyle {
    
    /// The background style in the current context.
    ///
    /// Access this value to get the style DanceUI uses for the background
    /// in the current context. The specific color that DanceUI renders depends
    /// on factors like the platform and whether the user has turned on Dark
    /// Mode.
    ///
    /// For information about how to use shape styles, see ``ShapeStyle``
    @_alwaysEmitIntoClient
    public static var background: BackgroundStyle {
        BackgroundStyle()
    }
}
