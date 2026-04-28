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
internal protocol ViewInputPredicate {
    
    static func evaluate(inputs: _GraphInputs) -> Bool
}


@available(iOS 13.0, *)
internal struct StaticIf<Predicate, Then, Else> where Predicate: ViewInputPredicate {
    
    fileprivate var trueBody: Then
    
    fileprivate var falseBody: Else
}

// MARK: ViewModifier

@available(iOS 13.0, *)
extension StaticIf: PrimitiveViewModifier, ViewModifier where Then: ViewModifier, Else: ViewModifier {

    internal init(_ type: Predicate.Type, then trueBody: Then, else falseBody: Else) {
        self.trueBody = trueBody
        self.falseBody = falseBody
    }
    
    internal init(_ type: Predicate.Type, then trueBody: Then) where Else == EmptyModifier {
        self.trueBody = trueBody
        self.falseBody = EmptyModifier()
    }
    
    internal static func _makeView(modifier: _GraphValue<StaticIf<Predicate, Then, Else>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        if Predicate.evaluate(inputs: inputs.base) {
            return Then.makeDebuggableViewModifier(value: modifier[{ .of(&$0.trueBody) }], inputs: inputs, body: body)
        } else {
            return Else.makeDebuggableViewModifier(value: modifier[{ .of(&$0.falseBody) }], inputs: inputs, body: body)
        }
    }
    
    internal static func _makeViewList(modifier: _GraphValue<StaticIf<Predicate, Then, Else>>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        if Predicate.evaluate(inputs: inputs.base) {
            return Then.makeDebuggableViewList(value: modifier[{ .of(&$0.trueBody) }], inputs: inputs, body: body)
        } else {
            return Else.makeDebuggableViewList(value: modifier[{ .of(&$0.falseBody) }], inputs: inputs, body: body)
        }
    }
    
    internal static func _viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
        if Predicate.evaluate(inputs: inputs.base) {
            return Then._viewListCount(inputs: inputs, body: body)
        } else {
            return Else._viewListCount(inputs: inputs, body: body)
        }
    }
}

// MARK: View

@available(iOS 13.0, *)
extension StaticIf: PrimitiveView, View where Then: View, Else: View {
    
    internal init(_ type: Predicate.Type, @ViewBuilder then trueBody: () -> Then, @ViewBuilder else falseBody : () -> Else) {
        self.trueBody = trueBody()
        self.falseBody = falseBody()
    }
    

    internal init<S: StyleContext>(in style: S, @ViewBuilder then trueBody: () -> Then, @ViewBuilder else falseBody : () -> Else) where Predicate == StyleContextPredicate<S> {
        self.trueBody = trueBody()
        self.falseBody = falseBody()
    }
    
    internal static func _makeView(view: _GraphValue<StaticIf<Predicate, Then, Else>>, inputs: _ViewInputs) -> _ViewOutputs {
        if Predicate.evaluate(inputs: inputs.base) {
            return Then.makeDebuggableView(value: view[{ .of(&$0.trueBody) }], inputs: inputs)
        } else {
            return Else.makeDebuggableView(value: view[{ .of(&$0.falseBody) }], inputs: inputs)
        }
    }
    
    internal static func _makeViewList(view: _GraphValue<StaticIf<Predicate, Then, Else>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        if Predicate.evaluate(inputs: inputs.base) {
            return Then.makeDebuggableViewList(value: view[{ .of(&$0.trueBody) }], inputs: inputs)
        } else {
            return Else.makeDebuggableViewList(value: view[{ .of(&$0.falseBody) }], inputs: inputs)
        }
    }
    
    internal static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        if Predicate.evaluate(inputs: inputs.base) {
            return Then._viewListCount(inputs: inputs)
        } else {
            return Else._viewListCount(inputs: inputs)
        }
    }
}

@available(iOS 13.0, *)
extension ViewModifier {
    
    internal func requiring<S: StyleContext>(_ styleContext: S) -> StaticIf<StyleContextPredicate<S>, Self, EmptyModifier> {
        StaticIf(StyleContextPredicate<S>.self, then: self)
    }
}

@available(iOS 13.0, *)
extension View {
    
    internal func requiring<S: StyleContext>(_ styleContext: S) -> StaticIf<StyleContextPredicate<S>, Self, EmptyView> {
        StaticIf(in: styleContext, then: { self }, else: { EmptyView() })
    }
}
