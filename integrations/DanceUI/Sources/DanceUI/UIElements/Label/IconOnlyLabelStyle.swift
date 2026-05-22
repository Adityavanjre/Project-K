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

/// A label style that only displays the icon of the label.
///
/// You can also use ``LabelStyle/iconOnly`` to construct this style.
@available(iOS 13.0, *)
public struct IconOnlyLabelStyle: LabelStyle {
    
    /// Creates an icon-only label style.
    public init() {
        // 0x404000 iOS14.3 empty
        _intentionallyLeftBlank()
    }

    /// Creates a view that represents the body of a label.
    ///
    /// The system calls this method for each ``Label`` instance in a view
    /// hierarchy where this style is the current label style.
    ///
    /// - Parameter configuration: The properties of the label.
    public func makeBody(configuration: IconOnlyLabelStyle.Configuration) -> some View {
        // 0x404050 iOS14.3
        /*
        typealias Body =
        ModifiedContent<
            LabelStyleConfiguration.Icon,
            _BackgroundModifier<
                ModifiedContent<
                    LabelStyleConfiguration.Title,
                    HiddenModifierAllowingAccessibility
                >
            >
        >
        */
        IconOnlyLabelStyle.Configuration.Icon()
            .background(IconOnlyLabelStyle.Configuration.Title()
                            .hiddenAllowingAccessibility(),
                        alignment: .center)
    }
}
