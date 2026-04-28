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
internal struct GeometryEffectDisplayList<Effect: GeometryEffect>: Rule {
    
    internal typealias Value = DisplayList
    
    @Attribute
    internal var effect: Effect

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var layoutDirection: LayoutDirection

    @Attribute
    internal var containerPosition: ViewOrigin

    @OptionalAttribute
    internal var content: DisplayList?

    internal let identity: DisplayList.Identity
    
    internal var value: DisplayList {
        let size = self.size.value
        var transformValue = effect.effectValue(size: size)
        
        if layoutDirection == .rightToLeft {
            let t = ProjectionTransform(
                m11: -1, m12: 0, m13: 0,
                m21: 0, m22: 1, m23: 0,
                m31: size.width, m32: 0, m33: 1
            )
            let transform = t.concatenating(transformValue)
            transformValue = transform.concatenating(t)
        }
        
        let isInvertible = transformValue.isInvertible
        
        let displayListEffect: DisplayList.Effect
        var origin = CGPoint(x: position.value.x - containerPosition.value.x,
                             y: position.value.y - containerPosition.value.y)
        if !isInvertible {
            runtimeIssue(type: .warning, "ignoring singular matrix: %@", "\(transformValue)")
            displayListEffect = .identity
        } else if !transformValue.isAffine {
            displayListEffect = .projection(transformValue)
        } else {
            let caTransform = transformValue.affineTransformValue
            if caTransform.isTranslation {
                displayListEffect = .identity
                origin = origin.addPoint(CGPoint(x: caTransform.tx, y: caTransform.ty))
            } else {
                displayListEffect = .affine(caTransform)
            }
        }
        
        let displayList = content ?? .empty
        
        guard !displayList.items.isEmpty else {
            return displayList
        }
        
        var item = DisplayList.Item(frame: CGRect(origin: origin, size: size),
                                    version: .make(),
                                    value: .effect(displayListEffect, displayList),
                                    identity: identity)
        item.canonicalize()
        
        return DisplayList(item: item)
    }
}
