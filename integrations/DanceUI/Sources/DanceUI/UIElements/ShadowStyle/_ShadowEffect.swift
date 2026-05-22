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
public struct _ShadowEffect: EnvironmentalModifier, Equatable {
    
    public typealias ResolvedModifier = _Resolved
    
    // 0x00
    public var color: Color
    
    // 0x08
    public var radius: CGFloat
    
    // 0x10
    public var offset: CGSize
    
    @inlinable
    public init(color: Color, radius: CGFloat, offset: CGSize) {
        self.color = color
        self.radius = radius
        self.offset = offset
    }
    
    public func resolve(in environment: EnvironmentValues) -> _Resolved {
        _Resolved(style: ResolvedShadowStyle(color: color.resolvePaint(in: environment),
                                             radius: radius,
                                             offset: offset))
    }
    
    public struct _Resolved: RendererEffect {
        
        public typealias AnimatableData = AnimatablePair<AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, Float>>>, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>>
        
        internal var style: ResolvedShadowStyle
        
        public var animatableData: AnimatableData {
            
            get {
                style.animatableData
            }
            
            set {
                style.animatableData = newValue
            }
        }
        
        internal func effectValue(size: CGSize) -> DisplayList.Effect {
            .filter(.shadow(style))
        }
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Adds a shadow to this view.
    /// - Parameters:
    ///   - color: The shadow's color.
    ///   - radius: The shadow's size.
    ///   - x: A horizontal offset you use to position the shadow relative to
    ///     this view.
    ///   - y: A vertical offset you use to position the shadow relative to this
    ///     view.
    ///
    /// - Returns: A view that adds a shadow to this view.
    @inlinable
    public func shadow(color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33),
                       radius: CGFloat,
                       x: CGFloat = 0,
                       y: CGFloat = 0) -> some View {
        modifier(_ShadowEffect(color: color,
                               radius: radius,
                               offset: CGSize(width: x, height: y)))
    }
}
