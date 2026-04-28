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
internal struct ModifiedViewList<Modifier: ViewModifier>: ViewList {

    internal let base: ViewList

    internal let modifier: _GraphValue<Modifier>

    internal let inputs: _GraphInputs

    @usableFromInline
    internal var viewIDs: _ViewList_ID.Views? {
        base.viewIDs
    }

    @usableFromInline
    internal var traits: ViewTraitCollection {
        base.traits
    }

    @usableFromInline
    internal var traitKeys: ViewTraitKeys? {
        base.traitKeys
    }

    internal func count(style: _ViewList_IteratorStyle) -> Int {
        base.count(style: style)
    }

    internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        base.estimatedCount(style: style)
    }

    internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        let item = Transform(modifier: modifier, inputs: inputs)
        transform.push(item)
        let result = base.applyNodes(from: &index, style: style, list: list, transform: &transform, to: body)
        transform.pop()
        return result
    }

    internal func edit(forID id: _ViewList_ID, since: TransactionID) -> _ViewList_Edit? {
        base.edit(forID: id, since: since)
    }

    internal func firstOffset<ID: Hashable>(forID id: ID,
                                            style: _ViewList_IteratorStyle) -> Int? {
        base.firstOffset(forID: id, style: style)
    }

}

@available(iOS 13.0, *)
extension ModifiedViewList {

    fileprivate struct Transform: _ViewList_SublistTransform_Item {

        internal var modifier: _GraphValue<Modifier>

        internal var inputs: _GraphInputs

        internal func apply(sublist: inout _ViewList_Sublist) {
            sublist.elements = ModifiedElements(base: sublist.elements, modifier: modifier, baseInputs: inputs)
        }
    }
}

@available(iOS 13.0, *)
extension ModifiedViewList {

    internal final class ListModifier: _ViewListOutputs.ListModifier {

        let pred: _ViewListOutputs.ListModifier?

        let modifier: _GraphValue<Modifier>

        let inputs: _GraphInputs

        internal init(pred: _ViewListOutputs.ListModifier?, modifier: _GraphValue<Modifier>, inputs: _GraphInputs) {
            self.pred = pred
            self.modifier = modifier
            self.inputs = inputs
        }

        internal override func apply(to viewList: inout ViewList) {
            if let predModifier = pred {
                predModifier.apply(to: &viewList)
            }
            viewList = ModifiedViewList<Modifier>(base: viewList, modifier: modifier, inputs: inputs)
        }
    }

}
