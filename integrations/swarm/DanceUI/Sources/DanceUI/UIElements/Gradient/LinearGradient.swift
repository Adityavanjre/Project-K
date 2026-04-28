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
public struct LinearGradient: Paint, View {
    
    public typealias Body = _ShapeView<Rectangle, LinearGradient>
    
    internal var gradient: Gradient

    internal var startPoint: UnitPoint
    
    internal var endPoint: UnitPoint
    
    /// Creates a linear gradient from a base gradient.
    public init(gradient: Gradient, startPoint: UnitPoint, endPoint: UnitPoint) {
        self.gradient = gradient
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    /// Creates a linear gradient from a collection of colors.
    public init(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) {
        self.init(gradient: .init(colors: colors), startPoint: startPoint, endPoint: endPoint)
    }

    /// Creates a linear gradient from a collection of color stops.
    public init(stops: [Gradient.Stop], startPoint: UnitPoint, endPoint: UnitPoint) {
        self.init(gradient: .init(stops: stops), startPoint: startPoint, endPoint: endPoint)
    }
    
    @_spi(DanceUICompose)
    public func resolvePaint(in environment: EnvironmentValues) -> _Paint {
        _Paint(gradient: self.gradient.resolve(in: environment),
               startPoint: self.startPoint,
               endPoint: self.endPoint)
    }
    
    @_spi(DanceUICompose)
    public struct _Paint: ResolvedPaint {
        
        public typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>
        
        internal var gradient: ResolvedGradient
        
        @ProxyCodable
        internal var startPoint: UnitPoint
        
        @ProxyCodable
        internal var endPoint: UnitPoint
        
        internal init(gradient: ResolvedGradient, startPoint: UnitPoint, endPoint: UnitPoint) {
            self.gradient = gradient
            self.startPoint = startPoint
            self.endPoint = endPoint
        }
        
        @_spi(DanceUICompose)
        public var animatableData: AnimatableData {
            
            set {
                startPoint.animatableData = newValue.first
                endPoint.animatableData = newValue.second
            }
            
            get {
                AnimatablePair(startPoint.animatableData, endPoint.animatableData)
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
            
            let startPointValue = CGPoint(x: startPoint.x * width + x, y: startPoint.y * height + y)
            
            let endPointValue = CGPoint(x: endPoint.x * width + x, y: endPoint.y * height + y)
            
            context.fill(path,
                         with: .gradient((self.gradient,
                                            .axial((startPointValue, endPointValue)),
                                            .linearColor)),
                         style: style)
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
        public static func == (lhs: _Paint, rhs: _Paint) -> Bool {
            return lhs.gradient == rhs.gradient &&
                lhs.startPoint == rhs.startPoint &&
                lhs.endPoint == rhs.endPoint
        }
        
        
        
        fileprivate enum CodingKeys: Hashable, CodingKey {
            
            case gradient
            
            case startPoint
            
            case endPoint
        }
    }
}
