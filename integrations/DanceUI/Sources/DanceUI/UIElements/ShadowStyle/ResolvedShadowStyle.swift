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

@_spi(DanceUICompose)
public struct ResolvedShadowStyle: Animatable, Equatable {
    
    public typealias AnimatableData = AnimatablePair<AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, Float>>>, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>>
    
    internal var color: Color.Resolved
    
    internal var radius: CGFloat
    
    internal var offset: CGSize
    
    public var animatableData: AnimatableData {
        get {
            AnimatableData(color.animatableData,
                           AnimatablePair(radius * 128.0,
                                          AnimatablePair(offset.width * 128.0,
                                                         offset.height * 128.0)))
        }
        
        set {
            color.animatableData = newValue.first
            radius = newValue.second.first / 128.0
            offset = CGSize(width: newValue.second.second.first / 128.0,
                            height: newValue.second.second.second / 128.0)
        }
    }
}

@available(iOS 13.0, *)
extension CALayer {
    
    internal func updateShadowStyle(style: ResolvedShadowStyle?) {
        if let shadowStyle = style {
            shadowOffset = shadowStyle.offset
            shadowRadius = shadowStyle.radius
            shadowOpacity = 1.0
            shadowColor = shadowStyle.color.cgColor
        } else {
            shadowOpacity = 0
        }
    }
}
