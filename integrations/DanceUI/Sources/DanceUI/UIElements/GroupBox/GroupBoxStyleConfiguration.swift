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


/// The properties of a group box instance.
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public struct GroupBoxStyleConfiguration {

    /// A type-erased label of a group box.
    public struct Label: ViewAlias {

        /// The type of view representing the body of this view.
        ///
        /// When you create a custom view, Swift infers this type from your
        /// implementation of the required ``View/body-swift.property`` property.
        public typealias Body = Never
    }

    /// A type-erased content of a group box.
    public struct Content: ViewAlias {

        /// The type of view representing the body of this view.
        ///
        /// When you create a custom view, Swift infers this type from your
        /// implementation of the required ``View/body-swift.property`` property.
        public typealias Body = Never
    }

    /// A view that provides the title of the group box.
    public let label: GroupBoxStyleConfiguration.Label

    /// A view that represents the content of the group box.
    public let content: GroupBoxStyleConfiguration.Content
}
