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

/// A control for navigating to a URL.
///
/// Create a link by providing a destination URL and a title. The title
/// tells the user the purpose of the link, and can be a string, a title
/// key that produces a localized string, or a view that acts as a label.
/// The example below creates a link to `example.com` and displays the
/// title string as a link-styled view:
///
///     Link("View Our Terms of Service",
///           destination: URL(string: "https://www.example.com/TOS.html")!)
///
/// When a user taps or clicks a `Link`, the default behavior depends on the
/// contents of the URL. For example, DanceUI opens a Universal Link in the
/// associated app if possible, or in the user's default web browser if not.
/// Alternatively, you can override the default behavior by setting the
/// ``EnvironmentValues/openURL`` environment value with a custom
/// ``OpenURLAction``:
///
///     Link("Visit Our Site", destination: URL(string: "https://www.example.com")!)
///         .environment(\.openURL, OpenURLAction { url in
///             print("Open \(url)")
///             return .handled
///         })
///
/// As with other views, you can style links using standard view modifiers
/// depending on the view type of the link's label. For example, a ``Text``
/// label could be modified with a custom ``View/font(_:)`` or
/// ``View/foregroundColor(_:)`` to customize the appearance of the link in
/// your app's UI.

@available(iOS 13.0, *)
public struct Link<Label: View> : View { // also need confirm to ConditionallyArchivableView
    
    internal var label: Label
    
    internal var destination: LinkDestination
    
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that DanceUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    public var body: some View {
        Button {
            destination.open()
        } label: {
            label
        }
    }
    
    /// Creates a control, consisting of a URL and a label, used to navigate
    /// to the given URL.
    ///
    /// - Parameters:
    ///     - destination: The URL for the link.
    ///     - label: A view that describes the destination of URL.
    public init(destination: URL, @ViewBuilder label: () -> Label) {
        self.init(configuration: LinkDestination.Configuration(url: destination, isSensitive: false), label: label())
    }
    
    internal init(configuration: LinkDestination.Configuration, label: Label) {
        self.label = label
        destination = LinkDestination(configuration: configuration)
    }
    
    internal init(sensitiveUrl: URL, @ViewBuilder label: () -> Label) {
        self.init(configuration: LinkDestination.Configuration(url: sensitiveUrl, isSensitive: true), label: label())
    }
    
}

@available(iOS 13.0, *)
extension Link where Label == Text {
    
    /// Creates a control, consisting of a URL and a title string, used to
    /// navigate to a URL.
    ///
    /// Use ``Link`` to create a control that your app uses to navigate to a
    /// URL that you provide. The example below creates a link to
    /// `example.com` and displays the title string you provide as a
    /// link-styled view in your app:
    ///
    ///     func marketingLink(_ callToAction: String) -> Link {
    ///         Link(callToAction,
    ///             destination: URL(string: "https://www.example.com/")!)
    ///     }
    ///
    /// - Parameters:
    ///     - title: A text string used as the title for describing the
    ///       underlying `destination` URL.
    ///     - destination: The URL for the link.
    @_disfavoredOverload
    public init<S>(_ title: S, destination: URL) where S: StringProtocol {
        self.init(destination: destination, label: {Text(title)})
    }
    
    /// Creates a control, consisting of a URL and a title key, used to
    /// navigate to a URL.
    ///
    /// Use ``Link`` to create a control that your app uses to navigate to a
    /// URL that you provide. The example below creates a link to
    /// `example.com` and uses `Visit Example Co` as the title key to
    /// generate a link-styled view in your app:
    ///
    ///     Link("Visit Example Co",
    ///           destination: URL(string: "https://www.example.com/")!)
    ///
    /// - Parameters:
    ///     - titleKey: The key for the localized title that describes the
    ///       purpose of this link.
    ///     - destination: The URL for the link.
    public init(_ titleKey: LocalizedStringKey, destination: URL) {
        self.init(destination: destination, label: {Text(titleKey)})
    }
}
