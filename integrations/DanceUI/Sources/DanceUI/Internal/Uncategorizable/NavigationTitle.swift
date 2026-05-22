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

@available(iOS 13.0, *)
internal struct NavigationTitleKey: HostPreferenceKey {
    
    internal typealias Value = NavigationTitleStorage?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
    
    internal static func reduce(value: inout NavigationTitleStorage?, nextValue: () -> NavigationTitleStorage?) {
        guard value != nil else {
            value = nextValue()
            return
        }

        guard value!.title == nil || value!.displayMode != nil else {
            return
        }
        
        guard let nextStorage = nextValue() else {
            return
        }
        
        if value!.title == nil {
            value!.title = nextStorage.title
        }
        
        if value?.displayMode == nil {
            value?.displayMode = nextStorage.displayMode
        }
    }
}

@available(iOS 13.0, *)
internal struct NavigationTitleStorage {

    internal var title: Text?

    internal var transaction: Transaction?

    internal var displayMode: NavigationBarItem.TitleDisplayMode?

}

@available(macOS, unavailable)
@available(iOS 13.0, *)
extension View {
    
    /// Configures the view's title for purposes of navigation.
    ///
    /// A view's navigation title is used to visually display
    /// the current navigation state of an interface.
    /// On iOS and watchOS, when a view is navigated to inside
    /// of a navigation view, that view's title is displayed
    /// in the navigation bar. On iPadOS, the primary destination's
    /// navigation title is reflected as the window's title in the
    /// App Switcher. Similarly on macOS, the primary destination's title
    /// is used as the window title in the titlebar, Windows menu
    /// and Mission Control.
    ///
    /// - Parameter title: The title to display.
    public func navigationTitle(_ title: Text) -> some View {
        _checkNavigationTitleStyled(title: title, functionName: #function)
        let navigationTitleStorage = NavigationTitleStorage(title: title, transaction: nil, displayMode: nil)
        return navigationTitlePreferenceTransform(adding: navigationTitleStorage)
    }
    
    /// Configures the view's title for purposes of navigation,
    /// using a localized string.
    ///
    /// A view's navigation title is used to visually display
    /// the current navigation state of an interface.
    /// On iOS and watchOS, when a view is navigated to inside
    /// of a navigation view, that view's title is displayed
    /// in the navigation bar. On iPadOS, the primary destination's
    /// navigation title is reflected as the window's title in the
    /// App Switcher. Similarly on macOS, the primary destination's title
    /// is used as the window title in the titlebar, Windows menu
    /// and Mission Control.
    ///
    /// - Parameter titleKey: The key to a localized string to display.
    public func navigationTitle(_ titleKey: LocalizedStringKey) -> some View{
        navigationTitle(Text(titleKey))
    }
    
    /// Configures the view's title for purposes of navigation, using a string.
    ///
    /// A view's navigation title is used to visually display
    /// the current navigation state of an interface.
    /// On iOS and watchOS, when a view is navigated to inside
    /// of a navigation view, that view's title is displayed
    /// in the navigation bar. On iPadOS, the primary destination's
    /// navigation title is reflected as the window's title in the
    /// App Switcher. Similarly on macOS, the primary destination's title
    /// is used as the window title in the titlebar, Windows menu
    /// and Mission Control.
    ///
    /// - Parameter title: The string to display.
    @_disfavoredOverload
    public func navigationTitle<S: StringProtocol>(_ title: S) -> some View {
        navigationTitle(Text(title))
    }
    
    /// Configures the title display mode for this view.
    ///
    /// - Parameter displayMode: The style to use for displaying the title.
    public func navigationBarTitleDisplayMode(_ displayMode: NavigationBarItem.TitleDisplayMode) -> some View {
        let navigationTitleStorage = NavigationTitleStorage(title: nil, transaction: nil, displayMode: displayMode)
        return navigationTitlePreferenceTransform(adding: navigationTitleStorage)
    }
    
    /// Sets the title in the navigation bar for this view.
    ///
    /// Use `navigationBarTitle(_:)` to set the title of the navigation bar.
    /// This modifier only takes effect when this view is inside of and visible
    /// within a ``NavigationView``.
    ///
    /// The example below shows setting the title of the navigation bar using a
    /// ``Text`` view:
    ///
    ///     struct FlavorView: View {
    ///         let items = ["Chocolate", "Vanilla", "Strawberry", "Mint Chip",
    ///                      "Pistachio"]
    ///         var body: some View {
    ///             NavigationView {
    ///                 List(items, id: \.self) {
    ///                     Text($0)
    ///                 }
    ///                 .navigationBarTitle(Text("Today's Flavors"))
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameter title: A description of this view to display in the
    ///   navigation bar.
    @available(iOS, renamed: "navigationTitle(_:)")
    public func navigationBarTitle(_ title: Text) -> some View {
        navigationTitle(title)
    }
    
    /// Sets the title of this view's navigation bar with a localized string.
    ///
    /// Use `navigationBarTitle(_:)` to set the title of the navigation bar
    /// using a ``LocalizedStringKey`` that will be used to search for a
    /// matching localized string in the application's localizable strings
    /// assets.
    ///
    /// This modifier only takes effect when this view is inside of and visible
    /// within a ``NavigationView``.
    ///
    /// In the example below, a string constant is used to access a
    /// ``LocalizedStringKey`` that will be resolved at run time to provide a
    /// title for the navigation bar. If the localization key cannot be
    /// resolved, the text of the key name will be used as the title text.
    ///
    ///     struct FlavorView: View {
    ///         let items = ["Chocolate", "Vanilla", "Strawberry", "Mint Chip",
    ///                      "Pistachio"]
    ///         var body: some View {
    ///             NavigationView {
    ///                 List(items, id: \.self) {
    ///                     Text($0)
    ///                 }
    ///                 .navigationBarTitle("Today's Flavors")
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameter titleKey: A key to a localized description of this view to
    ///   display in the navigation bar.
    @available(iOS, renamed: "navigationTitle(_:)")
    public func navigationBarTitle(_ titleKey: LocalizedStringKey) -> some View {
        navigationTitle(titleKey)
    }
    
    /// Sets the title of this view's navigation bar with a string.
    ///
    /// Use `navigationBarTitle(_:)` to set the title of the navigation bar
    /// using a `String`. This modifier only takes effect when this view is
    /// inside of and visible within a ``NavigationView``.
    ///
    /// In the example below, text for the navigation bar title is provided
    /// using a string:
    ///
    ///     struct FlavorView: View {
    ///         let items = ["Chocolate", "Vanilla", "Strawberry", "Mint Chip",
    ///                      "Pistachio"]
    ///         let text = "Today's Flavors"
    ///         var body: some View {
    ///             NavigationView {
    ///                 List(items, id: \.self) {
    ///                     Text($0)
    ///                 }
    ///                 .navigationBarTitle(text)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameter title: A title for this view to display in the navigation
    ///   bar.
    @available(iOS, renamed: "navigationTitle(_:)")
    public func navigationBarTitle<S: StringProtocol>(_ title: S) -> some View {
        navigationTitle(title)
    }
    
    /// Sets the title and display mode in the navigation bar for this view.
    ///
    /// Use `navigationBarTitle(_:displayMode:)` to set the title of the
    /// navigation bar for this view and specify a display mode for the title
    /// from one of the ``NavigationBarItem/TitleDisplayMode`` styles. This
    /// modifier only takes effect when this view is inside of and visible
    /// within a ``NavigationView``.
    ///
    /// In the example below, text for the navigation bar title is provided
    /// using a ``Text`` view. The navigation bar title's
    /// ``NavigationBarItem/TitleDisplayMode`` is set to `.inline` which places
    /// the navigation bar title in the bounds of the navigation bar.
    ///
    ///     struct FlavorView: View {
    ///        let items = ["Chocolate", "Vanilla", "Strawberry", "Mint Chip",
    ///                     "Pistachio"]
    ///        var body: some View {
    ///             NavigationView {
    ///                  List(items, id: \.self) {
    ///                      Text($0)
    ///                  }
    ///                 .navigationBarTitle(Text("Today's Flavors", displayMode: .inline)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - title: A title for this view to display in the navigation bar.
    ///   - displayMode: The style to use for displaying the navigation bar title.
    @available(iOS, message: "Use navigationTitle(_:) with navigationBarTitleDisplayMode(_:)")
    public func navigationBarTitle(_ title: Text, displayMode: NavigationBarItem.TitleDisplayMode) -> some View {
        navigationTitle(title).navigationBarTitleDisplayMode(displayMode)
    }
    
    /// Sets the title and display mode in the navigation bar for this view.
    ///
    /// Use `navigationBarTitle(_:displayMode:)` to set the title of the
    /// navigation bar for this view and specify a display mode for the title
    /// from one of the ``NavigationBarItem/TitleDisplayMode`` styles. This
    /// modifier only takes effect when this view is inside of and visible
    /// within a ``NavigationView``.
    ///
    /// In the example below, text for the navigation bar title is provided
    /// using a string. The navigation bar title's
    /// ``NavigationBarItem/TitleDisplayMode`` is set to `.inline` which places
    /// the navigation bar title in the bounds of the navigation bar.
    ///
    ///     struct FlavorView: View {
    ///         let items = ["Chocolate", "Vanilla", "Strawberry", "Mint Chip",
    ///                      "Pistachio"]
    ///         var body: some View {
    ///             NavigationView {
    ///                  List(items, id: \.self) {
    ///                      Text($0)
    ///                  }
    ///                 .navigationBarTitle("Today's Flavors", displayMode: .inline)
    ///             }
    ///         }
    ///     }
    ///
    /// If the `titleKey` can't be found, the title uses the text of the key
    /// name instead.
    ///
    /// - Parameters:
    ///   - titleKey: A key to a localized description of this view to display
    ///     in the navigation bar.
    ///   - displayMode: The style to use for displaying the navigation bar
    ///     title.
    @available(iOS, message: "Use navigationTitle(_:) with navigationBarTitleDisplayMode(_:)")
    public func navigationBarTitle(_ titleKey: LocalizedStringKey, displayMode: NavigationBarItem.TitleDisplayMode) -> some View {
        navigationTitle(titleKey).navigationBarTitleDisplayMode(displayMode)
    }
    
    /// Sets the title and display mode in the navigation bar for this view.
    ///
    /// Use `navigationBarTitle(_:displayMode:)` to set the title of the
    /// navigation bar for this view and specify a display mode for the
    /// title from one of the `NavigationBarItem.Title.DisplayMode`
    /// styles. This modifier only takes effect when this view is inside of and
    /// visible within a `NavigationView`.
    ///
    /// In the example below, `navigationBarTitle(_:displayMode:)` uses a
    /// string to provide a title for the navigation bar. Setting the title's
    /// `displayMode` to `.inline` places the navigation bar title within the
    /// bounds of the navigation bar.
    ///
    /// In the example below, text for the navigation bar title is provided using
    /// a string. The navigation bar title's `displayMode` is set to
    /// `.inline` which places the navigation bar title in the bounds of the
    /// navigation bar.
    ///
    ///     struct FlavorView: View {
    ///         let items = ["Chocolate", "Vanilla", "Strawberry", "Mint Chip",
    ///                      "Pistachio"]
    ///         let title = "Today's Flavors"
    ///         var body: some View {
    ///             NavigationView {
    ///                  List(items, id: \.self) {
    ///                      Text($0)
    ///                  }
    ///                 .navigationBarTitle(title, displayMode: .inline)
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// - Parameters:
    ///   - title: A title for this view to display in the navigation bar.
    ///   - displayMode: The way to display the title.
    @available(iOS, message: "Use navigationTitle(_:) with navigationBarTitleDisplayMode(_:)")
    public func navigationBarTitle<S: StringProtocol>(_ title: S, displayMode: NavigationBarItem.TitleDisplayMode) -> some View {
        navigationTitle(title).navigationBarTitleDisplayMode(displayMode)
    }
    
    fileprivate func navigationTitlePreferenceTransform(adding titleStorage: NavigationTitleStorage) -> some View {
        transactionalPreferenceTransform(key: NavigationTitleKey.self) { value, transaction in
            guard value != nil else {
                value = titleStorage
                value?.transaction = transaction
                return
            }
            
            if value?.title == nil {
                value?.title = titleStorage.title
            }
            
            if value?.displayMode == nil {
                value?.displayMode = titleStorage.displayMode
            }
            
            value?.transaction = transaction
        }
    }
    
}

@inline(__always)
@available(iOS 13.0, *)
// 如果是 anyTextStorage 且 isStyled 为 true，或者 modifiers 不为空，就打印警告信息
private func _checkNavigationTitleStyled(title: Text, functionName: String) {
    if case .anyTextStorage(let storage) = title.storage, storage.isStyled() {
        logger.fault("Only unstyled text can be used with \(functionName)")
        return
    }
    
    if !title.modifiers.isEmpty {
        logger.fault("Only unstyled text can be used with \(functionName)")
    }
}
