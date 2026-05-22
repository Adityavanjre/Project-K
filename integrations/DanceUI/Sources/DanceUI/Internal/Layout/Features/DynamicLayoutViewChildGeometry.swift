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
internal struct DynamicLayoutViewChildGeometry: StatefulRule {
    
    internal typealias Value = ViewGeometry
    
    @Attribute
    internal var containerInfo: DynamicContainer.Info

    @Attribute
    internal var childGeometries: [ViewGeometry]
    
    internal let id: DynamicContainerID
    

    internal mutating func updateValue() {
        let info = self.containerInfo
        var geometryIndex: Int? = nil
        let geometries = self.childGeometries
        if let index = info.indexMap[id.uniqueId] {
            let item = info.items[index]
            let idx = Int(id.viewIndex + item.precedingViewCount)
            if idx < geometries.count {
                geometryIndex = idx
            }
        }
        if let index = geometryIndex {
            self.value = geometries[index]
            return
        }
        guard context.hasValue else {
            self.value = .zero
            return
        }
        var value = context.value
        self.value = value
    }
}
