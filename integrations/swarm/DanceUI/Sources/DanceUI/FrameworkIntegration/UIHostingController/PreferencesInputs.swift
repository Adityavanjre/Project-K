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
internal struct PreferencesInputs {
    
    internal private(set) var keys: PreferenceKeys

    internal var hostKeys: Attribute<PreferenceKeys>
    
    @inlinable
    internal init(keys: PreferenceKeys, hostKeys: Attribute<PreferenceKeys>) {
        self.keys = keys
        self.hostKeys = hostKeys
    }
    
    @inlinable
    internal init(hostKeys: Attribute<PreferenceKeys>) {
        self.keys = PreferenceKeys()
        self.hostKeys = hostKeys
    }
    
    @inlinable
    internal func contains<Key: PreferenceKey>(_ key: Key.Type) -> Bool {
        keys.contains(key)
    }
    
    @inlinable
    internal mutating func add<Key: PreferenceKey>(_ key: Key.Type) {
        keys.add(key)
    }
    
    @inlinable
    internal mutating func remove<Key: PreferenceKey>(_ key: Key.Type) {
        keys.remove(key)
    }
    
    @inlinable
    internal mutating func merge(another: PreferenceKeys) {
        keys.merge(another)
    }

    @inlinable
    internal mutating func removeAll() {
        keys = PreferenceKeys()
    }
    
    // iOS 18.5 addition
    // Umbrellaed in DanceUIFeature.gestureContainer
    internal func makeIndirectOutputs() -> PreferencesOutputs {
        assert(DanceUIFeature.gestureContainer.isEnable)
        struct AddPreferenceVisitor: PreferenceKeyVisitor {
            
            internal var preferences = PreferencesOutputs()
            
            internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
                let source = GraphHost.currentHost.intern(Key.defaultValue, id: 0)
                preferences.appendPreference(key, value: IndirectAttribute(source: source).projectedValue)
            }
        }
        var visitor = AddPreferenceVisitor()
        for key in keys {
            key.visitKey(&visitor)
        }
        return visitor.preferences
    }
    
}
