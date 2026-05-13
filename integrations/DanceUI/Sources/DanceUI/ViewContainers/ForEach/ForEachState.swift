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

// iOS 14
@available(iOS 13.0, *)
internal final class ForEachState<Data: RandomAccessCollection, ID: Hashable, Content: View> where Data.Index: Hashable {
    

    internal let inputs: _ViewListInputs
    

    internal let parentSubgraph: DGSubgraphRef
    

    internal var info: Attribute<Info>?
    

    internal var list: Attribute<ViewList>?
    

    internal var view: ForEach<Data, ID, Content>?
    

    internal var viewsPerElement: Int??
    
// , corrected with iOS 14.3
    internal var viewCounts: [Int]

    // , corrected with iOS 14.3
    internal var viewCountStyle: _ViewList_IteratorStyle
    

    internal var items: [ID: Item]
    

    internal var edits: [ID: _ViewList_Edit]
    

    internal var lastTransaction: TransactionID
    

    internal var lastOffset: Int
    

    internal var seed: UInt32
    
    internal var traitKeys: ViewTraitKeys? {
        var traitKeys: ViewTraitKeys? = nil
        var index = 0
        _ = forEachItem(from: &index, style: .default) { (index, _, item) -> Bool in
            switch item.views {
            case .staticList:
                traitKeys = .init()
            case .dynamicList(let attribute, _):
                let listValue = DanceUIGraph.AnyRuleContext(list!.identifier)[attribute]
                traitKeys = listValue.traitKeys
            }
            return false
        }
        guard let traitKeys = traitKeys else {
            return nil
        }
        
        return traitKeys.isDataDependent ? nil : traitKeys
    }
    
    internal func count(style: _ViewList_IteratorStyle) -> Int {
        
        guard parentSubgraph.isValid else {
            return 0
        }
        
        let dataCount = view!.data.count
        
        guard dataCount != 0 else {
            return 0
        }
        
        if let views = fetchViewsPerElement() {
            
            let sumCount = views * dataCount
            
            if style.needsMultiplier {
                return sumCount * style.multiplier
            } else {
                return sumCount
            }
            
        } else {
            
            if viewCounts.count < dataCount {
                
                var primaryCount = 0
                var secondaryCount = 0
                
                var startIndex = 0
                
                forEachItem(from: &startIndex, style: .default) { (index, _, item) -> Bool in
                    switch item.views {
                    case let .dynamicList(viewList, _):
                        let list = DanceUIGraph.AnyRuleContext(list!.identifier)[viewList]
                        
                        primaryCount = list.count(style: style) + primaryCount
                        
                    case let .staticList(elements):
                        let elementsCount = elements.count
                        if style.needsMultiplier {
                            primaryCount = elementsCount + primaryCount
                        } else {
                            primaryCount = (elementsCount * style.multiplier) + primaryCount
                        }
                        
                    }
                    
                    let viewCountsCount = viewCounts.count
                    
                    if viewCountsCount == 0 || viewCountsCount == secondaryCount || self.viewCountStyle != style {
                        viewCounts.append(primaryCount)
                        viewCountStyle = style
                    }
                    
                    secondaryCount += 1
                    
                    return true
                }
                
                return primaryCount
            } else {
                return viewCounts[dataCount - 1]
            }
            
        }
    }
    
    internal var viewIDs: _ViewList_ID.Views? {
        guard parentSubgraph.isValid else {
            return nil
        }
        
        guard let preElement = fetchViewsPerElement() else {
            return nil
        }
        
        var index = 0
        var resultViewIDs: _ViewList_ID.Views?
        forEachItem(from: &index, style: .default) { indexValue, iteratorStyle, item in
            switch item.views {
            case .staticList:
                let staticIDCollection = StaticViewIDCollection(count: preElement)
                resultViewIDs = _ViewList_ID._Views(staticIDCollection, isDataDependent: false)
            case .dynamicList(let listAttribute, _):
                guard let forEachListAttribute = self.list else {
                    fatalError("ViewList Attribute is nil.")
                }
                let list = AnyRuleContext(forEachListAttribute.identifier)[listAttribute]
                resultViewIDs = list.viewIDs
            }
            return false
        }
        
        guard let resultViewIDs,
              let view,
              let list,
              !resultViewIDs.isEmpty else {
            return nil
        }

        let forEachIDcollection = ForEachViewIDCollection(base: resultViewIDs,
                                                          data: view.data,
                                                          idGenerator: view.idGenerator,
                                                          reuseID: nil,
                                                          isUnary: preElement == 1,
                                                          owner: list.identifier)
        
        return _ViewList_ID._Views(forEachIDcollection, isDataDependent: true)
    }
    
    internal init(inputs: _ViewListInputs) {
        self.inputs = inputs
        self.view = nil
        self.viewsPerElement = nil
        self.parentSubgraph = .current!
        self.viewCounts = []
        self.viewCountStyle = .default
        self.items = [:]
        self.edits = [:]
        self.lastTransaction = TransactionID()
        self.lastOffset = .max
        self.seed = 0
    }
    
    deinit {
        
    }
    
    /// `isViewChanged` indicates whether the view has changed
    internal func update(view: ForEach<Data, ID, Content>) {
        guard parentSubgraph.isValid else {
            return
        }
        let oldSeed = seed
        seed &+= 1
        invalidateViewCounts()

        guard let oldView = self.view, case .offset = oldView.idGenerator else {
            self._update(keyPathView: view)
            return
        }
        self._update(offsetView: view, seed: oldSeed)
    }
    
    private func _update(keyPathView: ForEach<Data, ID, Content>) {
        self.view = keyPathView
        edits.removeAll(keepingCapacity: false)
        lastTransaction = .init(context: RuleContext(attribute: list!))

        guard lastOffset >= 0 else {
            lastOffset = .max
            return
        }

        var startIndex = keyPathView.data.startIndex
        let endIndex = keyPathView.data.endIndex
        var lastOffset = 0
        var containsRemoved = true

        if !items.isEmpty && startIndex != endIndex {
            var itemsCount: Int = items.count
            var offset = 0
            while itemsCount > 0 {
                let idInfo = self.view!.makeID(index: startIndex, offset: offset)
                if let foundedItem: Item = items[idInfo.id] {
                    foundedItem.index = startIndex
                    foundedItem.offset = offset
                    foundedItem.seed = self.seed
                    itemsCount -= 1
                    if foundedItem.isRemoved {
                        edits[idInfo.id] = .inserted
                    }
                } else {
                    edits[idInfo.id] = .inserted
                }
                keyPathView.data.formIndex(after: &startIndex)
                lastOffset = offset
                offset += 1
                if startIndex == endIndex {
                    containsRemoved = false
                    break
                }
            }
        }
        self.lastOffset = lastOffset

        guard !containsRemoved else {
            return
        }

        var needsErasedItems: [Item] = []
        var itemStartIndex = items.startIndex
        let itemEndIndex = items.endIndex
        if itemStartIndex != itemEndIndex {
            var itemsCount: Int = items.count
            while itemsCount > 0 {
                let result = items[itemStartIndex]
                if !result.value.isRemoved && result.value.seed != self.seed {
                    needsErasedItems.append(result.value)
                    itemsCount -= 1
                    result.value.typedID.map { id in
                        edits[id] = .removed
                    }
                }
                items.formIndex(after: &itemStartIndex)
                if itemStartIndex == itemEndIndex {
                    break
                }
            }
        }

        for item in needsErasedItems {
            eraseItem(item)
        }
    }
    
    private func _update(offsetView: ForEach<Data, ID, Content>, seed: UInt32) {
        if self.view?.data.count != offsetView.data.count {
            // error log
            print("\(offsetView) count (\(offsetView.data.count) != its initial count \(self.view!.data.count).`ForEach(_:content:)` should only be used for *constant* data. Instead conform data to `Identifiable` or use `ForEach(_:id:content:)` and provide an explicit `id`!")
        } else {
            self.view = offsetView
        }
        
        for (_, value) in items {
            if value.seed == seed {
                value.seed = self.seed
            }
        }
        
        
    }
    
    internal func item(at index: Data.Index, offset: Int) -> Item {
        let idInfo = self.view!.makeID(index: index, offset: offset)
        let id = idInfo.id
        if let item = items[id] {
            if item.isRemoved {
                uneraseItem(item)
            }
            if item.seed != self.seed {
                item.offset = offset
                item.seed = self.seed
            }
            return item
        }
        let childSubgraph = DGSubgraphCreate2(parentSubgraph.graph, self.list?.identifier ?? .nil)
        self.parentSubgraph.add(child: childSubgraph)
        
        var newInpus = self.inputs
        newInpus.needTransition = true
        
        let (content, accessList) = _withObservation {
            Update.syncMainWithoutUpdate {
                let forEach = view!
                return forEach.content(forEach.data[index])
            }
        }
        
        let viewListOutputs: _ViewListOutputs = childSubgraph.apply {
            let child = Attribute(ForEachChild<Data, ID, Content>(info: info!, id: id))

            child.flags = .removable

            let _ = child.setValue(content) // Use `let _ =` to supress the wraning
            let trackings = _installObservation(accessList.map{[$0]} ?? [], child)

            child.mutateBody(as: ForEachChild<Data, ID, Content>.self, invalidating: true) { body in
                body.previousObservationTrackings = trackings
            }

            let viewList = Content._makeViewList(view: _GraphValue(child), inputs: newInpus)
            return viewList
        }
        
        let item = Item(id: id,
                        views: viewListOutputs.views,
                        subgraph: childSubgraph,
                        index: index,
                        offset: offset,
                        seed: self.seed,
                        state: self)
        items[id] = item
        
        if self.lastOffset <= offset {
            item.typedID.map { id in
                edits[id] = .inserted
            }
        }
        
        if self.viewsPerElement == nil {
            if let staticCount = viewListOutputs.staticCount {
                self.viewsPerElement = staticCount
            } else {
                self.viewsPerElement = Content._viewListCount(inputs: newInpus.viewListCountInputs)
            }
        }
        
        return item
    }
    
    internal func eraseItem(_ item: Item) {
        item.subgraph.willRemove()
        self.parentSubgraph.remove(child: item.subgraph)
        item.isRemoved = true
        item.release(isInserted: true)
    }
    
    internal func uneraseItem(_ item: Item) {
        item.retain()
        item.isRemoved = false
        self.parentSubgraph.add(child: item.subgraph)
        item.subgraph.didReinsert()
    }
    
    internal func fetchViewsPerElement() -> Int? {
        
        if let value = self.viewsPerElement {
            return value
        }
        
        guard view?.data.isEmpty == false else {
            return nil
        }
        
        _ = self.item(at: view!.data.startIndex, offset: 0)
        return self.viewsPerElement ?? nil
    }
    
    @discardableResult
    internal func forEachItem(from index: inout Int,
                              style: _ViewList_IteratorStyle,
                              do body: (inout Int, _ViewList_IteratorStyle, Item) -> Bool) -> Bool {
        //        print("[WSDBUG][ForEachState][forEachItem][begin] index: \(index)")
        guard parentSubgraph.isValid else {
            return true
        }
        let forEach = self.view!
        var startIndex = forEach.data.startIndex
        let endIndex = forEach.data.endIndex
        var offset: Int = 0
        if index > 0 {
            if var viewsPerElement = fetchViewsPerElement() {
                if style.needsMultiplier {
                    viewsPerElement *= style.multiplier
                }
                if index >= viewsPerElement {
                    offset = index / viewsPerElement
                    offset = offset >= forEach.data.count ? forEach.data.count : offset
                    forEach.data.formIndex(&startIndex, offsetBy: offset)
                    index -= viewsPerElement * offset
                }
            } else {
                if !viewCounts.isEmpty {
                    offset = viewCounts.firstIndex(where: { index < $0 }) ?? 1
                    forEach.data.formIndex(&startIndex, offsetBy: offset)
                    if offset > 0 {
                        index = viewCounts[index - 1]
                    }
                }
            }
        }
        
        while startIndex != endIndex {
            //            print("[WSDBUG][ForEachState][forEachItem][body1] \(startIndex) - \(endIndex)")
            let item = self.item(at: startIndex, offset: offset)
            guard body(&index, style, item) else {
                return false
            }
            offset += 1
            forEach.data.formIndex(after: &startIndex)
            //            print("[WSDBUG][ForEachState][forEachItem][body2] \(startIndex) - \(endIndex)")
        }
        return true
    }
    
    internal func edit(forID id: _ViewList_ID, since transactionID: TransactionID) -> _ViewList_Edit? {
        switch view!.idGenerator {
        case .keyPath:
            guard let explictID: ID = id.explicitID(owner: list!.identifier) else {
                return nil
            }
            if lastTransaction <= transactionID, let edit = edits[explictID] {
                return edit
            }
            guard let item = items[explictID], item.seed == seed else {
                return nil
            }
            switch item.views {
            case .staticList:
                return nil
            case .dynamicList(let viewListAttribute, _):
                let viewList = DanceUIGraph.AnyRuleContext(list!.identifier)[viewListAttribute]
                return viewList.edit(forID: id, since: transactionID)
            }
        case .offset:
            return nil
        }
    }
    
    internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
        guard parentSubgraph.isValid else {
            return 0
        }
        let view = self.view!
        guard view.data.count > 0 else {
            return 0
        }
        if let viewPerElement = fetchViewsPerElement() {
            var count = view.data.count * viewPerElement
            if style.needsMultiplier {
                count *= style.multiplier
            }
            return count
        }
        
        guard viewCounts.count < view.data.count || style != viewCountStyle else {
            var count = viewCounts[view.data.count - 1]
            if style.needsMultiplier {
                count *= style.multiplier
            }
            return count
        }
        
        var calculatedItemCount: Int = 0
        var totalCount: Int = 0
        for subItem in items {
            if subItem.value.seed == self.seed {
                calculatedItemCount += 1
                switch subItem.value.views {
                case .staticList(let elements):
                    var count = elements.count
                    if style.needsMultiplier {
                        count *= style.multiplier
                    }
                    calculatedItemCount += count
                case .dynamicList(let attribute, _):
                    let viewList = DanceUIGraph.AnyRuleContext(list!.identifier)[attribute]
                    totalCount += viewList.estimatedCount(style: style)
                }
            }
        }
        let uncalculateItemCount = view.data.count - calculatedItemCount
        guard uncalculateItemCount > 0 else {
            return totalCount
        }
        
        guard calculatedItemCount > 0 else {
            return totalCount + uncalculateItemCount
        }
        
        let diff = ceil(Double(totalCount) / Double(calculatedItemCount) * Double(uncalculateItemCount))
        _danceuiPrecondition(diff != .infinity)
        let diffCount = Int(diff)
        _danceuiPrecondition(diffCount > .min && diffCount < .max)
        return totalCount + diffCount
    }
    
    internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        forEachItem(from: &index, style: style) { (subIndex, style, item) -> Bool in
            switch item.views {
            case .staticList(let elements):
                return applyStaticList(from: &subIndex, style: style, transform: &transform, item: item, elements: elements, to: body)
            case .dynamicList(let attribute, let listModifier):
                return applyDynamicList(from: &subIndex, style: style, transform: &transform, item: item, childList: _GraphValue(attribute), listModifier: listModifier, to: body)
            }
        }
    }
    
    internal func applyStaticList(from index: inout Int, style: _ViewList_IteratorStyle, transform: inout _ViewList_SublistTransform, item: Item, elements: _ViewList_Elements, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        let elementCount = elements.count
        var count = elementCount
        if style.needsMultiplier {
            count *= style.multiplier
        }
        guard index < count else {
            index &-= count
            return true
        }
        
        var listID = _ViewList_ID(implicitID: 0)
        var id = AnyHashable(item.id)
        if view!.idGenerator.isConstant {
            id = AnyHashable(Pair(first: item.offset, second: list!.identifier))
        }
        var isUnary = false
        if let viewPerElementsWrapper = self.viewsPerElement, let viewPerElementsValue = viewPerElementsWrapper {
            isUnary = viewPerElementsValue == 1
        } else {
            isUnary = false
        }
        listID.bind(id: id, owner: list!.identifier, isUnary: isUnary)
        let sublist = _ViewList_Sublist(start: index,
                                          count: elementCount,
                                          id: listID,
                                          elements: elements,
                                          traits: .init(),
                                          list: nil,
                                          fromForEach: false)
        let transformItem = Transform(item: item, contentID: view!.contentID, bindID: false, isUnary: isUnary, isConstant: view!.idGenerator.isConstant)
        transform.push(transformItem)
        let result = body(&index, style, .sublist(sublist), &transform)
        transform.pop()
        return result
    }
    
    internal func applyDynamicList(from index: inout Int, style: _ViewList_IteratorStyle, transform: inout _ViewList_SublistTransform, item: Item, childList: _GraphValue<ViewList>, listModifier: _ViewListOutputs.ListModifier?, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
        var childViewList = DanceUIGraph.AnyRuleContext(self.list!.identifier)[childList.value]
        if let modifier = listModifier {
            modifier.apply(to: &childViewList)
        }
        var isUnary = false
        if let viewPerElementsWrapper = self.viewsPerElement, let viewPerElementsValue = viewPerElementsWrapper {
            isUnary = viewPerElementsValue == 1
        } else {
            isUnary = false
        }
        let view = view!
        
        let transformItem = Transform(item: item, contentID: view.contentID, bindID: true, isUnary: isUnary, isConstant: view.idGenerator.isConstant)
        transform.push(transformItem)
        let result = childViewList.applyNodes(from: &index, style: style, list: childList, transform: &transform, to: body)
        transform.pop()
        return result
    }
    
    internal func invalidateViewCounts() {
        viewCounts.removeAll()
        viewCountStyle = .default
    }
    
    internal func firstOffset<Index: Hashable>(forID id: Index,
                                               style: _ViewList_IteratorStyle) -> Int? {
        guard parentSubgraph.isValid else {
            return nil
        }

        var isSameType = false
        if Index.self == ID.self,
           case .keyPath = view!.idGenerator {
            isSameType = true
        }
        
        var fromIndex = 0
        var v40_loopCounter = 0
        var v70_result: Int? = nil
        
        let _ = forEachItem(from: &fromIndex, style: style) { (subIndex, style, item) -> Bool in
            var v30_result: Int = 0
            if !isSameType || item.typedID == nil || (item.typedID as! Index != id) {
                switch item.views {
                case .staticList:
                    v40_loopCounter &+= 1
                    return true
                case .dynamicList(let attribute, _):
                    let listValue = DanceUIGraph.AnyRuleContext(list!.identifier)[attribute]
                    guard let firstOffset = listValue.firstOffset(forID: id, style: style) else {
                        v40_loopCounter &+= 1
                        return true
                    }
                    v30_result = firstOffset
                }
            }
            
            guard v40_loopCounter != 0 else {
                v70_result = v30_result
                return false
            }
            if var fetchedViews = fetchViewsPerElement() {
                ///
                if style.needsMultiplier {
                    fetchedViews *= style.multiplier
                }
                fetchedViews *= v40_loopCounter
                v30_result += fetchedViews
            } else {
                if viewCounts.count < v40_loopCounter || style != viewCountStyle {
                    var subloopCount = 0
                    var subFromIndex = 0
                    _ = forEachItem(from: &subFromIndex, style: style, do: { (subIdx, style, item) -> Bool in
                        guard v40_loopCounter != subloopCount else {
                            return false
                        }
                        subloopCount &+= 1
                        switch item.views {
                        case .staticList(let elements):
                            var count = elements.count
                            if style.needsMultiplier {
                                count *= style.multiplier
                            }
                            v30_result += count
                        case .dynamicList(let attribute, _):
                            let listValue = DanceUIGraph.AnyRuleContext(list!.identifier)[attribute]
                            v30_result += listValue.count
                            return true
                        }
                        return true
                    })
                } else {
                    v30_result += viewCounts[v40_loopCounter - 1]
                }
            }
            v70_result = v30_result
            return false
        }
        return v70_result
    }
    
    internal struct StaticViewIDCollection: RandomAccessCollection, Equatable {
        
        internal var count: Int
        
        internal subscript(position: Int) -> _ViewList_ID { 
            var viewID = _ViewList_ID(implicitID: 0)
            viewID._index = Int32(position)
            return viewID
        }
        
        internal var endIndex: Int {
            count
        }
        
        internal var startIndex: Int {
            0
        }
        
        internal typealias Element = _ViewList_ID
        
        internal typealias Index = Int
        
        internal typealias SubSequence = Slice<StaticViewIDCollection>
        
        internal typealias Indices = Range<Int>
    }
    
    internal struct ForEachViewIDCollection: RandomAccessCollection, Equatable {
        
        internal typealias Element = _ViewList_ID
        
        internal typealias Index = Int
        
        internal typealias SubSequence = Slice<ForEachViewIDCollection>
        
        internal typealias Indices = Range<Int>
        

        internal var base: _ViewList_ID.Views
        

        internal var data: Data
        

        internal var idGenerator: ForEach<Data, ID, Content>.IDGenerator
        

        internal var reuseID: KeyPath<Data, Int>?
        

        internal var isUnary: Bool
        

        internal var owner: DGAttribute
        

        internal var baseCount: Int
        

        internal var count: Int
        
        internal init(base: _ViewList_ID.Views,
                      data: Data,
                      idGenerator: ForEach<Data, ID, Content>.IDGenerator,
                      reuseID: KeyPath<Data, Int>?,
                      isUnary: Bool,
                      owner: DGAttribute) {
            self.base = base
            self.data = data
            self.idGenerator = idGenerator
            self.reuseID = reuseID
            self.isUnary = isUnary
            self.owner = owner
            self.baseCount = (data.startIndex as? Int) ?? 0
            self.count = data.count + self.baseCount
        }

        internal subscript(position: Int) -> _ViewList_ID {
            _ViewList_ID(implicitID: 0)
        }
        
        internal var startIndex: Int {
            baseCount
        }
        
        internal var endIndex: Int {
            count
        }
        
        internal static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.base == rhs.base &&
            lhs.reuseID == rhs.reuseID &&
            lhs.isUnary == rhs.isUnary &&
            DGCompareValues(lhs: lhs.data, rhs: rhs.data)
        }
    }
}

@available(iOS 13.0, *)
// MARK: Item

extension ForEachState {
    
    internal final class Item: _ViewList_Subgraph {
        

        internal let id: ID
        

        internal let views: _ViewListOutputs.Views
        

        internal weak var state: ForEachState<Data, ID, Content>? = nil
        

        internal var index: Data.Index
        

        internal var offset: Int
        

        internal var seed: UInt32
        

        internal var isRemoved: Bool
        
        internal var typedID: ID? {
            self.id
        }
        
        internal init(id: ID,
                      views: _ViewListOutputs.Views,
                      subgraph: DGSubgraphRef,
                      index: Data.Index,
                      offset: Int,
                      seed: UInt32,
                      state: ForEachState<Data, ID, Content>) {
            self.id = id
            self.isRemoved = false
            self.views = views
            self.index = index
            self.offset = offset
            self.seed = seed
            self.state = state
            super.init(subgraph: subgraph)
        }
        
        deinit {
            
        }
        
        internal override func invalidate() {
            
            guard let state = self.state else {
                return
            }
            
            guard let typedID = self.typedID else {
                return
            }
            state.items.removeValue(forKey: typedID)
        }
    }
}

@available(iOS 13.0, *)
extension ForEachState {
    
    internal struct Transform: _ViewList_SublistTransform_Item {
        

        internal var item: Item
        
        internal var contentID: Int
        
        internal var bindID: Bool
        
        internal var isUnary: Bool
        
        internal var isConstant: Bool
        
        internal func apply(sublist: inout _ViewList_Sublist) {
            if bindID, let state = item.state, let list = state.list?.identifier {
                var id = AnyHashable(item.id)
                if isConstant {
                    id = AnyHashable(Pair(first: item.offset, second:  list))
                }
                sublist.id.bind(id: id, owner: list, isUnary: isUnary)
            }
            
            sublist.elements = item.wrapping(sublist.elements)
            guard !sublist.fromForEach else {
                return
            }
            sublist.traits[DynamicViewContentIDTraitKey.self] = contentID
            sublist.traits[DynamicViewContentOffsetTraitKey.self] = item.offset
            if let id = item.typedID {
                sublist.traits[TagValueTraitKey.self] = TagValueTraitKey.Value.tagged(id)
            }
            sublist.fromForEach = true
        }
    }
}

@available(iOS 13.0, *)
internal struct Pair<A: Hashable, B: Hashable>: Hashable {
    
    var first: A
    
    var second: B
}

@available(iOS 13.0, *)
internal struct DynamicViewContentIDTraitKey: _ViewTraitKey {
    
    internal typealias Value = Int?
    
    internal static var defaultValue: Int? {
        nil
    }
    
}

@available(iOS 13.0, *)
internal struct DynamicViewContentOffsetTraitKey: _ViewTraitKey {
    
    internal typealias Value = Int?
    
    internal static var defaultValue: Int? {
        nil
    }
}
