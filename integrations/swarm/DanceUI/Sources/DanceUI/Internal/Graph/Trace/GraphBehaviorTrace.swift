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

#if DEBUG || DANCE_UI_INHOUSE

// MARK: - attributeDescription
@available(iOS 13, *)
private func attributeDescription(_ attribute: DGAttribute, logPrefix: String = "attribute: ") -> String {
    guard attribute != .nil else {
        return "\(logPrefix)nil;"
    }
    let isIndirect = (attribute.rawValue & 0x1) == 0x1
    let flags = !isIndirect ? String(attribute.flags.rawValue, radix: 16) : "00"
    return "\(logPrefix)\(attribute.description); flags: 0x\(flags); self_type: \(isIndirect ? attribute.source._bodyType : attribute._bodyType); \(attribute.debugDescription)"
}

@available(iOS 13, *)
private struct GraphBehaviorTraceContext {

    init(logPrefix: String = "") {
        self.logPrefix = logPrefix
#if DEBUG
        logger.logLevel = .debug
#else
        logger.logLevel = .warning
#endif
    }

    private let logPrefix: String

    private var logger = Logger(label: "GraphBehaviorTrace", StreamLogHandler.standardOutput(label: "GraphBehaviorTrace"))

    private let queue: DispatchQueue = DispatchQueue(label: "com.bytedance.DG.trace")

    private var indentationLevel = 0 {
        willSet {
            if indentationLevel == 0, newValue > 0 {
                printSplitLine()
            } else if indentationLevel > 0, newValue == 0 {
                printSplitLine()
            }
        }
    }

    private func printSplitLine() {
        let logPrefix = self.logPrefix
        queue.async {
            self.logger.debug("\(logPrefix) \(String(repeating: "-", count: 140))")
        }
    }

    @_transparent
    fileprivate mutating func push() {
        indentationLevel += 1
    }

    @_transparent
    fileprivate mutating func pop() {
        precondition(indentationLevel > 0)
        indentationLevel -= 1
    }

    fileprivate func indentation() -> String {
        guard indentationLevel > 1 else {
            return ""
        }
        return String(repeating: "  ", count: indentationLevel)
    }

    fileprivate func log(_ description: String) {
        let prefix = self.logPrefix
        let indentation = indentation()
        queue.async {
            self.logger.debug("\(prefix)\(indentation)\(description)")
            fflush(stdout)
        }
    }
}

@available(iOS 13.0, *)
internal final class GraphBehaviorLogTrace: GraphTracing {

    deinit {

    }

    init(identifier: UnsafeRawPointer) {
        self.context = GraphBehaviorTraceContext(logPrefix: "\(identifier) ")
    }

    private var context: GraphBehaviorTraceContext

    internal override func graphWillStartTrace(_ graph: DGGraphRef) {
        context.log("[begin_trace] graph: \(ObjectIdentifier(graph));")
    }

    internal override func graphDidStopTrace(_ graph: DGGraphRef) {
        context.log("[end_trace] graph: \(ObjectIdentifier(graph));")
    }

    internal override func subgraphWillUpdate(_ subgraph: DGSubgraphRef, flags: UInt32) {
        context.push()
        context.log("[begin_update_subgraph] subgraph: \(ObjectIdentifier(subgraph)); flags: \(flags);")
    }

    internal override func subgraphDidUpdate(_ subgraph: DGSubgraphRef) {
        defer {
            context.pop()
        }
        context.log("[end_update_subgraph] subgraph: \(ObjectIdentifier(subgraph));")
    }

    internal override func beginUpdateNode(_ attribute: DGAttribute, flags: UInt32) {
        context.push()
        context.log("[begin_update_node] \(attributeDescription(attribute)); update_status: \(flags);")
    }

    internal override func endUpdateNode(_ attribute: DGAttribute, flags: UInt32) {
        defer {
            context.pop()
        }
        context.log("[end_update_node] \(attributeDescription(attribute)); update_status: \(flags);")
    }

    internal override func ignoreUpdateValue(_ attribute: DGAttribute) {

    }

    internal override func beginUpdateValue(_ attribute: DGAttribute) {
        context.push()
        context.log("[begin_update_value] \(attributeDescription(attribute));")
    }

    internal override func endUpdateValue(_ attribute: DGAttribute, changed: Bool) {
        defer {
            context.pop()
        }
        context.log("[end_update_value] \(attributeDescription(attribute)); changed: \(changed ? "true" : "false");")
    }

    internal override func graphWillUpdate(_ graph: DGGraphRef) {
        context.push()
        context.log("[begin_update_graph] graph: \(ObjectIdentifier(graph));")
    }

    internal override func graphDidUpdate(_ graph: DGGraphRef) {
        defer {
            context.pop()
        }
        context.log("[end_update_graph] graph: \(ObjectIdentifier(graph));")
    }

    internal override func graphWillInvalidate(_ graph: DGGraphRef, by attribute: DGAttribute) {
        context.push()
        context.log("[begin_invalidation_graph] graph: \(ObjectIdentifier(graph)); \(attributeDescription(attribute));")
    }

    internal override func graphDidInvalidate(_ graph: DGGraphRef, by attribute: DGAttribute) {
        defer {
            context.pop()
        }
        context.log("[end_invalidation_graph] graph: \(ObjectIdentifier(graph)); \(attributeDescription(attribute));")
    }

    internal override func attributeWillModify(_ attribute: DGAttribute) {
        context.push()
        context.log("[begin_modify_node] \(attributeDescription(attribute));")
    }

    internal override func attributeDidModify(_ attribute: DGAttribute) {
        defer {
            context.pop()
        }
        context.log("[end_modify_node] \(attributeDescription(attribute));")
    }

    internal override func attributeWillStartEvent(_ attribute: DGAttribute, name: UnsafePointer<CChar>) {
        context.push()
        context.log("[begin_event] \(attributeDescription(attribute)); event: \(String(cString: name));")
    }

    internal override func attributeDidEndEvent(_ attribute: DGAttribute, name: UnsafePointer<CChar>) {
        defer {
            context.pop()
        }
        context.log("[end_event] \(attributeDescription(attribute)); event: \(String(cString: name));")
    }

    internal override func graphDidCreate(_ graph: DGGraphRef) {
        context.log("[graph_created] graph: \(ObjectIdentifier(graph));")
    }

    internal override func graphWillDestroy(_ graph: DGGraphRef) {
        context.log("[graph_destroy] graph: \(ObjectIdentifier(graph));")
    }

    internal override func graphNeedsUpdate(_ graph: DGGraphRef) {
        context.log("[graph_needs_update] graph: \(ObjectIdentifier(graph));")
    }

    internal override func subgraphDidCreate(_ subgraph: DGSubgraphRef) {
        context.log("[subgraph_created] subgraph: \(ObjectIdentifier(subgraph));")
    }

    internal override func subgraphWillDestroy(_ subgraph: DGSubgraphRef) {
        context.log("[subgraph_destroy] subgraph: \(ObjectIdentifier(subgraph));")
    }

    internal override func subgraph(_ subgraph: DGSubgraphRef, didAdd child: DGSubgraphRef) {
        context.log("[subgraph_add_child] subgraph: \(ObjectIdentifier(subgraph)); child: \(ObjectIdentifier(child));")
    }

    internal override func subgraph(_ subgraph: DGSubgraphRef, didRemove child: DGSubgraphRef) {
        context.log("[subgraph_remove_child] subgraph: \(ObjectIdentifier(subgraph)); child: \(ObjectIdentifier(child));")
    }

    internal override func nodeDidAdd(_ attribute: DGAttribute) {
        context.log("[node_added] \(attributeDescription(attribute));")
    }

    internal override func node(_ attribute: DGAttribute, didAdd edgeAttribute: DGAttribute, flags: UInt32) {
        context.log("[node_add_edge] \(attributeDescription(attribute)); edge: \(edgeAttribute); options: \(flags);")
    }

    internal override func node(_ attribute: DGAttribute, didRemoveEdgeAt index: UInt64) {
        context.log("[node_remove_edge] \(attributeDescription(attribute)); edge_index: \(index);")
    }

    internal override func node(_ attribute: DGAttribute, edgeIndex: UInt64, pending: Bool) {
        context.log("[node_set_edge_pending] \(attributeDescription(attribute)); edge_index: \(edgeIndex); is_pending: \(pending ? "true" : "false");")
    }

    internal override func node(_ attribute: DGAttribute, dirty: Bool) {
        context.log("[node_set_dirty] \(attributeDescription(attribute)); is_dirty: \(dirty ? "true" : "false");")
    }

    internal override func node(_ attribute: DGAttribute, pending: Bool) {
        context.log("[node_set_pending] \(attributeDescription(attribute)); is_pending: \(pending ? "true" : "false");")
    }

    internal override func node(_ attribute: DGAttribute, value: UnsafeRawPointer) {
        context.log("[node_set_value] \(attributeDescription(attribute)); value: \(value);")
    }

    internal override func attributeDidMarkValue(_ attribute: DGAttribute) {
        context.log("[node_mark_value] \(attributeDescription(attribute));")
    }

    internal override func indirectNodeDidAdd(_ attribute: DGAttribute) {
        context.log("[indirect_node_added] attribute: \(attribute); subgraph_id: \(attribute.subgraph); \(attributeDescription(attribute.source, logPrefix: "source: "));")
    }

    internal override func indirectNode(_ attribute: DGAttribute, didSetSource source: DGAttribute) {
        context.log("[indirect_node_set_source]  attribute: \(attribute); \(attributeDescription(source, logPrefix: "source_attribute: "));")
    }

    internal override func indirectNode(_ attribute: DGAttribute, didSetDependency dependency: DGAttribute) {
        context.log("[indirect_node_set_dependency]  attribute: \(attribute); dependency_attribute: \(attributeDescription(dependency, logPrefix: "dependency_attribute: "));")
    }

    internal override func markProfile(with name: UnsafePointer<CChar>) {
        context.log("[profile_mark] event: \(String(cString: name));")
    }

}

@available(iOS 13, *)
internal struct GraphBehaviorLogTraceKey: DefaultFalseBoolEnvKey {
    
    internal static var raw: String {
        "DANCEUI_GRAPH_TRACE"
    }
    
}

@available(iOS 13, *)
extension EnvValue where K == GraphBehaviorLogTraceKey {
    
    private static let singleton: Self = .init()
    
    @inline(__always)
    internal static var isGraphTraceEnabled: Bool {
        singleton.value
    }
}

#endif
