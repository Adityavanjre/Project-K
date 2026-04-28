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
internal struct Cache3<KeyType: Equatable, ValueType> {

    internal struct Element {

        internal let key: KeyType

        internal let value: ValueType
    }

    internal var store0: Element? = nil
    internal var store1: Element? = nil
    internal var store2: Element? = nil

    @inlinable
    internal subscript(_ key: KeyType) -> ValueType? {
        get {
            if key == store0?.key {
                return store0?.value
            } else if key == store1?.key {
                return store1?.value
            } else if key == store2?.key {
                return store2?.value
            }
            return nil
        }
        set {
            if let value = newValue {
                store2 = store1
                store1 = store0
                store0 = .init(key: key, value: value)
            } else {
                if key == store0?.key {
                    store0 = nil
                } else if key == store1?.key {
                    store1 = nil
                } else if key == store2?.key {
                    store2 = nil
                }
            }
        }
    }

}
