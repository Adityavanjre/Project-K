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

internal protocol ViewModifierContentProvider {
    
}


@available(iOS 13.0, *)
extension ViewModifierContentProvider {
    
    internal static func _providerMakeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        var newInputs = _ViewInputs(inputs)
        guard let viewBody = newInputs.popLast(for: BodyInput.self) else {
            return .init()
        }
        switch viewBody {
        case .view(let makeViewBody):
            return makeViewBody(_Graph(), newInputs)
        case .list(let makeViewListBody):
            var visitor = MakeViewRoot(inputs: inputs) { graph, viewInputs in
                let viewListInputs = _ViewListInputs(base: viewInputs.base,
                                                     implicitID: 0,
                                                     options: viewInputs.viewListOptions,
                                                     traitKeys: ViewTraitKeys())
                return makeViewListBody(graph, viewListInputs)
            }
            inputs.implicitRootType.visitType(visitor: &visitor.self)
            return visitor.outputs!
        }
    }
    
    internal static func _providerMakeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        
        var newInputs = inputs
        
        guard let viewBody = newInputs.popLast(for: BodyInput.self) else {
            if inputs.hasParent {
                return .nonEmptyParentViewList(inputs: newInputs)
            } else {
                return .staticList(EmptyViewListElements(), inputs: newInputs, staticCount: 0)
            }
        }
        
        switch viewBody {
        case .view(let makeViewBody):
            let body = BodyUnaryViewGenerator { (inputs) -> _ViewOutputs in
                makeViewBody(_Graph(), inputs)
            }
            let element = UnaryElements(body: body, baseInputs: newInputs.base)
            return _ViewListOutputs.staticList(element, inputs: newInputs, staticCount: 1)
        case .list(let makeViewListBody):
            return makeViewListBody(_Graph(), newInputs)
        }
        
    }
    
    internal static func _providerViewListCount(inputs: _ViewListCountInputs) -> Int? {
        var newInputs = inputs
        guard let value = newInputs.popLast(type: BodyCountInput.self),
              !inputs.customModifierTypes.contains(where: { ObjectIdentifier(self.self) == $0 }) else {
            return nil
        }
        return value(newInputs)
    }
}


@available(iOS 13.0, *)
extension ViewModifier {
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeView(modifier: modifier, inputs: inputs, body: body)
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal static func makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let fields = DynamicPropertyCache.fields(of: self)
        var newInputs = inputs
        let (bodyGraphValue, linksOrNil) = withMutableViewInputs(&newInputs) { base in
            makeBody(modifier: modifier,
                     inputs: &base,
                     fields: fields)
        }
        newInputs.append(.view(body), for: BodyInput.self)
        let outputs = Body.makeDebuggableView(value: bodyGraphValue, inputs: newInputs)

        if let links: _DynamicPropertyBuffer = linksOrNil {
            links.traceMountedProperties(to: modifier, fields: fields)
        }
        return outputs
    }
    
    public static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        makeViewList(modifier: modifier, inputs: inputs, body: body)
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal static func makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        let fields = DynamicPropertyCache.fields(of: self)
        var newInputs = inputs
        
        let (bodyGraphValue, bufferOrNil): (_GraphValue<Self.Body>, _DynamicPropertyBuffer?) = newInputs.withMutableGraphInputs { base in
            let result = makeBody(modifier: modifier,
                                  inputs: &base,
                                  fields: fields)
            base.append(value: .list(body),
                        for: BodyInput.self)
            return result
        }
        
        let outputs = Body._makeViewList(view: bodyGraphValue, inputs: newInputs)
        if let buffer = bufferOrNil {
            buffer.traceMountedProperties(to: modifier, fields: fields)
        }
        return outputs
    }
    
    internal static func makeMultiViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        var outputs = body(_Graph(), inputs)
        outputs.multiModifier(modifier, inputs: inputs)
        return outputs
    }
    
    private static func makeBody(modifier: _GraphValue<Self>, inputs: inout _GraphInputs, fields: DynamicPropertyCache.Fields) -> (_GraphValue<Self.Body>, _DynamicPropertyBuffer?) {
        _danceuiPrecondition(Body.self != Never.self, "Body type is Never. Consider implement ViewModifier._makeView on \(Self.self) or protocol extensions it conforms to.")
        guard DGTypeID(Self.self).kind.isOfValueTypes else {
            _danceuiFatalError("\(_typeName(self)) must be value type.")
        }
        return ModifierBodyAccessor<Self>().makeBody(container: modifier, inputs: &inputs, fields: fields)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
        viewListCount(inputs: inputs, body: body)
    }
    
    private static func viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
        var newInputs = inputs
        newInputs.append(value: body, to: BodyCountInput.self)
        return Body._viewListCount(inputs: newInputs)
    }
}


@available(iOS 13.0, *)
internal struct BodyInput: ViewInput, PropertyKey {
    
    internal typealias Value = [Body]
    
    internal static var defaultValue: [Body] {
        [Body]()
    }
    
    internal typealias MakeViewBody = (_Graph, _ViewInputs) -> _ViewOutputs
    
    internal typealias MakeViewListBody = (_Graph, _ViewListInputs) -> _ViewListOutputs
    
    internal enum Body {
        case view(MakeViewBody)
        case list(MakeViewListBody)
    }
}

@available(iOS 13.0, *)
private struct BodyInputElement: ViewInput, PropertyKey {
    
    fileprivate typealias Value = [BodyInputElement]
    
    fileprivate static var defaultValue: Value {
        []
    }
    
    fileprivate typealias MakeViewBody = (_Graph, _ViewInputs) -> _ViewOutputs
    
    fileprivate typealias MakeViewListBody = (_Graph, _ViewListInputs) -> _ViewListOutputs
    
    fileprivate enum Body {
        case view(MakeViewBody)
        case list(MakeViewListBody)
    }
}

