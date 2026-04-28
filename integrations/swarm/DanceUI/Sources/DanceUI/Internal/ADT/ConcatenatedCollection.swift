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
internal struct ConcatenatedCollection<First: Collection, Second: Collection>: Collection where First.Element == Second.Element {

    internal let _base1: First

    internal let _base2: Second
    
    internal init(_base1: First, base2: Second) {
        self._base1 = _base1
        self._base2 = base2
    }
    
    internal var startIndex: ConcatenatedCollectionIndex<First, Second> {
        !_base1.isEmpty ?
            ConcatenatedCollectionIndex(first: _base1.startIndex) :
            ConcatenatedCollectionIndex(second: _base2.startIndex)
    }

    internal var endIndex: ConcatenatedCollectionIndex<First, Second> {
        ConcatenatedCollectionIndex(second: _base2.endIndex)
    }
    
    internal func index(after i: ConcatenatedCollectionIndex<First, Second>) -> ConcatenatedCollectionIndex<First, Second> {
        switch i._position {
        case .first(let index):
            let after = _base1.index(after: index)
            if after == _base1.endIndex {
                return ConcatenatedCollectionIndex(second: _base2.startIndex)
            } else {
                return ConcatenatedCollectionIndex(first: after)
            }
        case .second(let index):
            return ConcatenatedCollectionIndex(second: _base2.index(after: index))
        }
    }
    
    internal subscript(_ position: ConcatenatedCollectionIndex<First, Second>) -> First.Element {
        switch position._position {
        case .first(let index):
            return _base1[index]
        case .second(let index):
            return _base2[index]
        }
    }
    
    internal typealias Element = First.Element

    internal typealias Iterator = IndexingIterator<Self>
    
    internal typealias Index = ConcatenatedCollectionIndex<First, Second>

    internal typealias SubSequence = Slice<Self>

    internal typealias Indices = DefaultIndices<Self>

}

@available(iOS 13.0, *)
internal enum _ConcatenatedCollectionIndexRepresentation<First, Second> {

    case first(First)

    case second(Second)

}

@available(iOS 13.0, *)
internal struct ConcatenatedCollectionIndex<First: Collection, Second: Collection>: Comparable {

    internal let _position: _ConcatenatedCollectionIndexRepresentation<First.Index, Second.Index>
    
    internal init(first index: First.Index) {
        self._position = .first(index)
    }
    internal init(second index: Second.Index) {
        self._position = .second(index)
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs._position, rhs._position) {
        case (.first(let index1), .first(let index2)):
            return index1 < index2
        case (.second(let index1), .second(let index2)):
            return index1 < index2
        case (.first, .second):
            return true
        case (.second, .first):
            return false
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs._position, rhs._position) {
        case (.first(let index1), .first(let index2)):
            return index1 == index2
        case (.second(let index1), .second(let index2)):
            return index1 == index2
        default:
            return false
        }
    }

}

@available(iOS 13.0, *)
internal func concatenate<First: Collection, Second: Collection>(_ first: First, _ second: Second) -> ConcatenatedCollection<First, Second> where First.Element == Second.Element {
    ConcatenatedCollection(_base1: first, base2: second)
}
