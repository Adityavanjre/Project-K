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

/// A label style that shows both the title and icon of the label using a
/// system-standard layout.
///
/// You can also use ``LabelStyle/titleAndIcon`` to construct this style.
@available(iOS 13.0, *)
public struct TitleAndIconLabelStyle: LabelStyle {

    /// Creates a label style that shows both the title and icon of the label
    /// using a system-standard layout.
    public init() {
        // 0x5758c5 iOS15.2 empty
        _intentionallyLeftBlank()
    }

    /// Creates a view that represents the body of a label.
    ///
    /// The system calls this method for each ``Label`` instance in a view
    /// hierarchy where this style is the current label style.
    ///
    /// - Parameter configuration: The properties of the label.
    public func makeBody(configuration: TitleAndIconLabelStyle.Configuration) -> some View {
        // 0x575920 iOS15.2
        /*
        typealias Body =
        HStack<
            TupleView<
                (LabelStyleConfiguration.Icon,
                 ModifiedContent<
                    LabelStyleConfiguration.Title,
                    _EnvironmentKeyWritingModifier<TextAlignment>
                 >
                )
            >
        >
        */
        HStack {
            LabelStyleConfiguration.Icon()
            LabelStyleConfiguration.Title()
                .environment(\.multilineTextAlignment, .leading)
        }
    }
}
