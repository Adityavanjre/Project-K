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

internal struct MinHeap<T: Comparable> {
    
    private var elements: [T] = []

    internal var isEmpty: Bool {
        return elements.isEmpty
    }

    internal var count: Int {
        return elements.count
    }

    internal func peek() -> T? {
        return elements.first
    }

    private func parentIndex(ofChildAt index: Int) -> Int {
        return (index - 1) / 2
    }

    private func leftChildIndex(ofParentAt index: Int) -> Int {
        return 2 * index + 1
    }

    private func rightChildIndex(ofParentAt index: Int) -> Int {
        return 2 * index + 2
    }

    internal mutating func insert(_ element: T) {
        elements.append(element)
        heapifyUp(from: elements.count - 1)
    }

    private mutating func heapifyUp(from index: Int) {
        var childIndex = index
        let child = elements[childIndex]
        var parentIdx = parentIndex(ofChildAt: childIndex)

        while childIndex > 0 && child < elements[parentIdx] {
            elements[childIndex] = elements[parentIdx]
            childIndex = parentIdx
            parentIdx = parentIndex(ofChildAt: childIndex)
        }
        elements[childIndex] = child
    }

    internal mutating func remove() -> T? {
        guard !isEmpty else { return nil }
        if elements.count == 1 {
            return elements.removeLast()
        } else {
            let value = elements[0]
            elements[0] = elements.removeLast()
            heapifyDown(from: 0)
            return value
        }
    }
    
    internal mutating func removeAll(keepingCapacity: Bool) {
        elements.removeAll(keepingCapacity: keepingCapacity)
    }
    
    internal mutating func reserveCapacity(minimumCapacity: Int) {
        elements.reserveCapacity(minimumCapacity)
    }

    private mutating func heapifyDown(from index: Int) {
        var parentIndex = index
        while true {
            let leftChildIdx = leftChildIndex(ofParentAt: parentIndex)
            let rightChildIdx = rightChildIndex(ofParentAt: parentIndex)
            var smallestChildIndex = parentIndex

            if leftChildIdx < count && elements[leftChildIdx] < elements[smallestChildIndex] {
                smallestChildIndex = leftChildIdx
            }
            if rightChildIdx < count && elements[rightChildIdx] < elements[smallestChildIndex] {
                smallestChildIndex = rightChildIdx
            }

            if smallestChildIndex == parentIndex {
                break
            }

            elements.swapAt(parentIndex, smallestChildIndex)
            parentIndex = smallestChildIndex
        }
    }
    
    internal func allElements() -> [T] {
        return elements
    }
}
