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
internal enum _ViewList_Node {

    case list((ViewList, _GraphValue<ViewList>?))

    case sublist(_ViewList_Sublist)

    case group(_ViewList_Group)

    case section(_ViewList_Section)

    @usableFromInline
    internal func estimatedCount(_ style: _ViewList_IteratorStyle) -> Int {
        switch self {
        case .list((let viewList, _)):
            return viewList.estimatedCount(style: style)
        case .sublist(let sublist):
            return sublist.count
        case .group(let group):
            return group.estimatedCount(style: style)
        case .section(let section):
            return section.estimatedCount(style: style)
        }
    }

    internal func applyNodes(from index: inout Int,
                             style: _ViewList_IteratorStyle,
                             transform: inout _ViewList_SublistTransform,
                             to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        switch self {
        case .list((let list, let attribute)):
            return list.applyNodes(from: &index, style: style, list: attribute, transform: &transform, to: body)
        case .sublist(let sublist):
            var count = sublist.count
            if style.needsMultiplier {
                count *= style.multiplier
            }
            guard index < count else {
                index &-= count
                return true
            }
            let result = body(&index, style, .sublist(sublist), &transform)
            index = 0
            return result
        case .group(let viewListGroup):
            return viewListGroup.applyNodes(from: &index, style: style, transform: &transform, to: body)
        case .section(let viewListSection):
            guard !viewListSection.base.lists.isEmpty,
                  let (firstViewList, firstViewListAttribute) = viewListSection.base.lists.first else {
                fatalError("lists in _ViewList_Section is empty when applyNodes.")
            }
             return firstViewList.applyNodes(from: &index, style: style, list: firstViewListAttribute, transform: &transform, to: body)
        }
    }

    internal func firstOffset<Index: Hashable>(forID id: Index,
                                               style: _ViewList_IteratorStyle) -> Int? {
        switch self {
        case .list((let list, _)):
            return list.firstOffset(forID: id, style: style)
        case .sublist(let sublist):
            return nil
        case .group(let viewListGroup):
            return viewListGroup.firstOffset(forID: id, style: style)
        case .section(let viewListSection):
            return viewListSection.firstOffset(forID: id, style: style)
        }
    }

    internal func applySublists(from index: inout Int, style: _ViewList_IteratorStyle, transform: inout _ViewList_SublistTransform, to body: (_ViewList_Sublist) -> Bool) -> Bool {
        switch self {
        case .list((let list, let attribute)):
            return list.applySublists(from: &index, list: attribute, to: body)
        case .sublist(var sublist):
            var count = sublist.count
            if style.needsMultiplier {
                count *= style.multiplier
            }
            guard index < count else {
                return true
            }
            for item in transform.items.reversed() {
                item.apply(sublist: &sublist)
            }
            return body(sublist)
        case .group(let group):
            return group.applyNodes(from: &index, style: style, transform: &transform) { index, style, node, transform in
                node.applySublists(from: &index, style: style, transform: &transform, to: body)
            }
        case .section(let viewListSection):
            return viewListSection.applyNodes(from: &index, style: style, transform: &transform) { indexValue, iteratorStyle, node, info, sublistTransfrom in
                node.applySublists(from: &indexValue, style: iteratorStyle, transform: &sublistTransfrom, to: body)
            }
        }
    }

}
