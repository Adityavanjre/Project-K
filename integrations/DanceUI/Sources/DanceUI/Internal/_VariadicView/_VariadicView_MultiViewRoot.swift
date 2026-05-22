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
public protocol _VariadicView_MultiViewRoot : _VariadicView_ViewRoot {

}

@available(iOS 13.0, *)
extension _VariadicView_MultiViewRoot {

    public static func _makeView(root: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        return withoutActuallyEscaping(body) { body in

            let ImplicitRootType = inputs.implicitRootType
            var visitor = MakeViewRoot(inputs: inputs, body: body)
            ImplicitRootType.visitType(visitor: &visitor.self)

            guard let retVal = visitor.outputs else {
                _danceuiPreconditionFailure()
            }

            return retVal
        }
    }

    public static func _viewListCount(inputs: _ViewListCountInputs, body: (_ViewListCountInputs) -> Int?) -> Int? {
        body(inputs)
    }
}
