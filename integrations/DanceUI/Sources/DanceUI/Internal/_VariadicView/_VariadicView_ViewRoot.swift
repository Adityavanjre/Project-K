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
public protocol _VariadicView_ViewRoot : _VariadicView_Root {

    associatedtype Body : View

    static func _makeView(root: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs

    static func _makeViewList(root: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs

    static func _viewListCount(inputs: _ViewListCountInputs, body: (_ViewListCountInputs) -> Int?) -> Int?

    @ViewBuilder
    func body(children: _VariadicView.Children) -> Self.Body

}

@available(iOS 13.0, *)
extension _VariadicView_ViewRoot where Self.Body == Never {

    public func body(children: _VariadicView.Children) -> Never {
        _terminatedViewNode()
    }
}

@available(iOS 13.0, *)
extension _VariadicView_ViewRoot {

    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeView(root: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        let outputs = body(_Graph(), inputs)
        let listInputs = _ViewListInputs(base: inputs.base,
                                           implicitID: 0,
                                           options: _ViewListInputs.Options(),
                                           traitKeys: ViewTraitKeys())
        let outputsAttribute = outputs.makeAttribute(inputs: listInputs)
        let fields = DynamicPropertyCache.fields(of: Self.self)
        var newInputs = inputs

        let (body, buffer) = newInputs.withMutableGraphInputs { mutableInputs in
            makeBody(root: root, list:outputsAttribute, inputs: &mutableInputs, fields: fields)
        }

        let outputsValue = Body.makeDebuggableView(value: body, inputs: inputs)

        if let propertyBuffer = buffer {
            propertyBuffer.traceMountedProperties(to: root, fields: fields)
        }

        return outputsValue
    }

    @_semantics("optimize.sil.specialize.generic.never")
    public static func _makeViewList(root: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        let outputs = body(_Graph(), inputs)
        let listInputs = _ViewListInputs(base: inputs.base,
                                           implicitID: 0,
                                           options: _ViewListInputs.Options(),
                                           traitKeys: ViewTraitKeys())
        let outputsAttribute = outputs.makeAttribute(inputs: listInputs)
        let fields = DynamicPropertyCache.fields(of: Self.self)
        var newInputs = inputs

        let (body, buffer) = newInputs.withMutableGraphInputs { mutableInputs in
            makeBody(root: root, list:outputsAttribute, inputs: &mutableInputs, fields: fields)
        }

        let outputsValue = Body.makeDebuggableViewList(value: body, inputs: inputs)

        if let propertyBuffer = buffer {
            propertyBuffer.traceMountedProperties(to: root, fields: fields)
        }

        return outputsValue
    }

    public static func _viewListCount(inputs: _ViewListCountInputs, body: (_ViewListCountInputs) -> Int?) -> Int? {
        Body._viewListCount(inputs: inputs)
    }

    private static func makeBody(root: _GraphValue<Self>,
                                 list: Attribute<ViewList>,
                                 inputs: inout _GraphInputs,
                                 fields: DynamicPropertyCache.Fields) -> (_GraphValue<Self.Body>, _DynamicPropertyBuffer?) {
        _danceuiPrecondition(Self.Body.self != Never.self, "Never may not have Body == Never, Self: \(Self.self)")
        let kind = DGTypeID(Self.self).kind
        guard kind.isOfValueTypes else {
            _danceuiFatalError("\(_typeName(Self.self)) is a class.")
        }

        let subgraph = DGSubgraphRef.current!
        let bodyAccessor = ViewRootBodyAccessor<Self>(list: list, contentSubgraph: subgraph)
        return bodyAccessor.makeBody(container: root, inputs: &inputs, fields: fields)
    }
}
