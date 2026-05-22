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
internal protocol StyleableView: PrimitiveView {
    
    associatedtype DefaultBody: View

    func defaultBody() -> DefaultBody
    
}

@available(iOS 13.0, *)
extension StyleableView {
    
    internal static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        
        var newInputs = inputs
        
        let lastAnyStyle = newInputs.popLast(for: StyleInput<Self>.self)
        
        if let anyStyle = lastAnyStyle {
            return anyStyle.formula.makeView(view: view, style: anyStyle, inputs: newInputs)
        } else {
            typealias MakeDefaultBodyType = MakeDefaultBody<Self>
            
            let defaultBody = MakeDefaultBodyType(view: view.value)
            
            let graphValue = _GraphValue(defaultBody)
            
            let outputs = MakeDefaultBodyType.Value.makeDebuggableView(value: graphValue, inputs: newInputs)
            
            return outputs
        }
    }
    
    internal static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        
        var newInputs = inputs
        
        let lastAnyStyle = newInputs.popLast(for: StyleInput<Self>.self)
        
        if let anyStyle = lastAnyStyle {
            return anyStyle.formula.makeViewList(view: view, style: anyStyle, inputs: newInputs)
        } else {
            typealias MakeDefaultBodyType = MakeDefaultBody<Self>
            
            let defaultBody = MakeDefaultBodyType(view: view.value)
            
            let graphValue = _GraphValue(defaultBody)
            
            return MakeDefaultBodyType.Value._makeViewList(view: graphValue, inputs: newInputs)
        }
    }
}

@available(iOS 13.0, *)
private struct MakeDefaultBody<ViewType: StyleableView>: Rule {
    
    fileprivate typealias Value = ViewType.DefaultBody
    
    @Attribute
    fileprivate var view: ViewType

    fileprivate var value: Value {
        view.defaultBody()
    }
}

@available(iOS 13.0, *)
private struct StyleInput<A: StyleableView>: ViewInput {
    
    fileprivate typealias Value = [AnyStyle]
    
    fileprivate static var defaultValue: [AnyStyle] {
        []
    }
}

@available(iOS 13.0, *)
private protocol AnyStyleFormula {
    
    static func makeView<A1: StyleableView>(view: _GraphValue<A1>, style: AnyStyle, inputs: _ViewInputs) -> _ViewOutputs
    
    static func makeViewList<A1: StyleableView>(view: _GraphValue<A1>, style: AnyStyle, inputs: _ViewListInputs) -> _ViewListOutputs
}

@available(iOS 13.0, *)
private struct StyleFormula<Modifier: StyleModifier>: AnyStyleFormula {
    
    fileprivate static func makeView<View: StyleableView>(view: _GraphValue<View>, style: AnyStyle, inputs: _ViewInputs) -> _ViewOutputs {
        
        var newInputs = inputs
        
        let fields = DynamicPropertyCache.fields(of: Modifier.Style.self)
        
        let (graphValue, propertyBuffer) = withMutableViewInputs(&newInputs) { base in
            makeStyleBody(view: view, style: style, inputs: &base, fields: fields)
        }
        
        let outputs = Modifier.SubjectBody.makeDebuggableView(value: graphValue, inputs: newInputs)
        
        if let propertyBufferValue = propertyBuffer {
            propertyBufferValue.traceMountedProperties(to: view, fields: fields)
        }
        
        return outputs
        
    }
    
    fileprivate static func makeViewList<View: StyleableView>(view: _GraphValue<View>, style: AnyStyle, inputs: _ViewListInputs) -> _ViewListOutputs {
        var newInputs = inputs
        
        let styleFields = DynamicPropertyCache.fields(of: Modifier.Style.self)
        
        let (styleBody, styleBuffer) = newInputs.withMutableGraphInputs { base in
            makeStyleBody(view: view, style: style, inputs: &base, fields: styleFields)
        }
        
        let outputs = Modifier.SubjectBody._makeViewList(view: styleBody, inputs: newInputs)
        
        if let buffer = styleBuffer {
            buffer.traceMountedProperties(to: view, fields: styleFields)
        }
        
        return outputs
    }
    
    fileprivate static func makeStyleBody<View: StyleableView>(view: _GraphValue<View>, style: AnyStyle, inputs: inout _GraphInputs, fields: DynamicPropertyCache.Fields) -> (_GraphValue<Modifier.SubjectBody>, _DynamicPropertyBuffer?) {
        
        let kind = DGTypeID(Modifier.Style.self).kind
        
        guard kind.isOfValueTypes else {
            _danceuiFatalError("\(_typeName(Modifier.Style.self)) is a class.")
        }
        
        _ = GraphHost.currentHost
        
        let attribute = Attribute<Modifier.Style>(identifier: style.value)
        
        let graphValue = _GraphValue(attribute)
        
        let styleBodyAccessor = StyleBodyAccessor<Modifier, View>(view: view.value)
        
        return styleBodyAccessor.makeBody(container: graphValue, inputs: &inputs, fields: fields)
        
        
    }

}

@available(iOS 13.0, *)
internal protocol StyleModifier: MultiViewModifier, PrimitiveViewModifier {
    
    associatedtype Style
    
    associatedtype Subject: StyleableView
    
    associatedtype SubjectBody: View
    
    var style: Style { get set }
    
    @ViewBuilder
    static func body(view: Subject, style: Style) -> SubjectBody
}

@available(iOS 13.0, *)
extension StyleModifier {
    
    internal static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        var newInputs = inputs
        
        let styleValue = modifier[{.of(&$0.style)}]
        
        let style = AnyStyle(value: styleValue.value, modifierType: self)
        
        newInputs.append(style, for: StyleInput<Subject>.self)
        
        return body(_Graph(), newInputs)
    }
    
    internal static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        
        var newInputs = inputs
        
        let styleValue = modifier[{.of(&$0.style)}]
        
        let style = AnyStyle(value: styleValue.value, modifierType: self)
        
        newInputs.append(style, for: StyleInput<Subject>.self)
        
        return body(_Graph(), newInputs)

    }

}

@available(iOS 13.0, *)
private struct AnyStyle {
    
    internal let value: DGAttribute
    
    internal let formula: AnyStyleFormula.Type
    
    internal init<A: StyleModifier>(value: Attribute<A.Style>, modifierType: A.Type) {
        self.value = value.identifier
        self.formula = StyleFormula<A>.self
    }
}
