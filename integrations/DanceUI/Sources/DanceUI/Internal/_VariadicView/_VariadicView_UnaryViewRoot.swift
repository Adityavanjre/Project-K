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
public protocol _VariadicView_UnaryViewRoot : _VariadicView_ViewRoot {

}

@available(iOS 13.0, *)
extension _VariadicView_UnaryViewRoot {

    public static func _makeViewList(root: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        let bodyGenerator: (_ViewInputs) -> _ViewOutputs = { inputs in
            _makeView(root: root, inputs: inputs) { graph, viewInputs in
                let viewListInputs = _ViewListInputs(base: viewInputs.base,
                                                       implicitID: 0,
                                                       options: [],
                                                       traitKeys: ViewTraitKeys())
                return body(graph, viewListInputs)
            }
        }
        let elementBody = BodyUnaryViewGenerator(body: bodyGenerator)
        let elements = UnaryElements(body: elementBody, baseInputs: inputs.base)
        return _ViewListOutputs.staticList(elements, inputs: inputs, staticCount: 1)
    }

    public static func _viewListCount(inputs: _ViewListCountInputs, body: (_ViewListCountInputs) -> Int?) -> Int? {
        1
    }

}
