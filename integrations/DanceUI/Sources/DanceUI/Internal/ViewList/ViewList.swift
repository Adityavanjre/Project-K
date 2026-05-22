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
internal protocol ViewList {

    func count(style: _ViewList_IteratorStyle) -> Int

    func estimatedCount(style: _ViewList_IteratorStyle) -> Int

    var traitKeys: ViewTraitKeys? { get }

    var viewIDs: _ViewList_ID.Views? { get }

    var traits: ViewTraitCollection { get }

    func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool

    func edit(forID id: _ViewList_ID, since transaction: TransactionID) -> _ViewList_Edit?

    func firstOffset<ID: Hashable>(forID id: ID, style: _ViewList_IteratorStyle) -> Int?

}

@available(iOS 13.0, *)
extension ViewList {

    internal var count: Int {
        count(style: .default)
    }

    internal func applySublists(from index: inout Int,
                                style: _ViewList_IteratorStyle = .default,
                                list: _GraphValue<ViewList>?,
                                to body: (_ViewList_Sublist) -> Bool) -> Bool {
        var transform = _ViewList_SublistTransform()
        return applySublists(from: &index, style: style, list: list, transform: &transform, to: body)
    }

    internal func applySublists(from index: inout Int,
                                style: _ViewList_IteratorStyle,
                                list: _GraphValue<ViewList>?,
                                transform: inout _ViewList_SublistTransform,
                                to body: (_ViewList_Sublist) -> Bool) -> Bool {
        applyNodes(from: &index, style: style, list: list, transform: &transform) { internalIndex, style, node, transform in
            node.applySublists(from: &internalIndex, style: style, transform: &transform, to: body)
        }
    }
}

@available(iOS 13.0, *)
internal struct _ViewList_Group: ViewList {

    internal var lists: [(list: ViewList, attribute: _GraphValue<ViewList>)]

    @usableFromInline
    internal init(lists: [(list: ViewList, attribute: _GraphValue<ViewList>)]) {
        self.lists = lists
    }

    internal var viewIDs: _ViewList_ID.Views? {
        guard !lists.isEmpty else {
            return nil
        }

        let viewCollection: [_ViewList_ID.Views] = lists.compactMap({ $0.list.viewIDs })
        if viewCollection.count == 0 {
            return _ViewList_ID._Views(EmptyCollection<_ViewList_ID>(), isDataDependent: false)
        } else if viewCollection.count == 1 {
            return viewCollection.first
        } else {
            return _ViewList_ID.JoinedViews(viewCollection, isDataDependent: false)
        }
    }

    internal var traits: ViewTraitCollection {
        .init()
    }

    internal func count(style: _ViewList_IteratorStyle) -> Int {
        lists.reduce(0, {$0 + $1.list.count})
    }

    internal var traitKeys: ViewTraitKeys? {

        guard !lists.isEmpty else {
            return nil
        }

        return lists.reduce(nil) { (result, element) -> ViewTraitKeys? in
            guard var trait = result, let otherTrait = element.list.traitKeys else {
                return element.list.traitKeys
            }
            trait.types.formUnion(otherTrait.types)
            if !otherTrait.isDataDependent {
                trait.isDataDependent = false
            }
            return trait
        }
    }

    internal func applyNodes(from index: inout Int,
                               style: _ViewList_IteratorStyle,
                               list: _GraphValue<ViewList>?,
                               transform: inout _ViewList_SublistTransform,
                               to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        body(&index, style, .group(self), &transform)
    }

    internal func applyNodes(from index: inout Int,
                               style: _ViewList_IteratorStyle,
                               transform: inout _ViewList_SublistTransform,
                               to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        for (viewList, viewListAttr) in lists {
            guard viewList.applyNodes(from: &index, style: style, list: viewListAttr, transform: &transform, to: body) else {
                return false
            }
        }
        return true
    }

    func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        var count: Int = 0
        for list in lists {
            count += list.list.estimatedCount(style: style)
        }
        return count
    }

    internal struct Init: Rule {

        internal typealias Value = ViewList

        internal var list: [Attribute<ViewList>]

        internal var value: ViewList {
            _ViewList_Group(lists: list.map({ ($0.value, _GraphValue<ViewList>($0)) }))
        }
    }

    internal func edit(forID id: _ViewList_ID, since: TransactionID) -> _ViewList_Edit? {
        for list in lists {
            if let edit = list.list.edit(forID: id, since: since) {
                return edit
            }
        }
        return nil
    }

    internal func firstOffset<ID: Hashable>(forID id: ID, style: _ViewList_IteratorStyle) -> Int? {
        var count = 0
        for (list, _) in lists {
            if let result = list.firstOffset(forID: id, style: style) {
                return count + result
            }
            count += list.count(style: style)
        }
        return nil
    }

}

@available(iOS 13.0, *)
internal struct _ViewList_Sublist {

    internal var start: Int

    internal var count: Int

    internal var id: _ViewList_ID

    internal var elements: _ViewList_Elements

    internal var traits: ViewTraitCollection

    internal var list: Attribute<ViewList>?

    internal var fromForEach: Bool
}
