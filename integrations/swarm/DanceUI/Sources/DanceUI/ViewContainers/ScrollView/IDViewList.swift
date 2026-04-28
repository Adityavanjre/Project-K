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
internal import DanceUIRuntime

@available(iOS 13.0, *)
internal struct IDViewList<Content: View, ID: Hashable>: StatefulRule {
    
    internal typealias Value = ViewList
    

    @Attribute
    internal var view: IDView<Content, ID>


    internal var inputs: _ViewListInputs


    internal var parentSubgraph: DGSubgraphRef


    internal var allItems: MutableBox<[Unmanaged<Item>]>


    internal var lastItem: Item?
    
    internal init(view: Attribute<IDView<Content, ID>>,
                  inputs: _ViewListInputs,
                  lastItem: Item?) {
        self._view = view
        self.inputs = inputs
        self.parentSubgraph = .current!
        self.allItems = .init([])
        self.lastItem = lastItem
    }
    
    internal mutating func updateValue() {
        let view = self.view
        if let item = self.lastItem {
            if item.id != view.id || !item.subgraph.isValid {
                if item.subgraph.isValid {
                    item.subgraph.willRemove()
                    parentSubgraph.remove(child: item.subgraph)
                }
                item.release(isInserted: false)
                lastItem = nil
            }
        }
        
        if self.lastItem == nil {
            for item in allItems.value {
                let itemValue = item.takeUnretainedValue()
                guard itemValue.id == view.id else {
                    continue
                }
                itemValue.retain()
                parentSubgraph.add(child: itemValue.subgraph)
                itemValue.subgraph.didReinsert()
                self.lastItem = itemValue
                break
            }
        }
        
        if self.lastItem == nil && parentSubgraph.isValid {
            let newSubgraph = DGSubgraphCreate(parentSubgraph.graph)
            parentSubgraph.add(child: newSubgraph)
            var isUnary = false
            let viewList: Attribute<ViewList> = newSubgraph.apply {
                let cachedView = CachedView(view: _view, id: view.id)
                let listOutputs = Content._makeViewList(view: _GraphValue<Content>.init(cachedView), inputs: self.inputs)
                isUnary = (listOutputs.staticCount ?? 0) == 1
                return listOutputs.makeAttribute(inputs: self.inputs)
            }
            self.lastItem = Item(id: view.id, isUnary: isUnary, list: viewList, owner: .current!, subgraph: newSubgraph, allItems: self.allItems)
        }
        
        if let item = self.lastItem {
            let transactionID = TransactionID(context: RuleContext(attribute: Attribute<ViewList>(identifier: .current!)))
            value = WrappedList(base: item.list.value, item: item, lastID: item.id, lastTransaction: transactionID)
        } else {
            value = EmptyViewList()
        }
    }

}

@available(iOS 13.0, *)
extension IDViewList {
    
    internal struct Transform: _ViewList_SublistTransform_Item {
        
        internal var item: Item
        
        internal func apply(sublist: inout _ViewList_Sublist) {
            item.bindID(id: &sublist.id)
            sublist.elements = item.wrapping(sublist.elements)
        }
    }
    
    internal final class Item: _ViewList_Subgraph {
        
        internal let id: ID
        
        internal let isUnary: Bool
        
        internal let list: Attribute<ViewList>
        
        internal let owner: DGAttribute
        
        internal let allItems: MutableBox<[Unmanaged<Item>]>
        
        internal init(id: ID, isUnary: Bool, list: Attribute<ViewList>, owner: DGAttribute, subgraph: DGSubgraphRef, allItems: MutableBox<[Unmanaged<Item>]>) {
            self.id = id
            self.isUnary = isUnary
            self.list = list
            self.owner = owner
            self.allItems = allItems
            super.init(subgraph: subgraph)
            self.allItems.value.append(Unmanaged.passUnretained(self))
        }
        
        internal override func invalidate() {
            guard let index = allItems.value.firstIndex(where: {$0 == Unmanaged.passUnretained(self)}) else {
                return
            }
            allItems.value.remove(at: index)
        }
        
        internal func bindID(id: inout _ViewList_ID) {
            id.bind(id: self.id, owner: self.owner, isUnary: self.isUnary)
        }
    }
    
    internal struct WrappedList: ViewList {
        
        internal typealias IDType = ID
        
        internal let base: ViewList
        
        internal let item: Item
        
        internal let lastID: ID?

        internal let lastTransaction: TransactionID
        
        internal var viewIDs: _ViewList_ID.Views? {
            base.viewIDs
        }
        
        internal var traits: ViewTraitCollection {
            base.traits
        }
        
        internal var traitKeys: ViewTraitKeys? {
            base.traitKeys
        }
        
        internal func firstOffset<Index: Hashable>(forID id: Index, style: _ViewList_IteratorStyle) -> Int? where ID : Hashable {
            guard item.id == (id as? ID) else {
                if let lastID = lastID, lastID.hashValue == id.hashValue  {
                    return 0
                }
                return base.firstOffset(forID: id, style: style)
            }
            return 0
        }
        
        internal func count(style: _ViewList_IteratorStyle) -> Int {
            base.count(style: style)
        }
        
        internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
            base.estimatedCount(style: style)
        }
        
        internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
            transform.push(Transform(item: item))
            defer {
                transform.pop()
            }
            return base.applyNodes(from: &index, style: style, list: list, transform: &transform, to: body)
        }

        internal func edit(forID id: _ViewList_ID, since: TransactionID) -> _ViewList_Edit? {
            base.edit(forID: id, since: since)
        }
    }
    
    internal struct WrappedIDs: Collection, Equatable {
        
        internal typealias Element = _ViewList_ID
        
        internal typealias Iterator = IndexingIterator<Self>
        
        internal typealias Index = Int
        
        internal let base: ViewList
        
        internal let item: Item
        
        internal var startIndex: Int {
            0
        }
        
        internal var endIndex: Int {
            count
        }
        
        internal subscript(position: Int) -> _ViewList_ID {
            base.viewIDs![position]
        }
        
        internal func index(after i: Int) -> Int {
            i + 1
        }
        
        internal var count: Int {
            base.count
        }
        
        internal static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.item.id == rhs.item.id &&
                DGCompareValues(lhs: lhs.base, rhs: rhs.base)
        }
        
    }
    
}

@available(iOS 13.0, *)
fileprivate struct CachedView<Content: View, ID: Hashable>: StatefulRule {
    
    internal typealias Value = Content
    
    @Attribute
    internal var view: IDView<Content, ID>
    
    internal var id: ID
    
    internal mutating func updateValue() {
        let view = self.view
        guard !context.hasValue || self.id == view.id else {
            return
        }
        value = view.content
    }
}
