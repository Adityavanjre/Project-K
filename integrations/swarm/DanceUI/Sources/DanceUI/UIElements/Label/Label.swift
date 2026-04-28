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

/// A standard label for user interface items, consisting of an icon with a
/// title.
///
/// One of the most common and recognizable user interface components is the
/// combination of an icon and a label. This idiom appears across many kinds of
/// apps and shows up in collections, lists, menus of action items, and
/// disclosable lists, just to name a few.
///
/// You create a label, in its simplest form, by providing a title and the name
/// of an image, such as an icon from the
/// [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/)
/// collection:
///
///     Label("Lightning", systemImage: "bolt.fill")
///
/// You can also apply styles to labels in several ways. In the case of dynamic
/// changes to the view after device rotation or change to a window size you
/// might want to show only the text portion of the label using the
/// ``LabelStyle/titleOnly`` label style:
///
///     Label("Lightning", systemImage: "bolt.fill")
///         .labelStyle(.titleOnly)
///
/// Conversely, there's also an icon-only label style:
///
///     Label("Lightning", systemImage: "bolt.fill")
///         .labelStyle(.iconOnly)
///
/// Some containers might apply a different default label style, such as only
/// showing icons within toolbars on macOS and iOS. To opt in to showing both
/// the title and the icon, you can apply the ``LabelStyle/titleAndIcon`` label
/// style:
///
///     Label("Lightning", systemImage: "bolt.fill")
///         .labelStyle(.titleAndIcon)
///
/// You can also create a customized label style by modifying an existing
/// style; this example adds a red border to the default label style:
///
///     struct RedBorderedLabelStyle: LabelStyle {
///         func makeBody(configuration: Configuration) -> some View {
///             Label(configuration)
///                 .border(Color.red)
///         }
///     }
///
/// For more extensive customization or to create a completely new label style,
/// you'll need to adopt the ``LabelStyle`` protocol and implement a
/// ``LabelStyleConfiguration`` for the new style.
///
/// To apply a common label style to a group of labels, apply the style
/// to the view hierarchy that contains the labels:
///
///     VStack {
///         Label("Rain", systemImage: "cloud.rain")
///         Label("Snow", systemImage: "snow")
///         Label("Sun", systemImage: "sun.max")
///     }
///     .labelStyle(.iconOnly)
///
/// It's also possible to make labels using views to compose the label's icon
/// programmatically, rather than using a pre-made image. In this example, the
/// icon portion of the label uses a filled ``Circle`` overlaid
/// with the user's initials:
///
///     Label {
///         Text(person.fullName)
///             .font(.body)
///             .foregroundColor(.primary)
///         Text(person.title)
///             .font(.subheadline)
///             .foregroundColor(.secondary)
///     } icon: {
///         Circle()
///             .fill(person.profileColor)
///             .frame(width: 44, height: 44, alignment: .center)
///             .overlay(Text(person.initials))
///     }
///
@available(iOS 13.0, *)
public struct Label<Title: View, Icon: View>: View {

    private var title: Title

    private var icon: Icon
    
    /// Creates a label with a custom title and icon.
    public init(@ViewBuilder title: () -> Title, @ViewBuilder icon: () -> Icon) {
        // 0xa2aeb0 iOS14.3
        self.title = title()
        self.icon = icon()
    }
    
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
        
        /* iOS14.3
        typealias Body =
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    ModifiedContent<
                        ModifiedContent<
                            ResolvedLabelStyle,
                            StaticSourceWriter<
                                LabelStyleConfiguration.Icon,
                                ModifiedContent<
                                    B,
                                    AccessibilityAttachmentModifier
                                >
                            >
                        >,
                        StaticSourceWriter<
                            LabelStyleConfiguration.Title,
                            ModifiedContent<
                                A,
                                AccessibilityAttachmentModifier
                            >
                        >
                    >,
                    AccessibilityLabelModifier
                >,
                AccessibilityAttachmentModifier
            >,
            MergePlatformItemsModifier
        >
        */
        
        /* iOS15.2, AccessibilityLabelViewModifier not available yet, still using iOS14.3 implementation
        typealias Body =
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    ModifiedContent<
                        ResolvedLabelStyle,
                        StaticSourceWriter<
                            LabelStyleConfiguration.Icon,
                            ModifiedContent<
                                B,
                                AccessibilityAttachmentModifier
                            >
                        >
                    >,
                    StaticSourceWriter<
                        LabelStyleConfiguration.Title,
                        ModifiedContent<
                            A,
                            AccessibilityAttachmentModifier
                        >
                    >
                >,
                AccessibilityLabelViewModifier
            >,
            MergePlatformItemsModifier
        >
        */
        
        ResolvedLabelStyle()
            .viewAlias(LabelStyleConfiguration.Icon.self) {
                self.icon
                    .accessibilityAddTraits(.labelIcon)
            }
            .viewAlias(LabelStyleConfiguration.Title.self) {
                self.title
                    .accessibilityAddTraits(.labelTitle)
            }
            .labelAccessibility()
            .mergePlatformItems()
    }
}

@available(iOS 13.0, *)
extension Label where Title == Text, Icon == Image {
    
    /// Creates a label with an icon image and a title generated from a
    /// localized string.
    ///
    /// - Parameters:
    ///    - titleKey: A title generated from a localized string.
    ///    - image: The name of the image resource to lookup.
    public init(_ titleKey: LocalizedStringKey, image name: String) {
        // 0xa2b7e0 iOS14.3
        self.title = Text(titleKey)
        self.icon = Image(name)
    }
    
    // TODO: _notImplemented Label.init(_:systemImage:) unused
//    /// Creates a label with a system icon image and a title generated from a
//    /// localized string.
//    ///
//    /// - Parameters:
//    ///    - titleKey: A title generated from a localized string.
//    ///    - systemImage: The name of the image resource to lookup.
//    internal init(_ titleKey: LocalizedStringKey, systemImage name: String) {
//        // 0xa2b9d0 iOS14.3
//        // SystemImage is current unavailable, this public method is currently hidden
//        _notImplemented()
//    }
    
    /// Creates a label with an icon image and a title generated from a string.
    ///
    /// - Parameters:
    ///    - title: A string used as the label's title.
    ///    - image: The name of the image resource to lookup.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, image name: String) {
        // 0xa2bab0 iOS14.3
        self.title = Text(title)
        self.icon = Image(name)
    }
    
    // TODO: _notImplemented Label.init(_:systemImage:) unused
//    /// Creates a label with a system icon image and a title generated from a
//    /// string.
//    ///
//    /// - Parameters:
//    ///    - title: A string used as the label's title.
//    ///    - systemImage: The name of the image resource to lookup.
//    @_disfavoredOverload
//    internal init<S: StringProtocol>(_ title: S, systemImage name: String) {
//        // 0xa2bc80 iOS14.3
//        // SystemImage is current unavailable, this public method is currently hidden
//        _notImplemented()
//    }
}

@available(iOS 13.0, *)
extension Label where Title == LabelStyleConfiguration.Title, Icon == LabelStyleConfiguration.Icon {

    /// Creates a label representing the configuration of a style.
    ///
    /// You can use this initializer within the ``LabelStyle/makeBody(configuration:)``
    /// method of a ``LabelStyle`` instance to create an instance of the label
    /// that's being styled. This is useful for custom label styles that only
    /// wish to modify the current style, as opposed to implementing a brand new
    /// style.
    ///
    /// For example, the following style adds a red border around the label,
    /// but otherwise preserves the current style:
    ///
    ///     struct RedBorderedLabelStyle: LabelStyle {
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             Label(configuration)
    ///                 .border(Color.red)
    ///         }
    ///     }
    ///
    /// - Parameter configuration: The label style to use.
    public init(_ configuration: LabelStyleConfiguration) {
        // 0xa2b020 iOS14.3
        self.title = LabelStyleConfiguration.Title()
        self.icon = LabelStyleConfiguration.Icon()
    }
}

@available(iOS 13.0, *)
extension View {

    /// Sets the style for labels within this view.
    ///
    /// Use this modifier to set a specific style for all labels within a view:
    ///
    ///     VStack {
    ///         Label("Fire", systemImage: "flame.fill")
    ///         Label("Lightning", systemImage: "bolt.fill")
    ///     }
    ///     .labelStyle(MyCustomLabelStyle())
    ///
    public func labelStyle<S: LabelStyle>(_ style: S) -> some View {
        return self.modifier(LabelStyleWritingModifier(style: style))
    }
}

@available(iOS 13.0, *)
extension View {

    internal func mergePlatformItems() -> ModifiedContent<Self, MergePlatformItemsModifier> {
        self.modifier(MergePlatformItemsModifier())
    }
}

@available(iOS 13.0, *)
private struct LabelStyleModifier<A: LabelStyle>: StyleModifier {
    
    fileprivate typealias Style = A
    
    fileprivate typealias Subject = ResolvedLabelStyle
    
    fileprivate typealias SubjectBody = A.Body
    
    fileprivate var style: A

    internal static func body(view: ResolvedLabelStyle, style: A) -> A.Body {
        return style.makeBody(configuration: LabelStyleConfiguration())
    }
}

@available(iOS 13.0, *)
private struct LabelStyleWritingModifier<A: LabelStyle>: ViewModifier {
    
    internal var style: A

    internal func body(content: Content) -> some View {
        // 0x639d1d iOS15.2
        content
            .modifier(LabelStyleModifier(style: style))
            .environment(\EnvironmentValues.effectiveLabelStyle, nil)
    }
}

@available(iOS 13.0, *)
internal struct ResolvedLabelStyle: StyleableView {
    
    typealias Subject = ResolvedLabelStyle
    
    internal func defaultBody() -> some View {
        // 0x5aec90 iOS14.3 empty
        
        /* original:
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    ModifiedContent<
                        ModifiedContent<
                            ModifiedContent<
                                ModifiedContent<
                                    ModifiedContent<
                                        ModifiedContent<
                                            Label<
                                                LabelStyleConfiguration.Title,
                                                LabelStyleConfiguration.Icon
                                            >,
                                            ViewInputDependency<
                                                StyleContextPredicate<ListStyleContext<PlainListStyle>>,
                                                LabelStyleModifier<ListLabelStyle>
                                            >
                                        >,
                                        ViewInputDependency<
                                            StyleContextPredicate<ListStyleContext<GroupedListStyle>>,
                                            LabelStyleModifier<ListLabelStyle>
                                        >
                                    >,
                                    ViewInputDependency<
                                        StyleContextPredicate<ListStyleContext<OuterFormListStyle>>,
                                        LabelStyleModifier<ListLabelStyle>
                                    >
                                >,
                                ViewInputDependency<
                                    StyleContextPredicate<ListStyleContext<InsetGroupedListStyle>>,
                                    LabelStyleModifier<ListLabelStyle>
                                >
                            >,
                            ViewInputDependency<
                                StyleContextPredicate<ListStyleContext<SidebarListStyle>>,
                                LabelStyleModifier<SidebarLabelStyle>
                            >
                        >,
                        ViewInputDependency<
                            StyleContextPredicate<ListStyleContext<InsetListStyle>>,
                            LabelStyleModifier<InsetListLabelStyle>
                        >
                    >,
                    ViewInputDependency<
                        StyleContextPredicate<FormStyleContext>,
                        LabelStyleModifier<ListLabelStyle>
                    >
                >,
                ViewInputDependency<
                    StyleContextPredicate<ToolbarStyleContext>,
                    LabelStyleModifier<IconOnlyLabelStyle>
                >
            >,
            LabelStyleModifier<StackLabelStyle>
        >
        */
        
        /* implementation
        typealias DefaultBody =
        ModifiedContent<
            Label<
                LabelStyleConfiguration.Title,
                LabelStyleConfiguration.Icon
            >,
            LabelStyleModifier<StackLabelStyle>
        >
        */
        Label() {
            LabelStyleConfiguration.Title()
        } icon: {
            LabelStyleConfiguration.Icon()
        }
        .labelStyle(StackLabelStyle())
    }
    

}
