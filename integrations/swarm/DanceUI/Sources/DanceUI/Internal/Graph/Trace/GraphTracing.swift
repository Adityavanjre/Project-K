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

/// Ideally, this typa shall be a protocol. However, even class protocol
/// would introduce overhead in type casting in the C bridge. Thus this
/// type is a class such that we can reduce type casting overhead.
@available(iOS 13.0, *)
internal class GraphTracing {

    func graphWillStartTrace(_ graph: DGGraphRef) {

    }

    func graphDidStopTrace(_ graph: DGGraphRef) {

    }

    func subgraphWillUpdate(_ subgraph: DGSubgraphRef, flags: UInt32) {

    }

    func subgraphDidUpdate(_ subgraph: DGSubgraphRef) {

    }

    /// Called when the DanceUIGraph will update an attribute with
    /// an update stack.
    func beginUpdateNode(_ attribute: DGAttribute, flags: UInt32) {

    }

    /// Called when the DanceUIGraph did update an attribute with
    /// an update stack.
    func endUpdateNode(_ attribute: DGAttribute, flags: UInt32) {

    }

    /// Called when the DanceUIGraph will update a value during the
    /// attribute update.
    func beginUpdateValue(_ attribute: DGAttribute) {

    }

    /// Called when the DanceUIGraph did update a value during the
    /// attribute update.
    func endUpdateValue(_ attribute: DGAttribute, changed: Bool) {

    }

    /// Called when the DanceUIGraph ignores the update of a value during
    /// the attribute update.
    func ignoreUpdateValue(_ attribute: DGAttribute) {

    }

    func graphWillUpdate(_ graph: DGGraphRef) {

    }

    func graphDidUpdate(_ graph: DGGraphRef) {

    }

    func graphWillInvalidate(_ graph: DGGraphRef, by attribute: DGAttribute) {

    }

    func graphDidInvalidate(_ graph: DGGraphRef, by attribute: DGAttribute) {

    }

    func attributeWillModify(_ attribute: DGAttribute) {

    }

    func attributeDidModify(_ attribute: DGAttribute) {

    }

    func attributeWillStartEvent(_ attribute: DGAttribute, name: UnsafePointer<CChar>) {

    }

    func attributeDidEndEvent(_ attribute: DGAttribute, name: UnsafePointer<CChar>) {

    }

    func graphDidCreate(_ graph: DGGraphRef) {

    }

    func graphWillDestroy(_ graph: DGGraphRef) {

    }

    func graphNeedsUpdate(_ graph: DGGraphRef) {

    }

    func subgraphDidCreate(_ subgraph: DGSubgraphRef) {

    }

    func subgraphWillDestroy(_ subgraph: DGSubgraphRef) {

    }

    func subgraph(_ subgraph: DGSubgraphRef, didAdd child: DGSubgraphRef) {

    }

    func subgraph(_ subgraph: DGSubgraphRef, didRemove child: DGSubgraphRef) {

    }

    func nodeDidAdd(_ attribute: DGAttribute) {

    }

    func node(_ attribute: DGAttribute, didAdd edge: DGAttribute, flags: UInt32) {

    }

    func node(_ attribute: DGAttribute, didRemoveEdgeAt index: UInt64) {

    }

    func node(_ attribute: DGAttribute, edgeIndex: UInt64, pending: Bool) {

    }

    func node(_ attribute: DGAttribute, dirty: Bool) {

    }

    func node(_ attribute: DGAttribute, pending: Bool) {

    }

    func node(_ attribute: DGAttribute, value: UnsafeRawPointer) {

    }

    func attributeDidMarkValue(_ attribute: DGAttribute) {

    }

    func indirectNodeDidAdd(_ attribute: DGAttribute) {

    }

    func indirectNode(_ attribute: DGAttribute, didSetSource source: DGAttribute) {

    }

    func indirectNode(_ attribute: DGAttribute, didSetDependency dependency: DGAttribute) {

    }

    func markProfile(with name: UnsafePointer<CChar>) {

    }

    func attributeWillInvalidateValue(_ attribute: DGAttribute) {

    }

    func attributeDidInvalidateValue(_ attribute: DGAttribute) {

    }

    func attributeWillSetValue(_ attribute: DGAttribute) {

    }

    func attributeDidSetValue(_ attribute: DGAttribute) {

    }

    func attributeWillMutateBody(_ attribute: DGAttribute, _ invalidating: Bool) {

    }

    func attributeDidMutateBody(_ attribute: DGAttribute, _ invalidating: Bool) {

    }

}

@available(iOS 13.0, *)
private var globalTrace: DGTraceType = .init(version: 0) { ctx, graph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphWillStartTrace(graph)
} end_trace: { ctx, graph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphDidStopTrace(graph)
} begin_subgraph_update: { ctx, subgraph, flags in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.subgraphWillUpdate(subgraph, flags: flags)
} end_subgraph_update: { ctx, subgraph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.subgraphDidUpdate(subgraph)
} begin_node_update: { ctx, attribute, flags in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.beginUpdateNode(attribute, flags: flags)
} end_node_update: { ctx, attribute, flags in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.endUpdateNode(attribute, flags: flags)
} begin_value_update: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.beginUpdateValue(attribute)
} end_value_update: { ctx, attribute, changed in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.endUpdateValue(attribute, changed: changed)
} begin_graph_update: { ctx, graph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphWillUpdate(graph)
} end_graph_update: { ctx, graph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphDidUpdate(graph)
} begin_graph_invalidation: { ctx, graph, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphWillInvalidate(graph, by: attribute)
} end_graph_invalidation: { ctx, graph, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphDidInvalidate(graph, by: attribute)
} begin_modify_node: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeWillModify(attribute)
} end_modify_node: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeDidModify(attribute)
} begin_event: { ctx, attribute, eventName in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeWillStartEvent(attribute, name: eventName)
} end_event: { ctx, attribute, eventName in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeDidEndEvent(attribute, name: eventName)
} graph_created: { ctx, graph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphDidCreate(graph)
} graph_destroy: { ctx, graph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphWillDestroy(graph)
} graph_needs_update: { ctx, graph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.graphNeedsUpdate(graph)
} subgraph_created: { ctx, subgraph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.subgraphDidCreate(subgraph)
} subgraph_destroy: { ctx, subgraph in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.subgraphWillDestroy(subgraph)
} subgraph_add_child: { ctx, subgraph, child in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.subgraph(subgraph, didAdd: child)
} subgraph_remove_child: { ctx, subgraph, child in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.subgraph(subgraph, didRemove: child)
} node_added: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.nodeDidAdd(attribute)
} node_add_edge: { ctx, attribute, edge, edgeFlags in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.node(attribute, didAdd: edge, flags: edgeFlags)
} node_remove_edge: { ctx, attribute, edgeIndex in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.node(attribute, didRemoveEdgeAt: edgeIndex)
} node_set_edge_pending: { ctx, attribute, edgeIndex, pending in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.node(attribute, edgeIndex: edgeIndex, pending: pending)
} node_set_dirty: { ctx, attribute, dirty in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.node(attribute, dirty: dirty)
} node_set_pending: { ctx, attribute, pending in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.node(attribute, pending: pending)
} node_set_value: { ctx, attribute, value in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.node(attribute, value: value)
} node_mark_value: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeDidMarkValue(attribute)
} indirect_node_added: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.indirectNodeDidAdd(attribute)
} indirect_node_set_source: { ctx, indirectAttribute, sourceAttribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.indirectNode(indirectAttribute, didSetSource: sourceAttribute)
} indirect_node_set_dependency: { ctx, indirectAttribute, dependencyAttribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.indirectNode(indirectAttribute, didSetDependency: dependencyAttribute)
} profile_mark: { ctx, profileName in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.markProfile(with: profileName)
} ignore_update_value: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.ignoreUpdateValue(attribute)
} node_will_invalidate_value: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeWillInvalidateValue(attribute)
} node_did_invalidate_value: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeDidInvalidateValue(attribute)
} node_will_set_value: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeWillSetValue(attribute)
} node_did_set_value: { ctx, attribute in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeDidSetValue(attribute)
} node_will_mutate_body: { ctx, attribute, invalidating in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeWillMutateBody(attribute, invalidating)
} node_did_mutate_body: { ctx, attribute, invalidating in
    let context = Unmanaged<GraphTracing>.fromOpaque(ctx).takeUnretainedValue()
    context.attributeDidMutateBody(attribute, invalidating)
}


@available(iOS 13.0, *)
extension DGGraphRef {

    internal func add(trace: GraphTracing) -> DGUniqueID {
        self.add(trace: &globalTrace,
                 context: Unmanaged.passRetained(trace as AnyObject).toOpaque())
    }

}
