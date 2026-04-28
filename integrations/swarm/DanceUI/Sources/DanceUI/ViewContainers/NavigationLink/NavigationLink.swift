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
import UIKit

@propertyWrapper
@available(iOS 13.0, *)
internal enum StateOrBinding<A>: DynamicProperty {
    
    case state(State<A>)
    
    case binding(Binding<A>)
    
    internal var wrappedValue: A {
        get {
            switch self {
            case let .state(s):
                return s.wrappedValue
            case let .binding(b):
                return b.wrappedValue
            }
        }
        nonmutating set {
            switch self {
            case let .state(s):
                s.wrappedValue = newValue
            case let .binding(b):
                b.wrappedValue = newValue
            }
        }
    }
    
    internal init(wrappedValue: A) {
        let state = State(wrappedValue: wrappedValue)
        self = .state(state)
    }
    
    internal var projectedValue: Binding<A> {
        switch self {
        case let .state(s):
            return s.projectedValue
        case let .binding(b):
            return b.projectedValue
        }
    }
}

@available(iOS 13.0, *)
internal enum NavigationEnabled {
    
    case unknown
    
    case enabled
    
    case disabled
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var navigationEnabled: NavigationEnabled {
        get {
            self[NavigationEnabledKey.self]
        }
        set {
            self[NavigationEnabledKey.self] = newValue
        }
    }
    
    fileprivate struct NavigationEnabledKey: EnvironmentKey {
        
        internal typealias Value = NavigationEnabled
        
        static var defaultValue: NavigationEnabled {
            .unknown
        }
    }
    
}

/// A view that controls a navigation presentation.
///
/// People click or tap a navigation link to present a view inside a
/// ``NavigationStack`` or ``NavigationSplitView``. You control the visual
/// appearance of the link by providing view content in the link's `label`
/// closure. For example, you can use a ``Label`` to display a link:
///
///     NavigationLink {
///         FolderDetail(id: workFolder.id)
///     } label: {
///         Label("Work Folder", systemImage: "folder")
///     }
///
/// For a link composed only of text, you can use one of the convenience
/// initializers that takes a string and creates a ``Text`` view for you:
///
///     NavigationLink("Work Folder") {
///         FolderDetail(id: workFolder.id)
///     }
///
/// ### Link to a destination view
///
/// You can perform navigation by initializing a link with a destination view
/// that you provide in the `destination` closure. For example, consider a
/// `ColorDetail` view that fills itself with a color:
///
///     struct ColorDetail: View {
///         var color: Color
///
///         var body: some View {
///             color.navigationTitle(color.description)
///         }
///     }
///
/// The following ``NavigationStack`` presents three links to color detail
/// views:
///
///     NavigationStack {
///         List {
///             NavigationLink("Mint") { ColorDetail(color: .mint) }
///             NavigationLink("Pink") { ColorDetail(color: .pink) }
///             NavigationLink("Teal") { ColorDetail(color: .teal) }
///         }
///         .navigationTitle("Colors")
///     }
///
/// ### Create a presentation link
///
/// Alternatively, you can use a navigation link to perform navigation based
/// on a presented data value. To support this, use the
/// ``View/navigationDestination(for:destination:)`` view modifier
/// inside a navigation stack to associate a view with a kind of data, and
/// then present a value of that data type from a navigation link. The
/// following example reimplements the previous example as a series of
/// presentation links:
///
///     NavigationStack {
///         List {
///             NavigationLink("Mint", value: Color.mint)
///             NavigationLink("Pink", value: Color.pink)
///             NavigationLink("Teal", value: Color.teal)
///         }
///         .navigationDestination(for: Color.self) { color in
///             ColorDetail(color: color)
///         }
///         .navigationTitle("Colors")
///     }
///
/// Separating the view from the data facilitates programmatic navigation
/// because you can manage navigation state by recording the presented data.
///
/// ### Control a presentation link programmatically
///
/// To navigate programmatically, introduce a state variable that tracks the
/// items on a stack. For example, you can create an array of colors to
/// store the stack state from the previous example, and initialize it as
/// an empty array to start with an empty stack:
///
///     @State private var colors: [Color] = []
///
/// Then pass a ``Binding`` to the state to the navigation stack:
///
///     NavigationStack(path: $colors) {
///         // ...
///     }
///
/// You can use the array to observe the current state of the stack. You can
/// also modify the array to change the contents of the stack. For example,
/// you can programmatically add ``ShapeStyle/blue`` to the array, and
/// navigation to a new color detail view using the following method:
///
///     func showBlue() {
///         colors.append(.blue)
///     }
///
/// ### Coordinate with a list
///
/// You can also use a navigation link to control ``List`` selection in a
/// ``NavigationSplitView``:
///
///     let colors: [Color] = [.mint, .pink, .teal]
///     @State private var selection: Color? // Nothing selected by default.
///
///     var body: some View {
///         NavigationSplitView {
///             List(colors, id: \.self, selection: $selection) { color in
///                 NavigationLink(color.description, value: color)
///             }
///         } detail: {
///             if let color = selection {
///                 ColorDetail(color: color)
///             } else {
///                 Text("Pick a color")
///             }
///         }
///     }
///
/// The list coordinates with the navigation logic so that changing the
/// selection state variable in another part of your code activates the
/// navigation link with the corresponding color. Similarly, if someone
/// chooses the navigation link associated with a particular color, the
/// list updates the selection value that other parts of your code can read.
@available(iOS 13.0, *)
public struct NavigationLink<Label, Destination>: View where Label: View, Destination: View {
    
    //    public typealias Body = ModifiedContent<ModifiedContent<ModifiedContent<ModifiedContent<ModifiedContent<ModifiedContent<Button<Label>, ButtonStyleModifier<NavigationLinkStyle>>, _EnvironmentKeyTransformModifier<Bool>>, NavigationDestination<Destination>>, EmptyModifier>, SelectionBehaviorVisualStyleModifier>, _PreferenceTransformModifier<PlatformItemList.Key>>
    

    @StateOrBinding
    internal var isActive: Bool
    

    internal var label: Label
    

    internal var destination: Destination
    

    @Environment(\.navigationEnabled)
    fileprivate var isNavigationEnabled: NavigationEnabled
    

    internal var isDetailLink: Bool
    
    /// Creates a navigation link that presents the destination view.
    /// - Parameters:
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the `destination`
    ///    to present.
    @available(*, message: "Pass a closure as the destination")
    public init(destination: Destination, @ViewBuilder label: () -> Label) {
        _isActive = StateOrBinding(wrappedValue: false)
        self.label = label()
        self.destination = destination
        self.isDetailLink = true
    }
    
    /// Creates a navigation link that presents the destination view when active.
    /// - Parameters:
    ///   - destination: A view for the navigation link to present.
    ///   - isActive: A binding to a Boolean value that indicates whether
    ///   `destination` is currently presented.
    ///   - label: A view builder to produce a label describing the `destination`
    ///    to present.
    @available(*, renamed: "NavigationLink(isActive:destination:label:)")
    public init(destination: Destination, isActive: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.isDetailLink = true
        _isActive = .binding(isActive)
        self.label = label()
        self.destination = destination
    }
    
    /// Creates a navigation link that presents the destination view when
    /// a bound selection variable equals a given tag value.
    /// - Parameters:
    ///   - destination: A view for the navigation link to present.
    ///   - tag: The value of `selection` that causes the link to present
    ///   `destination`.
    ///   - selection: A bound variable that causes the link to present
    ///   `destination` when `selection` becomes equal to `tag`.
    ///   - label: A view builder to produce a label describing the
    ///   `destination` to present.
    @available(*, renamed: "NavigationLink(tag:selection:destination:label:)")
    public init<V: Hashable>(destination: Destination,
                             tag: V,
                             selection: Binding<V?>,
                             @ViewBuilder label: () -> Label) {
        self.isDetailLink = true
        
        let getValueBlock = { () -> Bool in
            let wrappedValue = selection.wrappedValue
            return wrappedValue == tag
        }
        let locationBox = LocationBox(FunctionalLocation(getValue: getValueBlock, setValue: { newValue, transaction in
            if newValue {
                selection.wrappedValue = tag
                return
            }
            
            if selection.wrappedValue == tag {
                selection.wrappedValue = nil
            }
        }))
        
        _isActive = .binding(Binding(value: getValueBlock(), location: locationBox))
        self.label = label()
        self.destination = destination
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
        let navigationEnabled = self.isNavigationEnabled == .enabled
        let destinationContent = NavigationDestination(isPresented: self.$isActive,
                                                       updateSeed: nil,
                                                       isDetail: self.isDetailLink,
                                                       navigationContent: self.destination)
        let style: PlatformItemList.Item.SelectionBehavior.VisualStyle = self.isActive ? .selected : .plain
        let button = Button {
            show()
        } label: {
            self.label
        }
            .buttonStyle(NavigationLinkStyle())
            .disabled(!navigationEnabled)
            .modifier(destinationContent)
            .modifier(EmptyModifier())
            .platformItemSelectionVisualStyle(style: style)
        #warning("_PreferenceTransformModifier")
        return button
    }
    
    /// Creates a navigation link that presents the destination view.
    /// - Parameters:
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the `destination`
    ///    to present.
    public init(@ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.init(destination: destination(), label: label)
    }
    
    /// Creates a navigation link that presents the destination view when active.
    /// - Parameters:
    ///   - isActive: A binding to a Boolean value that indicates whether
    ///   `destination` is currently presented.
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the `destination`
    ///    to present.
    public init(isActive: Binding<Swift.Bool>, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.init(destination: destination(), isActive: isActive, label: label)
    }
    
    /// Creates a navigation link that presents the destination view when
    /// a bound selection variable equals a given tag value.
    /// - Parameters:
    ///   - tag: The value of `selection` that causes the link to present
    ///   `destination`.
    ///   - selection: A bound variable that causes the link to present
    ///   `destination` when `selection` becomes equal to `tag`.
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the
    ///   `destination` to present.
    public init<V: Hashable>(tag: V, selection: Binding<V?>, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.init(
            destination: destination(),
            tag: tag,
            selection: selection,
            label: label)
    }
    
    fileprivate func show() {
        self.isActive = true
    }
    
}

@available(iOS 13.0, *)
extension NavigationLink where Label == Text {
    
    /// Creates a navigation link that presents a destination view, with a text label
    /// that the link generates from a localized string key.
    /// - Parameters:
    ///   - titleKey: A localized string key for creating a text label.
    ///   - destination: A view for the navigation link to present.
    public init(_ titleKey: LocalizedStringKey, @ViewBuilder destination: () -> Destination) {
        self.init(titleKey, destination: destination())
    }
    
    /// Creates a navigation link that presents a destination view, with a text
    /// label that the link generates from a localized string key.
    /// - Parameters:
    ///   - titleKey: A localized string key for creating a text label.
    ///   - destination: A view for the navigation link to present.
    @available(*, message: "Pass a closure as the destination")
    public init(_ titleKey: LocalizedStringKey, destination: Destination) {
        self.init(destination: destination) {
            Text(titleKey)
        }
    }
    
    /// Creates a navigation link that presents a destination view when active, with a
    /// text label that the link generates from a localized string key.
    /// - Parameters:
    ///   - titleKey: A localized string key for creating a text label.
    ///   - isActive: A binding to a Boolean value that indicates whether
    ///   `destination` is currently presented.
    ///   - destination: A view for the navigation link to present.
    public init(_ titleKey: LocalizedStringKey, isActive: Binding<Swift.Bool>, @ViewBuilder destination: () -> Destination) {
        self.init(titleKey, destination: destination(), isActive: isActive)
    }
    
    /// Creates a navigation link that presents a destination view when active, with a
    /// text label that the link generates from a localized string key.
    /// - Parameters:
    ///   - titleKey: A localized string key for creating a text label.
    ///   - destination: A view for the navigation link to present.
    ///   - isActive: A binding to a Boolean value that indicates whether
    ///   `destination` is currently presented.
    @available(*, renamed: "NavigationLink(_:isActive:destination:)")
    public init(_ titleKey: LocalizedStringKey, destination: Destination, isActive: Binding<Bool>) {
        self.init(destination: destination, isActive: isActive) {
            Text(titleKey)
        }
    }
    
    /// Creates a navigation link that presents a destination view when a bound
    /// selection variable matches a value you provide, using a text label
    /// that the link generates from a localized string key.
    /// - Parameters:
    ///   - titleKey: A localized string key for creating a text label.
    ///   - tag: The value of `selection` that causes the link to present
    ///   `destination`.
    ///   - selection: A bound variable that causes the link to present
    ///   `destination` when `selection` becomes equal to `tag`.
    ///   - destination: A view for the navigation link to present.
    public init<V: Hashable>(_ titleKey: LocalizedStringKey, tag: V, selection: Binding<V?>, @ViewBuilder destination: () -> Destination) {
        self.init(titleKey, destination: destination(), tag: tag, selection: selection)
    }
    
    /// Creates a navigation link that presents a destination view when a bound
    /// selection variable matches a value you provide, using a text label
    /// that the link generates from a localized string key.
    /// - Parameters:
    ///   - titleKey: A localized string key for creating a text label.
    ///   - destination: A view for the navigation link to present.
    ///   - tag: The value of `selection` that causes the link to present
    ///   `destination`.
    ///   - selection: A bound variable that causes the link to present
    ///   `destination` when `selection` becomes equal to `tag`.
    @available(*, renamed: "NavigationLink(_:tag:selection:destination:)")
    public init<V: Hashable>(_ titleKey: LocalizedStringKey, destination: Destination, tag: V, selection: Binding<V?>) {
        self.init(destination: destination, tag: tag, selection: selection) {
            Text(titleKey)
        }
    }
    
    /// Creates a navigation link that presents a destination view, with a text label
    /// that the link generates from a title string.
    /// - Parameters:
    ///   - title: A string for creating a text label.
    ///   - destination: A view for the navigation link to present.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, @ViewBuilder destination: () -> Destination) {
        self.init(title, destination: destination())
    }
    
    /// Creates a navigation link that presents a destination view, with a text
    /// label that the link generates from a title string.
    /// - Parameters:
    ///   - title: A string for creating a text label.
    ///   - destination: A view for the navigation link to present.
    @_disfavoredOverload
    @available(*, message: "Pass a closure as the destination")
    public init<S: StringProtocol>(_ title: S, destination: Destination) {
        self.init(destination: destination) {
            Text(title)
        }
    }
    
    /// Creates a navigation link that presents a destination view when active, with a
    /// text label that the link generates from a title string.
    /// - Parameters:
    ///   - title: A string for creating a text label.
    ///   - isActive: A binding to a Boolean value that indicates whether
    ///   `destination` is currently presented.
    ///   - destination: A view for the navigation link to present.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination) {
        self.init(title, destination: destination(), isActive: isActive)
    }
    
    /// Creates a navigation link that presents a destination view when active, with a
    /// text label that the link generates from a title string.
    /// - Parameters:
    ///   - title: A string for creating a text label.
    ///   - destination: A view for the navigation link to present.
    ///   - isActive: A binding to a Boolean value that indicates whether
    ///   `destination` is currently presented.
    @_disfavoredOverload
    @available(*, renamed: "NavigationLink(_:isActive:destination:)")
    public init<S: StringProtocol>(_ title: S, destination: Destination, isActive: Binding<Bool>) {
        self.init(destination: destination, isActive: isActive) {
            Text(title)
        }
    }
    
    /// Creates a navigation link that presents a destination view when a bound
    /// selection variable matches a value you provide, using a text label
    /// that the link generates from a title string.
    /// - Parameters:
    ///   - title: A string for creating a text label.
    ///   - tag: The value of `selection` that causes the link to present
    ///   `destination`.
    ///   - selection: A bound variable that causes the link to present
    ///   `destination` when `selection` becomes equal to `tag`.
    ///   - destination: A view for the navigation link to present.
    @_disfavoredOverload
    public init<S: StringProtocol, V: Hashable>(_ title: S, tag: V, selection: Binding<V?>, @ViewBuilder destination: () -> Destination) {
        self.init(title, destination: destination(), tag: tag, selection: selection)
    }
    
    /// Creates a navigation link that presents a destination view when a bound
    /// selection variable matches a value you provide, using a text label
    /// that the link generates from a title string.
    /// - Parameters:
    ///   - title: A string for creating a text label.
    ///   - destination: A view for the navigation link to present.
    ///   - tag: The value of `selection` that causes the link to present
    ///   `destination`.
    ///   - selection: A bound variable that causes the link to present
    ///   `destination` when `selection` becomes equal to `tag`.
    @_disfavoredOverload
    @available(*, renamed: "NavigationLink(_:tag:selection:destination:)")
    public init<S: StringProtocol, V: Hashable>(_ title: S, destination: Destination, tag: V, selection: Binding<V?>) {
        self.init(destination: destination, tag: tag, selection: selection) {
            Text(title)
        }
    }
    
}

@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension NavigationLink {
    
    /// Sets the navigation link to present its destination as the detail
    /// component of the containing navigation view.
    ///
    /// This method sets the behavior when the navigation link is used in a
    /// ``NavigationSplitView``, or a
    /// multi-column navigation view, such as one using
    /// ``ColumnNavigationViewStyle``.
    ///
    /// For example, in a two-column navigation split view, if `isDetailLink` is
    /// `true`, triggering the link in the sidebar column sets the contents of
    /// the detail column to be the link's destination view. If `isDetailLink`
    /// is `false`, the link navigates to the destination view within the
    /// primary column.
    ///
    /// If you do not set the detail link behavior with this method, the
    /// behavior defaults to `true`.
    ///
    /// The `isDetailLink` modifier only affects view-destination links. Links
    /// that present data values always search for a matching navigation
    /// destination beginning in the column that contains the link.
    ///
    /// - Parameter isDetailLink: A Boolean value that specifies whether this
    /// link presents its destination as the detail component when used in a
    /// multi-column navigation view.
    /// - Returns: A view that applies the specified detail link behavior.
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func isDetailLink(_ isDetailLink: Bool) -> some View {
        var newSelf = self
        newSelf.isDetailLink = isDetailLink
        return newSelf
    }
    
}
