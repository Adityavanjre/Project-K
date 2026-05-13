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

/// The size classes, like regular or small, that you can apply to controls
/// within a view.
@available(iOS 13.0, *)
public enum ControlSize: Hashable, CaseIterable {

    /// A control version that is minimally sized.
    case mini

    /// A control version that is proportionally smaller size for space-constrained views.
    case small

    /// A control version that is the default size.
    case regular

    /// A control version that is prominently sized.
    case large
    
    case extraLarge

    /// A collection of all values of this type.
    public static var allCases: [ControlSize] {
        [
            .mini,
            .small,
            .regular,
            .large,
            .extraLarge,
        ]
    }
}
