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
internal struct IncrementalPreference<Key: PreferenceKey>: Rule {

    internal typealias Value = Key.Value

    @Attribute
    internal var children: [_IncrementalLayout_PlacedChild]

    internal var cache: ViewCache?

    internal var value: Key.Value {
        let _includesRemovedValues = Key._includesRemovedValues
        var value: Key.Value = Key.defaultValue
        let children = self.children
        var firstValue = true

        for child in children {
            let item = child.item
            guard let attribute = item.outputs[Key.self] else {
                continue
            }
            guard _includesRemovedValues || (!_includesRemovedValues && !item.state.isRemoved) else {
                continue
            }
            if firstValue {
                value = attribute.value
            } else {
                Key.reduce(value: &value) { () -> Key.Value in
                    attribute.value
                }
            }
            firstValue = false
        }
        return value
    }

}
