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
internal struct FocusStoreListModifier<A: Hashable>: MultiViewModifier, PrimitiveViewModifier {
    
    internal let binding: FocusState<A>.Binding

    internal let prototype: A

    internal let responder: ResponderNode
    
    internal static func _makeView(modifier: _GraphValue<FocusStoreListModifier<A>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let filter = ItemFilter(modifier: modifier.value,
                                focusItem: inputs.focusedItem.attribute!,
                                focusBridge: inputs.environmentAttribute(keyPath: \.focusBridge),
                                focusScopes: inputs.environmentAttribute(keyPath: \.focusScopes),
                                isFocused: false)
        let filteredList = Attribute(filter)
        
        let listTransform = Attribute(ListTransform(list: filteredList))
        
        var outputs = body(_Graph(), inputs)
        
        outputs.makePreferenceTransformer(inputs: inputs, key: FocusStoreList.Key.self, transform: listTransform)
        
        return outputs
    }
    
    internal struct ItemFilter: StatefulRule {
        
        internal typealias Value = FocusStoreList
        
        @Attribute
        internal var modifier: FocusStoreListModifier<A>

        @Attribute
        internal var focusItem: FocusItem?

        @Attribute
        internal var focusBridge: FocusBridge?

        @Attribute
        internal var focusScopes: [Namespace.ID]

        internal var isFocused: Bool
        
        @inline(__always)
        private var shouldFocus: Bool {
            guard let focusItem = focusItem else {
                return false
            }
            
            if let focusItemResponder = focusItem.responder {
                return focusItemResponder.isDescendant(of: modifier.responder)
            } else {
                return false
            }
        }
        
        internal mutating func updateValue() {
            let (focusBridge, isFocusBridgeChanged) = self.$focusBridge.changedValue()
            let (focusScopes, isFocusScopesChanged) = self.$focusScopes.changedValue()
            
            let shouldFocus = self.shouldFocus
            
            let shouldUpdate: Bool
            
            if shouldFocus != isFocused {
                isFocused = shouldFocus
                shouldUpdate = true
            } else {
                shouldUpdate = isFocusBridgeChanged || isFocusScopesChanged || !hasValue
            }
            
            guard shouldUpdate else {
                return
            }
            
            let modifier = self.modifier
            
            let bindingUpdateAction = FocusBindingUpdateAction(binding: modifier.binding,
                                                               prototype: modifier.prototype)
            
            let storeUpdateAction = FocusStoreUpdateAction(binding: modifier.binding,
                                                           prototype: modifier.prototype,
                                                           responder: modifier.responder,
                                                           bridge: focusBridge,
                                                           focusScopes: focusScopes)
            
            let item = FocusStoreList.Item(version: .make(),
                                           propertyID: modifier.binding.propertyID,
                                           bindingUpdateAction: bindingUpdateAction,
                                           storeUpdateAction: storeUpdateAction,
                                           responder: modifier.responder,
                                           bridge: focusBridge,
                                           isFocused: isFocused)
            
            value = FocusStoreList(item: item)
        }
        
    }

    internal struct ListTransform: Rule {
        
        internal typealias Value = (inout FocusStoreList) -> ()

        @Attribute
        internal var list: FocusStoreList

        internal var value: Value {
            let listCopy = self.list
            return { list in
                list.append(contentsOf: listCopy.items)
            }
        }

    }
    
}
