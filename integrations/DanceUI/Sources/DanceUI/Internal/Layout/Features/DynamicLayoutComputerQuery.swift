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
internal struct DynamicLayoutComputer<Layout: _Layout>: StatefulRule {

    internal typealias Value = LayoutComputer

    @Attribute
    internal var layout: Layout

    @Attribute
    internal var environment: EnvironmentValues

    @OptionalAttribute
    internal var containerInfo: DynamicContainer.Info?

    internal var layoutComputerMap: DynamicLayoutMap
    
    internal mutating func updateValue() {
        updateLayoutComputer(
            layout: layout,
            environment: $environment,
            layoutAttributes: layoutComputerMap.layoutAttributes(info: containerInfo!)
        )
    }
}

@available(iOS 13.0, *)
internal struct DynamicLayoutMap {

    internal var map: [(id: DynamicContainerID, value: LayoutProxyAttributes)]

    internal var sortedArray: [LayoutProxyAttributes]

    internal var sortedSeed: UInt32
    
    internal subscript(_ id: DynamicContainerID) -> LayoutProxyAttributes? {
        
        get {
            map.first(where: {$0.id == id})?.value
        }
        
        set {
            let index = map.firstIndex(where: {$0.id == id})
            guard let index = index else {
                if let value = newValue {
                    map.append((id, value))
                }
                return
            }
            guard let value = newValue else {
                map.remove(at: index)
                return
            }
            map[index].value = value
        }
        
    }
    
    
    internal mutating func layoutAttributes(info: DynamicContainer.Info) -> [LayoutProxyAttributes] {
        
        guard info.seed != sortedSeed else {
            return sortedArray
        }
        
        sortedArray.removeAll()
        
        let itemsCount = info.items.count
        let activeCount = itemsCount - (info.removedCount + info.unusedCount)
        var totalViewCount = Int32(activeCount)
        defer {
            sortedSeed = info.seed
        }
        if activeCount > 0 && !info.allUnary {
            let lastActiveItem = info.items[activeCount - 1]
            totalViewCount = (lastActiveItem.viewCount &+ lastActiveItem.precedingViewCount)
        }
        _danceuiPrecondition(totalViewCount >= 0)
        guard totalViewCount > 0 else {
            return sortedArray
        }
        
        for index in 0..<totalViewCount {
            if !info.allUnary {
                _danceuiPrecondition(activeCount > 0)
            }
            var itemIndex = 0
            while true {
                guard itemIndex != activeCount else {
                    _danceuiFatalError("> outside View.body")
                }
                let item = info.items[itemIndex]
                guard index >= (item.viewCount + item.precedingViewCount) else {
                    break
                }
                itemIndex &+= 1
            }
            
            let item = info.items[Int(itemIndex)]
            let viewIndex = index - item.precedingViewCount
            let value = map.first(where: {$0.id.viewIndex == viewIndex && $0.id.uniqueId == item.uniqueId})?.value
            sortedArray.append(LayoutProxyAttributes(_layoutComputer: .init(value?._layoutComputer.attribute), _traitsList: .init(value?._traitsList.attribute)))
        }
        
        return sortedArray
    }
    
    internal mutating func remove(uniqueId: UInt32) {
        guard !map.isEmpty else {
            return
        }
        map = map.filter({ item in
            let result = item.id.uniqueId != uniqueId
            if !result {
                sortedSeed = 0
            }
            return result
        })
    }
}
