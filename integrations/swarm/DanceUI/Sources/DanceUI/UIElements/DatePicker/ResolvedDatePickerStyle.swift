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

@available(iOS 13.0, *)
internal struct ResolvedDatePickerStyle : StyleableView {
    
    /*
    typealias DefaultBody =
    FeatureConditional<
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    ModifiedContent<
                        ModifiedContent<
                            DatePicker<_DatePickerStyleLabel>,
                            ViewInputDependency<
                                StyleContextPredicate<ListStyleContext<GroupedListStyle>>,
                                DatePickerStyleModifier<CollapsibleWheelDatePickerStyle>
                            >
                        >,
                        ViewInputDependency<
                            StyleContextPredicate<ListStyleContext<OuterFormListStyle>>,
                            DatePickerStyleModifier<CollapsibleWheelDatePickerStyle>
                        >
                    >,
                    ViewInputDependency<
                        StyleContextPredicate<ListStyleContext<InsetGroupedListStyle>>,
                        DatePickerStyleModifier<CollapsibleWheelDatePickerStyle>
                    >
                >,
                ViewInputDependency<
                    StyleContextPredicate<FormStyleContext>,
                    DatePickerStyleModifier<CollapsibleWheelDatePickerStyle>
                >
            >,
            DatePickerStyleModifier<WheelDatePickerStyle>
        >,
        ModifiedContent<
            DatePicker<_DatePickerStyleLabel>,
            DatePickerStyleModifier<CompactDatePickerStyle>
        >,
        Semantics.IOSCompactDatePickerFeature
    >
    */

    internal var configuration: DatePicker<_DatePickerStyleLabel>

    internal func defaultBody() -> some View {
        configuration
            .datePickerStyle(DefaultDatePickerStyle())
    }
    
}

@available(iOS 13.0, *)
internal struct DatePickerStyleModifier<Style : DatePickerStyle> : StyleModifier {
    
    internal typealias Style = Style

    internal typealias Subject = ResolvedDatePickerStyle

    internal typealias SubjectBody = Style._Body

    internal var style: Style

    internal static func body(view: ResolvedDatePickerStyle, style: Style) -> Style._Body {
        style._body(configuration: view.configuration)
    }
}
