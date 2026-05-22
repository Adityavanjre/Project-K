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
extension PickerStyle where Self == WheelPickerStyle {

    /// A picker style that presents the options in a scrollable wheel that
    /// shows the selected option and a few neighboring options.
    ///
    /// Because most options aren't visible, organize them in a predictable
    /// order, such as alphabetically.
    ///
    /// To apply this style to a picker, or to a view that contains pickers, use
    /// the ``View/pickerStyle(_:)`` modifier.
    @_alwaysEmitIntoClient
    public static var wheel: WheelPickerStyle {
        WheelPickerStyle()
    }
}

@available(iOS 13.0, *)
public struct WheelPickerStyle : PickerStyle {

    fileprivate struct Body<SelectionType : Hashable> : Rule {
        
        fileprivate typealias Value = _VariadicView.Tree<WheelPicker<SelectionType>, ModifiedContent<PickerStyleConfiguration<SelectionType>.Content, VerticalStackOrientationModifier>>
        
        @Attribute
        fileprivate var base: _PickerValue<WheelPickerStyle, SelectionType>
        
        fileprivate var value: Value {
            _VariadicView.Tree(WheelPicker(configuration: base.configuration)) {
                base.configuration.content.modifier(VerticalStackOrientationModifier())
            }
        }
    }
    
    public init() { }
    
    public static func _makeView<SelectionType>(value: _GraphValue<_PickerValue<Self, SelectionType>>, inputs: _ViewInputs) -> _ViewOutputs where SelectionType : Hashable {
        Body<SelectionType>.Value._makeView(view: _GraphValue(Body(base: value.value)), inputs: inputs)
    }
    
    public static func _makeViewList<SelectionType>(value: _GraphValue<_PickerValue<Self, SelectionType>>, inputs: _ViewListInputs) -> _ViewListOutputs where SelectionType : Hashable {
        Body<SelectionType>.Value._makeViewList(view: _GraphValue(Body(base: value.value)), inputs: inputs)
    }
}

@available(iOS 13.0, *)
internal struct VerticalStackOrientationModifier : PrimitiveViewModifier, MultiViewModifier {
    
    internal typealias Body = Never
    
    internal static func _makeView(modifier: _GraphValue<VerticalStackOrientationModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        body(_Graph(), inputs)
    }
}

@available(iOS 13.0, *)
internal struct HiddenLabeledViewStyle : LabeledViewStyle {
    
    
    internal static let combineAccessibility: Bool? = nil

    internal func body(configuration: LabeledView<LabeledViewLabel, LabeledViewContent>) -> some View {
        LabeledViewContent()
            .modifier(_BackgroundModifier(background: LabeledViewLabel().modifier(HiddenModifierAllowingAccessibility()),
                                          alignment: .center))
    }
}

@available(iOS 13.0, *)
fileprivate struct WheelPicker<SelectionType : Hashable> : _VariadicView_ViewRoot {

    fileprivate var configuration: PickerStyleConfiguration<SelectionType>
    
    fileprivate func body(children: _VariadicView.Children) -> some View {
        let index = children.tagIndex(tag: configuration.$selection)
        
        let selection = Binding.init {
            [index.wrappedValue ?? 0]
        } set: { idx in
            index.wrappedValue = idx.count == 0 ? nil : idx[0]
        }

        return LabeledView(label: configuration.label, content: WheelPicker_Phone<DataSource>(dataSource: DataSource(children: children), selection: selection)).modifier(WheelPickerLabelsHiddenModifier(), require: ShouldHideLabels.self)
    }
}

@available(iOS 13.0, *)
fileprivate struct DataSource : CustomWheelPickerDataSource {

    fileprivate typealias Rows = [Element]
    
    fileprivate typealias Element = WheelPickerRow<AnyHashable, _VariadicView_Children.Element>
    
    fileprivate var children: _VariadicView_Children
    
    fileprivate var columnCount : Int { 1 }
    
    fileprivate func rows(in index: Int) -> [Element] {
        var elements: [Element] = []
        for i in 0 ..< children.list.count {
            let element = children[i]
            elements.append(Element.init(identifier: element.id, cell: element))
        }
        return elements
    }

}

@available(iOS 13.0, *)
fileprivate struct WheelPickerLabelsHiddenModifier : ViewModifier {
    
    fileprivate typealias Body =
        ModifiedContent<
            _ViewModifier_Content<WheelPickerLabelsHiddenModifier>,
            _LabeledViewStyleModifier<HiddenLabeledViewStyle>>

    fileprivate func body(content: Content) -> Body {
        content.modifier(_LabeledViewStyleModifier(style: HiddenLabeledViewStyle()))
    }
}

@available(iOS 13.0, *)
fileprivate struct ShouldHideLabels : Feature {
    
    fileprivate static let isEnable: Bool = true
}

