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
internal struct _ViewList_ID: Hashable {

    internal var _index: Int32

    internal var implicitID: Int32

    internal var explicitIDs: ArrayWith2Inline<Explicit>

    @inlinable
    internal init(implicitID: Int) {
        self.init(_index: 0,
                  implicitID: numericCast(implicitID),
                  explicitIDs: ArrayWith2Inline())
    }

    @inline(__always)
    private init(_index: Int32, implicitID: Int32, explicitIDs: ArrayWith2Inline<Explicit>) {
        self._index = _index
        self.implicitID = implicitID
        self.explicitIDs = explicitIDs
    }

    @inlinable
    internal var primaryExplicitID: AnyHashable? {
        explicitIDs.first
    }

    @inlinable
    internal func elementID(at index: Int) -> _ViewList_ID {
        _ViewList_ID(_index: numericCast(index), implicitID: implicitID, explicitIDs: explicitIDs)
    }

    internal func elementIDs(count: Int) -> ElementCollection {
        ElementCollection(id: self, count: count)
    }

    @inlinable
    internal func explicitID<T: Hashable>(owner: DanceUIGraph.DGAttribute) -> T? {
        for explicitID in explicitIDs where explicitID.owner == owner {
            if let result = explicitID.id.base as? T {
                return result
            }
        }
        return nil
    }

    @inlinable
    internal mutating func bind(id: AnyHashable, owner: DanceUIGraph.DGAttribute, isUnary: Bool) {
        explicitIDs.append(Explicit(id: id, owner: owner, isUnary: isUnary))
    }

    internal struct Explicit: Hashable {

        internal let id: AnyHashable

        internal let owner: DGAttribute

        internal let isUnary: Bool

    }

    internal struct ElementCollection: RandomAccessCollection, Equatable {

        internal typealias Element = _ViewList_ID

        internal typealias Iterator = IndexingIterator<Self>

        internal typealias Index = Int

        internal typealias SubSequence = Slice<Self>

        internal typealias Indices = Range<Int>

        internal var id: _ViewList_ID

        internal var count: Int

        @inlinable
        internal init(id: _ViewList_ID, count: Int) {
            self.id = id
            self.count = count
        }

        @inlinable
        internal var startIndex: Int {
            0
        }

        @inlinable
        internal var endIndex: Int {
            count
        }

        @inlinable
        internal subscript(position: Int) -> _ViewList_ID {
            _ViewList_ID(_index: numericCast(position), implicitID: id.implicitID, explicitIDs: id.explicitIDs)
        }

    }


    internal class Views: RandomAccessCollection, Equatable {

        internal typealias Element = _ViewList_ID

        internal typealias Iterator = IndexingIterator<Views>

        internal typealias Index = Int

        internal typealias SubSequence = Slice<Views>

        internal typealias Indices = Range<Int>

        internal let isDataDependent: Bool

        @inlinable
        internal init(isDataDependent: Bool) {
            self.isDataDependent = isDataDependent
        }

        @inlinable
        internal var startIndex: Int {
            0
        }

        internal var endIndex: Int {
            _abstract(self)

        }

        subscript(position: Int) -> _ViewList_ID {
            _abstract(self)
        }

        internal func isEqual(to views: Views) -> Bool {
            _abstract(self)
        }

        @inlinable
        internal static func == (lhs: Views, rhs: Views) -> Bool {
            lhs.isEqual(to: rhs)
        }

    }

    internal final class _Views<BaseType: Collection & Equatable>: Views where BaseType.Element == _ViewList_ID, BaseType.Index == Int {

        internal var base: BaseType

        @inlinable
        internal init(_ base: BaseType, isDataDependent: Bool) {
            self.base = base
            super.init(isDataDependent: isDataDependent)
        }

        @inlinable
        internal override func isEqual(to views: Views) -> Bool {
            guard let another = views as? _Views else {
                return false
            }
            return base == another.base
        }

        @inlinable
        internal override var endIndex: Int {
            base.endIndex
        }

        @inlinable
        internal override subscript(position: Int) -> _ViewList_ID {
            base[position]
        }

    }

    internal final class JoinedViews: Views {

        internal let views: [(views: Views, endOffset: Int)]

        internal let count: Int

        @inlinable
        internal init(_ views: [Views], isDataDependent: Bool) {
            var endOffset = 0

            self.views = views.enumerated().map { (index, viewsElement) in
                endOffset += views.distance(from: 0, to: viewsElement.endIndex)
                return (views: viewsElement, endOffset: endOffset)
            }
            self.count = endOffset
            super.init(isDataDependent: isDataDependent)
        }

        @inlinable
        internal override var endIndex: Int {
            views.endIndex
        }

        @inlinable
        internal override subscript(index: Int) -> Element {
            guard let (views, endOffset) = views.first(where: {$0.endOffset < index}) else {
                _danceuiPreconditionFailure()
            }

            let viewIndex = views.index(views.startIndex, offsetBy: endOffset - index)

            return views[viewIndex]
        }

        @inlinable
        internal override func isEqual(to views: Views) -> Bool {
            guard let another = views as? JoinedViews else {
                return false
            }
            return self.views.elementsEqual(another.views, by: {$0.views == $1.views && $0.endOffset == $1.endOffset})
        }

    }

    internal struct Canonical: Hashable {

        internal var _index: Int32

        internal var implicitID: Int32

        internal var explicitID: AnyHashable?

        @inlinable
        internal init(id: _ViewList_ID) {
            self._index = numericCast(id._index)
            self.implicitID = numericCast(id.implicitID)
            self.explicitID = id.explicitIDs.first
        }
    }

}
