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
internal final class AccessibilityRelationshipScope: ViewInput {

    private var relatedNodesByKey: [Key: [Relationship: [AccessibilityNode]]]

    private var recordsByAttribute: [DGAttribute: Record]

    private var keysByNodeRelation: [NodeRelation: Set<Key>]
    
    deinit {
        _intentionallyLeftBlank()
    }
    
    internal init() {
        self.relatedNodesByKey = [:]
        self.recordsByAttribute = [:]
        self.keysByNodeRelation = [:]
    }
    
    internal var description: String {
"""
<AccessibilityRelationshipScopeFaker: \(ObjectIdentifier(self))>
    relatedNodesByKey: \(relatedNodesByKey),
    recordsByAttribute: \(recordsByAttribute),
    keysByNodeRelation: \(keysByNodeRelation)
"""
    }
    
    internal static var defaultValue: AccessibilityRelationshipScope? {
        nil
    }
    
    internal func combine<Identifier: Hashable>(label: AccessibilityNode, contents: [AccessibilityNode], id: Identifier, namespace: Namespace.ID, from attribute: DGAttribute) {
        update(.combinedLabelPair(.content), nodes: contents, identifier: id, in: namespace, from: attribute)
        update(.combinedLabelPair(.label), nodes: [label], identifier: id, in: namespace, from: attribute)
    }
    
    internal func labeledPairNodes<Identifier: Hashable>(for role: AccessibilityLabeledPairRole, with identifier: Identifier, in namespace: Namespace.ID) -> [AccessibilityNode] {
        let labelNodes = nodes(for: .labeledPair(role), with: identifier, in: namespace)
        let combinedLabelNodes = nodes(for: .combinedLabelPair(role), with: identifier, in: namespace)
        let combineLabelIDs = Set(combinedLabelNodes).map { $0.id }
        
        return labelNodes.filter {
            !combineLabelIDs.contains($0.id)
        }
        .sorted(with: nil)
    }
    
    internal func elements(for nodes: [AccessibilityNode]) -> [AnyObject] {
        nodes.map {
            $0.platformElement ?? $0
        }
    }
    
    internal func labeledPairNodes(for node: AccessibilityNode, role: AccessibilityLabeledPairRole) -> [AccessibilityNode] {
        let antonymRole: AccessibilityLabeledPairRole = role == .label ? .content : .label
        let labelNodes = nodes(for: .labeledPair(antonymRole), of: node, returning: .labeledPair(role))
        guard !labelNodes.isEmpty else {
            return []
        }
        
        let combineLabelIDs = Set(nodes(for: .combinedLabelPair(antonymRole), of: node, returning: .combinedLabelPair(role))).map { $0.id }
        return labelNodes.filter {
            !combineLabelIDs.contains($0.id)
        }.sorted(with: nil)
    }
    
    internal func linkedNodes(for node: AccessibilityNode) -> [AccessibilityNode] {
        nodes(for: .linkedGroup, of: node, returning: .linkedGroup)
            .filter { $0.id != node.id }
            .sorted(with: nil)
    }
    
    private func nodes(for relationship: Relationship, of node: AccessibilityNode, returning returningRelationship: Relationship) -> [AccessibilityNode] {
        keysByNodeRelation[NodeRelation(node: node.id, relationship: relationship)]?.reduce([], { partialResult, key in
            partialResult + (relatedNodesByKey[key]?[returningRelationship] ?? [])
        }) ?? []
    }
    
    private func nodes<Identifier: Hashable>(for relationship: Relationship, with identifier: Identifier, in namespace: Namespace.ID) -> [AccessibilityNode] {
        relatedNodesByKey[Key(identifier: identifier, in: namespace)]?[relationship] ?? []
    }
    
    fileprivate func update<Identifier: Hashable>(_ relationship: Relationship, nodes: [AccessibilityNode], identifier: Identifier, in namespace: Namespace.ID, from attribute: DGAttribute) {
        let key = Key(identifier: identifier, in: namespace)
        let newRecord = Record(key: key, relationship: relationship, nodes: nodes)
        
        func updateRecordsByAttribute(_ record: inout Record?) -> Bool {
            let changed = newRecord != record
            if changed {
                record = newRecord
            }
            return changed
        }
        
        guard updateRecordsByAttribute(&recordsByAttribute[attribute]) else {
            return
        }
        
        func updateRelatedNodesByKey(_ relatedNodes: inout [Relationship : [AccessibilityNode]]) {
            func updateRelatedNodes(_ relatedNodes: inout [AccessibilityNode]) {
                for node in nodes where !relatedNodes.contains(node) {
                    relatedNodes.append(node)
                }
            }
            
            if relatedNodes[relationship] == nil {
                relatedNodes[relationship] = nodes
            }
            
            updateRelatedNodes(&relatedNodes[relationship]!)
        }

        var relatedNodes = relatedNodesByKey[key] ?? [relationship: nodes]
        updateRelatedNodesByKey(&relatedNodes)
        relatedNodesByKey[key] = relatedNodes

        for node in nodes {
            let nodeRelation = NodeRelation(node: node.id, relationship: relationship)
            var keys = keysByNodeRelation[nodeRelation] ?? []
            keys.insert(key)
            keysByNodeRelation[nodeRelation] = keys
        }
    }
    
    internal func clear(from attribute: DGAttribute) {
        guard let record = recordsByAttribute.removeValue(forKey: attribute) else {
            return
        }
        
        var relationships: [Relationship] = []
        
        func updateRelatedNodesByKey(_ relatedNodesOrNil: inout [Relationship : [AccessibilityNode]]?) {
            guard var relatedNodes = relatedNodesOrNil else {
                return
            }
            defer {
                relatedNodesOrNil = relatedNodes
            }
            
            func updateRelatedNodes(removing relationship: Relationship, from rawNodes: inout [AccessibilityNode]?) -> Bool {
                guard var nodes = rawNodes else {
                    return false
                }

                guard record.relationship != relationship && record.nodes != rawNodes else {
                    rawNodes = nil
                    return true
                }
                
                defer {
                    rawNodes = nodes
                }
                
                for recordNode in record.nodes {
                    if !nodes.contains(recordNode) {
                        return false
                    }
                }

                nodes.removeAll(where: { record.nodes.contains($0) })
                return true
            }
            
            for relationship in relatedNodes.keys {
                if updateRelatedNodes(removing: relationship, from: &relatedNodes[relationship]) {
                    relationships.append(relationship)
                }
            }
        }
    
        updateRelatedNodesByKey(&relatedNodesByKey[record.key])
        
        for node in record.nodes {
            for relationship in relationships {
                let relation = NodeRelation(node: node.id, relationship: relationship)
                keysByNodeRelation[relation]?.remove(record.key)
            }
        }
    }

    private struct Key: Hashable {

        fileprivate var identifier: AnyHashable

        fileprivate var namespace: Namespace.ID
        
        fileprivate init<Identifier: Hashable>(identifier: Identifier, in namespace: Namespace.ID) {
            self.identifier = identifier
            self.namespace = namespace
        }

    }
    
    private struct NodeRelation: Hashable {

        fileprivate var node: UniqueID

        fileprivate var relationship: Relationship

    }
    
    internal enum Relationship: Hashable {

        case labeledPair(AccessibilityLabeledPairRole)

        case combinedLabelPair(AccessibilityLabeledPairRole)

        case linkedGroup

        case focusable

    }
    
    private struct Record: Equatable {
        
        internal let key: Key
        
        internal let relationship: Relationship
        
        internal let nodes: [AccessibilityNode]
        
    }

}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var accessibilityRelationshipScope: AccessibilityRelationshipScope? {
        get {
            self[AccessibilityRelationshipScope.self]
        }
        set {
            self[AccessibilityRelationshipScope.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension View {

    internal func accessibilityRelationShip<Identifier: Hashable>(_ relation: AccessibilityRelationshipScope.Relationship, id: Identifier, in namespace: Namespace.ID) -> some View {
        modifier(RelationshipModifier(relationship: relation, id: id, namespace: namespace))
    }
}

@available(iOS 13.0, *)
fileprivate struct RelationshipModifier<Identifier: Hashable>: PrimitiveViewModifier, MultiViewModifier, Equatable {
    
    fileprivate var relationship: AccessibilityRelationshipScope.Relationship

    fileprivate var id: Identifier

    fileprivate var namespace: Namespace.ID
    
    fileprivate static func _makeView(modifier: _GraphValue<RelationshipModifier<Identifier>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let outputs = body(_Graph(), inputs)
        
        guard inputs.preferences.requiresAccessibilityNodes, let relationshipScope = inputs.accessibilityRelationshipScope, let nodes = outputs.accessibilityNodes else {
            return outputs
        }
        
        let accessibilityEnabled = inputs.environmentAttribute(keyPath: \.accessibilityEnabled)
        
        let transform = Transform(
            selfAttribute: .nil,
            modifier: modifier.value,
            nodeList: nodes,
            accessibilityEnabled: accessibilityEnabled,
            scope: relationshipScope,
            state: nil
        )
        let attribute = Attribute(transform)
        attribute.flags = .active
        
        return outputs
    }
    
}

@available(iOS 13.0, *)
fileprivate struct Transform<Identifier: Hashable>: ObservedAttribute, StatefulRule, RemovableAttribute {
    
    fileprivate typealias Value = Void

    private var selfAttribute: DGAttribute

    @Attribute
    private var modifier: RelationshipModifier<Identifier>

    @Attribute
    private var nodeList: AccessibilityNodeList

    @Attribute
    private var accessibilityEnabled: Bool

    private var scope: AccessibilityRelationshipScope

    private var state: State?
    
    fileprivate init(selfAttribute: DGAttribute, modifier: Attribute<RelationshipModifier<Identifier>>, nodeList: Attribute<AccessibilityNodeList>, accessibilityEnabled: Attribute<Bool>, scope: AccessibilityRelationshipScope, state: State?) {
        self.selfAttribute = selfAttribute
        self._modifier = modifier
        self._nodeList = nodeList
        self._accessibilityEnabled = accessibilityEnabled
        self.scope = scope
        self.state = state
    }
    
    fileprivate static func didReinsert(attribute: DGAttribute) {
        _intentionallyLeftBlank()
    }
    
    fileprivate static func willRemove(attribute: DGAttribute) {
        attribute.info.body.assumingMemoryBound(to: Self.self).pointee.destroy()
    }
    
    fileprivate func destroy() {
        scope.clear(from: selfAttribute)
    }
    
    fileprivate mutating func updateValue() {
        if selfAttribute == .nil {
            selfAttribute = DGAttribute.current ?? .nil
        }
        
        guard accessibilityEnabled else {
            scope.clear(from: selfAttribute)
            return
        }
        
        let modifier = modifier
        let nodeList = nodeList
        let nodeIDs = Set(nodeList.nodes.map { $0.id })
        
        let newState = State(modifier: modifier, nodeIDs: nodeIDs)
        
        guard newState != state else {
            return
        }
        state = newState
        scope.clear(from: selfAttribute)
        
        scope.update(modifier.relationship, nodes: nodeList.nodes, identifier: modifier.id, in: modifier.namespace, from: selfAttribute)
        
        nodeList.nodes.forEach {
            $0.relationshipScope = scope
        }
    }
    
    fileprivate struct State: Equatable {

        fileprivate var modifier: RelationshipModifier<Identifier>

        fileprivate var nodeIDs: Set<UniqueID>

    }

}
