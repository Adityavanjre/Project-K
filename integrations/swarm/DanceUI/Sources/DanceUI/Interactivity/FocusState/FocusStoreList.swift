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
internal struct FocusStoreList {

    internal private(set) var items: [Item]
    
    @inlinable
    internal init() {
        items = Array()
    }
    
    @inlinable
    internal init(item: Item) {
        self.init(items: [item])
    }
    
    @inlinable
    internal init(items: Array<Item>) {
        self.items = items
    }
    
    @inlinable
    internal mutating func append(_ item: Item) {
        items.append(item)
    }
    
    @inlinable
    internal mutating func append<Items: Sequence>(contentsOf another: Items) where Items.Element == Item {
        items.append(contentsOf: another)
    }
    
    @inlinable
    internal func forEachItem(_ body: (_ item: Item) -> Void) {
        items.forEach(body)
    }
    
    @inlinable
    internal var version: DisplayList.Version {
        items.reduce(.zero) { partialResult, item in
            max(partialResult, item.version)
        }
    }
    
    internal struct Key: HostPreferenceKey {
        
        internal typealias Value = FocusStoreList
        
        internal static var defaultValue: Value {
            FocusStoreList()
        }
        
        internal static func reduce(value: inout Value, nextValue: () -> Value) {
            value.append(contentsOf: nextValue().items)
        }
        
    }

    internal struct Item {

        internal var version: DisplayList.Version

        internal var propertyID: ObjectIdentifier

        internal var bindingUpdateAction: FocusBindingUpdateAction

        internal var storeUpdateAction: FocusStoreUpdateAction

        internal var responder: ResponderNode

        internal var bridge: FocusBridge?

        internal var isFocused: Bool
        
        internal init(version: DisplayList.Version,
                      propertyID: ObjectIdentifier,
                      bindingUpdateAction: FocusBindingUpdateAction,
                      storeUpdateAction: FocusStoreUpdateAction,
                      responder: ResponderNode,
                      bridge: FocusBridge? = nil,
                      isFocused: Bool
        ) {
            self.version = version
            self.propertyID = propertyID
            self.bindingUpdateAction = bindingUpdateAction
            self.storeUpdateAction = storeUpdateAction
            self.responder = responder
            self.bridge = bridge
            self.isFocused = isFocused
        }

    }
}
