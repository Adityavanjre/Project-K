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
public struct _ColorMonochromeEffect: EnvironmentalModifier {
    
    public typealias ResolvedModifier = _Resolved
    
    public var color: Color
    
    public var amount: Double
    
    public var bias: Double
    
    @inlinable
    public init(color: Color,
                  amount: Double = 1,
                  bias: Double = 0) {
        self.color = color
        self.bias = bias
        self.amount = amount
    }
    
    public func resolve(in environment: EnvironmentValues) -> _Resolved {
        _Resolved(color: color.resolvePaint(in: environment),
                  bias: Float(bias),
                  amount: Float(amount))
    }
    
    
    public struct _Resolved: RendererEffect {
        
        public typealias AnimatableData = AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, Float>>>>>
        
        internal var color: Color.Resolved
        
        internal var bias: Float
        
        internal var amount: Float
        
        public var animatableData: AnimatableData {
            get {
                AnimatableData(amount, AnimatablePair(bias, color.animatableData))
            }
            
            set {
                amount = newValue.first
                bias = newValue.second.first
                color.animatableData = newValue.second.second
            }
        }
        
        internal func effectValue(size: CGSize) -> DisplayList.Effect {
            .filter(.colorMonochrome(GraphicsFilter.ColorMonochrome(color: color,
                                                                    amount: amount,
                                                                    bias: bias)))
        }
    }
}

@available(iOS 13.0, *)
extension View {
  
    /// apply ColorMonochrome effect to view
    @inlinable
    public func _colorMonochrome(_ color: Color, amount: Double = 1, bias: Double = 0) -> some View {
        modifier(_ColorMonochromeEffect(color: color, amount: amount, bias: bias))
    }
  
}
