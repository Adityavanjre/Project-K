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
internal struct HitTestBindingModifier: PrimitiveViewModifier, MultiViewModifier {
    
    internal typealias Body = Never
    
    internal typealias Content = Never
    
    internal static func _makeView(modifier: _GraphValue<HitTestBindingModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        var outputs = body(_Graph(), inputs)
        guard inputs.preferences.requiresViewResponders else {
            return outputs
        }
        let viewGraph = ViewGraph.current

        let responders = outputs.viewResponders ?? viewGraph.$emptyViewResponders

        let filter = HitTestBindingFilter(children: responders, responder: HitTestBindingResponder(inputs: inputs))
        outputs.viewResponders = Attribute(filter)
        return outputs
    }
}

@available(iOS 13.0, *)
private final class HitTestBindingResponder: DefaultLayoutViewResponder {
    
    fileprivate override init(inputs: _ViewInputs) {
        super.init(inputs: inputs)
    }
    
    fileprivate override func bindEvent(_ event: EventType) -> ResponderNode? {
        guard let hitTestableEvent = HitTestableEvent(event) else {
            return nil
        }
        
        if let node = hitTest(globalPoint: hitTestableEvent.hitTestLocation, radius: hitTestableEvent.hitTestRadius) {
            return node
        }
        
        return super.bindEvent(event)
    }
    
}

@available(iOS 13.0, *)
private struct HitTestBindingFilter: StatefulRule {
    
    internal typealias Value = [ViewResponder]
    
    @Attribute
    internal var children: [ViewResponder]

    internal let responder: HitTestBindingResponder
    
    internal mutating func updateValue() {
        responder.children = children
        if !context.hasValue {
            value = [responder]
        }
    }
}
