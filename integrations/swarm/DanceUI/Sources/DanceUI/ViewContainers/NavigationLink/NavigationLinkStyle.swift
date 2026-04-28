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
internal struct NavigationLinkStyle: PrimitiveButtonStyle {
    /*
    typealias Body =
    ModifiedContent<
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    ModifiedContent<
                        ModifiedContent<
                            ModifiedContent<
                                Button<PrimitiveButtonStyleConfiguration.Label>,
                                ViewInputDependency<
                                    StyleContextPredicate<ListStyleContext<PlainListStyle>>,
                                    ButtonStyleModifier<DefaultListNavigationLinkStyle>
                                >
                            >,
                            ViewInputDependency<
                                StyleContextPredicate<ListStyleContext<GroupedListStyle>>,
                                ButtonStyleModifier<DefaultListNavigationLinkStyle>>
                            >,
                        ViewInputDependency<
                            StyleContextPredicate<ListStyleContext<OuterFormListStyle>>,
                            ButtonStyleModifier<DefaultListNavigationLinkStyle>>
                        >,
                    ViewInputDependency<
                        StyleContextPredicate<ListStyleContext<.InsetGroupedListStyle>>,
                        ButtonStyleModifier<DefaultListNavigationLinkStyle>>
                    >,
                ViewInputDependency<
                    StyleContextPredicate<ListStyleContext<SidebarListStyle>>,
                    ButtonStyleModifier<SidebarListNavigationLinkStyle>>
                >,
            ViewInputDependency<
                StyleContextPredicate<ListStyleContext<InsetListStyle>>,
                ButtonStyleModifier<InsetListNavigationLinkStyle>>
            >,
        ViewInputDependency<
            StyleContextPredicate<FormStyleContext>,
            ButtonStyleModifier<DefaultListNavigationLinkStyle>
        >
    >
     */
    
    internal func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        Button(configuration)
    }
    
}

// InsetListNavigationLinkStyle not needed for now
/*
internal struct InsetListNavigationLinkStyle: PrimitiveButtonStyle {

    // typealias Body = VStack<InsetListNavigationLinkStyle.ListLink>
    internal struct ListLink: View {

        // typealias Body = ModifiedContent<HStack<TupleView<(ModifiedContent<PrimitiveButtonStyleConfiguration.Label, _PaddingLayout>, Swift.Optional<TupleView<(ModifiedContent<Spacer, _TraitWritingModifier<LayoutPriorityTraitKey>>, _DisclosureIndicator)>>)>>, NavigationLinkStyleCommonModifier>
        var configuration: PrimitiveButtonStyleConfiguration

        @Environment(\.listRowInsets)
        internal var listRowInsets: EdgeInsets

        @Environment(\.isSplitViewExpended)
        internal var isInExpandedSplitView: Bool
        
        internal var body: some View {
            _notImplemented()
        }

    }
    
    internal func makeBody(configuration: Configuration) -> some View {
        VStack {
            ListLink(configuration: configuration)
        }
    }
}
 */


