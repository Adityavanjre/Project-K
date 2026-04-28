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
internal struct AccessibilityIncrementalLayoutScrollViewModifier: AccessibilityViewModifier {

    @Attribute
    internal var scrollables: [Scrollable]
    
    internal var scrollableCollection: ScrollableCollection? {
        scrollables.first as? ScrollableCollection
    }
    
    internal func willCreateNode(for nodes: [AccessibilityNode]) -> Bool {
        scrollableCollection != nil
    }
    
    internal func createOrUpdateNode(viewRendererHost: ViewRendererHost?, existingNode: AccessibilityNode?) -> AccessibilityNode {
        if let scrollableCollection = scrollableCollection {
            if let existingNode = existingNode as? AccessibilityIncrementalLayoutNode {
                existingNode.scrollableCollection = scrollableCollection
                return existingNode
            }
            return AccessibilityIncrementalLayoutNode(viewRendererHost: viewRendererHost, scrollableCollection: scrollableCollection)
        }
        
        if let existingNode = existingNode, !(existingNode is AccessibilityIncrementalLayoutNode) {
            return existingNode
        }
        return AccessibilityNode(viewRendererHost: viewRendererHost)
    }

}
