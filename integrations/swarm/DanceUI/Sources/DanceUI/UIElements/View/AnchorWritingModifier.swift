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
internal import DanceUIGraph

@usableFromInline
@available(iOS 13.0, *)
internal struct _AnchorWritingModifier<AnchorValue, Key>: PrimitiveViewModifier, MultiViewModifier where Key: PreferenceKey {
    
    @usableFromInline
    internal typealias Body = Never
    
    internal var anchor: Anchor<AnchorValue>.Source
    
    internal var transform: (Anchor<AnchorValue>) -> Key.Value
    
    @usableFromInline
    internal init(anchor: Anchor<AnchorValue>.Source, transform: @escaping (Anchor<AnchorValue>) -> Key.Value) {
        self.anchor = anchor
        self.transform = transform
    }
    
    @usableFromInline
    internal static func _makeView(modifier: _GraphValue<_AnchorWritingModifier<AnchorValue, Key>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let animatedPosition = inputs.animatedPosition
        let animatedSize = inputs.animatedSize
        
        var outputs = body(_Graph(), inputs)
        outputs.preferences.makePreferenceWriter(inputs: inputs.preferences,
                                                 key: Key.self,
                                                 value: Attribute(AnchorWriter(modifier: modifier.value,
                                                                                            position: animatedPosition,
                                                                                            size: animatedSize,
                                                                                            transform: inputs.transform)))
        return outputs
    }
}

@available(iOS 13.0, *)
fileprivate struct AnchorWriter<AnchorValue, Key: PreferenceKey>: Rule  {
    
    @Attribute
    internal var modifier: _AnchorWritingModifier<AnchorValue, Key>
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var transform: ViewTransform
    
    internal static var initialValue: Value? {
        nil
    }
    
    internal var value: Key.Value {
        let translationWidth = position.value.x - transform.positionAdjustment.width
        let translationHeight = position.value.y - transform.positionAdjustment.height
        
        var newTransform = transform
        if translationWidth != 0 || translationHeight != 0 {
            newTransform.appendTranslation(.init(width: -translationWidth, height: -translationHeight))
        }
        
        newTransform.positionAdjustment = .init(width: position.value.x, height: position.value.y)
        let anchor = modifier.anchor.prepare(size: size.value, transform: newTransform)
        
        let output = modifier.transform(anchor)
        return output
    }
    
}
