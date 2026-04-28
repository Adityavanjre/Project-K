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

internal struct TopK<Element: Comparable> {
    
    private var heap: MinHeap<Element>
    
    private let capacity: Int
    
    internal var values: [Element] {
        var elementsCopy = heap.allElements()
        elementsCopy.sort(by: >)
        return elementsCopy
    }
    
    internal init(capacity: Int) {
        self.heap = MinHeap<Element>()
        self.heap.reserveCapacity(minimumCapacity: capacity)
        self.capacity = max(1, capacity)
    }
    
    internal init<C: Collection>(capacity: Int, contentsOf collection: C) where C.Element == Element {
        self.init(capacity: capacity)
        for each in collection {
            self.add(each)
        }
    }
    
    internal mutating func add(_ value: Element) {
        if heap.count < capacity {
            heap.insert(value)
        } else if let smallestInTopN = heap.peek(), value > smallestInTopN {
            _ = heap.remove()
            heap.insert(value)
        }
    }
    
}
