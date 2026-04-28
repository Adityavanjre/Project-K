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
internal struct DynamicContainerInfo<Adaptor: DynamicContainerAdaptor>: StatefulRule, DanceUIGraph.ObservedAttribute {

    internal typealias Value = DynamicContainer.Info

    @Attribute
    internal var asyncSignal: Void

    internal var adaptor: Adaptor

    internal let inputs: _ViewInputs

    internal let outputs: _ViewOutputs

    internal let parentSubgraph: DGSubgraphRef

    internal var info: DynamicContainer.Info

    internal var lastUniqueId: UInt32

    internal var lastRemoved: UInt32

    internal var lastResetSeed: UInt32

    internal var needsPhaseUpdate: Bool

    @usableFromInline
    internal init(asyncSignal: Attribute<()>, adaptor: Adaptor, inputs: _ViewInputs, outputs: _ViewOutputs) {
        self._asyncSignal = asyncSignal
        self.adaptor = adaptor
        self.inputs = inputs
        self.outputs = outputs
        self.parentSubgraph = DGSubgraphRef.current!
        self.info = DynamicContainer.Info()
        self.lastUniqueId = 0
        self.lastRemoved = 0
        self.lastResetSeed = .max
        self.needsPhaseUpdate = false
    }

    internal func destroy() {
        for item in self.info.items {
            if item.phase == nil {
                item.subgraph.invalidate()
            }
            item.destroy()
        }
    }

    internal mutating func eraseItem(at index: Int) {
        let item = self.info.items[index].for(Adaptor.self)
        switch item.phase {
        case .none, .willInsert:
            _danceuiFatalError()
        case .didRemove:
            self.info.removedCount &-= 1
        case .normal:
            break
        }

        if info.unusedCount < adaptor.maxUnusedItems {
            self.info.items.remove(at: index)
            item.removalOrder = 0
            item.resetSeed &+= 1
            item.phase = nil
            item.listener = nil
            self.info.items.append(item)
            self.info.unusedCount &+= 1
        } else {
            self.adaptor.removeItemLayout(uniqueId: item.uniqueId, itemLayout: item.itemLayout)
            self.info.items.remove(at: index)
        }
        item.subgraph.willRemove()
        self.parentSubgraph.remove(child: item.subgraph)
        guard self.info.unusedCount >= 0 else {
            return
        }
        item.subgraph.invalidate()
    }

    internal mutating func updateValue() {
        let viewPhase = inputs.phase.value
        let preLastResetSeed = lastResetSeed
        lastResetSeed = viewPhase.seed

        var hasWillInsertItem = false
        if needsPhaseUpdate {
            for itemInfo in info.items where itemInfo.phase == .willInsert {
                itemInfo.phase = .normal
                hasWillInsertItem = true
            }
            needsPhaseUpdate = false
        }
        let disableTransitions = viewPhase.seed != preLastResetSeed
        let (changed, hasDepth) = updateItems(
            disableTransitions: disableTransitions
        )

        var needUpdate = false
        if !hasWillInsertItem && !changed {
            for (index, itemInfo) in info.items.enumerated().reversed() {
                guard let phase = itemInfo.phase else {
                    continue
                }
                guard phase == .didRemove else {
                    break
                }
                let removeSuccess = tryRemovingItem(at: index,
                                                    disableTransitions: disableTransitions)
                if removeSuccess {
                    needUpdate = true
                }
            }
        } else {
            for itemInfo in info.items.reversed() {
                guard let phase = itemInfo.phase else {
                    continue
                }
                guard phase == .didRemove else {
                    break
                }

                let animationListener: DynamicAnimationListener
                if let listener = itemInfo.listener {
                    animationListener = listener
                    if animationListener.isAnimating {
                        break
                    }
                } else {
                    let viewGraph = ViewGraph.current
                    animationListener = DynamicAnimationListener(
                        viewGraph: viewGraph,
                        asyncSignal: WeakAttribute(_asyncSignal)
                    )
                    itemInfo.listener = animationListener
                }

                animationListener.animationWasAdded()
                Update.enqueueAction {
                    animationListener.animationWasRemoved()
                }
            }
            needUpdate = true
        }

        if needUpdate {
            let inuseItemCount = info.items.count - info.unusedCount
            let unremovedIndex = inuseItemCount - info.removedCount
            if unremovedIndex < inuseItemCount {
                var arraySlice = info.items[unremovedIndex..<inuseItemCount]
                arraySlice.sort { $0.removalOrder < $1.removalOrder }
                info.items[unremovedIndex..<inuseItemCount] = arraySlice
            }

            info.allUnary = true
            var indexMap: [UInt32: Int] = [:]
            if inuseItemCount != 0 {

                var precedingViewCount: Int32 = 0

                for index in 0..<inuseItemCount {
                    let infoItem = info.items[index]
                    indexMap[infoItem.uniqueId] = index
                    infoItem.precedingViewCount = precedingViewCount

                    if info.allUnary && infoItem.viewCount != 0x1 {
                        info.allUnary = false
                    }
                    precedingViewCount += infoItem.viewCount
                }
            }
            info.indexMap = indexMap

            if hasDepth {
                var displayMap: [UInt32] = []
                let activeItemsCount = info.items.count - info.removedCount - info.unusedCount
                if unremovedIndex > 0 {
                    displayMap = (0..<activeItemsCount).map { UInt32($0) }
                }
                func lessThan(_ lhs: UInt32, _ rhs: UInt32) -> Bool {
                    info.items[Int(lhs)].zIndex < info.items[Int(rhs)].zIndex
                }
                displayMap.sort(by: lessThan)
                var removedDisplayMap: [UInt32] = []
                if info.removedCount != 0x0 {
                    if unremovedIndex != 0x0 {
                        for i in 0..<activeItemsCount {
                            removedDisplayMap.append(displayMap[i])
                        }
                    }
                    var mapValue = activeItemsCount
                    for _ in -info.removedCount..<0 {
                        removedDisplayMap.append(UInt32(mapValue))
                        mapValue &+= 1
                    }
                    removedDisplayMap.sort(by: lessThan)
                }
                displayMap = displayMap + removedDisplayMap
                info.displayMap = displayMap
            } else {
                info.displayMap = nil
            }
        } else {
            guard !info.items.isEmpty || !context.hasValue else {
                return
            }
        }
        info.seed &+= 1
        self.value = info
    }

    internal mutating func makeItem(
        _ item: Adaptor.Item,
        uniqueId: UInt32,
        container: Attribute<DynamicContainer.Info>,
        disableTransitions: Bool
    ) -> DynamicContainer.ItemInfo {

        let phase: TransitionPhase
        let needsTransitions = item.needsTransitions
        if needsTransitions && !disableTransitions {
            let signalAttribute = WeakAttribute(_asyncSignal)
            ViewGraph.currentHost.continueTransaction {
                guard let signalAttribute = signalAttribute.attribute else {
                    return
                }
                signalAttribute.invalidateValue()
            }
            needsPhaseUpdate = true
            phase = .willInsert
        } else {
            phase = .normal
        }

        let newSubgraph = DGSubgraphCreate2(parentSubgraph.graph, item.list?.identifier ?? .nil)
        parentSubgraph.add(child: newSubgraph)
        return newSubgraph.apply {
            let newInputs = _ViewInputs(deepCopy: inputs)
            let (newOutputs, layout) = adaptor.makeItemLayout(item: item, uniqueId: uniqueId, inputs: newInputs, containerInfo: container) { inputs in
                inputs.transaction = Attribute(DynamicTransaction(info: container, transaction: inputs.transaction, uniqueId: uniqueId, wasRemoved: false))
                inputs.phase = Attribute(DynamicViewPhase(info: container, phase: inputs.phase, uniqueId: uniqueId))
            }
            return DynamicContainer._ItemInfo<Adaptor>(item: item, itemLayout: layout, subgraph: newSubgraph, uniqueId: uniqueId, viewCount: Int32(item.count), phase: phase, needsTransitions: needsTransitions, outputs: newOutputs)
        }
    }

    internal mutating func tryRemovingItem(at index: Int, disableTransitions: Bool) -> Bool {
        let itemInfo = info.items[index]
        switch itemInfo.phase {
        case .willInsert:
            _danceuiFatalError()
        case .normal:
            guard !disableTransitions, itemInfo.needsTransitions else {
                eraseItem(at: index)
                return true
            }
            let lastRemoved = self.lastRemoved &+ 1
            self.lastRemoved = lastRemoved > 0 ? lastRemoved : 1
            itemInfo.removalOrder = lastRemoved
            info.removedCount &+= 1
            itemInfo.phase = .didRemove

            let animationListener: DynamicAnimationListener
            if let listener = itemInfo.listener {
                animationListener = listener
            } else {
                let viewGraph = ViewGraph.current
                animationListener = DynamicAnimationListener(
                    viewGraph: viewGraph,
                    asyncSignal: WeakAttribute(_asyncSignal)
                )
                itemInfo.listener = animationListener
            }
            animationListener.animationWasAdded()
            Update.enqueueAction {
                animationListener.animationWasRemoved()
            }
            return false
        case .didRemove:
            if !itemInfo.listener!.isAnimating {
                eraseItem(at: index)
                return true
            } else {
                return false
            }
        case .none:
            return false
        }
    }

    internal mutating func unremoveItem(at index: Int) {
        var phase: TransitionPhase
        switch info.items[index].phase {
        case .willInsert:
            _danceuiFatalError()
        case .normal:
            info.items[index].resetSeed &+= 1
            phase = .willInsert
        case .didRemove:
            info.removedCount &-= 1
            info.items[index].removalOrder = 0
            phase = .normal
        case .none:
            info.unusedCount &-= 1
            let subgraph = info.items[index].subgraph
            parentSubgraph.add(child: subgraph)
            subgraph.didReinsert()
            phase = .willInsert
        }
        if !info.items[index].needsTransitions {
            phase = .normal
        }

        info.items[index].phase = phase
        guard phase == .willInsert else {
            return
        }
        self.needsPhaseUpdate = true
        let viewGraph = ViewGraph.current
        let asyncSignal = WeakAttribute(_asyncSignal)
        viewGraph.continueTransaction {
            asyncSignal.attribute?.invalidateValue()
        }
    }

    private mutating func updateItems(disableTransitions: Bool) -> (changed: Bool, hasDepth: Bool) {
        var changed = false
        var hasDepth = false

        guard let items = adaptor.updatedItems() else {
            hasDepth = info.displayMap != nil
            return (changed, hasDepth)
        }

        var currentIndex: Int = 0
        var currentItemsCount = info.items.count

        adaptor.foreachItem(items) { (item) in
            var matchesIndex = -1
            var findMatchesIdentify = false
            for index in currentIndex..<currentItemsCount {
                let infoItem = self.info.items[index].for(Adaptor.self)

                if infoItem.item.matchesIdentity(of: item) {
                    if index != currentIndex {
                        self.info.items.swapAt(currentIndex, index)
                        changed = true
                    }

                    infoItem.item = item

                    if infoItem.phase != .normal {
                        self.unremoveItem(at: currentIndex)
                        changed = true
                    }
                    findMatchesIdentify = true
                    break

                } else {
                    if matchesIndex < 0 &&
                        infoItem.phase == nil &&
                        infoItem.item.canBeReused(by: item) {
                        matchesIndex = index
                    }
                }

            }

            if !findMatchesIdentify {
                if matchesIndex < 0 {
                    if Adaptor.Item.supportsReuse {
                        for index in currentIndex..<currentItemsCount {
                            let infoItem = self.info.items[index].for(Adaptor.self)
                            if infoItem.needsTransitions &&
                                infoItem.item.canBeReused(by: item) &&
                                !Adaptor.containsItem(items, infoItem.item) {
                                matchesIndex = index
                                break
                            }
                        }
                    }
                }

                if matchesIndex >= 0 {
                    let infoItem = self.info.items[matchesIndex].for(Adaptor.self)
                    infoItem.item = item
                    self.unremoveItem(at: matchesIndex)
                    if currentIndex < matchesIndex {
                        self.info.items.swapAt(currentIndex, matchesIndex)
                    }
                } else {
                    self.lastUniqueId += 1
                    let currentAttribute = DGAttribute.current!
                    let item = self.makeItem(item, uniqueId: self.lastUniqueId, container: Attribute<DynamicContainer.Info>(identifier: currentAttribute), disableTransitions: disableTransitions)
                    self.info.items.append(item)

                    if currentIndex < currentItemsCount {
                        self.info.items.swapAt(currentIndex, currentItemsCount)
                    }
                    currentItemsCount += 1
                }
                changed = true
            }

            let zIndex = item.zIndex
            if zIndex != 0x0 {
                hasDepth = true
            }
            let infoItem = self.info.items[currentIndex]
            if infoItem.zIndex != zIndex {
                infoItem.zIndex = zIndex
                changed = true
            }
            currentIndex += 1
        }

        for index in (currentIndex..<currentItemsCount).reversed() {
            let itemPhase = info.items[index].phase
            guard !tryRemovingItem(at: index, disableTransitions: disableTransitions) else {
                changed = true
                continue
            }
            let item = info.items[index]
            if item.zIndex != 0 {
                hasDepth = true
            }
            let currentItemZIndex = info.items[currentIndex].zIndex
            if item.zIndex != currentItemZIndex {
                info.items[currentIndex].zIndex = item.zIndex
                changed = true
            }

            if itemPhase != item.phase {
                changed = true
            }
        }
        return (changed, hasDepth)
    }
}
