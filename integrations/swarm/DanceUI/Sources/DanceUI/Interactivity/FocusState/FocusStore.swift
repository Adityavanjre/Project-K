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
internal struct FocusStore: Equatable {

    internal var version: DisplayList.Version

    internal var focusedResponders: ContiguousArray<ResponderNode>

    private var plists: [ObjectIdentifier : PropertyList]
    
    @inlinable
    internal init() {
        version = .zero
        focusedResponders = ContiguousArray()
        plists = Dictionary()
    }
    
    @inlinable
    internal static func == (lhs: FocusStore, rhs: FocusStore) -> Bool {
        lhs.version == rhs.version
    }
    
    @inlinable
    internal func plist(forObject object: AnyObject) -> PropertyList? {
        return plist(forObjectID: ObjectIdentifier(object))
    }
    
    @inlinable
    internal func plist(forObjectID objectID: ObjectIdentifier) -> PropertyList? {
        return plists[objectID]
    }
    
    @inlinable
    internal mutating func setPlist(_ plist: PropertyList, forObject object: AnyObject) {
        setPlist(plist, forObjectID: ObjectIdentifier(object))
    }
    
    @inlinable
    internal mutating func setPlist(_ plist: PropertyList, forObjectID objectID: ObjectIdentifier) {
        plists[objectID] = plist
    }
    
    internal struct Entry<Value: Hashable> {

        internal var prototype: Value

        /// `FocusState.Binding` holds a strong reference to the `FocusStoreLocation`.
        /// This entry also get held by the same `FocusStoreLocation`. Thus there is
        /// a retain-cycle between them. We use `FocusState.WeakBinding` to break this
        /// retain-cycle.
        internal var _binding: FocusState<Value>.WeakBinding

        internal var responder: ResponderNode

        internal weak var bridge: FocusBridge?

        internal var focusScopes: [Namespace.ID]

        @inlinable
        internal var binding: FocusState<Value>.Binding? {
            return _binding.makeStrong()
        }
        
        @inlinable
        internal init(prototype: Value,
                      binding: FocusState<Value>.Binding,
                      responder: ResponderNode,
                      bridge: FocusBridge?,
                      focusScopes: [Namespace.ID]) {
            self.prototype = prototype
            self._binding = binding.makeWeak()
            self.responder = responder
            self.bridge = bridge
            self.focusScopes = focusScopes
        }

    }

    internal struct Key<EntryValue: Hashable>: PropertyKey {
        
        internal typealias Value = FocusStore.Entry<EntryValue>?
        
        internal static var defaultValue: Value {
            nil
        }
        
    }
    
}

@available(iOS 13.0, *)
// Probably related to FocusedValue/FocusedValues
internal struct FocusBindingUpdateAction {

    internal let update: () -> Void
    
    @inlinable
    internal init<A: Hashable>(binding: FocusState<A>.Binding, prototype: A) {
        update = {
            binding.wrappedValue = prototype
        }
    }

}

@available(iOS 13.0, *)
internal struct FocusStoreUpdateAction {
    
    internal let update: (inout PropertyList) -> Void
    
    @inlinable
    internal init<A: Hashable>(binding: FocusState<A>.Binding,
                               prototype: A,
                               responder: ResponderNode,
                               bridge: FocusBridge?,
                               focusScopes: [Namespace.ID]) {
        update = { plist in
            plist[FocusStore.Key.self] = FocusStore.Entry(prototype: prototype,
                                                          binding: binding,
                                                          responder: responder,
                                                          bridge: bridge,
                                                          focusScopes: focusScopes)
        }
    }

}

@available(iOS 13.0, *)
internal struct FocusGroupID: Hashable {

    internal var base: Int

}
