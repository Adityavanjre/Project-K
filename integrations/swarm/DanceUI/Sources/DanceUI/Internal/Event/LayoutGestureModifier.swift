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
import Foundation

// This file is unsed

@available(iOS 13, *)
internal final class LayoutGestureResponder<Content>: MultiViewResponder where Content: Gesture, Content.Value == () {

    internal let modifier: Attribute<LayoutGestureModifier<Content>>
    
    internal let inputs: _ViewInputs
    
    internal let viewSubgraph: DGSubgraphRef
    
    internal var childSubgraph: DGSubgraphRef? = nil

    internal var childViewSubgraph: DGSubgraphRef? = nil

    internal var invalidateChildren: (() -> Void)? = nil

    internal init(modifier: Attribute<LayoutGestureModifier<Content>>, inputs: _ViewInputs) {
        self.modifier = modifier
        self.inputs = inputs
        self.viewSubgraph = DGSubgraphRef.current!
        super.init()
    }
    
    internal override func makeGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        makeGesture(inputs: inputs)
    }
    
    internal override func makeGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        let outputs: _GestureOutputs<Void> = inputs.makeDefaultOutputs()
        guard viewSubgraph.isValid else {
            return outputs
        }
        let currentSubgraph = DGSubgraphRef.current!
        let needGestureGraph = inputs.options.contains(.gestureGraph)
        childSubgraph = DGSubgraphCreate((needGestureGraph ? currentSubgraph : viewSubgraph).graph)
        viewSubgraph.add(child: childSubgraph!)
        currentSubgraph.add(child: childSubgraph!)
        if needGestureGraph {
            childViewSubgraph = DGSubgraphCreate(viewSubgraph.graph)
            childSubgraph!.add(child: childViewSubgraph!)
        }
        childSubgraph!.apply {
            let gesture = Attribute(LayoutGestureChild(modifier: modifier, node: self))
            let weakGesture = WeakAttribute(gesture)
            invalidateChildren = {
                Update.enqueueAction {
                    weakGesture.attribute?.invalidateValue()
                }
            }
            let subgraph = (childViewSubgraph ?? childSubgraph)!
            var childInputs = inputs
            childInputs.mergeViewInputs(self.inputs, viewSubgraph: subgraph)
            let childOutputs = Content._makeGesture(
                gesture: _GraphValue(gesture),
                inputs: childInputs
            )
            outputs.overrideDefaultValues(childOutputs)
        }
        return outputs
    }
    
    internal override func childrenDidChange() {
        if let invalidateChildren {
            invalidateChildren()
        }
        super.childrenDidChange()
    }
    
    internal override func resetGesture() {
        invalidateChildren = nil
        childSubgraph = nil
        childViewSubgraph = nil
        super.resetGesture()
    }
}

@available(iOS 13, *)
internal struct LayoutGestureModifier<Content>: MultiViewModifier, PrimitiveViewModifier where Content: Gesture, Content.Value == () {
    internal var transform: (MultiViewResponder) -> Content
    
    internal static func _makeView(
        modifier: _GraphValue<LayoutGestureModifier<Content>>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        var outputs = body(_Graph(), inputs)
        if inputs.preferences.requiresViewResponders {
            let responder = LayoutGestureResponder(
                modifier: modifier.value,
                inputs: inputs
            )
            let filter = LayoutResponderFilter<Content>(
                children: outputs.viewResponders ?? GraphHost.currentHost.intern([], id: 0),
                responder: responder
            )
            outputs[ViewRespondersKey.self] = Attribute(filter)
        }
        return outputs
    }
}

@available(iOS 13, *)
extension View {
    internal func layoutGesture<Content>(_ transform: @escaping (MultiViewResponder) -> Content) -> some View where Content: Gesture, Content.Value == () {
        return modifier(LayoutGestureModifier(transform: transform))
    }
}

@available(iOS 13, *)
internal struct LayoutGestureChild<Content>: Rule where Content: Gesture, Content.Value == () {
    @DanceUIGraph.Attribute
    internal var modifier: LayoutGestureModifier<Content>
    
    internal let node: MultiViewResponder
    
    internal typealias Value = Content
    
    internal var value: Value {
        modifier.transform(node)
    }
}

@available(iOS 13, *)
internal struct LayoutResponderFilter<Content>: StatefulRule where Content: Gesture, Content.Value == () {
    @DanceUIGraph.Attribute
    internal var children: [ViewResponder]
    
    internal let responder: LayoutGestureResponder<Content>
    
    internal typealias Value = [ViewResponder]
    
    internal mutating func updateValue() {
        responder.updateChildren($children.changedValue())
        if !hasValue {
            value = [responder]
        }
    }
}
