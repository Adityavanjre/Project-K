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
internal struct ViewListSlice: ViewList {

    internal let base: ViewList

    internal let bounds: Range<Int>

    internal func count(style: _ViewList_IteratorStyle) -> Int {
        bounds.count
    }

    internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        bounds.count
    }

    internal var traitKeys: ViewTraitKeys? {
        nil
    }

    internal var viewIDs: _ViewList_ID.Views? {
        base.viewIDs.map({ ViewIDsSlice(base: $0, bounds: bounds) })
    }

    internal var traits: ViewTraitCollection {
        .init()
    }

    internal func applyNodes(from index: inout Int,
                             style: _ViewList_IteratorStyle,
                             list: _GraphValue<ViewList>?,
                             transform: inout _ViewList_SublistTransform,
                             to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        var start = index + bounds.lowerBound
        return base.applyNodes(from: &start,
                               style: style,
                               list: list,
                               transform: &transform) { indexValue, iteratorStyle, listNode, sublistTransform in
            guard indexValue < bounds.upperBound else {
                return false
            }
            let value = body(&indexValue, iteratorStyle, listNode, &sublistTransform)
            indexValue &+= 1
            return value
        }
    }

    internal func edit(forID id: _ViewList_ID, since transaction: TransactionID) -> _ViewList_Edit? {
        base.edit(forID: id, since: transaction)
    }

    internal func firstOffset<ID>(forID id: ID, style: _ViewList_IteratorStyle) -> Int? where ID : Hashable {
        guard let firstOffset = base.firstOffset(forID: id, style: style) else {
            return nil
        }
        return bounds.lowerBound &- firstOffset
    }

    internal class ViewIDsSlice: _ViewList_ID.Views {

        internal let base: _ViewList_ID.Views

        internal let bounds: Range<Int>

        internal init(base: _ViewList_ID.Views, bounds: Range<Int>) {
            self.base = base
            self.bounds = bounds
            super.init(isDataDependent: true)
        }

        internal override var endIndex: Int {
            bounds.upperBound &- bounds.lowerBound
        }

        internal override subscript(position: Int) -> _ViewList_ID {
            let index = position &+ bounds.lowerBound
            return base[index]
        }
    }
}
