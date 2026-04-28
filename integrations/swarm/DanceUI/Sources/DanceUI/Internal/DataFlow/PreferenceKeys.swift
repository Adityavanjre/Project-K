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

@available(iOS 13.0, *)
internal struct PreferenceKeys: MutableCollection, RandomAccessCollection {
    
    private var keys: [AnyPreferenceKey.Type] = []
    
    internal init() {
        self.keys = []
    }
    
    @inlinable
    internal mutating func add<Key: PreferenceKey>(_ keyType: Key.Type) {
        add(_AnyPreferenceKey<Key>.self)
    }
    
    @inline(never)
    internal mutating func add(_ keyType: AnyPreferenceKey.Type) {
        keys.append(keyType)
    }
    
    @inlinable
    internal mutating func remove<Key: PreferenceKey>(_ keyType: Key.Type) {
        remove(_AnyPreferenceKey<Key>.self)
    }
    
    @inline(never)
    internal mutating func remove(_ keyType: AnyPreferenceKey.Type) {
        guard let index = keys.firstIndex(where: { $0.self == keyType }) else {
            return
        }
        keys.remove(at: index)
    }
    
    @inlinable
    internal func contains<Key: PreferenceKey>(_ keyType: Key.Type) -> Bool {
        contains(_AnyPreferenceKey<Key>.self)
    }
    
    @inline(never)
    internal func contains(_ keyType: AnyPreferenceKey.Type) -> Bool {
        keys.contains(where: { $0.self == keyType })
    }
    
    @inline(never)
    internal mutating func merge(_ another: PreferenceKeys) {
        for each in another {
            if !contains(each) {
                add(each)
            }
        }
    }
    
    @inlinable
    internal func merging(_ another: PreferenceKeys) -> PreferenceKeys {
        var merged = self
        merged.merge(another)
        return merged
    }
    
    @inline(never)
    internal subscript(position: Int) -> AnyPreferenceKey.Type {
        get {
            keys[position]
        }
        set {
            keys[position] = newValue
        }
    }
    
    @inlinable
    internal var startIndex: Int {
        keys.startIndex
    }
    
    @inline(never)
    internal var endIndex: Int {
        keys.endIndex
    }
    
    @inlinable
    internal func index(after i: Int) -> Int {
        keys.index(after: i)
    }
}
