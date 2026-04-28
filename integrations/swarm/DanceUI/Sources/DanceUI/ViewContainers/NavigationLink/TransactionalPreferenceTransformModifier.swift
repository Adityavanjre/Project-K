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

@available(iOS 13.0, *)
internal struct TransactionalPreferenceTransformModifier<Key: PreferenceKey>: PrimitiveViewModifier, MultiViewModifier {
    
    internal typealias Body = Never

    internal var transform: (inout Key.Value, Transaction) -> ()
    
    internal static func _makeView(modifier: _GraphValue<TransactionalPreferenceTransformModifier<Key>>,
                                     inputs: _ViewInputs,
                                     body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let isAnimated = IsAnimated(modifier: modifier.value, transaction: inputs.transaction)
        let animatedAttr = Attribute(isAnimated)
        animatedAttr.flags = .active
        
        var outputs = body(_Graph(), inputs)
        outputs.preferences.makePreferenceTransformer(inputs: inputs.preferences, key: Key.self, transform: animatedAttr)
        
        return outputs
    }

}

@available(iOS 13.0, *)
private struct IsAnimated<Key: PreferenceKey>: StatefulRule {

    @Attribute
    internal var modifier: TransactionalPreferenceTransformModifier<Key>

    @Attribute
    internal var transaction: Transaction

    internal static var initialValue: ((inout Key.Value) -> ())? {
        nil
    }

    internal mutating func updateValue() {
        let (modifier, changed) = _modifier.changedValue()
        guard changed || !self.hasValue else {
            return
        }
        
        let transaction = DGGraphRef.withoutUpdate {
            self.transaction
        }
        
        self.value = { value in
            modifier.transform(&value, transaction)
        }
    }
}

@available(iOS 13.0, *)
extension View {
    
    internal func transactionalPreferenceTransform<Key: PreferenceKey>(key: Key.Type,
                                                                       transform: @escaping (inout Key.Value, Transaction) -> ()) -> some View {
        let modifier = TransactionalPreferenceTransformModifier<Key>(transform: transform)
        return self.modifier(modifier)
    }
    
}
