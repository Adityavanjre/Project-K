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

/// A radial gradient that draws an ellipse.
///
/// The gradient maps its coordinate space to the unit space square
/// in which its center and radii are defined, then stretches that
/// square to fill its bounding rect, possibly also stretching the
/// circular gradient to have elliptical contours.
///
/// For example, an elliptical gradient centered on the view, filling
/// its bounds:
///
///     EllipticalGradient(gradient: .init(colors: [.red, .yellow]))
///
/// When using an elliptical gradient as a shape style, you can also use
/// ``ShapeStyle/ellipticalGradient(colors:center:startRadiusFraction:endRadiusFraction:)``.
@available(iOS 13.0, *)
@frozen
public struct EllipticalGradient: Paint, View {

    public typealias Body = _ShapeView<Rectangle, EllipticalGradient>

    internal var gradient: Gradient

    internal var center: UnitPoint

    internal var startRadiusFraction: CGFloat

    internal var endRadiusFraction: CGFloat

    /// Creates an elliptical gradient.
    ///
    /// For example, an elliptical gradient centered on the top-leading
    /// corner of the view:
    ///
    ///     EllipticalGradient(
    ///         gradient: .init(colors: [.blue, .green]),
    ///         center: .topLeading,
    ///         startRadiusFraction: 0,
    ///         endRadiusFraction: 1)
    ///
    /// - Parameters:
    ///  - gradient: The colors and their parametric locations.
    ///  - center: The center of the circle, in [0, 1] coordinates.
    ///  - startRadiusFraction: The start radius value, as a fraction
    ///    between zero and one. Zero maps to the center point, one
    ///    maps to the diameter of the unit circle.
    ///  - endRadiusFraction: The end radius value, as a fraction
    ///    between zero and one. Zero maps to the center point, one
    ///    maps to the diameter of the unit circle.
    public init(gradient: Gradient,
                center: UnitPoint = .center,
                startRadiusFraction: CGFloat = 0,
                endRadiusFraction: CGFloat = 0.5) {
        self.gradient = gradient
        self.center = center
        self.startRadiusFraction = startRadiusFraction
        self.endRadiusFraction = endRadiusFraction
    }
    
    /// Creates an elliptical gradient from a collection of colors.
    ///
    /// For example, an elliptical gradient centered on the top-leading
    /// corner of the view:
    ///
    ///     EllipticalGradient(
    ///         colors: [.blue, .green],
    ///         center: .topLeading,
    ///         startRadiusFraction: 0,
    ///         endRadiusFraction: 1)
    ///
    /// - Parameters:
    ///  - colors: The colors, evenly distributed throughout the gradient.
    ///  - center: The center of the circle, in [0, 1] coordinates.
    ///  - startRadiusFraction: The start radius value, as a fraction
    ///    between zero and one. Zero maps to the center point, one
    ///    maps to the diameter of the unit circle.
    ///  - endRadiusFraction: The end radius value, as a fraction
    ///    between zero and one. Zero maps to the center point, one
    ///    maps to the diameter of the unit circle.
    public init(colors: [Color],
                center: UnitPoint = .center,
                startRadiusFraction: CGFloat = 0,
                endRadiusFraction: CGFloat = 0.5) {
        self.gradient = .init(colors: colors)
        self.center = center
        self.startRadiusFraction = startRadiusFraction
        self.endRadiusFraction = endRadiusFraction
    }
    
    /// Creates an elliptical gradient from a collection of color stops.
    ///
    /// For example, an elliptical gradient centered on the top-leading
    /// corner of the view, with some extra green area:
    ///
    ///     EllipticalGradient(
    ///         stops: [
    ///             .init(color: .blue, location: 0.0),
    ///             .init(color: .green, location: 0.9),
    ///             .init(color: .green, location: 1.0),
    ///         ],
    ///         center: .topLeading,
    ///         startRadiusFraction: 0,
    ///         endRadiusFraction: 1)
    ///
    /// - Parameters:
    ///  - stops: The colors and their parametric locations.
    ///  - center: The center of the circle, in [0, 1] coordinates.
    ///  - startRadiusFraction: The start radius value, as a fraction
    ///    between zero and one. Zero maps to the center point, one
    ///    maps to the diameter of the unit circle.
    ///  - endRadiusFraction: The end radius value, as a fraction
    ///    between zero and one. Zero maps to the center point, one
    ///    maps to the diameter of the unit circle.
    public init(stops: [Gradient.Stop],
                center: UnitPoint = .center,
                startRadiusFraction: CGFloat = 0,
                endRadiusFraction: CGFloat = 0.5) {
        self.gradient = .init(stops: stops)
        self.center = center
        self.startRadiusFraction = startRadiusFraction
        self.endRadiusFraction = endRadiusFraction
    }

    internal func resolvePaint(in environment: EnvironmentValues) -> _Paint {
        _Paint(gradient: self.gradient.resolve(in: environment),
               center: self.center,
               startRadiusFraction: self.startRadiusFraction,
               endRadiusFraction: self.endRadiusFraction)
    }

    internal struct _Paint: ResolvedPaint {

        internal typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>

        internal var gradient: ResolvedGradient

        @ProxyCodable
        internal var center: UnitPoint

        internal var startRadiusFraction: CGFloat

        internal var endRadiusFraction: CGFloat

        internal var animatableData: AnimatableData {
            get {
                AnimatableData(center.animatableData, AnimatablePair(startRadiusFraction, endRadiusFraction))
            }

            set {
                center.animatableData = newValue.first
                startRadiusFraction = newValue.second.first
                endRadiusFraction = newValue.second.second
            }
        }

        internal func fill(_ path: Path, style: FillStyle, in context: GraphicsContext, bounds: CGRect?) {
            let paintBounds: CGRect
            
            if let boundsValue = bounds {
                paintBounds = boundsValue
            } else {
                paintBounds = path.boundingRect
            }
            
            let newOrigin: CGPoint = .init(x: center.x * paintBounds.width + paintBounds.origin.x, 
                                           y: center.y * paintBounds.height + paintBounds.origin.y)
            let rect: CGRect = .init(origin: newOrigin, size: paintBounds.size)
            context.fill(path,
                         with: .gradient((self.gradient,
                                            .elliptical((rect, startRadiusFraction, endRadiusFraction)),
                                            .linearColor)),
                         style: style)
        }

        internal var isOpaque: Bool {
            guard gradient.stops.count > 0 else {
                return false
            }
            
            let result = gradient.stops.first {
                $0.color.opacity != 1
            }
            
            return result == nil
        }

        internal var isClear: Bool {
            guard gradient.stops.count > 0 else {
                return true
            }
            
            let result = gradient.stops.first {
                $0.color.opacity != 0
            }
            
            return result == nil
        }
    }
}
