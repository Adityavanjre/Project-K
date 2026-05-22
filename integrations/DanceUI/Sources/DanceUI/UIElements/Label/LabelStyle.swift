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

/// A type that applies a custom appearance to all labels within a view.
///
/// To configure the current label style for a view hierarchy, use the
/// ``View/labelStyle(_:)`` modifier.
@available(iOS 13.0, *)
public protocol LabelStyle {

    /// A view that represents the body of a label.
    associatedtype Body: View

    @ViewBuilder
    func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = LabelStyleConfiguration
}

@available(iOS 13.0, *)
extension LabelStyle where Self == IconOnlyLabelStyle {

    /// A label style that only displays the icon of the label.
    ///
    /// The title of the label is still used for non-visual descriptions, such as
    /// VoiceOver.
    @_alwaysEmitIntoClient
    public static var iconOnly: IconOnlyLabelStyle {
        IconOnlyLabelStyle()
    }
}

@available(iOS 13.0, *)
extension LabelStyle where Self == TitleOnlyLabelStyle {

    /// A label style that only displays the title of the label.
    @_alwaysEmitIntoClient
    public static var titleOnly: TitleOnlyLabelStyle {
        TitleOnlyLabelStyle()
    }
}

@available(iOS 13.0, *)
extension LabelStyle where Self == TitleAndIconLabelStyle {

    /// A label style that shows both the title and icon of the label using a
    /// system-standard layout.
    ///
    /// In most cases, labels show both their title and icon by default. However,
    /// some containers might apply a different default label style to their
    /// content, such as only showing icons within toolbars on macOS and iOS. To
    /// opt in to showing both the title and the icon, you can apply the title
    /// and icon label style:
    ///
    ///     Label("Lightning", systemImage: "bolt.fill")
    ///         .labelStyle(.titleAndIcon)
    ///
    /// To apply the title and icon style to a group of labels, apply the style
    /// to the view hierarchy that contains the labels:
    ///
    ///     VStack {
    ///         Label("Rain", systemImage: "cloud.rain")
    ///         Label("Snow", systemImage: "snow")
    ///         Label("Sun", systemImage: "sun.max")
    ///     }
    ///     .labelStyle(.titleAndIcon)
    ///
    /// The relative layout of the title and icon is dependent on the context it
    /// is displayed in. In most cases, however, the label is arranged
    /// horizontally with the icon leading.
    @_alwaysEmitIntoClient
    public static var titleAndIcon: TitleAndIconLabelStyle {
        TitleAndIconLabelStyle()
    }
}

@available(iOS 13.0, *)
extension LabelStyle where Self == DefaultLabelStyle {

    /// A label style that resolves its appearance automatically based on the
    /// current context.
    @_alwaysEmitIntoClient
    public static var automatic: DefaultLabelStyle {
        DefaultLabelStyle()
    }
}
