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

@frozen
@available(iOS 13.0, *)
public struct AngularGradient: Paint, View {
    
    public typealias Body = _ShapeView<Rectangle, AngularGradient>
    
    internal var gradient: Gradient
    
    internal var center: UnitPoint
    
    internal var startAngle: Angle
    
    internal var endAngle: Angle
    
    /// Creates an angular gradient.
    public init(gradient: Gradient, center: UnitPoint, startAngle: Angle = .zero, endAngle: Angle = .zero) {
        self.gradient = gradient
        self.center = center
        self.startAngle = startAngle
        self.endAngle = endAngle
    }
    
    /// Creates an angular gradient from a collection of colors.
    public init(colors: [Color], center: UnitPoint, startAngle: Angle, endAngle: Angle) {
        self.init(gradient: .init(colors: colors), center: center, startAngle: startAngle, endAngle: endAngle)
    }
    
    /// Creates an angular gradient from a collection of color stops.
    public init(stops: [Gradient.Stop], center: UnitPoint, startAngle: Angle, endAngle: Angle) {
        self.init(gradient: .init(stops: stops), center: center, startAngle: startAngle, endAngle: endAngle)
    }
    
    /// Creates a conic gradient that completes a full turn.
    public init(gradient: Gradient, center: UnitPoint, angle: Angle = .zero) {
        self.gradient = gradient
        self.center = center
        self.startAngle = angle
        self.endAngle = .init(radians: angle.radians + 2 * Double.pi)
    }
    
    /// Creates a conic gradient from a collection of colors that completes
    /// a full turn.
    public init(colors: [Color], center: UnitPoint, angle: Angle = .zero) {
        self.init(gradient: .init(colors: colors), center: center, angle: angle)
    }
    
    /// Creates a conic gradient from a collection of color stops that
    /// completes a full turn.
    public init(stops: [Gradient.Stop], center: UnitPoint, angle: Angle = .zero) {
        self.init(gradient: .init(stops: stops), center: center, angle: angle)
    }
    
    @_spi(DanceUICompose)
    public func resolvePaint(in environment: EnvironmentValues) -> _Paint {
        _Paint(gradient: gradient.resolve(in: environment),
               center: center,
               startAngle: startAngle,
               endAngle: endAngle)
    }
    
    @_spi(DanceUICompose)
    public struct _Paint: ResolvedPaint {
        
        public typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<Double, Double>>
        
        internal var gradient: ResolvedGradient
        
        @ProxyCodable
        internal var center: UnitPoint
        
        @ProxyCodable
        internal var startAngle: Angle
        
        @ProxyCodable
        internal var endAngle: Angle
        
        internal init(gradient: ResolvedGradient,
                           center: UnitPoint,
                           startAngle: Angle,
                           endAngle: Angle) {
            self.gradient = gradient
            self.center = center
            self.startAngle = startAngle
            self.endAngle = endAngle
        }
        
        @_spi(DanceUICompose)
        public mutating func setUsePerceptualBlending(_ usePerceptualBlending: Bool) {
            self.gradient.usePerceptualBlending = usePerceptualBlending
        }
        
        @_spi(DanceUICompose)
        public var isOpaque: Bool {
            guard gradient.stops.count > 0 else {
                return false
            }
            
            let result = gradient.stops.first {
                $0.color.opacity != 1
            }
            
            return result == nil
        }
        
        @_spi(DanceUICompose)
        public var isClear: Bool {
            guard gradient.stops.count > 0 else {
                return true
            }
            
            let result = gradient.stops.first {
                $0.color.opacity != 0
            }
            
            return result == nil
        }
        
        @_spi(DanceUICompose)
        public var animatableData: AnimatableData {
            set {
                center.animatableData = newValue.first
                startAngle.animatableData = newValue.second.first
                endAngle.animatableData = newValue.second.second
            }
            
            get {
                AnimatableData(center.animatableData, .init(startAngle.animatableData, endAngle.animatableData))
            }
        }
        
        public static func == (lhs: _Paint, rhs: _Paint) -> Bool {
            lhs.gradient == rhs.gradient &&
            lhs.center == rhs.center &&
            lhs.startAngle == rhs.startAngle &&
            lhs.endAngle == rhs.endAngle
        }
        
        @_spi(DanceUICompose)
        public func fill(_ path: Path, style: FillStyle, in context: GraphicsContext, bounds: CGRect?) {
            
            var paintBounds: CGRect
            
            if let boundsValue = bounds {
                paintBounds = boundsValue
            } else {
                paintBounds = path.boundingRect
            }
            
            let conicGradient = ConicGradient(paint: self, bounds: paintBounds)
            
            context.fill(path,
                         with: .gradient((self.gradient,
                                          .conic((conicGradient.center, conicGradient.angle)),
                                          .linearColor)),
                         style: style)
            
        }
        
        
        fileprivate enum CodingKeys: Hashable, CodingKey {
            case gradient
            
            case center
            
            case startAngle
            
            case endAngle
        }
    }
}
