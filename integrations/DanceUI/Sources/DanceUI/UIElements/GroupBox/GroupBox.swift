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

/// A stylized view, with an optional label, that visually collects a logical
/// grouping of content.
///
/// Use a group box when you want to visually distinguish a portion of your
/// user interface with an optional title for the boxed content.
///
/// The following example sets up a `GroupBox` with the label "End-User
/// Agreement", and a long `agreementText` string in a ``DanceUI/Text`` view
/// wrapped by a ``DanceUI/ScrollView``. The box also contains a
/// ``DanceUI/Toggle`` for the user to interact with after reading the text.
///
///     var body: some View {
///         GroupBox(label:
///             Label("End-User Agreement", systemImage: "building.columns")
///         ) {
///             ScrollView(.vertical, showsIndicators: true) {
///                 Text(agreementText)
///                     .font(.footnote)
///             }
///             .frame(height: 100)
///             Toggle(isOn: $userAgreed) {
///                 Text("I agree to the above terms")
///             }
///         }
///     }
///
///
/// A stylized view, with an optional label, that visually collects a logical grouping of content.
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public struct GroupBox<Label: View, Content: View>: View {
    
    internal let label: Label?

    internal let content: Content

    @Namespace
    internal var namespace

    /// Creates a group box with the provided label and view content.
    /// - Parameters:
    ///   - content: A ``DanceUI/ViewBuilder`` that produces the content for the
    ///     group box.
    ///   - label: A ``DanceUI/ViewBuilder`` that produces a label for the group
    ///     box.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.init(label: label(), content: content)
    }

    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that DanceUIDanceUI provides, plus other
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
        // 0x56edc0 iOS14.3
        /*
        typealias Body =
        ModifiedContent<
            ModifiedContent<
                ModifiedContent<
                    ModifiedContent<
                        ModifiedContent<
                            ModifiedContent<
                                ResolvedGroupBoxStyle,
                                StaticSourceWriter<
                                    GroupBoxStyleConfiguration.Label,
                                    Optional<
                                        ModifiedContent<
                                            ModifiedContent<
                                                ModifiedContent<A, AccessibilityContainerModifier>,
                                                AccessibilityAttachmentModifier
                                            >,
                                            RelationshipModifier<String>
                                        >
                                    >
                                >
                            >,
                            StaticSourceWriter<GroupBoxStyleConfiguration.Content, B>
                        >,
                        _EnvironmentKeyTransformModifier<Int>
                    >,
                    AccessibilityContainerModifier
                >,
                AccessibilityAttachmentModifier
            >,
            RelationshipModifier<String>
        >
         */
        ResolvedGroupBoxStyle(configuration: GroupBoxStyleConfiguration(label: GroupBoxStyleConfiguration.Label(), content: GroupBoxStyleConfiguration.Content()))
            .viewAlias(GroupBoxStyleConfiguration.Label.self) {
                self.label
                    .modifier(AccessibilityContainerModifier(behavior: AccessibilityChildBehavior.contain))
                    .accessibilityCaptureTypeInfo()
                    .accessibilityRelationShip(.linkedGroup, id: "Identifier1", in: self.namespace)
            }
            .viewAlias(GroupBoxStyleConfiguration.Content.self) {
                self.content
            }
            ._addingBackgroundGroup()
            .accessibilityElement(children: AccessibilityChildBehavior.contain)
            .accessibilityLabeledPair(role: AccessibilityLabeledPairRole.content, id: "Identifier2", in: self.namespace)
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension GroupBox where Label == GroupBoxStyleConfiguration.Label, Content == GroupBoxStyleConfiguration.Content {

    /// Creates a group box based on a style configuration.
    ///
    /// Use this initializer within the ``GroupBoxStyle/makeBody(configuration:)``
    /// method of a ``GroupBoxStyle`` instance to create a styled group box,
    /// with customizations, while preserving its existing style.
    ///
    /// The following example adds a pink border around the group box,
    /// without overriding its current style:
    ///
    ///     struct PinkBorderGroupBoxStyle: GroupBoxStyle {
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             GroupBox(configuration)
    ///                 .border(Color.pink)
    ///         }
    ///     }
    /// - Parameter configuration: The properties of the group box instance being created.
    public init(_ configuration: GroupBoxStyleConfiguration) {
        // 0x56f610 iOS14.3
        self.label = GroupBoxStyleConfiguration.Label()
        self.content = GroupBoxStyleConfiguration.Content()
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension GroupBox where Label == EmptyView {

    /// Creates an unlabeled group box with the provided view content.
    /// - Parameters:
    ///   - content: A ``DanceUI/ViewBuilder`` that produces the content for
    ///    the group box.
    public init(@ViewBuilder content: () -> Content) {
        // 0x56f620 iOS14.3
        self.content = content()
        self.label = nil
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension GroupBox where Label == Text {

    /// Creates a group box with the provided view content and title.
    /// - Parameters:
    ///   - titleKey: The key for the group box's title, which describes the
    ///     content of the group box.
    ///   - content: A ``DanceUI/ViewBuilder`` that produces the content for the
    ///     group box.
    public init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        // 0x5d483e iOS15.2
        self.label = Text(titleKey)
        self.content = content()
    }

    /// Creates a group box with the provided view content.
    /// - Parameters:
    ///   - title: A string that describes the content of the group box.
    ///   - content: A ``DanceUI/ViewBuilder`` that produces the content for the
    ///     group box.
    public init<S>(_ title: S, @ViewBuilder content: () -> Content) where S : StringProtocol {
        // 0x5d4936 iOS15.2
        self.label = Text(title)
        self.content = content()
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension GroupBox {

    @available(iOS, deprecated: 100000.0, renamed: "GroupBox(content:label:)")
    @available(macOS, deprecated: 100000.0, renamed: "GroupBox(content:label:)")
    public init(label: Label, @ViewBuilder content: () -> Content) {
        // 0x56e9f0 iOS14.3
        self.label = label
        self.content = content()
    }
}
