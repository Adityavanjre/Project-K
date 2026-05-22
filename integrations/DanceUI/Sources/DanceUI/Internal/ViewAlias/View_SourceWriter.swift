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
extension View {

    internal func viewAlias<Alias: ViewAlias, Source: View>(_ alias: Alias.Type, source: () -> Source) -> some View {
        modifier(StaticSourceWriter<Alias, Source>(source: source()))
    }

    internal func viewAlias<Alias: ViewAlias, Source: View>(_ alias: Alias.Type, source: () -> Source?) -> some View {
        modifier(OptionalSourceWriter<Alias, Source>(source: source()))
    }

}

@available(iOS 13.0, *)
internal protocol ViewAlias: PrimitiveView {

    init()

}

@available(iOS 13.0, *)
extension ViewAlias {

    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        var childInputs = inputs
        if let source = childInputs.popLast(for: SourceInput<Self>.self) {
            return source.formula.makeView(view: view, source: source, inputs: childInputs)
        } else {
            return EmptyView._makeView(view: view.unsafeBitCast(to: EmptyView.self), inputs: inputs)
        }
    }

    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        var childInputs = inputs
        if let source = childInputs.popLast(for: SourceInput<Self>.self) {
            return source.formula.makeViewList(view: view, source: source, inputs: childInputs)
        } else {
            return EmptyView._makeViewList(view: view.unsafeBitCast(to: EmptyView.self), inputs: inputs)
        }
    }

    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        var childInputs = inputs.base
        if let source = childInputs.popLast(for: SourceInput<Self>.self) {
            return source.formula.viewListCount(source: source, inputs: inputs)
        } else {
            return EmptyView._viewListCount(inputs: inputs)
        }
    }

}

@propertyWrapper
@available(iOS 13.0, *)
internal struct OptionalViewAlias<Alias: ViewAlias>: DynamicProperty {

    internal var wrappedValue: Alias? {
        if sourceExists {
            return Alias()
        } else {
            return nil
        }
    }

    internal var sourceExists: Bool

    internal static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        if let anySource = inputs[SourceInput<Alias>.self].last {
            if let valueIsNil = anySource.valueIsNil {
                let box = OptionalSourceBox(sourceIsNil: valueIsNil)
                buffer.append(box, fieldOffset: fieldOffset)
            } else {
                let box = StaticSourceBox(sourceExists: true)
                buffer.append(box, fieldOffset: fieldOffset)
            }
        } else {
            let box = StaticSourceBox(sourceExists: false)
            buffer.append(box, fieldOffset: fieldOffset)
        }
    }

    private struct StaticSourceBox: DynamicPropertyBox {

        internal typealias Property = OptionalViewAlias<Alias>

        internal var sourceExists: Bool

        internal mutating func update(property: inout OptionalViewAlias<Alias>, phase: _GraphInputs.Phase) -> Bool {
            property.sourceExists = sourceExists
            return false
        }

    }

    private struct OptionalSourceBox: DynamicPropertyBox {

        internal typealias Property = OptionalViewAlias<Alias>

        @Attribute
        internal var sourceIsNil: Bool

        internal mutating func update(property: inout OptionalViewAlias<Alias>, phase: _GraphInputs.Phase) -> Bool {
            let (sourceIsNil, isChanged) = $sourceIsNil.changedValue()
            property.sourceExists = !sourceIsNil
            return isChanged
        }

    }

}

@available(iOS 13.0, *)
fileprivate struct StaticSourceWriter<Alias: ViewAlias, Source: View>: PrimitiveViewModifier, _GraphInputsModifier {

    fileprivate typealias Body = Never

    fileprivate var source: Source

    fileprivate static func _makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs) {
        inputs.append(value: AnySource(modifier[{.of(&$0.source)}].value),
                      for: SourceInput<Alias>.self)
    }

}

@available(iOS 13.0, *)
fileprivate struct OptionalSourceWriter<Alias: ViewAlias, Source: View>: PrimitiveViewModifier, _GraphInputsModifier {

    fileprivate typealias Body = Never

    fileprivate var source: Source?

    fileprivate static func _makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs) {
        inputs.append(value: AnySource(modifier[{.of(&$0.source)}].value),
                      for: SourceInput<Alias>.self)
    }

}

@available(iOS 13.0, *)
fileprivate protocol AnySourceFormula {

    static func makeView<A: ViewAlias>(view: _GraphValue<A>, source: AnySource, inputs: _ViewInputs) -> _ViewOutputs

    static func makeViewList<A: ViewAlias>(view: _GraphValue<A>, source: AnySource, inputs: _ViewListInputs) -> _ViewListOutputs

    static func viewListCount(source: AnySource, inputs: _ViewListCountInputs) -> Int?

}

@available(iOS 13.0, *)
fileprivate struct SourceFormula<Source: View>: AnySourceFormula {

    fileprivate static func makeView<Alias: ViewAlias>(view: _GraphValue<Alias>, source: AnySource, inputs: _ViewInputs) -> _ViewOutputs {
        if source.valueIsNil != nil {
            let sourceValue = _GraphValue<Source?>(Attribute<Source?>(identifier: source.value))

            let outputs = Source?.makeDebuggableView(value: sourceValue, inputs: inputs)

            return outputs
        } else {
            let sourceValue = _GraphValue<Source>(Attribute<Source>(identifier: source.value))

            let outputs = Source.makeDebuggableView(value: sourceValue, inputs: inputs)

            return outputs
        }
    }

    fileprivate static func makeViewList<Alias: ViewAlias>(view: _GraphValue<Alias>, source: AnySource, inputs: _ViewListInputs) -> _ViewListOutputs {
        if source.valueIsNil != nil {
            let sourceValue = _GraphValue<Source?>(Attribute<Source?>(identifier: source.value))

            return Source?._makeViewList(view: sourceValue, inputs: inputs)
        } else {
            let sourceValue = _GraphValue<Source>(Attribute<Source>(identifier: source.value))

            return Source._makeViewList(view: sourceValue, inputs: inputs)
        }
    }

    fileprivate static func viewListCount(source: AnySource, inputs: _ViewListCountInputs) -> Int? {
        if source.valueIsNil != nil {
            return Source?._viewListCount(inputs: inputs)
        }
        return Source._viewListCount(inputs: inputs)
    }

}

@available(iOS 13.0, *)
fileprivate struct SourceInput<A: View>: ViewInput {

    fileprivate typealias Value = [AnySource]

    fileprivate static var defaultValue: [AnySource] {
        []
    }

}

@available(iOS 13.0, *)
fileprivate struct AnySource {

    fileprivate let formula: AnySourceFormula.Type

    fileprivate let value: DanceUIGraph.DGAttribute

    fileprivate let valueIsNil: Attribute<Bool>?

    fileprivate init<Source: View>(_ attribute: Attribute<Source>) {
        formula = SourceFormula<Source>.self
        value = attribute.identifier
        valueIsNil = nil
    }

    fileprivate init<Source: View>(_ attribute: Attribute<Source?>) {
        formula = SourceFormula<Source>.self
        value = attribute.identifier
        valueIsNil = Attribute(IsNil(input: attribute))
    }

    fileprivate struct IsNil<Input: View>: Rule {

        fileprivate typealias Value = Bool

        @Attribute
        fileprivate var input: Input?

        var value: Bool {
            input == nil
        }

    }

}
