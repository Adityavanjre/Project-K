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
@_spi(DanceUI) import DanceUIObservation

@available(iOS 13.0, *)
internal protocol AccessibilityViewModifier: PrimitiveViewModifier, MultiViewModifier {
    
    func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment?
        
    func attachment(for nodes: [AccessibilityNode], atIndex: Int) -> AccessibilityAttachment
    
    func willCreateNode(for nodes: [AccessibilityNode]) -> Bool
    
    func initialPropertiesForNode(nodes: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties
    
    func createOrUpdateNode(viewRendererHost: ViewRendererHost?, existingNode: AccessibilityNode?) -> AccessibilityNode
    
}

@available(iOS 13.0, *)
extension AccessibilityViewModifier {
    
    internal func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
        .properties(AccessibilityProperties())
    }
    
    internal func attachment(for nodes: [AccessibilityNode], atIndex: Int) -> AccessibilityAttachment {
        guard nodes.count > 2 else {
            return .properties(AccessibilityProperties())
        }
        
        return .properties(AccessibilityProperties(\.outline, .defaultFrame))
    }
    
    internal func willCreateNode(for nodes: [AccessibilityNode]) -> Bool {
        false
    }
    
    internal func initialPropertiesForNode(nodes: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
        AccessibilityProperties()
    }
    
    internal func createOrUpdateNode(viewRendererHost: ViewRendererHost?, existingNode: AccessibilityNode?) -> AccessibilityNode {
        if let existingNode = existingNode {
            return existingNode
        }
        
        return AccessibilityNode(viewRendererHost: viewRendererHost)
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInput = inputs
        if inputs.preferences.requiresAccessibilityNodes &&
            !inputs.preferences.requiresViewResponders {
            newInput.preferences.requiresViewResponders = true
        }
        
        if inputs.enableAccessibilityTransform {
            newInput.containerPosition = inputs.animatedPosition
        }
        
        var outputs = body(_Graph(), newInput)
        guard inputs.preferences.requiresAccessibilityNodes else {
            return outputs
        }
        
        if inputs.enableAccessibilityTransform {
            let transform = DisplayListTransform(
                modifier: modifier.value,
                size: inputs.animatedSize,
                position: inputs.animatedPosition,
                containerPosition: inputs.containerPosition,
                environment: inputs.base.environment,
                content: outputs.displayList,
                nodeList: outputs.accessibilityNodes,
                identity: .make()
            )
            outputs.displayList = Attribute(transform)
        }
        
        let propertiesTransform = PropertiesTransform(
            modifier: modifier.value,
            environment: inputs.environment,
            phase: inputs.phase,
            nodeList: outputs.accessibilityNodes,
            isInPlatformItemList: inputs[PlatformItemListIncludeAX.self],
            lastNodes: [],
            parentNode: nil,
            resetSeed: 0x0
        )
        let accessibilityNodes = Attribute(propertiesTransform)
        outputs.accessibilityNodes = accessibilityNodes
        
        if inputs.preferences.requiresPlatformItemList {
            let platformItemListTransform = PlatformItemListTransform(
                nodes: accessibilityNodes,
                accessibilityEnabled: inputs.environmentAttribute(keyPath: \.accessibilityEnabled)
            )
            
            @Attribute(PreferenceTransform<PlatformItemList.Key>(transform: Attribute(platformItemListTransform), childValue: outputs.platformItemList))
            var preferenceTransform
            $preferenceTransform.flags = .removable
            
            outputs.platformItemList = $preferenceTransform
        }
        
        outputs.accessibilityNodes = makeAccessibilityGeometryTransform(for: accessibilityNodes, inputs: newInput, outputs: outputs)
        
        return outputs
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal static func makeAccessibilityTransform(modifier: _GraphValue<Self>, inputs: _ViewInputs, outputs: _ViewOutputs) -> Attribute<AccessibilityNodeList>? {
        
        guard inputs.preferences.requiresAccessibilityNodes else {
            return nil
        }
        let propertiesTransform = PropertiesTransform(
            modifier: modifier.value,
            environment: inputs.environment,
            phase: inputs.phase,
            nodeList: outputs.accessibilityNodes,
            isInPlatformItemList: inputs[PlatformItemListIncludeAX.self],
            lastNodes: [],
            parentNode: nil,
            resetSeed: 0x0
        )
        
        return makeAccessibilityGeometryTransform(for: Attribute(propertiesTransform), inputs: inputs, outputs: outputs)
    }

}

@available(iOS 13.0, *)
fileprivate struct DisplayListTransform<Modifier>: Rule {
    
    fileprivate typealias Value = DisplayList

    @Attribute
    fileprivate var modifier: Modifier

    @Attribute
    fileprivate var size: ViewSize

    @Attribute
    fileprivate var position: ViewOrigin

    @Attribute
    fileprivate var containerPosition: ViewOrigin

    @Attribute
    fileprivate var environment: EnvironmentValues

    @OptionalAttribute
    fileprivate var content: DisplayList?

    @OptionalAttribute
    fileprivate var nodeList: AccessibilityNodeList?

    fileprivate let identity: DisplayList.Identity

    fileprivate init(
        modifier: Attribute<Modifier>,
        size: Attribute<ViewSize>,
        position: Attribute<ViewOrigin>,
        containerPosition: Attribute<ViewOrigin>,
        environment: Attribute<EnvironmentValues>,
        content: Attribute<DisplayList>?,
        nodeList: Attribute<AccessibilityNodeList>?,
        identity: DisplayList.Identity
    ) {
        self._modifier = modifier
        self._size = size
        self._position = position
        self._containerPosition = containerPosition
        self._environment = environment
        self._content = OptionalAttribute(content)
        self._nodeList = OptionalAttribute(nodeList)
        self.identity = identity
    }
    
    fileprivate var value: DisplayList {
        
        let content = self.content ?? .empty
        
        let environment = environment
        
        guard environment.accessibilityEnabled else {
            return content
        }
        
        assertionFailure("[DanceUI] An unimplemented function is being called")
        logger.fault("[DanceUI] An unimplemented function is being called")
        return content
    }

}

@available(iOS 13.0, *)
fileprivate struct PropertiesTransform<Modifier: AccessibilityViewModifier>: StatefulRule {

    fileprivate typealias Value = AccessibilityNodeList

    @Attribute
    fileprivate var modifier: Modifier

    @Attribute
    fileprivate var environment: EnvironmentValues

    @Attribute
    fileprivate var phase: _GraphInputs.Phase

    @OptionalAttribute
    fileprivate var nodeList: AccessibilityNodeList?

    fileprivate var isInPlatformItemList: Bool

    fileprivate var lastNodes: [AccessibilityNode]

    fileprivate var parentNode: AccessibilityNode?

    fileprivate var resetSeed: UInt32
    
    fileprivate init(
        modifier: Attribute<Modifier>,
        environment: Attribute<EnvironmentValues>,
        phase: Attribute<_GraphInputs.Phase>,
        nodeList: Attribute<AccessibilityNodeList>?,
        isInPlatformItemList: Bool,
        lastNodes: [AccessibilityNode],
        parentNode: AccessibilityNode? = nil,
        resetSeed: UInt32
    ) {
        self._modifier = modifier
        self._environment = environment
        self._phase = phase
        self._nodeList = OptionalAttribute(nodeList)
        self.isInPlatformItemList = isInPlatformItemList
        self.lastNodes = lastNodes
        self.parentNode = parentNode
        self.resetSeed = resetSeed
    }
    
    fileprivate mutating func updateValue() {
        guard environment.accessibilityEnabled else {
            value = .empty
            return
        }
        
        let seed = phase.seed
        if seed != resetSeed {
            lastNodes = []
            parentNode = nil
            resetSeed = seed
        }
        
        let modifier = self.modifier
        let (environment, environmentChanged) = $environment.changedValue()
        
        let newToken = AccessibilityAttachmentToken(context.attribute)
        
        let nodesChanged: Bool
        let nodeList: AccessibilityNodeList
        
        if let attribute = $nodeList {
            (nodeList, nodesChanged) = attribute.changedValue()
        } else {
            nodeList = .empty
            nodesChanged = lastNodes.count != 0
        }
        
        var nodesSet: Set<AccessibilityNode> = []
        
        guard let attachment = modifier.attachment(for: nodeList.nodes) else {
            value = nodeList
            return
        }
        
        var nodesWithoutAttachment: [AccessibilityNode] = []
        
        var didChangeVersion: Bool
        
        if nodesChanged {
            for lastNode in lastNodes where !nodeList.nodes.contains(lastNode) {
                guard lastNode.hasAttachment(token: newToken) else {
                    continue
                }
                lastNode.removeAttachment(isInPlatformItemList: isInPlatformItemList, token: newToken)
            }
            didChangeVersion = true
        } else {
            didChangeVersion = false
        }

        let updatedNodes: [AccessibilityNode]
        
        if modifier.willCreateNode(for: nodeList.nodes) {
            let newNode = modifier.createOrUpdateNode(viewRendererHost: ViewGraph.viewRendererHost, existingNode: parentNode)
            if newNode != parentNode {
                for lastNode in lastNodes {
                    lastNode.removeAttachments(after: newToken)
                }
                parentNode = newNode
                nodesSet.insert(newNode)
            }

            let properties = modifier.initialPropertiesForNode(nodes: nodeList.nodes, environment: environment)
            let newProperties = (attachment.properties ?? AccessibilityProperties()).combined(with: properties)
            
            let newAttachment = attachment.updatedProperties(newProperties)
            
            if nodesSet.isEmpty {
                if newNode.needsUpdate(to: newAttachment, reference: [], token: newToken) {
                    newNode.updateAttachment(newAttachment, reference: nodeList.nodes, isInPlatformItemList: isInPlatformItemList, token: newToken)
                    didChangeVersion = true
                }
            } else {
                newNode.addAttachment(newAttachment, reference: nodeList.nodes, isInPlatformItemList: isInPlatformItemList, token: newToken)
                didChangeVersion = true
            }
            
            for node in nodeList.nodes {
                node.parent = newNode
            }
            newNode.children = nodeList.nodes
            
            updatedNodes = [newNode]
        } else {
            if parentNode != nil {
                for node in nodeList.nodes {
                    node.parent = nil
                }
                parentNode = nil
            }
            
            updatedNodes = nodeList.nodes
            
            var nonLabelNodes: [AccessibilityNode] = []
            
            for node in nodeList.nodes {
                if !node.isLabel {
                    nonLabelNodes.append(node)
                }
            }
            
            for i in nodeList.nodes.indices {
                
                let node = nodeList.nodes[i]
                let attachment = modifier.attachment(for: nodeList.nodes, atIndex: i)
                
                if let index = nonLabelNodes.firstIndex(where: { $0 == node}) {
                    if node.hasAttachment(token: newToken) {
                        if node.needsUpdate(to: attachment, reference: [], token: newToken) {
                            node.updateAttachment(attachment, reference: [], isInPlatformItemList: isInPlatformItemList, token: newToken)
                            didChangeVersion = true
                        }
                    } else {
                        node.addAttachment(attachment, reference: [], isInPlatformItemList: isInPlatformItemList, token: newToken)
                        nodesSet.insert(node)
                        didChangeVersion = true
                    }
                } else {
                    nodesWithoutAttachment.append(node)
                    if node.hasAttachment(token: newToken) {
                        node.removeAttachment(isInPlatformItemList: isInPlatformItemList, token: newToken)
                        didChangeVersion = true
                    }
                }
            }
        }

        for updatedNode in updatedNodes {
            if !nodesWithoutAttachment.contains(updatedNode) {
                if environmentChanged || nodesSet.contains(updatedNode) {
                    updatedNode.updateEnvironment(environment, token: newToken)
                }
            }
        }
        
        lastNodes = nodeList.nodes

        let version = didChangeVersion ? .make() : nodeList.version
        let result = AccessibilityNodeList(nodes: updatedNodes, version: version)
        value = result
    }

}

@available(iOS 13.0, *)
private struct PreferenceTransform<Key: PreferenceKey>: StatefulRule, ObservationAttribute {
    
    fileprivate typealias Value = Key.Value

    @Attribute
    fileprivate var transform: (inout Key.Value) -> ()

    @OptionalAttribute
    fileprivate var childValue: Key.Value?
    
    fileprivate var previousObservationTrackings: [ObservationTracking]?
    
    fileprivate var deferredObservationGraphMutation: DeferredObservationGraphMutation?
    
    fileprivate init(transform: Attribute<(inout Key.Value) -> ()>, childValue: Attribute<Key.Value>?) {
        self._transform = transform
        self._childValue = OptionalAttribute(childValue)
    }
    
    fileprivate mutating func updateValue() {
        var result = childValue ?? Key.defaultValue
        let (transform, isTransformChanged) = $transform.changedValue()
        withObservation(shouldCancelPrevious: isTransformChanged) { [transform] in
            transform(&result)
        }
        value = result
    }

}

@available(iOS 13.0, *)
fileprivate struct PlatformItemListTransform: Rule {
    
    fileprivate typealias Value = (inout PlatformItemList) -> ()

    @OptionalAttribute
    fileprivate var nodes: AccessibilityNodeList?

    @Attribute
    fileprivate var accessibilityEnabled: Bool
    
    fileprivate init(
        nodes: Attribute<AccessibilityNodeList>?,
        accessibilityEnabled: Attribute<Bool>
    ) {
        self._nodes = OptionalAttribute(nodes)
        self._accessibilityEnabled = accessibilityEnabled
    }
    
    fileprivate var value: (inout PlatformItemList) -> Void {
        assertionFailure("[DanceUI] An unimplemented function is being called")
        logger.fault("[DanceUI] An unimplemented function is being called")
        return { _ in
            assertionFailure("[DanceUI] An unimplemented function is being called")
            logger.fault("[DanceUI] An unimplemented function is being called")
        }
    }

}
