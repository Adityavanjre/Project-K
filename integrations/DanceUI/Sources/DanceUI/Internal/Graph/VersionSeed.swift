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
internal struct VersionSeed: Equatable {
    
    internal static let zero: VersionSeed = VersionSeed(value: 0x0)
    
    internal static let invalid: VersionSeed = VersionSeed(value: 0xffffffff)
    
    internal var value: UInt32
    
    internal var isVaild: Bool {
        value != VersionSeed.invalid.value
    }
}

#if DEBUG
@available(iOS 13.0, *)
extension VersionSeed: CustomStringConvertible {

    var description: String {
        if !isVaild {
            return "VersionSeed.invalid"
        }
        return "\(Self.self)(value: \(String(value, radix: 16)))"
    }

}
#endif
@available(iOS 13.0, *)
internal struct VersionSeedTracker {
    
    internal struct Value {

        internal var key: AnyPreferenceKey.Type

        internal var seed: VersionSeed

    }
    
    private struct HasChangesVisitor: PreferenceKeyVisitor {

        internal let preferences: PreferenceList

        internal var seed: VersionSeed

        internal var matches: Bool?
        
        internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
            let preferenceListSeed = preferences[key].seed
            self.matches = (preferenceListSeed != .invalid && self.seed == preferenceListSeed)
        }

    }
    
    private struct UpdateSeedVisitor: PreferenceKeyVisitor {

        internal var preferences: PreferenceList

        internal var seed: VersionSeed?
        
        internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
            self.seed = preferences[key].seed
        }

    }

    internal var values: [Value]
    
    internal mutating func addPreference<Key: HostPreferenceKey>(_ : Key.Type) {
        let newValue = Value(key: _AnyPreferenceKey<Key>.self, seed: .invalid)
        values.append(newValue)
    }
    
    internal func hasChanges(in preferenceList: PreferenceList) -> Bool {
        var changed = false
        values.forEach { value in
            let matches: Bool? = nil
            var visitor = HasChangesVisitor(preferences: preferenceList, seed: value.seed, matches: matches)
            value.key.visitKey(&visitor)
            
            if let matches = visitor.matches {
                changed = changed || !matches
            }
        }
        return changed
    }
    
    internal mutating func updateSeeds(to preferenceList: PreferenceList) {
        for i in values.indices {
            var visitor = UpdateSeedVisitor(preferences: preferenceList, seed: nil)
            values[i].key.visitKey(&visitor)
            
            guard let seed = visitor.seed else {
                continue
            }
            
            values[i].seed = seed
        }
    }

}


