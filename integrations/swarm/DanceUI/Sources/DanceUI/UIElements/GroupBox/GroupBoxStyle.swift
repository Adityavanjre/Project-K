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

/// A type that specifies the appearance and interaction of all group boxes
/// within a view hierarchy.
///
/// To configure the current `GroupBoxStyle` for a view hierarchy, use the
/// ``View/groupBoxStyle(_:)`` modifier.
/// Sets the style for group boxes within this view.
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public protocol GroupBoxStyle {

    /// A view that represents the body of a group box.
    associatedtype Body : View

    @ViewBuilder
    func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = GroupBoxStyleConfiguration

}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension GroupBoxStyle where Self == DefaultGroupBoxStyle {

    /// The default style for group box views.
    @_alwaysEmitIntoClient
    public static var automatic: DefaultGroupBoxStyle {
        DefaultGroupBoxStyle()
    }
}
