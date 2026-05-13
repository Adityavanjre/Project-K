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
internal struct ForEachList<Data: RandomAccessCollection, ID: Hashable, Content: View>: ViewList where Data.Index: Hashable {
    

    internal var state: ForEachState<Data, ID, Content>
    

    internal var seed: UInt32
    
    internal func count(style: _ViewList_IteratorStyle) -> Int {
        state.count(style: style)
    }
    
    internal var viewIDs: _ViewList_ID.Views? {
        state.viewIDs
    }
    
    internal var traits: ViewTraitCollection {
        .init()
    }
    
    internal var traitKeys: ViewTraitKeys? {
        state.traitKeys
    }
    
    internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        state.estimatedCount(style: style)
    }
    
    internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        return state.applyNodes(from: &index, style: style, list: list, transform: &transform, to: body)
    }
    
    internal func edit(forID id: _ViewList_ID,
                       since: TransactionID) -> _ViewList_Edit? {
        state.edit(forID: id, since: since)
    }
    
    internal func firstOffset<_ID: Hashable>(forID id: _ID,
                                            style: _ViewList_IteratorStyle) -> Int? {
        state.firstOffset(forID: id, style: style)
    }
}

@available(iOS 13.0, *)
extension ForEachList {
    
    internal struct Init: StatefulRule {
        
        internal typealias Value = ViewList
        
        @Attribute
        internal var info: ForEachState<Data, ID, Content>.Info
        
        internal var seed: UInt32
        
        internal mutating func updateValue() {
            let info = info
            info.state.invalidateViewCounts()
            seed &+= 1
            value = ForEachList(state: info.state, seed: seed)
        }
    }
}

