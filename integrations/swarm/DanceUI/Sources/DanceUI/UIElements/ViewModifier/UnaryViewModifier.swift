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

import Foundation

@available(iOS 13.0, *)
internal protocol UnaryViewModifier: ViewModifier {
    
}

@available(iOS 13.0, *)
extension UnaryViewModifier {
    
    internal static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        return makeUnaryViewList(modifier: modifier, inputs: inputs, body: body)
    }
    
    internal static func _viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
        1
    }
    
}

@available(iOS 13.0, *)
fileprivate struct MakeModifiedRoot<Modifier: ViewModifier>: _VariadicView_ImplicitRootVisitor {

    internal var modifier: _GraphValue<Modifier>

    internal var inputs: _ViewInputs

    internal var body: (_Graph, _ViewInputs) -> _ViewListOutputs

    internal var outputs: _ViewOutputs?
    
    internal mutating func visit<RootType>(type: RootType.Type) where RootType : _VariadicView_ImplicitRoot {
        let attr = inputs.intern(RootType.implicitRoot, id: .init(0x1))
        
        inputs.viewListOptions = RootType._viewListOptions
        
        self.outputs = Modifier._makeView(modifier: modifier, inputs: inputs) { [self] graph, viewInputs in
            let root = _GraphValue(attr)
            return type._makeView(root: root, inputs: viewInputs, body: self.body)
        }
    }

}

@available(iOS 13.0, *)
extension ViewModifier {
    
    internal static func makeUnaryViewList(modifier: _GraphValue<Self>,
                                           inputs: _ViewListInputs,
                                           body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        let bodyGenerator: (_ViewInputs) -> _ViewOutputs = { inputs in
            makeImplicitRoot(modifier: modifier, inputs: inputs) { graph, viewInputs in
                let viewListInputs = _ViewListInputs(base: viewInputs.base,
                                                       implicitID: 0,
                                                       options: .disableTransition,
                                                       traitKeys: ViewTraitKeys())
                return body(graph, viewListInputs)
            }
        }
        let elementBody = BodyUnaryViewGenerator(body: bodyGenerator)
        let elements = UnaryElements(body: elementBody, baseInputs: inputs.base)
        return _ViewListOutputs.staticList(elements, inputs: inputs, staticCount: 1)
    }
    
    internal static func makeImplicitRoot(modifier: _GraphValue<Self>,
                                          inputs: _ViewInputs,
                                          body: @escaping (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        var visitor = MakeModifiedRoot(modifier: modifier,
                                       inputs: inputs,
                                       body: body,
                                       outputs: nil)
        inputs.implicitRootType.visitType(visitor: &visitor)
        return visitor.outputs!
    }
    
}
