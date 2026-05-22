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

/// The properties of a label.
@available(iOS 13.0, *)
public struct LabelStyleConfiguration {

    /// A type-erased title view of a label.
    public struct Title: ViewAlias {

        /// The type of view representing the body of this view.
        ///
        /// When you create a custom view, Swift infers this type from your
        /// implementation of the required ``View/body-swift.property`` property.
        public typealias Body = Never
    }

    /// A type-erased icon view of a label.
    public struct Icon: ViewAlias {

        /// The type of view representing the body of this view.
        ///
        /// When you create a custom view, Swift infers this type from your
        /// implementation of the required ``View/body-swift.property`` property.
        public typealias Body = Never
    }

    /// A description of the labeled item.
    public var title: LabelStyleConfiguration.Title {
        LabelStyleConfiguration.Title()
    }

    /// A symbolic representation of the labeled item.
    public var icon: LabelStyleConfiguration.Icon {
        LabelStyleConfiguration.Icon()
    }
}
