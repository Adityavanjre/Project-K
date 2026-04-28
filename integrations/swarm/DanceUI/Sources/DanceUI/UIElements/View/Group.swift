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
/// A type that collects multiple instances of a content type — like views, scenes, or commands — into a single unit.
@frozen
@available(iOS 13.0, *)
public struct Group<Content> {

    /// The type of content representing the body of this toolbar content.
    public typealias Body = Never
    
    @usableFromInline
    internal var content: Content
}

@available(iOS 13.0, *)
extension Group: View, PrimitiveView, MultiView where Content: View {
    
    @inline(__always)
    internal init(content: Content) {
        self.content = content
    }
    
    /// Creates a group of views.
    /// - Parameter content: A ``DanceUI/ViewBuilder`` that produces the views
    /// to group.
    @inlinable
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public static func _makeViewList(view: _GraphValue<Group<Content>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let treeType = _VariadicView.Tree<GroupContainer, Content>.self

        let variadicView = view.unsafeBitCast(to: treeType)
        return treeType._makeViewList(view: variadicView, inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        Content._viewListCount(inputs: inputs)
    }
}

@available(iOS 13.0, *)
extension Group {
    /// Constructs a group from the subviews of the given view.
    ///
    /// Use this initializer to create a group that gives you programmatic
    /// access to the group's subviews. The following `CardsView` defines the
    /// group's structure based on the set of views that you provide to it:
    ///
    ///     struct CardsView<Content: View>: View {
    ///         var content: Content
    ///
    ///         init(@ViewBuilder content: () -> Content) {
    ///             self.content = content()
    ///         }
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Group(subviews: content) { subviews in
    ///                     HStack {
    ///                         if subviews.count >= 2 {
    ///                             SecondaryCard { subview[1] }
    ///                         }
    ///                         if let first = subviews.first {
    ///                             FeatureCard { first }
    ///                         }
    ///                         if subviews.count >= 3 {
    ///                             SecondaryCard { subviews[2] }
    ///                         }
    ///                     }
    ///                     if subviews.count > 3 {
    ///                         subviews[3...]
    ///                     }
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// You can use `CardsView` with its view builder-based initializer to
    /// arrange a collection of subviews:
    ///
    ///     CardsView {
    ///         NavigationLink("What's New!") { WhatsNewView() }
    ///         NavigationLink("Latest Hits") { LatestHitsView() }
    ///         NavigationLink("Favorites") { FavoritesView() }
    ///         NavigationLink("Playlists") { MyPlaylists() }
    ///     }
    ///
    /// Subviews collection constructs subviews on demand, so only access the
    /// part of the collection you need to create the resulting content.
    ///
    /// Subviews are proxies to the view they represent, which means
    /// that modifiers that you apply to the original view take effect before
    /// modifiers that you apply to the subview. DanceUI resolves the view
    /// using the environment of its container rather than the environment of
    /// its subview proxy. Additionally, because subviews represent a
    /// single view or container, a subview might represent a view after the
    /// application of styles. As a result, applying a style to a subview might
    /// have no effect.
    ///
    /// - Parameters:
    ///   - view: The view to get the subviews of.
    ///   - transform: A closure that constructs a view from the collection of
    ///     subviews.
    public init<Base, Result>(subviews view: Base,
                              @ViewBuilder transform: @escaping (SubviewsCollection) -> Result) where Content == GroupElementsOfContent<Base, Result>, Base : View, Result : View {
        self.init {
            GroupElementsOfContent(subviews: view, content: transform)
        }
    }
}

@available(iOS 13.0, *)
extension Group {
    /// Constructs a group from the sections of the given view.
    ///
    /// Sections are constructed lazily, on demand, so access only as much
    /// of this collection as is necessary to create the resulting content.
    ///
    ///     struct SectionedStack<Content: View>: View {
    ///         var content: Content
    ///
    ///         init(@ViewBuilder content: () -> Content) {
    ///             self.content = content()
    ///         }
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Group(sections: content) { sections in
    ///                     ForEach(sections) { section in
    ///                         SectionChrome {
    ///                             section.content
    ///                         } header: {
    ///                             section.header
    ///                         } footer: {
    ///                             section.footer
    ///                         }
    ///                     }
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// This can then be used by creating a `SectionedStack` with it's
    /// view builder-based initializer.
    ///
    ///     SectionedStack {
    ///         Section("Header A") {
    ///             Text("Hello")
    ///             Text("World")
    ///         } footer: {
    ///             Text("Footer A")
    ///         }
    ///         Section("Header B") {
    ///             Text("Foo")
    ///             Text("Bar")
    ///         } footer: {
    ///             Text("Footer B")
    ///         }
    ///     }
    ///
    /// Any content of the given view which is not explicitly specified as a
    /// section is grouped with its sibling content to form implicit sections,
    /// meaning the minimum number of sections in a `SectionCollection` is one.
    /// For example in the following `SectionedStack`, there is one explicit
    /// section, and two implicit sections containing the content before,
    /// and after the explicit section:
    ///
    ///     SectionedStack {
    ///         Text("First implicit section")
    ///         Section("Explicit section") {
    ///             Text("Content")
    ///         }
    ///         Text("Second implicit section")
    ///     }
    ///
    /// - Parameters:
    ///   - view: The view to extract the sections of.
    ///   - content: A closure that constructs a view from the collection of
    ///     sections.
    public init<Base, Result>(sections view: Base,
                              @ViewBuilder transform: @escaping (SectionCollection) -> Result) where Content == GroupSectionsOfContent<Base, Result>, Base: View, Result: View {
        self.init {
            GroupSectionsOfContent(sections: view, content: transform)
        }
    }
}
