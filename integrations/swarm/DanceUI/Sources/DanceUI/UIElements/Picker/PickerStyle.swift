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
public protocol PickerStyle {
    
    static func _makeView<SelectionType>(value: _GraphValue<_PickerValue<Self, SelectionType>>, inputs: _ViewInputs) -> _ViewOutputs where SelectionType : Hashable
    
    static func _makeViewList<SelectionType>(value: _GraphValue<_PickerValue<Self, SelectionType>>, inputs: _ViewListInputs) -> _ViewListOutputs where SelectionType : Hashable
}

@available(iOS 13.0, *)
extension PickerStyle where Self == DefaultPickerStyle {

    /// The default picker style, based on the picker's context.
    ///
    /// How a picker using the default picker style appears largely depends on
    /// the platform and the view type in which it appears. For example, in a
    /// standard view, the default picker styles by platform are:
    ///
    /// * On iOS and watchOS the default is a wheel.
    /// * On macOS, the default is a pop-up button.
    /// * On tvOS, the default is a segmented control.
    ///
    /// The default picker style may also take into account other factors — like
    /// whether the picker appears in a container view — when setting the
    /// appearance of a picker.
    ///
    /// You can override a picker’s style. To apply the default style to a
    /// picker, or to a view that contains pickers, use the
    /// ``View/pickerStyle(_:)`` modifier.
    @_alwaysEmitIntoClient
    public static var automatic2: DefaultPickerStyle {
        DefaultPickerStyle()
    }
}

/// The default picker style, based on the picker's context.
///
/// You can also use ``PickerStyle/automatic`` to construct this style.
@available(iOS 13.0, *)
public struct DefaultPickerStyle : PickerStyle {
    
    internal struct Body<SelectionType : Hashable> : Rule {
        
        @Attribute
        internal var base: _PickerValue<DefaultPickerStyle, SelectionType>
        
        
        internal var value: some View {
            ResolvedPicker(configuration: base.configuration)
                .pickerStyle(.wheel)
        }
    }

    /// Creates a default picker style.
    public init() { }
    
    public static func _makeView<SelectionType>(value: _GraphValue<_PickerValue<Self, SelectionType>>, inputs: _ViewInputs) -> _ViewOutputs where SelectionType : Hashable {
        Body<SelectionType>.Value._makeView(view: _GraphValue(Body(base: value.value)), inputs: inputs)
    }
    
    public static func _makeViewList<SelectionType>(value: _GraphValue<_PickerValue<Self, SelectionType>>, inputs: _ViewListInputs) -> _ViewListOutputs where SelectionType : Hashable {
        Body<SelectionType>.Value._makeViewList(view: _GraphValue(Body(base: value.value)), inputs: inputs)
    }
}
