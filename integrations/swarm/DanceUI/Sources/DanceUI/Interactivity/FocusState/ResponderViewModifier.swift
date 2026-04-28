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
internal struct ResponderViewModifier<A: ViewModifier>: PrimitiveViewModifier, MultiViewModifier {

    internal var content: (ResponderNode) -> A
    
    internal static func _makeView(modifier: _GraphValue<ResponderViewModifier<A>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let responder = DefaultLayoutViewResponder(inputs: inputs)
        let responderChild = _GraphValue(ResponderChild(modifier: modifier.value, responder: responder))
        
        /*
         if AGSubgraphShouldRecordTree {
            AGSubgraphBeginTreeElement()
         }
         */
        
        var outputs = A.makeDebuggableViewModifier(value: responderChild, inputs: inputs, body: body)
        
        if inputs.preferences.requiresViewResponders {
            outputs.viewResponders = Attribute(DefaultLayoutResponderFilter(children: outputs.viewResponders ?? ViewGraph.current.$emptyViewResponders, responder: responder))
        }
        
        return outputs
    }

}

@available(iOS 13.0, *)
fileprivate struct ResponderChild<A: ViewModifier>: Rule {
    
    fileprivate typealias Value = A

    @Attribute
    fileprivate var modifier: ResponderViewModifier<A>

    fileprivate let responder: DefaultLayoutViewResponder
    
    fileprivate var value: Value {
        modifier.content(responder)
    }

}

@available(iOS 13.0, *)
internal struct DefaultLayoutResponderFilter: StatefulRule {
    
    internal typealias Value = [ViewResponder]

    @Attribute
    internal var children: [ViewResponder]

    internal let responder: DefaultLayoutViewResponder
    
    @inlinable
    internal init(children: Attribute<[ViewResponder]>, responder: DefaultLayoutViewResponder) {
        self._children = children
        self.responder = responder
    }
    
    internal mutating func updateValue() {
        let (children, areChildrenChanged) = $children.changedValue()
        
        if areChildrenChanged {
            responder.children = children
        }
        
        guard !hasValue else {
            return
        }
        
        value = [responder]
    }

}
