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

@frozen
@available(iOS 13.0, *)
public struct _TraitWritingModifier<Key: _ViewTraitKey>: ViewModifier {
    
    public typealias Body = Never
    
    // 0x0
    public let value: Key.Value
    
    @inlinable
    public init(value: Key.Value) {
        self.value = value
    }
    
    public static func _makeView(modifier: _GraphValue<_TraitWritingModifier<Key>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        body(_Graph(), inputs)
    }
    
    public static func _makeViewList(modifier: _GraphValue<_TraitWritingModifier<Key>>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        
        guard Key.self != LayoutPriorityTraitKey.self else {
            var outputs = body(_Graph(), inputs)
            let layoutModifier = _GraphValue(modifier.value.unsafeCast(to: LayoutPriorityLayout.self))
            outputs.multiModifier(layoutModifier, inputs: inputs)
            return outputs
        }
        
        var newInputs = inputs
        newInputs.$traits = .init(AddTrait(modifier: modifier.value, traits: OptionalAttribute(inputs.$traits)))
        newInputs.addTraitKey(Key.self)
        
        return body(_Graph(), newInputs)
    }
    
    

}

@available(iOS 13.0, *)
extension _TraitWritingModifier {
    
    fileprivate struct AddTrait: Rule {
        
        internal typealias Value = ViewTraitCollection
        
        @Attribute
        internal var modifier: _TraitWritingModifier<Key>

        @OptionalAttribute
        internal var traits: ViewTraitCollection?
        
        internal var value: ViewTraitCollection {
            var collection = traits ?? ViewTraitCollection()
            collection[Key.self] = modifier.value
            return collection
        }
    }
    
}
