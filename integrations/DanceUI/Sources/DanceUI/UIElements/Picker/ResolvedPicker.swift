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
public struct PickerStyleConfiguration<SelectionType : Hashable> {

    @Binding
    public var selection: SelectionType

    public var label: Label

    public var content: Content
    
    public init(selection: Binding<SelectionType>) {
        self._selection = selection
        self.label = Label()
        self.content = Content()
    }
    
    public struct Content : ViewAlias { }

    public struct Label : ViewAlias { }
}

@available(iOS 13.0, *)
public struct _PickerValue<Style, SelectionType> where Style : PickerStyle, SelectionType : Hashable {

    public var style: Style

    public var configuration: PickerStyleConfiguration<SelectionType>
    
    public init(style: Style, configuration: PickerStyleConfiguration<SelectionType>) {
        self.style = style
        self.configuration = configuration
    }
    
    internal struct Init1: Rule {
        
        internal typealias Value = _PickerValue<Style, SelectionType>

        @Attribute
        internal var base: ResolvedPicker<SelectionType>

        internal var style: Style

        internal var value: Value {
            _PickerValue<Style, SelectionType>(style: style, configuration: base.configuration)
        }
        
        internal init(base: Attribute<ResolvedPicker<SelectionType>>, style: Style) {
            self._base = base
            self.style = style
        }
    }
    
    internal struct Init2: Rule {
        
        internal typealias Value = _PickerValue<Style, SelectionType>

        @Attribute
        internal var base: ResolvedPicker<SelectionType>

        @Attribute
        internal var style: Style
        
        internal var value: Value {
            _PickerValue<Style, SelectionType>(style: style, configuration: base.configuration)
        }
    }

}

@available(iOS 13.0, *)
internal struct ResolvedPicker<SelectionType : Hashable> : PrimitiveView {
        
    internal var configuration: PickerStyleConfiguration<SelectionType>
        
    internal init(configuration: PickerStyleConfiguration<SelectionType>) {
        self.configuration = configuration
    }
    
    internal static func _makeView(view: _GraphValue<ResolvedPicker<SelectionType>>, inputs: _ViewInputs) -> _ViewOutputs {
        if let pickerStyle = inputs[PickerStyleInput.self] {
            return pickerStyle.type.makeView(view: view, style: pickerStyle, inputs: inputs)
        } else {
            return makeView(view: view, style: DefaultPickerStyle(), inputs: inputs)
        }
    }
    
    internal static func _makeViewList(view: _GraphValue<ResolvedPicker<SelectionType>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        if let pickerStyle = inputs[PickerStyleInput.self] {
            return pickerStyle.type.makeViewList(view: view, style: pickerStyle, inputs: inputs)
        } else {
            return makeViewList(view: view, style: DefaultPickerStyle(), inputs: inputs)
        }
    }
    
}

@available(iOS 13.0, *)
extension ResolvedPicker {
    
    fileprivate static func makeView<Style : PickerStyle>(view: _GraphValue<ResolvedPicker<SelectionType>>, style: Style, inputs: _ViewInputs) -> _ViewOutputs {
        let pickValue = _GraphValue(_PickerValue<Style, SelectionType>.Init1(base: view.value, style: style))
        return Style._makeView(value: pickValue, inputs: inputs)
    }
    
    fileprivate static func makeViewList<Style : PickerStyle>(view: _GraphValue<ResolvedPicker<SelectionType>>, style: Style, inputs: _ViewListInputs) -> _ViewListOutputs {
        let pickValue = _GraphValue(_PickerValue<Style, SelectionType>.Init1(base: view.value, style: style))
        return Style._makeViewList(value: pickValue, inputs: inputs)
    }
}

@available(iOS 13.0, *)
internal struct PickerStyleWriter<Style : PickerStyle> : _GraphInputsModifier, PrimitiveViewModifier {
    
    internal typealias Body = Never

    internal var style: Style

    internal static func _makeInputs(modifier: _GraphValue<PickerStyleWriter<Style>>, inputs: inout _GraphInputs) {
        let indirectAttribute = DanceUIGraph.IndirectAttribute(source: modifier.value)
        let attribute = indirectAttribute[keyPath: \.style]
        inputs[PickerStyleInput.self] = AnyStyle_Picker(type: StyleType<Style>.self, value: attribute.identifier)
    }

}

@available(iOS 13.0, *)
fileprivate struct PickerStyleInput : ViewInput {
    
    fileprivate typealias Value = AnyStyle_Picker?
    
    @inline(__always)
    fileprivate static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
fileprivate protocol AnyStyleType {
    
    static func makeView<SelectionType : Hashable>(view: _GraphValue<ResolvedPicker<SelectionType>>, style: AnyStyle_Picker, inputs: _ViewInputs) -> _ViewOutputs
    
    static func makeViewList<SelectionType : Hashable>(view: _GraphValue<ResolvedPicker<SelectionType>>, style: AnyStyle_Picker, inputs: _ViewListInputs) -> _ViewListOutputs
}

@available(iOS 13.0, *)
fileprivate struct StyleType<Style : PickerStyle> : AnyStyleType {
    
    fileprivate static func makeView<SelectionType : Hashable>(view: _GraphValue<ResolvedPicker<SelectionType>>, style: AnyStyle_Picker, inputs: _ViewInputs) -> _ViewOutputs {
        let pickValue = _GraphValue(_PickerValue<Style, SelectionType>.Init2(base: view.value, style: Attribute(identifier: style.value)))
        return Style._makeView(value: pickValue, inputs: inputs)
    }
    
    
    fileprivate static func makeViewList<SelectionType : Hashable>(view: _GraphValue<ResolvedPicker<SelectionType>>, style: AnyStyle_Picker, inputs: _ViewListInputs) -> _ViewListOutputs {
        let pickValue = _GraphValue(_PickerValue<Style, SelectionType>.Init2(base: view.value, style: Attribute(identifier: style.value)))
        return Style._makeViewList(value: pickValue, inputs: inputs)
    }
}

@available(iOS 13.0, *)
fileprivate struct AnyStyle_Picker {

    fileprivate let type: AnyStyleType.Type

    fileprivate let value: DGAttribute
}

