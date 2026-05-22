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
internal struct EmptyViewList: ViewList {

    internal var viewIDs: _ViewList_ID.Views? {
        _ViewList_ID._Views(EmptyCollection(), isDataDependent: false)
    }

    internal var traits: ViewTraitCollection {
        ViewTraitCollection()
    }

    internal var traitKeys: ViewTraitKeys? {
        ViewTraitKeys()
    }

    internal func count(style: _ViewList_IteratorStyle) -> Int {
        0
    }

    internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        0
    }

    internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        true
    }

    internal func edit(forID id: _ViewList_ID, since: TransactionID) -> _ViewList_Edit? {
        nil
    }

    internal func firstOffset<ID: Hashable>(forID id: ID, style: _ViewList_IteratorStyle) -> Int? {
        nil
    }
}
