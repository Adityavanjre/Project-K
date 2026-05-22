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

/// The default label style in the current context.
///
/// You can also use ``LabelStyle/automatic`` to construct this style.
@available(iOS 13.0, *)
public struct DefaultLabelStyle: LabelStyle {

    /// Creates an automatic label style.
    public init() {
        // 0x5af6c0 iOS14.3 empty
        _intentionallyLeftBlank()
    }

    /// Creates a view that represents the body of a label.
    ///
    /// The system calls this method for each ``Label`` instance in a view
    /// hierarchy where this style is the current label style.
    ///
    /// - Parameter configuration: The properties of the label.
    public func makeBody(configuration: DefaultLabelStyle.Configuration) -> some View {
        
        /* original 15.2
        typealias Body =
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    ModifiedContent<
                        ModifiedContent<
                            ModifiedContent<
                                ModifiedContent<
                                    ModifiedContent<
                                        ModifiedContent<
                                            ModifiedContent<
                                                ModifiedContent<
                                                    Label<
                                                        LabelStyleConfiguration.Title,
                                                        LabelStyleConfiguration.Icon
                                                    >,
                                                    StaticIf<
                                                        StyleContextPredicate<
                                                            ListStyleContext<PlainListStyle>
                                                        >,
                                                        LabelStyleWritingModifier<ListLabelStyle>,
                                                        EmptyModifier
                                                    >
                                                >,
                                                StaticIf<
                                                    StyleContextPredicate<
                                                        ListStyleContext<SidebarListStyle>
                                                    >,
                                                    LabelStyleWritingModifier<SidebarLabelStyle>,
                                                    EmptyModifier
                                                >
                                            >,
                                            StaticIf<
                                                StyleContextPredicate<
                                                    ListStyleContext<InsetListStyle>
                                                >,
                                                LabelStyleWritingModifier<InsetListLabelStyle>,
                                                EmptyModifier
                                            >
                                        >,
                                        StaticIf<
                                            StyleContextPredicate<FormStyleContext>,
                                            LabelStyleWritingModifier<ListLabelStyle>,
                                            EmptyModifier
                                        >
                                    >,
                                    StaticIf<
                                        StyleContextPredicate<
                                            ListStyleContext<GroupedListStyle>
                                        >,
                                        LabelStyleWritingModifier<ListLabelStyle>,
                                        EmptyModifier
                                    >
                                >,
                                StaticIf<
                                    StyleContextPredicate<
                                        ListStyleContext<OuterFormListStyle>
                                    >,
                                    LabelStyleWritingModifier<ListLabelStyle>,
                                    EmptyModifier
                                >
                            >,
                            StaticIf<
                                StyleContextPredicate<
                                    ListStyleContextInsetGroupedListStyle
                                >
                            >,
                            LabelStyleWritingModifier<ListLabelStyle>,
                            EmptyModifier>
                        >,
                        StaticIf<
                            StyleContextPredicate<ToolbarStyleContext>,
                            LabelStyleWritingModifier<IconOnlyLabelStyle>,
                            EmptyModifier
                        >
                    >,
                    StaticIf<
                        StyleContextPredicate<SwipeActionsContext>,
                        LabelStyleWritingModifier<TitleAndIconLabelStyle>,
                        EmptyModifier
                    >
                >,
                StaticIf<
                    StyleContextPredicate<AccessibilityRepresentableContext>,
                    LabelStyleWritingModifier<AccessibilityLabelStyle>,
                    EmptyModifier
                >
            >,
            LabelStyleWritingModifier<TitleAndIconLabelStyle>
        >
        */
        
        /* implementation iOS15.2
        typealias Body =
        ModifiedContent<
            Label<
                LabelStyleConfiguration.Title,
                LabelStyleConfiguration.Icon
            >,
            LabelStyleWritingModifier<TitleAndIconLabelStyle>
        >
        */
        Label() {
            DefaultLabelStyle.Configuration.Title()
        } icon: {
            DefaultLabelStyle.Configuration.Icon()
        }
        .labelStyle(TitleAndIconLabelStyle())
    }
}
