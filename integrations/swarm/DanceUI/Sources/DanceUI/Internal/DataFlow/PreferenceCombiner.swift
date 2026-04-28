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
internal struct PairPreferenceCombiner<Key: PreferenceKey>: Rule {
    
    internal typealias Value = Key.Value
    
    internal var attributes: (lhs: Attribute<Key.Value>, rhs: Attribute<Key.Value>)
    
    internal var value: Key.Value {
        var value = attributes.lhs.value
        Key.reduce(value: &value) {
            attributes.rhs.value
        }
        return value
    }
}

@available(iOS 13.0, *)
internal struct PreferenceCombiner<Key: PreferenceKey>: Rule {
    
    internal typealias Value = Key.Value
    
    internal var attributes: [WeakAttribute<Value>]
    
    internal init(attributes: [Attribute<Value>]) {
        self.attributes = attributes.map({WeakAttribute($0)})
    }

    internal var value: Key.Value {
        Key.apply(indices: 0..<attributes.count, values: {
            attributes[$0].value ?? Key.defaultValue
        })
    }
}
