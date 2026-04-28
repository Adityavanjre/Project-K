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

fileprivate typealias ArrayWithInline = ExpressibleByArrayLiteral &
    RangeReplaceableCollection &
    MutableCollection &
    RandomAccessCollection
@available(iOS 13.0, *)
internal struct ArrayWith2Inline<Element>: ArrayWithInline {
    
    internal var storage: ArrayWith2InlineStorage<Element>
    
    internal init() {
        storage = .empty
    }

    internal init(arrayLiteral elements: Element...) {
        self = elements.withUnsafeBufferPointer { elementsPointer in
            ArrayWith2Inline(elementsPointer)
        }
    }
    
    internal init<S: Sequence>(_ sequence: S) where S.Element == Element {
        
        guard sequence.underestimatedCount < 3 else {
            self.storage = .many(ContiguousArray(sequence))
            return
        }
        
        var iterator = sequence.makeIterator()
        
        guard let one = iterator.next() else {
            self.storage = .empty
            return
        }
        
        guard let two = iterator.next() else {
            self.storage = .one(one)
            return
        }
        
        guard iterator.next() != nil else {
            self.storage = .two(one, two)
            return
        }
        
        self.storage = .many(ContiguousArray(sequence))
    }
    
    internal var startIndex: Int {
        0
    }
    
    internal var endIndex: Int {
        switch storage {
        case .one:
            return 1
        case .two:
            return 2
        case .many(let array):
            return array.endIndex
        case .empty:
            return 0
        }
    }
    
    subscript(bounds: Int) -> Element {
        get {
            switch (bounds, storage) {
            case (0, .one(let element0)), (0, .two(let element0, _)):
                return element0
            case (1, .two(_, let element1)):
                return element1
            case (_, .many(let array)):
                return array[bounds]
            default:
                _danceuiFatalError()
            }
        }
        set {
            switch (bounds, storage) {
            case (0, .one):
                storage = .one(newValue)
            case (0, .two(_, let element1)):
                storage = .two(newValue, element1)
            case (1, .two(let element0, _)):
                storage = .two(element0, newValue)
            case (_, .many(var array)):
                array[bounds] = newValue
                storage = .many(array)
            default:
                _danceuiFatalError()
            }
        }
    }
    
    internal func _copyToContiguousArray() -> ContiguousArray<Element> {
        switch storage {
        case .empty:
            return []
        case .one(let element):
            return [element]
        case .two(let element0, let element1):
            return [element0, element1]
        case .many(let array):
            return array._copyToContiguousArray()
        }
    }
    
    internal mutating func append(_ element: Element) -> () {
        switch storage {
        case .one(let element0):
            storage = .two(element0, element)
        case .two(let element0, let element1):
            storage = .many([element0, element1, element])
        case .many(var array):
            array.append(element)
            storage = .many(array)
        case .empty:
            storage = .one(element)
        }
    }
    
    internal func distance(from: Int, to: Int) -> Int {
        to - from
    }
    
    internal func index(_ start: Int, offsetBy: Int) -> Int {
        start + offsetBy
    }
    
    internal func index(after index: Int) -> Int {
        index + 1
    }
    
    internal func index(before index: Int) -> Int {
        index - 1
    }
    
    internal mutating func removeAll(keepingCapacity: Bool)  {
        storage = .empty
    }
    
    internal mutating func replaceSubrange<C: Collection>(_ subRange: Range<Int>, with newElements: C) where Element == C.Element {
        if case var .many(array) = storage {
            array.replaceSubrange(subRange, with: newElements)
            storage = .many(array)
            return
        }
        
        let firstPart = self[PartialRangeUpTo(subRange.lowerBound)]
        let collection = concatenate(firstPart, newElements)
        if collection.count != subRange.upperBound {
            let lastPart = self[PartialRangeFrom(subRange.upperBound)]
            self = ArrayWith2Inline(concatenate(collection, lastPart))
        } else {
            self = ArrayWith2Inline(collection)
        }
    }
    
    internal mutating func reserveCapacity(_ minimumCapacity: Int) {
        guard minimumCapacity > 2, case var .many(array) = storage else {
            return
        }
        array.reserveCapacity(minimumCapacity)
        storage = .many(array)
    }
    
    internal typealias ArrayLiteralElement = Element
    
    internal typealias SubSequence = Slice<ArrayWith2Inline<Element>>
    
    internal typealias Iterator = IndexingIterator<ArrayWith2Inline<Element>>
    
    internal typealias Index = Int
    
    internal typealias Indices = Range<Int>

}

@available(iOS 13.0, *)
internal enum ArrayWith2InlineStorage<Element> {

    case one(Element)

    case two(Element, Element)

    case many(ContiguousArray<Element>)

    case empty

}

@available(iOS 13.0, *)
extension ArrayWith2InlineStorage: Equatable where Element: Equatable {
    
}

@available(iOS 13.0, *)
extension ArrayWith2InlineStorage: Hashable where Element: Hashable {
    
}

@available(iOS 13.0, *)
extension ArrayWith2Inline: Equatable where Element: Equatable {
    
}

@available(iOS 13.0, *)
extension ArrayWith2Inline: Hashable where Element: Hashable {
    
}

@available(iOS 13.0, *)
internal struct ArrayWith3Inline<Element> : ArrayWithInline {

    internal var storage: ArrayWith3InlineStorage<Element>
    
    internal init() {
        storage = .empty
    }

    internal init(arrayLiteral elements: Element...) {
        self = elements.withUnsafeBufferPointer { elementsPointer in
            ArrayWith3Inline(elementsPointer)
        }
    }
    
    internal init<S: Sequence>(_ sequence: S) where S.Element == Element {
        
        guard sequence.underestimatedCount < 4 else {
            self.storage = .many(ContiguousArray(sequence))
            return
        }
        
        var iterator = sequence.makeIterator()
        
        guard let one = iterator.next() else {
            self.storage = .empty
            return
        }
        
        guard let two = iterator.next() else {
            self.storage = .one(one)
            return
        }
        
        guard let three = iterator.next() else {
            self.storage = .two(one, two)
            return
        }
        
        guard iterator.next() != nil else {
            self.storage = .three(one, two, three)
            return
        }
        
        self.storage = .many(ContiguousArray(sequence))
    }
    
    internal var startIndex: Int {
        0
    }
    
    internal var endIndex: Int {
        switch storage {
        case .one(_):
            return 1
        case .two(_, _):
            return 2
        case .three(_, _, _):
            return 3
        case .many(let array):
            return array.count
        case .empty:
            return 0
        }
    }
    
    subscript(bounds: Int) -> Element {
        get {
            switch (bounds, storage) {
            case (0, .one(let element0)), (0, .two(let element0, _)), (0, .three(let element0, _, _)):
                return element0
            case (1, .two(_, let element1)), (1, .three(_, let element1, _)):
                return element1
            case (2, .three(_, _, let element2)):
                return element2
            case (_, .many(let array)):
                return array[bounds]
            default:
                _danceuiFatalError()
            }
        }
        set {
            switch (bounds, storage) {
            case (0, .one(_)):
                storage = .one(newValue)
            case (0, .two(_, let element1)):
                storage = .two(newValue, element1)
            case (0, .three(_, let element1, let element2)):
                storage = .three(newValue, element1, element2)
            case (1, .two(let element0, _)):
                storage = .two(element0, newValue)
            case (1, .three(let element0, _, let element2)):
                storage = .three(element0, newValue, element2)
            case (2, .three(let element0, let element1, _)):
                storage = .three(element0, element1, newValue)
            case (_, .many(var array)):
                array[bounds] = newValue
                storage = .many(array)
            default:
                _danceuiFatalError()
            }
        }
    }
    
    internal func _copyToContiguousArray() -> ContiguousArray<Element> {
        switch storage {
        case .empty:
            return []
        case .one(let element):
            return [element]
        case .two(let element0, let element1):
            return [element0, element1]
        case .three(let element0, let element1, let element2):
            return [element0, element1, element2]
        case .many(let array):
            return array._copyToContiguousArray()
        }
    }
    
    internal mutating func append(_ element: Element) -> () {
        switch storage {
        case .one(let element0):
            storage = .two(element0, element)
        case .two(let element0, let element1):
            storage = .three(element0, element1, element)
        case .three(let element0, let element1, let element2):
            storage = .many(.init(arrayLiteral: element0, element1, element2, element))
        case .many(var array):
            array.append(element)
            storage = .many(array)
        case .empty:
            storage = .one(element)
        }
    }
    
    internal func distance(from: Int, to: Int) -> Int {
        to - from
    }
    
    internal func index(_ start: Int, offsetBy: Int) -> Int {
        start + offsetBy
    }
    
    internal func index(after index: Int) -> Int {
        index + 1
    }
    
    internal func index(before index: Int) -> Int {
        index - 1
    }
    
    internal mutating func removeAll(keepingCapacity: Bool)  {
        storage = .empty
    }
    
    internal mutating func replaceSubrange<C: Collection>(_ subRange: Range<Int>, with newElements: C) where Element == C.Element  {
        if case var .many(array) = storage {
            array.replaceSubrange(subRange, with: newElements)
            storage = .many(array)
            return
        }
        let firstPart = self[PartialRangeUpTo(subRange.lowerBound)]
        let collection = concatenate(firstPart, newElements)
        if collection.count != subRange.upperBound {
            let lastPart = self[PartialRangeFrom(subRange.upperBound)]
            self = ArrayWith3Inline(concatenate(collection, lastPart))
        } else {
            self = ArrayWith3Inline(collection)
        }
    }
    
    internal mutating func reserveCapacity(_ minimumCapacity: Int) {
        guard minimumCapacity > 3, case var .many(array) = storage else {
            return
        }
        array.reserveCapacity(minimumCapacity)
        storage = .many(array)
    }
    
    internal typealias ArrayLiteralElement = Element
    
    internal typealias SubSequence = Slice<ArrayWith3Inline<Element>>
        
    internal typealias Iterator = IndexingIterator<ArrayWith3Inline<Element>>
    
    internal typealias Index = Int
    
    internal typealias Indices = Range<Int>

}

@available(iOS 13.0, *)
internal enum ArrayWith3InlineStorage<Element> {

    case one(Element)

    case two(Element, Element)

    case three(Element, Element, Element)

    case many(ContiguousArray<Element>)

    case empty

}

@available(iOS 13.0, *)
extension ArrayWith3InlineStorage: Equatable where Element: Equatable {
    
}

@available(iOS 13.0, *)
extension ArrayWith3InlineStorage: Hashable where Element: Hashable {
    
}

@available(iOS 13.0, *)
extension ArrayWith3Inline: Equatable where Element: Equatable {
    
}

@available(iOS 13.0, *)
extension ArrayWith3Inline: Hashable where Element: Hashable {
    
}
