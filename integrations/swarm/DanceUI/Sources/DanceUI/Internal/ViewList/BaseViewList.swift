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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct BaseViewList: ViewList {

    @usableFromInline
    internal var elements: _ViewList_Elements

    @usableFromInline
    internal var implicitID: Int

    @usableFromInline
    internal var traitKeys: ViewTraitKeys?

    @usableFromInline
    internal var traits: ViewTraitCollection

    @usableFromInline
    internal init(elements: _ViewList_Elements,
                  implicitID: Int,
                  canTransition: Bool,
                  traitKeys: ViewTraitKeys?,
                  traits: ViewTraitCollection) {
        self.elements = elements
        self.implicitID = implicitID
        self.traitKeys = traitKeys
        self.traits = traits
        guard canTransition else {
            return
        }
        self.traits[CanTransitionTraitKey.self] = true
    }

    @usableFromInline
    internal var viewIDs: _ViewList_ID.Views? {
        let id = _ViewList_ID(implicitID: implicitID)
        let collection: _ViewList_ID.ElementCollection = .init(id: id, count: elements.count)
        return _ViewList_ID._Views(collection, isDataDependent: false)
    }

    internal func count(style: _ViewList_IteratorStyle) -> Int {
        estimatedCount(style: style)
    }

    internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        guard style.needsMultiplier else {
            return elements.count
        }
        return elements.count * style.multiplier
    }

    internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        var elementCount = elements.count
        if style.multiplier > 0 {
            elementCount *= style.multiplier
        }
        guard index < elementCount else {
            index &-= elementCount
            return true
        }
        let id = _ViewList_ID(implicitID: implicitID)
        let sublist = _ViewList_Sublist(start: index, count: count, id: id, elements: elements, traits: traits, list: list?.value, fromForEach: false)
        let result = body(&index, style, .sublist(sublist), &transform)
        index = 0
        return result
    }

    internal func edit(forID id: _ViewList_ID, since: TransactionID) -> _ViewList_Edit? {
        nil
    }

    internal func firstOffset<ID: Hashable>(forID id: ID,
                                            style: _ViewList_IteratorStyle) -> Int? {
        nil
    }
}

@available(iOS 13.0, *)
extension BaseViewList {

    internal struct Init: Rule {

        internal typealias Value = ViewList

        internal let elements: _ViewList_Elements

        internal let implicitID: Int

        internal let canTransition: Bool

        internal let traitKeys: ViewTraitKeys?

        @OptionalAttribute
        internal var traits: ViewTraitCollection?

        internal var value: ViewList {
            BaseViewList(elements: elements,
                         implicitID: implicitID,
                         canTransition: canTransition,
                         traitKeys: traitKeys,
                         traits: self.traits ?? ViewTraitCollection())
        }

    }
}
