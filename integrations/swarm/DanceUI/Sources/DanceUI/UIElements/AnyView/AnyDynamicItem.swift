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
internal struct AnyDynamicItem: DynamicContainerItem {

    internal var storage: DynamicStorage
    
    internal var layoutPriority: Double?
    
    internal var zIndex: Double
    
    internal static var supportsReuse: Bool {
        true
    }
    
    internal var needsTransitions: Bool {
        storage.needsTransitions
    }
    
    internal var count: Int {
        1
    }
    
    internal var list: Attribute<ViewList>? {
        nil
    }
    
    internal init<V: View, H: Hashable>(_ content: V, id: H) {
        self.storage = makeStorage(content: content, identifier: id)
        self.layoutPriority = 0
        self.zIndex = 0
    }
    
    internal func canBeReused(by item: AnyDynamicItem) -> Bool {
        matchesIdentity(of: item)
    }

    internal func makeView<A: DynamicContainerAdaptor>(uniqueId: UInt32,
                                                       container: Attribute<DynamicContainer.Info>,
                                                       inputs: _ViewInputs,
                                                       adaptor: A.Type) -> _ViewOutputs where A.Item == AnyDynamicItem {
        storage.makeView(uniqueId: uniqueId, container: container, inputs: inputs, adaptor: adaptor)
    }
    
    internal func matchesIdentity(of item: AnyDynamicItem) -> Bool {
        if storage === item.storage {
            return true
        }
        if item.storage.matchesIdentity(of: storage) {
            return true
        }
        
        return item.needsTransitions == needsTransitions &&
            item.storage.identifier == storage.identifier
    }
    
}

@available(iOS 13.0, *)
private func makeStorage<V: View, H: Hashable>(content: V, identifier: H) -> DynamicStorage {
    _notImplemented()
}

@available(iOS 13.0, *)
fileprivate struct MakeStorageVisitor1<A>: ViewVisitor {

    internal var identifier: A

    internal var storage: DynamicStorage?
    
    internal func visit<V>(_: V) where V : View {
        _notImplemented()
    }

}
