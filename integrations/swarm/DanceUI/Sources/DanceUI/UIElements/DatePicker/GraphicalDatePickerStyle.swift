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

import Foundation

/// A date picker style that displays an interactive calendar or clock.
///
/// You can also use ``DatePickerStyle/graphical`` to construct this style.
@available(iOS 14.0, macOS 10.15, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct GraphicalDatePickerStyle : DatePickerStyle {

//    typealias _Body = ModifiedContent<UIKitDatePicker, _LabeledViewStyleModifier<HiddenLabeledViewStyle>>

    /// Creates an instance of the graphical date picker style.
    public init() { }
    
    public func _body(configuration: DatePicker<_Label>) -> some View {
        UIKitDatePicker(configuration: configuration, style: .inline)
            .modifier(_LabeledViewStyleModifier(style: HiddenLabeledViewStyle()))
    }
}
