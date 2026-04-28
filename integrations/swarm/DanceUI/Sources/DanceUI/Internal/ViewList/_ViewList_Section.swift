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
internal struct _ViewList_Section: ViewList {

    internal var id: UInt32

    internal var base: _ViewList_Group

    internal var traits: ViewTraitCollection

    internal struct Info {

        internal var id: UInt32

        internal var isHeader: Bool

        internal var isFooter: Bool
    }

    internal var traitKeys: ViewTraitKeys? {
        base.traitKeys
    }

    internal var viewIDs: _ViewList_ID.Views? {
        base.viewIDs
    }

    internal var header: (list: ViewList, attribute: Attribute<ViewList>) {
        (base.lists[0].list, base.lists[0].attribute.value)
    }

    internal var content: (list: ViewList, attribute: Attribute<ViewList>) {
        (base.lists[1].list, base.lists[1].attribute.value)
    }

    internal var footer: (list: ViewList, attribute: Attribute<ViewList>) {
        (base.lists[2].list, base.lists[2].attribute.value)
    }

    internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        let contentEstimatedCount = base.lists[1].list.estimatedCount(style: style)
        var totalEstimatedCount = contentEstimatedCount
        let multiplier = style.multiplier
        if multiplier != 1 {
            totalEstimatedCount &+= contentEstimatedCount % multiplier
        }
        let headerFooterStyle = style.headerFooterStyle
        let headerEstimatedCount = base.lists[0].list.estimatedCount(style: headerFooterStyle)
        totalEstimatedCount &+= headerEstimatedCount
        let footerEstimatedCount = base.lists[2].list.estimatedCount(style: headerFooterStyle)
        totalEstimatedCount &+= footerEstimatedCount
        return totalEstimatedCount
    }

    internal func count(style: _ViewList_IteratorStyle) -> Int {
        let contentCount = base.lists[1].list.estimatedCount(style: style)
        var totalCount = contentCount
        let multiplier = style.multiplier
        if multiplier != 1 {
            totalCount &+= contentCount % multiplier
        }
        let headerFooterStyle = style.headerFooterStyle
        let headerCount = base.lists[0].list.estimatedCount(style: headerFooterStyle)
        totalCount &+= headerCount
        let footerCount = base.lists[2].list.estimatedCount(style: headerFooterStyle)
        totalCount &+= footerCount
        return totalCount
    }

    internal func edit(forID id: _ViewList_ID, since transaction: TransactionID) -> _ViewList_Edit? {
        base.edit(forID: id, since: transaction)
    }

    internal func firstOffset<ID>(forID id: ID, style: _ViewList_IteratorStyle) -> Int? where ID : Hashable {
        guard !base.lists.isEmpty else {
            return nil
        }
        var count = 0
        for (index, (list, _)) in base.lists.enumerated() {
            let listStyle = index == 1 ? style : style.headerFooterStyle
            if let offset = list.firstOffset(forID: id, style: listStyle) {
                return offset + count
            }
            let listCount = list.count(style: listStyle)
            count += listCount
        }
        return count
    }

    internal func applyNodes(from index: inout Int,
                             style: _ViewList_IteratorStyle,
                             list: _GraphValue<ViewList>?,
                             transform: inout _ViewList_SublistTransform,
                             to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        body(&index, style, .section(self), &transform)
    }

    internal func applyNodes(from index: inout Int,
                             style: _ViewList_IteratorStyle,
                             transform: inout _ViewList_SublistTransform,
                             to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, _ViewList_Section.Info, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        style.alignToPreviousGranularityMultiple(&index)
        let headerFooterStyle = style.headerFooterStyle
        let multiplier = style.multiplier
        for (groupItemIndex, tuple) in base.lists.enumerated() {
            let inGroupStyle: _ViewList_IteratorStyle = groupItemIndex == 1 ? style : headerFooterStyle
            let (viewList, viewListAttr) = tuple
            let result = viewList.applyNodes(from: &index, style: inGroupStyle, list: viewListAttr, transform: &transform) { inNodeIndex, inNodeStyle, node, inNodeSublistTransform in
                body(&inNodeIndex, inNodeStyle, node, Info.init(id: id, isHeader: groupItemIndex == 0, isFooter: groupItemIndex == 0x2), &inNodeSublistTransform)
            }
            guard result else {
                return false
            }
            guard index != 0, multiplier != 1 else {
                continue
            }
            _danceuiPrecondition(multiplier != 0)
            index = index - (index / multiplier)
        }
        return true
    }
}
