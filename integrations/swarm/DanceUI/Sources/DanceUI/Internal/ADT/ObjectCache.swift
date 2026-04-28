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

@_spi(DanceUICompose)
public final class ObjectCache<Key, Value> where Key: Hashable {
    @_spi(DanceUICompose)
    public let constructor: (Key) -> Value

    @AtomicBox
    private var data: Data

    @_spi(DanceUICompose)
    public init(constructor: @escaping (Key) -> Value) {
        self.constructor = constructor
        self.data = Data()
    }

    @_spi(DanceUICompose)
    public final subscript(key: Key) -> Value {
        let hash = key.hashValue
        let bucket = (hash & ((1 << 3) - 1)) << 2
        var targetOffset: Int = 0
        var diff: Int32 = Int32.min
        let value = $data.access { data -> Value? in
            for offset in 0 ..< 4 {
                let index = bucket + offset
                if let itemData = data.table[index].data {
                    if itemData.hash == hash, itemData.key == key {
                        data.clock &+= 1
                        data.table[index].used = data.clock
                        return itemData.value
                    } else {
                        let dist = Int32(bitPattern: data.clock &- data.table[index].used)
                        if diff < dist {
                            targetOffset = offset
                            diff = dist
                        }
                    }
                } else {
                    if diff != Int32.max {
                        targetOffset = offset
                        diff = Int32.max
                    }
                }
            }
            return nil
        }
        if let value {
            return value
        } else {
            let value = constructor(key)
            $data.access { data in
                data.clock += 1
                data.table[bucket + targetOffset] = Item(data: (key, hash, value), used: data.clock)
            }
            return value
        }
    }

    private struct Item {
        internal var data: (key: Key, hash: Int, value: Value)?
        internal var used: UInt32
    }

    private struct Data {
        internal var table: [Item]
        internal var clock: UInt32

        internal init() {
            self.table = Array(repeating: Item(data: nil, used: 0), count: 32)
            self.clock = 0
        }
    }
}
