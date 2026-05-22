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

/// The default style for group box views.
///
/// You can also use ``GroupBoxStyle/automatic`` to construct this style.
@available(iOS 13.0, *)
public struct DefaultGroupBoxStyle: GroupBoxStyle {

    public init() { }
    
    /*
    typealias Body =
    ModifiedContent<
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    VStack<
                        TupleView<(
                            ModifiedContent<
                                ModifiedContent<
                                    GroupBoxStyleConfiguration.Label,
                                    _AlignmentLayout
                                >,
                                _EnvironmentKeyWritingModifier<Optional<Font>>
                            >,
                            GroupBoxStyleConfiguration.Content
                        )>
                    >,
                    _PaddingLayout
                >,
                _BackgroundModifier<_ShapeView<RoundedRectangle, BackgroundStyle>>
            >,
            StyleContextWriter<ContainerStyleContext>
        >,
        SpacingLayout
    >
    */

    /// Creates a view representing the body of a group box.
    ///
    /// DanceUI calls this method for each instance of ``DanceUI/GroupBox``
    /// created within a view hierarchy where this style is the current
    /// group box style.
    ///
    /// - Parameter configuration: The properties of the group box instance being
    ///   created.
    @ViewBuilder
    public func makeBody(configuration: Self.Configuration) -> some View {
        // 0x52d1c0 iOS14.3
        PhoneIdiomGroupBoxStyle().makeBody(configuration: configuration)
    }

}
