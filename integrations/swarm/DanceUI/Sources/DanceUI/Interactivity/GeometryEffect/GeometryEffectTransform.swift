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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct GeometryEffectTransform<Effect: GeometryEffect>: Rule {
    
    internal typealias Value = ViewTransform
    
    @Attribute
    internal var effect: Effect

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var transform: ViewTransform

    @Attribute
    internal var layoutDirection: LayoutDirection
    
    internal var value: ViewTransform {
        
        var transform: ViewTransform = self.transform
        
        transform.appendViewOrigin(position)
        
        transform.clearPositionAdjustment()
        
        let viewSize = self.size
        var effectValue = effect.effectValue(size: viewSize.value)
        
        if layoutDirection == .rightToLeft {
            let t = ProjectionTransform(
                m11: -1, m12: 0, m13: 0,
                m21: 0, m22: 1, m23: 1,
                m31: viewSize.value.width, m32: 1, m33: 1
            )
            let transform = t.concatenating(effectValue)
            effectValue = transform.concatenating(t)
        }
        
        transform.appendProjectionTransform(effectValue, inverse: true)
        return transform
    }
    
}
