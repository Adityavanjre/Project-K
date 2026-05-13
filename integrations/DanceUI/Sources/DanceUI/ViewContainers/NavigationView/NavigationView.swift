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

/// A view for presenting a stack of views that represents a visible path in a
/// navigation hierarchy.
///
/// Use a `NavigationView` to create a navigation-based app in which the user
/// can traverse a collection of views. Users navigate to a destination view
/// by selecting a ``NavigationLink`` that you provide. On iPadOS and macOS, the
/// destination content appears in the next column. Other platforms push a new
/// view onto the stack, and enable removing items from the stack with
/// platform-specific controls, like a Back button or a swipe gesture.
///
///
/// Use the ``init(content:)`` initializer to create a
/// navigation view that directly associates navigation links and their
/// destination views:
///
///     NavigationView {
///         List(model.notes) { note in
///             NavigationLink(note.title, destination: NoteEditor(id: note.id))
///         }
///         Text("Select a Note")
///     }
///
/// Style a navigation view by modifying it with the
/// ``View/navigationViewStyle(_:)`` view modifier. Use other modifiers, like
/// ``View/navigationTitle(_:)-avgj``, on views presented by the navigation
/// view to customize the navigation interface for the presented view.
@available(iOS 13.0, *)
public struct NavigationView<ContentView: View>: PubliclyPrimitiveView {
    
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never
    
    internal var content: ContentView
    
    internal var internalBody: some View {
        ResolvedNavigationViewStyle().viewAlias(_NavigationViewStyleConfiguration.Content.self) {
            content.environment(\.navigationEnabled, .enabled)
        }
    }
    
    /// Creates a destination-based navigation view.
    ///
    /// Perform navigation by initializing a link with a destination view.
    /// For example, consider a `ColorDetail` view that displays a color sample:
    ///
    ///     struct ColorDetail: View {
    ///         var color: Color
    ///
    ///         var body: some View {
    ///             color
    ///                 .frame(width: 200, height: 200)
    ///                 .navigationTitle(color.description.capitalized)
    ///         }
    ///     }
    ///
    /// The following ``NavigationView`` presents three links to color detail
    /// views:
    ///
    ///     NavigationView {
    ///         List {
    ///             NavigationLink("Purple", destination: ColorDetail(color: .purple))
    ///             NavigationLink("Pink", destination: ColorDetail(color: .pink))
    ///             NavigationLink("Orange", destination: ColorDetail(color: .orange))
    ///         }
    ///         .navigationTitle("Colors")
    ///
    ///         Text("Select a Color") // A placeholder to show before selection.
    ///     }
    ///
    /// When the horizontal size class is ``UserInterfaceSizeClass/regular``,
    /// like on an iPad in landscape mode, or on a Mac,
    /// the navigation view presents itself as a multicolumn view,
    /// using its second and later content views --- a single ``Text``
    /// view in the example above --- as a placeholder for the corresponding
    /// column:
    ///
    ///
    /// When the user selects one of the navigation links from the
    /// list, the linked destination view replaces the placeholder
    /// text in the detail column:
    ///
    ///
    /// When the size class is ``UserInterfaceSizeClass/compact``, like
    /// on an iPhone in portrait orientation, the navigation view presents
    /// itself as a single column that the user navigates as a stack. Tapping
    /// one of the links replaces the list with the detail view, which
    /// provides a back button to return to the list:
    ///
    ///
    /// - Parameter content: A ``ViewBuilder`` that produces the content that
    ///   the navigation view wraps. Any views after the first act as
    ///   placeholders for corresponding columns in a multicolumn display.
    public init(@ViewBuilder content: () -> ContentView) {
        self.content = content()
    }
    
}
