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
internal struct PreferenceList: CustomStringConvertible {
    
    fileprivate var first: PreferenceNode?
    
    @inline(__always)
    internal init() {
        self.first = nil
    }
    
    internal subscript<Key: PreferenceKey>(_ key: Key.Type) -> Value<Key.Value> {
        get {
            guard let first = self.first,
                  let node = first.find(key: key) else {
                      return Value(value: Key.defaultValue, seed: .zero)
                  }
            
            return Value(value: node.value, seed: node.seed)
        }
        set {
            if let first = self.first,
               let _ = first.find(key: key) {
                self.removeValue(for: key)
            }
            
            self.first = _PreferenceNode<Key>(value: newValue.value, seed: newValue.seed, next: self.first)
        }
    }
    
    internal mutating func modifyValue<Key: PreferenceKey>(for key: Key.Type, transform: Value<(inout Key.Value) -> Void>) {
        var value = self[key]
        if transform.seed != .zero && value.seed != .invalid {
            var seedValue = transform.seed.value
            if transform.seed != .invalid && value.seed != .zero {
                seedValue = merge32(a: value.seed.value, b: transform.seed.value)
            }
            value.seed.value = seedValue
        }
        
        transform.value(&value.value)
        removeValue(for: key)
        self.first = _PreferenceNode<Key>(value: value.value, seed: value.seed, next: self.first)
    }
    
    internal mutating func removeValue<Key: PreferenceKey>(for key: Key.Type) {
        let first = self.first
        guard first != nil else {
            return
        }

        self.first = nil
        first?.forEach({ node in
            guard node.keyType != key else {
                return
            }
            self.first = node.copy(next: self.first)
        })
    }
    
    
    internal func valueIfPresent<Key: PreferenceKey>(for key: Key.Type) -> PreferenceList.Value<Key.Value>? {
        guard let first = self.first else {
            return nil
        }
        
        let mayNilNode = first.find(key: key)
        return mayNilNode.map { node in
            Value(value: node.value, seed: node.seed)
        }
    }
    
    internal func contains<Key: PreferenceKey>(_ key: Key.Type) -> Bool {
        first?.find(key: key) != nil
    }
    
    internal var description: String {
        var desc = "<PreferenceList"
        var nodeOrNil = first
        while let node = nodeOrNil {
            desc += "\n\t\(node.keyType) = \(node.anyValue)"
            nodeOrNil = node.next
        }
        desc += ">"
        return desc
    }
    
    @inlinable
    internal var mergedSeed: VersionSeed? {
        return first?.mergedSeed
    }
}

@available(iOS 13.0, *)
extension PreferenceList {

    internal struct Value<A> {
        internal var value: A

        internal var seed: VersionSeed
        
        @inline(__always)
        internal init(value: A) {
            self.value = value
            self.seed = .invalid
        }
        
        internal init(value: A, seed: VersionSeed) {
            self.value = value
            self.seed = seed
        }
    }
}

@available(iOS 13.0, *)
fileprivate class PreferenceNode {

    internal var keyType: Any.Type

    internal var seed: VersionSeed

    internal var mergedSeed: VersionSeed

    internal var next: PreferenceNode?

    internal var anyValue: Any {
        _abstract(self)
    }
    
    internal init(keyType: Any.Type, seed: VersionSeed, mergedSeed: VersionSeed, next: PreferenceNode?) {
        self.keyType = keyType
        self.seed = seed
        self.mergedSeed = mergedSeed
        self.next = next
    }
    
    internal func copy(next: PreferenceNode?) -> PreferenceNode {
        _abstractFunction()
    }
    
    internal func find<Key: PreferenceKey>(key: Key.Type) -> _PreferenceNode<Key>? {
        var currentNode: PreferenceNode? = self
        while let node = currentNode {
            if node.keyType == key {
                return node as? _PreferenceNode<Key>
            }
            currentNode = node.next
        }
        return nil
    }
    
    internal func find(from node: PreferenceNode?) -> PreferenceNode? {
        _abstractFunction()
    }

    internal func combine(from: PreferenceNode?, next: PreferenceNode?) -> PreferenceNode? {
        _abstractFunction()
    }
    
    internal func forEach(_ body: (PreferenceNode) -> Void) {
        var currentNode: PreferenceNode? = self
        while let node = currentNode {
            body(node)
            currentNode = node.next
        }
    }
    
    internal init(keyType: Any.Type, seed: VersionSeed, next: PreferenceNode?) {
        self.keyType = keyType
        self.seed = seed
        
        guard let next = next else {
            mergedSeed = seed
            return
        }
        
        self.next = next
        
        let nextMergedSeed = next.mergedSeed
        guard nextMergedSeed != .invalid, seed != .invalid else {
            self.mergedSeed = .invalid
            return
        }
        
        guard seed != .zero else {
            self.mergedSeed = nextMergedSeed
            return
        }
        
        guard nextMergedSeed != .zero else {
            self.mergedSeed = seed
            return
        }
        
        let mergedSeedValue = merge32(a: nextMergedSeed.value, b: seed.value)
        self.mergedSeed = VersionSeed(value: mergedSeedValue)
    }
    
}

@available(iOS 13.0, *)
private final class _PreferenceNode<Key: PreferenceKey>: PreferenceNode {

    internal var value: Key.Value

    internal override var anyValue: Any {
        return value
    }
    
    internal init(value: Key.Value, seed: VersionSeed, next: PreferenceNode?) {
        self.value = value
        super.init(keyType: Key.self, seed: seed, next: next)
    }
    
    internal override func copy(next: PreferenceNode?) -> PreferenceNode {
        return _PreferenceNode(value: self.value, seed: self.seed, next: next)
    }
    
    internal override func find(from node: PreferenceNode?) -> PreferenceNode? {
        guard let node = node else {
            return nil
        }
        
        return node.find(key: Key.self)
    }
    
    internal override func combine(from: PreferenceNode?, next: PreferenceNode?) -> PreferenceNode? {
        var cursor: PreferenceNode? = from
        while let newFrom = cursor {
            if newFrom.keyType == self.keyType {
                return _combine(from: newFrom, next: next)
            }
            cursor = newFrom.next
        }
        return nil
    }
    
    @inline(__always)
    private func _combine(from: PreferenceNode, next: PreferenceNode?) -> PreferenceNode? {
        var selfValue = self.value
        
        let fromSeed = from.seed
        var selfSeed = self.seed
        Key.reduce(value: &selfValue) {
            if fromSeed != .zero && selfSeed != .invalid {
                var mergedSeedValue = fromSeed.value
                if fromSeed != .invalid && selfSeed != .zero {
                    mergedSeedValue = merge32(a: selfSeed.value, b: fromSeed.value)
                }
                selfSeed.value = mergedSeedValue
            }
            return unsafeDowncast(from, to: _PreferenceNode.self).value
        }
        
        return _PreferenceNode(value: selfValue, seed: selfSeed, next: next)
    }
}

@available(iOS 13.0, *)
extension PreferencesInputs {
    
    @inlinable
    internal var requiresHostPreferences: Bool {
        get {
            contains(HostPreferencesKey.self)
        }
        set {
            if newValue {
                add(HostPreferencesKey.self)
            } else {
                remove(HostPreferencesKey.self)
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension _ViewOutputs {
    
    internal var hostPreferences: Attribute<PreferenceList>? {
        get {
            self[HostPreferencesKey.self]
        }
        set {
            self[HostPreferencesKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
internal struct HostPreferencesKey: PreferenceKey {
    
    internal typealias Value = PreferenceList
    
    internal static func reduce(value: inout PreferenceList, nextValue: () -> PreferenceList) {
        let preferenceList = nextValue()
        guard let nextFirst = preferenceList.first else {
            return
        }
        
        guard let first = value.first else {
            value.first = nextFirst
            return
        }
        
        value = PreferenceList()
        first.forEach { node in
            let combined = node.combine(from: nextFirst, next: value.first)
            guard combined == nil else {
                value.first = combined
                return
            }
            value.first = node.copy(next: value.first)
        }
        
        nextFirst.forEach { node in
            if node.find(from: first) == nil {
                value.first = node.copy(next: value.first)
            }
        }
    }
    
    internal static var defaultValue: PreferenceList {
        PreferenceList()
    }
    
    private static var nodeId: UInt32 = 0
    
    @inline(__always)
    internal static func makeNodeId() -> UInt32 {
        defer {
            nodeId &+= 1
        }
        return nodeId
    }
    
}

@available(iOS 13.0, *)
internal /* private */ func merge32(a: UInt32, b: UInt32) -> UInt32 {
    let part0 = UInt64(a) << 0x20 | UInt64(b)
    let part1 = UInt64(b) << 0x20 ^ (~0)
    let value = part0 &+ part1
    return uint64_hash(value: value)
}

@inline(__always)
@available(iOS 13.0, *)
internal func uint64_hash(value: UInt64) -> UInt32 {
    
    var result = (value >> 0x16) ^ value
    result = ((result << 0xd) ^ (~0)) &+ result
    result = (result >> 0x8) ^ result
    result = result &+ result &* 8
    result = (result >> 0xf) ^ result
    result = ((result << 0x1b) ^ (~0)) &+ result
    
    return UInt32(truncatingIfNeeded:(result >> 0x1f)) ^ UInt32(truncatingIfNeeded: result)
}

@available(iOS 13.0, *)
extension VersionSeed {
    
    @inline(__always)
    internal func merge(_ another: VersionSeed) -> VersionSeed? {
        guard self != .zero && another != .invalid else {
            return nil
        }
        
        guard self != .invalid && another != .zero else {
            return self
        }
        
        return VersionSeed(value: merge32(a: another.value, b: value))
    }
    
}
