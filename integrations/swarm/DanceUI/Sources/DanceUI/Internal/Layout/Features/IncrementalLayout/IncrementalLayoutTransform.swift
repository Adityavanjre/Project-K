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
internal func makeAccessibilityIncrementalLayoutTransform(role: AccessibilityLayoutRole?, inputs: _ViewInputs, outputs: _ViewOutputs) -> Attribute<AccessibilityNodeList>? {

    if let scrollable = outputs.scrollable, let nodeList = outputs.accessibilityNodes {
        let transform = IncrementalLayoutTransform(
            role: role,
            accessibilityEnabled: inputs.environmentAttribute(keyPath: \.accessibilityEnabled),
            nodeList: nodeList,
            scrollables: scrollable,
            previousNodes: []
        )
        return Attribute(transform)
    } else {
        return outputs.accessibilityNodes
    }

}

@available(iOS 13.0, *)
fileprivate struct IncrementalLayoutTransform: StatefulRule {

    fileprivate typealias Value = AccessibilityNodeList

    fileprivate var role: AccessibilityLayoutRole?

    @Attribute
    fileprivate var accessibilityEnabled: Bool

    @OptionalAttribute
    fileprivate var nodeList: AccessibilityNodeList?

    @Attribute
    fileprivate var scrollables: [Scrollable]

    fileprivate var previousNodes: [AccessibilityNode]

    internal init(role: AccessibilityLayoutRole?, accessibilityEnabled: Attribute<Bool>, nodeList: Attribute<AccessibilityNodeList>?, scrollables: Attribute<[Scrollable]>, previousNodes: [AccessibilityNode]) {
        self.role = role
        self._accessibilityEnabled = accessibilityEnabled
        self._nodeList = OptionalAttribute(nodeList)
        self._scrollables = scrollables
        self.previousNodes = previousNodes
    }

    fileprivate mutating func updateValue() {

        let token: AccessibilityAttachmentToken = .attribute(.current!)

        let result: AccessibilityNodeList
        defer {
            value = result
        }

        guard accessibilityEnabled, let nodeList = nodeList else {
            for previousNode in previousNodes {
                previousNode.removeAttachment(isInPlatformItemList: false, token: token)
            }
            result = .empty
            return
        }

        let (scrollables, scrollablesIsChanged) = $scrollables.changedValue()

        let scrollableCollections = scrollables.compactMap { $0 as? ScrollableCollection }

        if let collection = scrollableCollections.first {

            guard scrollablesIsChanged || previousNodes != nodeList.nodes else {
                result = nodeList
                return
            }

            for node in nodeList.nodes {
                if let subgraph = node.subgraph, let viewID = collection.collectionViewID(for: subgraph) {

                    let context = AccessibilityIncrementalLayoutContext(
                        role: role,
                        scrollableCollection: collection,
                        collectionViewID: viewID
                    )
                    let properties = AccessibilityProperties(\.incrementalLayoutContext, context)

                    if node.hasAttachment(token: token) {
                        if node.needsUpdate(to: .properties(properties), reference: [], token: token) {
                            node.addAttachment(.properties(properties), reference: [], isInPlatformItemList: false, token: token)
                        }
                    } else {
                        node.addAttachment(.properties(properties), reference: [], isInPlatformItemList: false, token: token)
                    }



                } else {
                    node.removeAttachment(isInPlatformItemList: false, token: token)

                }
            }
        } else {
            result = nodeList
            return
        }

        for previousNode in previousNodes where !nodeList.nodes.contains(previousNode) {
            previousNode.removeAttachment(isInPlatformItemList: false, token: token)
        }

        previousNodes = nodeList.nodes

        result = AccessibilityNodeList(nodes: nodeList.nodes, version: .make())
    }

}
