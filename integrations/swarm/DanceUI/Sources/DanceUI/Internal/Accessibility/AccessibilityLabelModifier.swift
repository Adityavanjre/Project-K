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

@available(iOS 13.0, *)
private struct AccessibilityLabelModifier: AccessibilityViewModifier {

    fileprivate func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
        .properties(AccessibilityProperties())
    }
    
    fileprivate func attachment(for nodes: [AccessibilityNode], atIndex index: Int) -> AccessibilityAttachment {
        guard index >= 0, nodes.count > index,
                nodes[index].properties.traits[.labelIcon] == true else {
            return .properties(AccessibilityProperties())
        }
        var properties = AccessibilityProperties()
        properties.visibility = .hidden
        return .properties(properties)
    }
    
    fileprivate func initialPropertiesForNode(nodes: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
        let titleNodes = titleNodes(from: nodes)
        guard titleNodes.count != 1 else {
            return AccessibilityProperties()

        }
        let properties = AccessibilityChildBehavior.defaultChildProperties(from: titleNodes)
        return AccessibilityChildBehavior.defaultCombine(childProperties: properties, environment: environment)
    }
    
    fileprivate func willCreateNode(for nodes: [AccessibilityNode]) -> Bool {
        titleNodes(from: nodes).count != 1
    }
    
    private func titleNodes(from nodes: [AccessibilityNode]) -> [AccessibilityNode] {
        nodes.filter { node in
            let properties = node.properties
            return properties.visibility != .hidden &&
            properties.traits.contains(.labelTitle)
        }
    }

}

@available(iOS 13.0, *)
extension View {

    internal func labelAccessibility() -> some View {
        self.debuggableAccessibilityModifier(AccessibilityLabelModifier())
    }
}
