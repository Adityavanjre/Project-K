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
internal class ViewCache {

    internal weak var viewGraph: ViewGraph?

    internal unowned(unsafe) let parentSubgraph: DGSubgraphRef

    internal let inputs: _ViewInputs

    internal var outputs: _ViewOutputs

    @Attribute
    internal var list: ViewList

    @Attribute
    internal var layoutDirection: LayoutDirection

    @Attribute
    internal var accessibilityEnabled: Bool

    @Attribute
    internal var placedChildren: [_IncrementalLayout_PlacedChild]

    internal var items: [_ViewList_ID.Canonical: ViewCacheItem]

    internal var usedSeed: UInt32

    internal var commitSeed: UInt32 = 0

    internal var lastTransactionID: TransactionID

    internal var placementSeed: UInt32

    internal var failedSeed: UInt32 = 0

    internal var invalidationSeed : UInt32 = 0

    internal var invalidationTTL : UInt8 = 0

    internal var hasSections: Bool

    internal var hasDepth: Bool = false

    internal var isFirstCommit: Bool

    internal var currentTransactionID: TransactionID {
        self.viewGraph?.transactionID ?? TransactionID()
    }

    internal func mayInvalidate() -> Bool {
        guard let viewGraph else {
            return false
        }
        let updateSeed = DGGraphRef.withoutUpdate {
            viewGraph.updateSeed
        }

        if self.invalidationSeed != updateSeed {
            self.invalidationSeed = updateSeed
            self.invalidationTTL = 2
        }

        if invalidationTTL != 0 {
            invalidationTTL -= 1
            return true
        } else {
            return false
        }
    }

    internal init<Layout: IncrementalLayout>(layout: Attribute<Layout>,
                                             list: Attribute<ViewList>,
                                             inputs: _ViewInputs) {
        items = [:]
        usedSeed = 0
        placementSeed = 0
        lastTransactionID = TransactionID()
        hasSections = false
        isFirstCommit = true
        viewGraph = GraphHost.currentHost as? ViewGraph
        self.inputs = inputs
        parentSubgraph = DGSubgraphRef.current!
        _list = list
        _layoutDirection = inputs.environmentAttribute(keyPath: \.layoutDirection)
        _accessibilityEnabled = inputs.environmentAttribute(keyPath: \.accessibilityEnabled)

        let childPlacementsParent = WeakAttribute<Scrollable>(inputs.scrollableView)
        let incrementalChildPlacements = IncrementalChildPlacements<Layout>(layout: layout, size: inputs.size, position: inputs.position, transform: inputs.transform, environment: inputs.environment, parent: childPlacementsParent, layoutComputer: .init(nil), cache: nil, validRect: .null, placedChildren: [], resetSeed: 0)
        let childPlacements = Attribute(incrementalChildPlacements)

        _placedChildren = childPlacements
        let collectedPlacements = Attribute(IncrementalCollectedPlacements(children: childPlacements, cache: nil))
        collectedPlacements.flags = DGAttributeFlags.active

        var visitor = MakeChildOutputs(children: childPlacements, outputs: .init())
        for key in inputs.preferences.keys {
            key.visitKey(&visitor)
        }

        outputs = visitor.outputs
        outputs.setLayout(inputs) {
            .init(IncrementalLayoutComputer(layout: layout, environment: inputs.environment, cache: nil))
        }
        let layoutComputer = outputs.layout

        _placedChildren.mutateBody(as: IncrementalChildPlacements<Layout>.self, invalidating: true) { body in
            body.cache = self
            body.layoutComputer = layoutComputer
        }

        collectedPlacements.mutateBody(as: IncrementalCollectedPlacements.self, invalidating: true) { body in
            body.cache = self
        }

        if let layoutAttribute = outputs.layout.attribute {
            layoutAttribute.mutateBody(as: IncrementalLayoutComputer<Layout>.self, invalidating: true) { body in
                body.cache = self
            }
        }

        var updateChildOutputs = UpdateChildOutputs(cache: self, outputs: outputs)
        for key in inputs.preferences.keys {
            key.visitKey(&updateChildOutputs)
        }
    }

    internal func invalidate() {
        for (_, item) in items {
            guard !item.hasParent else {
                continue
            }
            item.subgraph.invalidate()
        }
    }

    internal func item(data: _IncrementalLayout_Child.Data) -> ViewCacheItem {
        let key = _ViewList_ID.Canonical(id: data.id)
        func add(item: ViewCacheItem, reset: Bool) {
            items[key] = item
            item.usedSeed = usedSeed
            item.zIndex = data.traits.value(for: ZIndexTraitKey.self, defaultValue: 0)
            item.removedSeed = .max
            item.insertionTransactionID = currentTransactionID
            DGGraphRef.withoutUpdate {
                let transaction = inputs.transaction.value
                var state = item.state
                if !transaction.fromScrollView {
                    let list = DGGraphRef.withoutUpdate {
                        self.list
                    }
                    let edit = list.edit(forID: data.id, since: lastTransactionID)
                    state.phase = .willInsert
                    state.enableTransitions = state.enableTransitions || edit == .inserted
                } else {
                    state.phase = .normal
                }
                state.isRemoved = false
                if reset {
                    state.resetDelta &+= 1
                }
                item.state = state
            }
            hasSections = hasSections || data.section.id != nil
            guard !hasDepth else {
                return
            }
            hasDepth = item.zIndex != 0
        }
        if let item = items[key] {
            if item.displayIndex != nil
                || item.insertionTransactionID == currentTransactionID {
                if usedSeed != item.usedSeed {
                    item.usedSeed = usedSeed
                    let zIndex = data.traits.value(for: ZIndexTraitKey.self, defaultValue: 0)
                    item.zIndex = zIndex
                    hasDepth = hasDepth || (zIndex != 0)
                }
            } else {
                add(item: item, reset: false)
            }
            return item
        } else {
            let transition = data.list == nil ? nil : data.traits.optionalTransition
            failedSeed &+= 1
            while true {
                var targetKV: (key: _ViewList_ID.Canonical, value: ViewCacheItem)? = nil
                var usedSeedThreshold: UInt32 = 1
                for (key, value) in items {
                    let remainUsedSeed = usedSeed &- value.usedSeed
                    guard remainUsedSeed > usedSeedThreshold, placementSeed != value.placementSeed, value.displayIndex == nil, failedSeed != value.failedSeed else {
                        continue
                    }

                    guard let t = transition else {
                        continue
                    }
                    var visitor = CompareTransitionType(existingType: value.transitionType, compatibleTypes: true)
                    t.box.visitType(applying: &visitor)
                    guard visitor.compatibleTypes else {
                        continue
                    }
                    usedSeedThreshold = remainUsedSeed
                    targetKV = (key, value)
                }
                if let targetKey = targetKV?.key, let targetValue = targetKV?.value {
                    let canReuse = targetValue.elements.tryToReuseElement(at: targetValue.elementIndex, by: data.elements, at: numericCast(data.id._index), indirectMap: targetValue.indirectMap, testOnly: true)
                    if canReuse {
                        items.removeValue(forKey: targetKey)
                        let reused = targetValue.elements.tryToReuseElement(at: targetValue.elementIndex, by: data.elements, at: numericCast(data.id._index), indirectMap: targetValue.indirectMap, testOnly: false)
                        if reused {
                            if let release = targetValue.releaseSecondaryElements {
                                release()
                            }
                            targetValue.releaseSecondaryElements = data.elements.retain()
                            targetValue.id = data.id
                            targetValue.section = data.section
                            add(item: targetValue, reset: true)
                            return targetValue
                        }
                    }
                    targetValue.failedSeed = failedSeed
                } else {
                    break
                }
            }
            let newSubgraph = DGSubgraphCreate(parentSubgraph.graph)
            let map = _ViewList_IndirectMap(newSubgraph)
            var stateAttribute: Attribute<ViewCacheItem.State>?
            var geometryAttribute: Attribute<ViewGeometry>?
            var phaseAttribute: Attribute<_GraphInputs.Phase>?
            var transactionAttribute: Attribute<Transaction>?
            var transitionAttribute: DGAttribute?
            var transitionType: Any.Type?
            let viewOutputs: _ViewOutputs? = newSubgraph.apply {
                let outputs = data.elements.makeOneElement(at: numericCast(data.id._index), inputs: _ViewInputs(deepCopy: inputs), indirectMap: map) { (inputs, body) -> _ViewOutputs? in
                    let state = ViewCacheItem.State(resetDelta: 0, phase: .willInsert, enableTransitions: false, isRemoved: true)
                    stateAttribute = Attribute(value: state)
                    geometryAttribute = Attribute(IncrementalViewGeometry(children: _placedChildren, size: self.inputs.size, parentPosition: inputs.position, layoutDirection: _layoutDirection, cache: self, item: nil))
                    phaseAttribute = Attribute(IncrementalViewPhase(phase1: inputs.phase, phase2: self.inputs.phase, state: stateAttribute!))

                    var newInputs = inputs
                    let sizeAttribute = geometryAttribute!.size()
                    newInputs.size = sizeAttribute
                    newInputs.merge(inputs: self.inputs.base, ignoringPhase: true)
                    newInputs.merge(phase: phaseAttribute!)

                    transactionAttribute = Attribute(IncrementalTransaction(transaction: inputs.transaction, state: stateAttribute!, item: nil, lastPhase: nil))
                    newInputs.merge(transaction: transactionAttribute!)
                    newInputs.position = geometryAttribute!.origin()

                    var outputs: _ViewOutputs?
                    if let t = transition {
                        var visitor = MakeChildTransition(state: stateAttribute!, inputs: newInputs, id: data.id, makeElt: { (inputs) -> _ViewOutputs in
                            body(inputs)
                        }, outputs: nil, transition: nil, transitionType: nil)
                        t.box.visitBase(applying: &visitor)
                        transitionAttribute = visitor.transition
                        transitionType = visitor.transitionType
                        outputs = visitor.outputs
                    } else {
                        outputs = body(newInputs)
                    }
                    return outputs
                }
                return outputs
            }

            let newItem = ViewCacheItem(cache: self,
                                        subgraph: newSubgraph,
                                        outputs: viewOutputs ?? _ViewOutputs(),
                                        state: stateAttribute!,
                                        list: data.list,
                                        elements: data.elements,
                                        id: data.id,
                                        elementIndex: numericCast(data.id._index),
                                        section: data.section,
                                        indirectMap: map,
                                        transition: transitionAttribute,
                                        transitionType: transitionType)
            geometryAttribute!.mutateBody(as: IncrementalViewGeometry.self, invalidating: true) { body in
                body.item = newItem
            }
            transactionAttribute!.mutateBody(as: IncrementalTransaction.self, invalidating: true) { body in
                body.item = newItem
            }

            if let t = transitionAttribute {
                var visitor = UpdateChildTransition(transition: t, item: newItem)
                transition!.box.visitBase(applying: &visitor)
            }
            add(item: newItem, reset: false)
            return newItem
        }
    }

    internal func item(for subgraph: DGSubgraphRef) -> ViewCacheItem? {
        for (_, value) in items {
            if value.subgraph.isAncestor(subgraph) {
                return value
            }
        }
        return nil
    }

    internal func reset() {
        hasSections = false
        commitSeed = 0
        lastTransactionID = TransactionID()
        isFirstCommit = true
        items.removeAll(keepingCapacity: true)
    }

    internal func children(context: DanceUIGraph.AnyRuleContext) -> _IncrementalLayout_Children {
        if currentTransactionID != lastTransactionID {
            usedSeed &+= 1
            lastTransactionID = currentTransactionID
        }
        let list = context[_list]
        let children = _IncrementalLayout_Children(cache: self, context: context, node: _ViewList_Node.list((list, _GraphValue(_list))), transform: .init(), section: .init(id: nil, isHeader: false, isFooter: false))
        return children
    }

    internal func ensureInserted(item: ViewCacheItem) {
        guard !item.hasParent else {
            return
        }
        parentSubgraph.add(child: item.subgraph)
        parentSubgraph.apply {
            item.subgraph.didReinsert()
        }
        item.hasParent = true
    }

    internal func ensureRemoved(item: ViewCacheItem) {
        guard item.hasParent else {
            return
        }
        parentSubgraph.apply {
            item.subgraph.willRemove()
        }
        parentSubgraph.remove(child: item.subgraph)
        item.hasParent = false
    }


    internal func enqueueItemPhaseUpdate(_ item: ViewCacheItem) {
        guard let viewGraph = self.viewGraph else {
            return
        }
        viewGraph.continueTransaction {
            self.updateItemPhase(item)
        }
    }

    internal func updateItemPhases() {
        for item in items.values {
            updateItemPhase(item)
        }
    }

    internal func updateItemPhase(_ item: ViewCacheItem) {
        guard item.subgraph.isValid else {
            return
        }
        guard item.commitSeed != self.commitSeed else {
            if item.state.phase != .normal {
                item.state.phase = .normal
            }
            return
        }
        var newState = item.state
        switch item.state.phase {
        case .willInsert:
            break
        case .normal:
            if item.displayIndex != nil {
                newState.enableTransitions = item.willEnableTransitions
                newState.phase = .didRemove
                item.willEnableTransitions = false
                break
            }
            fallthrough
        case .didRemove:
            guard item.animationCount == 0 else {
                return
            }
            item.displayIndex = nil
            item.placement = nil
            newState.isRemoved = true
        }
        item.state = newState
    }

    internal func collect() {
        let usedThreshold = 10
        items = items.filter({ (key: _ViewList_ID.Canonical, value: ViewCacheItem) -> Bool in
            if value.displayIndex == nil {
                ensureRemoved(item: value)
            } else {
                ensureInserted(item: value)
            }
            if usedThreshold >= 0 {
                let remainUsedSeed = self.usedSeed &- value.usedSeed
                if (usedThreshold == 0 && remainUsedSeed == 0) || remainUsedSeed <= usedThreshold {
                    return true
                }
            }

            if self.commitSeed == value.commitSeed || value.animationCount != 0 {
                return true
            }
            value.subgraph.invalidate()
            return false
        })
    }

    internal func placement(of item: ViewCacheItem, in placedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement? {
        if let index = item.displayIndex, index < placedChildren.count,  placedChildren[index].item === item {
            return placedChildren[index].placement
        }

        guard !placedChildren.isEmpty else {
            return nil
        }

        return placedChildren.first(where: {$0.item === item})?.placement
    }

    internal func withMutableState<State, R>(type: State.Type,
                                             _ body: (inout State) -> R) -> R {
        _abstract(ViewCache.self)
    }

    internal func commitPlacedChildren(from sourceChild: inout [_IncrementalLayout_PlacedChild], to destinationChild: inout [_IncrementalLayout_PlacedChild]) {
        commitSeed &+= 1
        var needUpdateItemPhase = false
        for (index, child) in destinationChild.enumerated() {
            _danceuiPrecondition(child.item.commitSeed != commitSeed, "each layout item may only occur once")
            let item = child.item
            if item.state.phase != .normal {
                needUpdateItemPhase = true
                if item.displayIndex == nil {
                    if !isFirstCommit {
                        let placement = initialPlacement(at: index, in: destinationChild, wasInserted: item.state.isRemoved, oldPlacedChildren: sourceChild)
                        destinationChild[index].placement = placement
                    }
                    needUpdateItemPhase = true
                    sourceChild.append(.init(item: item, placement: destinationChild[index].placement))
                }
            }
            item.displayIndex = index
            item.usedSeed = usedSeed
            item.commitSeed = commitSeed
            item.placement = child.placement
        }
        var itemArray: [ViewCacheItem] = []
        var flag_var108 = false
        for (_, value) in items {
            guard value.commitSeed != commitSeed, var placement = value.placement, let displayIndex = value.displayIndex else {
                continue
            }
            switch value.state.phase {
            case .didRemove:
                if value.willAnimateRemoval {
                    value.willAnimateRemoval = false
                    needUpdateItemPhase = true
                } else {
                    needUpdateItemPhase = needUpdateItemPhase || value.animationCount == 0
                }
            case .willInsert, .normal:
                let transaction = DGGraphRef.withoutUpdate {
                    inputs.transaction.value
                }
                guard !transaction.fromScrollView else {
                    value.displayIndex = nil
                    value.placement = nil
                    continue
                }
                let list = DGGraphRef.withoutUpdate {
                    self.list
                }
                let edit = list.edit(forID: value.id, since: lastTransactionID)
                let wasRemoved = edit == .removed
                placement = finalPlacement(at: displayIndex, in: sourceChild, wasRemoved: wasRemoved, newPlacedChildren: destinationChild)
                value.willEnableTransitions = value.transition != nil && wasRemoved
                value.willAnimateRemoval = true
                value.removedSeed = self.commitSeed
                itemArray.append(value)
                needUpdateItemPhase = true
            }
            value.displayIndex = destinationChild.count
            value.usedSeed = usedSeed
            destinationChild.append(.init(item: value, placement: placement))
            flag_var108 = true
        }

        for item: ViewCacheItem in itemArray {
            _danceuiPrecondition(item.displayIndex! < destinationChild.count)
            let itemPlacement = item.placement!
            item.placement = destinationChild[item.displayIndex!].placement
            destinationChild[item.displayIndex!].placement = itemPlacement
        }

        if hasDepth || hasSections || flag_var108 {
            destinationChild.sortForDisplay()
        }
        guard needUpdateItemPhase else {
            isFirstCommit = false
            return
        }
        viewGraph?.continueTransaction({
            self.updateItemPhases()
        })
    }

    internal func initialPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasInserted: Bool, oldPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement {
        _abstract(ViewCache.self)
    }

    internal func finalPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasRemoved: Bool, newPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement {
        _abstract(ViewCache.self)
    }
}

@available(iOS 13.0, *)
internal final class ViewCacheItem: AnimationListener {

    internal unowned var cache: ViewCache?

    internal let subgraph: DGSubgraphRef

    internal let outputs: _ViewOutputs

    @Attribute
    internal var state: State

    @OptionalAttribute
    internal var list: ViewList?

    internal let elements: _ViewList_Elements

    internal let elementIndex: Int

    internal let releaseElements: () -> Void

    internal let indirectMap: _ViewList_IndirectMap

    internal let transition: DGAttribute?

    internal let transitionType: Any.Type?

    internal var id: _ViewList_ID

    internal var section: ViewCache.Section

    internal var zIndex: Double = 0

    internal var insertionTransactionID: TransactionID = TransactionID()

    internal var animationCount: Int32 = 0

    internal var usedSeed: UInt32 = 0

    internal var placementSeed: UInt32 = 0

    internal var commitSeed: UInt32 = 0

    internal var displayIndex: Int? = nil

    internal var removedSeed: UInt32 = .max

    internal var failedSeed: UInt32 = .max

    internal var placement: _Placement? = nil

    internal var releaseSecondaryElements: (() -> Void)? = nil

    internal var willEnableTransitions: Bool = false

    internal var willAnimateRemoval: Bool = false

    internal var hasParent: Bool = false

    deinit {
        releaseElements()
        releaseSecondaryElements?()
    }

    internal init(cache: ViewCache, subgraph: DGSubgraphRef, outputs: _ViewOutputs, state: Attribute<State>, list: Attribute<ViewList>?, elements: _ViewList_Elements, id: _ViewList_ID, elementIndex: Int, section: ViewCache.Section, indirectMap: _ViewList_IndirectMap, transition: DGAttribute?, transitionType: Any.Type?) {
        self.cache = cache
        self.subgraph = subgraph
        self.outputs = outputs
        self._state = state
        self.elements = elements
        self.releaseElements = elements.retain()
        self.id = id
        self.elementIndex = elementIndex
        self.section = section
        self.indirectMap = indirectMap
        self.transition = transition
        self.transitionType = transitionType
        self._list = .init(list)
    }

    internal func willPlace() {
        placementSeed = cache!.placementSeed
    }

    internal func animationWasAdded() {
        animationCount &+= 1
    }

    internal func animationWasRemoved() {
        animationCount &-= 1
        guard animationCount == 0, let viewCache = cache else {
            return
        }
        viewCache.enqueueItemPhaseUpdate(self)
    }

    internal func checkDispatched() {
        _intentionallyLeftBlank()
    }

}

@available(iOS 13.0, *)
internal final class _ViewCache<Layout: IncrementalLayout>: ViewCache {

    @Attribute
    internal var layout: Layout

    internal var state: Layout.State

    internal init(layout: Attribute<Layout>, list: Attribute<ViewList>, inputs: _ViewInputs) {
        _layout = layout
        state = Layout.initialState
        super.init(layout: layout, list: list, inputs: inputs)
        guard inputs.preferences.requiresScrollable else {
            return
        }

        let scrollableViewInput = inputs.scrollableView
        let attribute = WeakAttribute(scrollableViewInput)
        let scrollableChildren = outputs.scrollable

        let incrementalScrollable = IncrementalScrollable(position: inputs.position, transform: inputs.transform, parent: attribute, children: .init(scrollableChildren), cache: self)
        outputs.scrollable = Attribute(value: [incrementalScrollable] as [Scrollable])
    }

    override internal func reset() {
        super.reset()
    }

    override func withMutableState<State, R>(type: State.Type,
                                             _ body: (inout State) -> R) -> R {
        return withUnsafeMutablePointer(to: &state) { (statePtr) in
            statePtr.withMemoryRebound(to: type, capacity: 1) { (ptr) in
                body(&ptr.pointee)
            }
        }
    }


    @usableFromInline
    internal func withPlacementData<R>(_ body: (Layout, _IncrementalLayout_PlacementContext) -> R) -> R {
        let layout = DGGraphRef.withoutUpdate {
            self.layout
        }
        let context = _IncrementalLayout_PlacementContext(
            placedChildren: $placedChildren,
            environment: inputs.environment,
            size: inputs.size,
            position: inputs.position,
            transform: inputs.transform,
            pinnedViews: layout.pinnedViews,
            accessibilityEnabled: $accessibilityEnabled
        )
        return body(layout, context)
    }

    internal override func initialPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasInserted: Bool, oldPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement {
        withPlacementData { (layout, context) -> _Placement in
            layout.initialPlacement(at: index, in: placedChildren, wasInserted: wasInserted, context: context, oldPlacedChildren: oldPlacedChildren)
        }
    }

    internal override func finalPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasRemoved: Bool, newPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement {
        withPlacementData { (layout, context) -> _Placement in
            layout.finalPlacement(at: index, in: placedChildren, wasRemoved: wasRemoved, context: context, newPlacedChildren: newPlacedChildren)
        }
    }

}

@available(iOS 13.0, *)
extension ViewCacheItem {

    internal struct State {

        internal var resetDelta: UInt32

        internal var phase: TransitionPhase

        internal var enableTransitions: Bool

        internal var isRemoved: Bool

    }
}

@available(iOS 13.0, *)
extension ViewCache {

    internal struct Section {

        internal var id: UInt32?

        internal var isHeader: Bool

        internal var isFooter: Bool

        @usableFromInline
        internal var isSectionHeaderOrFooter: Bool {
            isHeader || isFooter
        }
    }
}
