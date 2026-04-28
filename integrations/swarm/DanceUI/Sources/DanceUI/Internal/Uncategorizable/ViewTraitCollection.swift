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

@available(iOS 13.0, *)
internal struct ViewTraitCollection {

    private var storage: [any AnyViewTrait]
    
    @inlinable
    internal init(reservedCapacity: Int? = nil) {
        storage = []
        guard let reservedCapacity = reservedCapacity else {
            return
        }
        storage.reserveCapacity(reservedCapacity)
    }
    
    @inlinable
    internal mutating func reserveCapacity(_ n: Int) {
        storage.reserveCapacity(n)
    }
    
    @inlinable
    internal var optionalTransition : AnyTransition? {
        
        let canTransition = value(for: CanTransitionTraitKey.self, defaultValue: false)
        
        if canTransition {
            let transition = value(for: TransitionTraitKey.self, defaultValue: AnyTransition.opacity)
            if !transition.box.isIdentity {
                return transition
            }
        }
        
        return nil
    }
    
    internal func tagValue<A: Hashable>(for type: A.Type) -> A? {
        let value = self[TagValueTraitKey<A>.self]
        if case .tagged(let tag) = value {
            return tag
        }
        return nil
    }
    
    internal func tag<A: Hashable>(for type: A.Type) -> A? {
        let value = self[TagValueTraitKey<A>.self]
        let isAuxiliaryContent = self[IsAuxiliaryContentTraitKey.self]
        if case .tagged(let tag) = value,
           !isAuxiliaryContent {
            return tag
        }
        return nil
    }
    
    internal mutating func mergeValues(_ otherTrait: ViewTraitCollection) {
        guard !otherTrait.storage.isEmpty else {
            return
        }
        
        otherTrait.storage.forEach { trait in
            setErasedValue(trait: trait)
        }
    }
    
    fileprivate mutating func setErasedValue<Trait: AnyViewTrait>(trait: Trait) {
        guard !storage.isEmpty else {
            storage.append(trait)
            return
        }
        
        if let index = storage.firstIndex(where: { $0.id == trait.id }) {
            storage[index] = trait
        } else {
            storage.append(trait)
        }
    }
    
    @inlinable
    internal subscript<TraitKey: _ViewTraitKey>(type: TraitKey.Type) -> TraitKey.Value {
        get {
            value(for: type, defaultValue: type.defaultValue)
        }
        set {
            if let index = storage.firstIndex(where: { $0.id == ObjectIdentifier(type) }) {
                storage[index][] = newValue
            } else {
                let trait = AnyTrait<TraitKey>(value: newValue)
                storage.append(trait)
            }
        }
    }
    
    @inlinable
    internal func value<TraitKey: _ViewTraitKey>(for type: TraitKey.Type, defaultValue: TraitKey.Value) -> TraitKey.Value {
        
        for trait in storage where trait.id == .init(type) {
            return trait[]
        }
        return defaultValue
    }

}

@available(iOS 13.0, *)
internal protocol AnyViewTrait {
    
    var id: ObjectIdentifier { get }
    
    subscript<A1>() -> A1 { get set }
}

@available(iOS 13.0, *)
extension ViewTraitCollection {

    internal struct AnyTrait<Key: _ViewTraitKey>: AnyViewTrait {

        internal var value: Key.Value
        
        @inlinable
        internal var id: ObjectIdentifier {
            ObjectIdentifier(Key.self)
        }
        
        @inlinable
        internal subscript<Value>() -> Value {
            get {
                value as! Value
            }
            set {
                value = newValue as! Key.Value
            }
        }
    }
}
