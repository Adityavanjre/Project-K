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
public struct RadialGradient: Paint, View {
    
    public typealias Body = _ShapeView<Rectangle, RadialGradient>
    
    internal var gradient: Gradient
    
    internal var center: UnitPoint
    
    internal var startRadius: CGFloat
    
    internal var endRadius: CGFloat
    
    /// Creates a radial gradient from a base gradient.
    public init(gradient: Gradient, center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat) {
        self.gradient = gradient
        self.center = center
        self.startRadius = startRadius
        self.endRadius = endRadius
    }
    
    /// Creates a radial gradient from a collection of colors.
    public init(colors: [Color], center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat){
        self.init(gradient: .init(colors: colors), center: center, startRadius: startRadius, endRadius: endRadius)
    }
    
    /// Creates a radial gradient from a collection of color stops.
    public init(stops: [Gradient.Stop], center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat) {
        self.init(gradient: .init(stops: stops), center: center, startRadius: startRadius, endRadius: endRadius)
    }
    
    @_spi(DanceUICompose)
    public func resolvePaint(in environment: EnvironmentValues) -> _Paint {
        _Paint(gradient: self.gradient.resolve(in: environment),
               center: self.center,
               startRadius: self.startRadius,
               endRadius: self.endRadius)
    }
    
    @_spi(DanceUICompose)
    public struct _Paint: ResolvedPaint {
        
        public typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>
        
        
        internal var gradient: ResolvedGradient
        
        @ProxyCodable
        internal var center: UnitPoint
        
        internal var startRadius: CGFloat
        
        internal var endRadius: CGFloat
        
        internal init(gradient: ResolvedGradient, center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat) {
            self.gradient = gradient
            self.center = center
            self.startRadius = startRadius
            self.endRadius = endRadius
        }
                
        @_spi(DanceUICompose)
        public mutating func setUsePerceptualBlending(_ usePerceptualBlending: Bool) {
            self.gradient.usePerceptualBlending = usePerceptualBlending
        }

        public static func == (lhs: RadialGradient._Paint, rhs: RadialGradient._Paint) -> Bool {
            lhs.gradient == rhs.gradient &&
            lhs.center == rhs.center &&
            lhs.startRadius == rhs.startRadius &&
            lhs.endRadius == rhs.endRadius
        }
        
        public var animatableData: AnimatableData {
            set {
                self.center.animatableData = newValue.first
                self.startRadius = newValue.second.first
                self.endRadius = newValue.second.second
            }
            
            get {
                AnimatableData(center.animatableData, .init(startRadius, endRadius))
            }
        }
        
        @_spi(DanceUICompose)
        public func fill(_ path: Path, style: FillStyle, in context: GraphicsContext, bounds: CGRect?) {
            
            var paintBounds: CGRect
            
            if let boundsValue = bounds {
                paintBounds = boundsValue
            } else {
                paintBounds = path.boundingRect
            }
            
            let x = paintBounds.origin.x
            
            let y = paintBounds.origin.y
            
            let width = paintBounds.size.width
            
            let height = paintBounds.size.height
            
            let center: CGPoint = .init(x: center.x * width + x, y: center.y * height + y)
            
            context.fill(path,
                         with: .gradient((self.gradient,
                                            .radial((center, startRadius, endRadius)),
                                            .linearColor)),
                         style: style)
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
        public var isOpaque: Bool {
            guard gradient.stops.count > 0 else {
                return false
            }
            
            let result = gradient.stops.first {
                $0.color.opacity != 1
            }
            
            return result == nil
        }
        
        
        fileprivate enum CodingKeys: Hashable, CodingKey {
            case gradient
            
            case center
            
            case startRadius
            
            case endRadius
        }
    }
}
