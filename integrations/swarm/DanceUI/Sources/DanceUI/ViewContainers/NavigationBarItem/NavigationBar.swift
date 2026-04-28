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
internal typealias NavigationBarButtonView = ModifiedContent<ModifiedContent<AnyView, _EnvironmentKeyWritingModifier<Binding<EditMode>?>>, _FixedSizeLayout>

@available(macOS, unavailable)
@available(iOS 13.0, *)
extension View {
    
    /// Hides the navigation bar for this view.
    ///
    /// Use `navigationBarHidden(_:)` to hide the navigation bar. This modifier
    /// only takes effect when this view is inside of and visible within a
    /// ``NavigationView``.
    ///
    /// - Parameter hidden: A Boolean value that indicates whether to hide the
    ///   navigation bar.
    /// > Tip:
    /// > NavigationBar hidden effect rules:
    /// > 1. The `hidden` state of [UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar) is managed per ``UIHostingController``. Any ``UIHostingController`` can affect the visibility of [UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar) (typically there is only one global UINavigationBar).
    /// > 2. Within the same ``UIHostingController``, all `hidden` values are combined using OR logic. If `view.navigationBarHidden(true)` is called on any ``View``, that ``UIHostingController`` will set `UINavigationBar`'s `hidden = true`.
    /// > 3. Even if `navigationBarHidden` is not explicitly called within a `UIHostingController`'s DSL, it will implicitly set [UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar)'s `hidden = false`. This ensures that when popping back from a page that explicitly called `navigationBarHidden(true)`, the current page can correctly restore the [UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar) visibility without explicitly calling `navigationBarHidden(false)`.
    /// > 4. In some scenarios, a ``UIHostingController``'s `children` may contain other ``UIHostingController`` instances, such as when using `CollectionView` from ``DanceUIExtension``, integrating libraries like `DanceUIParchment`, or providing other ``UIHostingController`` instances within ``UIViewControllerRepresentable``. These child ``UIHostingController`` instances will also implicitly set `hidden = false`. The rule is: explicit `hidden` settings take priority over implicit settings. As long as any [UIViewController](https://developer.apple.com/documentation/uikit/uiviewcontroller) in the chain from `parentViewController` to [UINavigationController](https://developer.apple.com/documentation/uikit/uinavigationcontroller) has explicitly set `hidden`, implicit settings will not take effect.
    @available(macOS, unavailable)
    public func navigationBarHidden(_ hidden: Bool) -> some View {
        preference(key: NavigationBarHiddenKey.self, value: hidden)
    }
    
    /// Hides the navigation bar back button for the view.
    ///
    /// Use `navigationBarBackButtonHidden(_:)` to hide the back button for this
    /// view.
    ///
    /// This modifier only takes effect when this view is inside of and visible
    /// within a ``NavigationView``.
    ///
    /// - Parameter hidesBackButton: A Boolean value that indicates whether to
    ///   hide the back button. The default value is `true`.
    @available(macOS, unavailable)
    public func navigationBarBackButtonHidden(_ hidesBackButton: Bool = true) -> some View {
        preference(key: NavigationBarBackButtonHiddenKey.self, value: hidesBackButton)
    }
    
    public func navigationBarItems<L: View>(leading: L) -> some View {
        
        @_transparent
        func contentView(environment: EnvironmentValues) -> some View {
            let leadingView: AnyView = self.navigationItemStyled(styleView: leading)
            let barItemsStorage: NavigationBarItem.BarItemStorage = .init(leadingView: leadingView,
                                                                          trailingView: nil,
                                                                          environment: environment)
            return self.preference(key: NavigationBarItemsKey.self, value: barItemsStorage)
        }
        
        return EnvironmentValues.reader { environment in
            contentView(environment: environment)
        }
    }
    
    public func navigationBarItems<T: View>(trailing: T) -> some View {
        
        @_transparent
        func contentView(environment: EnvironmentValues) -> some View {
            let trailingView: AnyView = self.navigationItemStyled(styleView: trailing)
            let barItemsStorage: NavigationBarItem.BarItemStorage = .init(leadingView: nil,
                                                                          trailingView: trailingView,
                                                                          environment: environment)
            return self.preference(key: NavigationBarItemsKey.self, value: barItemsStorage)
        }
        
        return EnvironmentValues.reader { environment in
            contentView(environment: environment)
        }
    }
    
    public func navigationBarItems<L: View, T: View>(leading: L, trailing: T) -> some View {
        
        @_transparent
        func contentView(environment: EnvironmentValues) -> some View {
            let leadingView: AnyView = self.navigationItemStyled(styleView: leading)
            let trailingView: AnyView = self.navigationItemStyled(styleView: trailing)
            let barItemsStorage: NavigationBarItem.BarItemStorage = .init(leadingView: leadingView,
                                                                          trailingView: trailingView,
                                                                          environment: environment)
            return self.preference(key: NavigationBarItemsKey.self, value: barItemsStorage)
        }
        
        return EnvironmentValues.reader { environment in
            contentView(environment: environment)
        }
    }
    
    internal func navigationItemStyled<A: View>(styleView: A) -> AnyView {
        let font: Font = .system(size: 17)
        return AnyView(styleView.font(font))
    }
}

@available(iOS 13.0, *)
extension UIViewController {
    
    @discardableResult
    internal func updateNavigationBar(_ coordinator: UIKitToolbarCoordinator,
                                      in environment: EnvironmentValues,
                                      avoiding: NavigationBarUpdateFlags,
                                      pushTarget: PushTarget?,
                                      overrideSplitController: UISplitViewController?,
                                      overrideNavController: UINavigationController?) -> NavigationBarUpdateFlags {
        
        var updatedFlags: NavigationBarUpdateFlags = []
        let hasBackItem = hasBackItem(in: environment,
                                      pushTarget: pushTarget,
                                      overrideSplitController: overrideSplitController)
        
        var hasSystemItem = false
        if hasBackItem && !self.navigationItem.hidesBackButton {
            hasSystemItem = true
        } else {
            hasSystemItem = self.navigationItem.leftBarButtonItems?.contains {
                $0.my_isSystemItem()
            } ?? false
        }
        
        let navigationController = overrideNavController ?? self.navigationController
        if !avoiding.contains(.title) {
            updateNavigationTitle(coordinator: coordinator, in: environment)
            updatedFlags.insert(.title)
        }
        
        if !avoiding.contains(.rightBarItems) {
            let updated = updateBarItems(coordinator,
                                         at: .right,
                                         in: environment,
                                         hasSystemItems: hasSystemItem,
                                         navController: navigationController)
            if updated {
                updatedFlags.insert(.rightBarItems)
            }
        }
        
        // This modifies updatedFlags
        func updateFlagIfNeeded(flag: NavigationBarUpdateFlags) {
            guard !avoiding.contains(flag) else {
                return
            }
            
            guard flag.rawValue > 0,
                  flag.rawValue <= NavigationBarUpdateFlags.bottomPalette.rawValue else {
                      return
                  }
            switch flag.rawValue {
            case NavigationBarUpdateFlags.title.rawValue:
                return
            case NavigationBarUpdateFlags.leftBarItems.rawValue:
                let updated = updateBarItems(coordinator,
                                             at: .left,
                                             in: environment,
                                             hasSystemItems: hasSystemItem,
                                             navController: navigationController)
                guard updated else {
                    return
                }
                
                let danceUIItems = self.navigationItem.leftBarButtonItems?.filter { $0.isFromDanceUI } ?? []
                self.navigationItem.leftItemsSupplementBackButton = danceUIItems.count > 0
                
                /// This logic may be common to all cases, to be verified later
                updatedFlags.insert(flag)
            case NavigationBarUpdateFlags.rightBarItems.rawValue:
                return
            case NavigationBarUpdateFlags.bottomPalette.rawValue:
                return
            default:
                return
            }
        }
        updateFlagIfNeeded(flag: .leftBarItems)
        
        if !avoiding.contains(.bottomPalette) {
            let updated = updateBottomPalette(coordinator,
                                              in: environment,
                                              navController: navigationController)
            if updated {
                updatedFlags.insert(.bottomPalette)
            }
        }
        
        return updatedFlags
    }
    
    /*
    // DanceUI Addition
    @inline(__always)
    private func removeSplitModeButtonForLowVersion(items: [UIBarButtonItem]) -> [UIBarButtonItem] {
        if #available(iOS 14.0, *) {
            return items
        }
        guard items.count == 1,
              String(describing: items[0]).contains("UISplitViewControllerDisplayModeBarButtonItem") else {
            return items
        }
        return []
    }
     */
    
    internal func updateNavigationBar(item: NavigationBarItem,
                                      title: NavigationTitleStorage,
                                      transaction: Transaction?,
                                      environment: EnvironmentValues,
                                      navController: UINavigationController?) -> NavigationBarUpdateFlags {
        var flags: NavigationBarUpdateFlags = .none
        self.navigationItem.hidesBackButton = item.hidesBackButton
        let barItemEnvironemnt = item.barItemStorage?.environment ?? environment
        var nativeButtonItems = self.navigationItem.leftBarButtonItems?.filter({ item in
            !(item.customView is _UIHostingView<NavigationBarButtonView>)
        }) ?? []
        
//        nativeButtonItems = removeSplitModeButtonForLowVersion(items: nativeButtonItems)
        
        if let leadingView = item.barItemStorage?.leadingView {
            let existingView = self.navigationItem.leftBarButtonItem?.customView as? _UIHostingView<NavigationBarButtonView>
            let barButtonItem = updateBarButtonItem(view: leadingView,
                                                    environment: barItemEnvironemnt,
                                                    navController: navController,
                                                    existingView: existingView)
            nativeButtonItems.append(barButtonItem)
            flags.insert(.leftBarItems)
        }
        self.navigationItem.leftBarButtonItems = nativeButtonItems
        
        if let trailingView = item.barItemStorage?.trailingView {
            let existingView = self.navigationItem.rightBarButtonItem?.customView as? _UIHostingView<NavigationBarButtonView>
            let barButtonItem = updateBarButtonItem(view: trailingView,
                                                    environment: barItemEnvironemnt,
                                                    navController: navController,
                                                    existingView: existingView)
            self.navigationItem.rightBarButtonItem = barButtonItem
            flags.insert(.rightBarItems)
        }
        
        if let displayMode = title.displayMode, #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = displayMode.toNavigationItemDisplayMode()
        }
        
        if let text = title.title {
            self.navigationItem.title = text.resolveText(in: environment)
            flags.insert(.title)
        }
        
        self.navigationItem.leftItemsSupplementBackButton = true
        return flags
    }
    
    fileprivate func hasBackItem(in environment: EnvironmentValues,
                                 pushTarget: PushTarget?,
                                 overrideSplitController: UISplitViewController?) -> Bool {
        let navigationController = self.navigationController ?? pushTarget?.navController
        let splitViewController = self.splitViewController ?? overrideSplitController
        
        guard navigationController?.traitCollection.horizontalSizeClass == .compact || splitViewController?.traitCollection.horizontalSizeClass == .compact else {
            return false
        }
        
        if let pushTarget = pushTarget {
            guard pushTarget.shouldReplaceRoot || pushTarget._column != nil else {
                return true
            }
        } else {
            guard self.navigationController?.navigationBar.backItem == nil else {
                return true
            }
        }
        
        guard let splitViewController = splitViewController else {
            return false
        }
        
        if let pushTarget = pushTarget,
           let column = pushTarget._column,
           let viewController = splitViewController[column],
           let navVC = viewController as? UINavigationController {
            return navVC.viewControllers.count > 0
        }
        
        if let primaryViewController = splitViewController.primaryViewController,
           let primaryNavigationController = primaryViewController as? UINavigationController {
            if primaryNavigationController.viewControllers.count == 0 {
                return primaryNavigationController.navigationBar.backItem != nil
            }
        }
        
        guard let secondaryViewController = splitViewController.secondaryViewController,
              let secondaryNavigationController = secondaryViewController as? UINavigationController,
              let lastViewController = secondaryNavigationController.viewControllers.last,
              lastViewController == self else {
                  return false
              }
        
        return secondaryNavigationController.navigationBar.backItem != nil
    }
    
    fileprivate func updateNavigationTitle(coordinator: UIKitToolbarCoordinator,
                                           in environment: EnvironmentValues) {
        let items = coordinator.placeItems { entry, value in
            value = false
            guard !entry.isPlaced else {
                return false
            }
            
            return entry.item.placement == .principal || entry.item.placement == .navigationBarTitle
        }
        
        guard let item = items.first else {
            return
        }
        
        self.navigationItem.titleView = _UIHostingView(rootView: item.view.fixedSize())
    }
    
    fileprivate func updateBarItems(_ coordinator: UIKitToolbarCoordinator,
                                    at position: BarPosition,
                                    in environment: EnvironmentValues,
                                    hasSystemItems: Bool,
                                    navController: UINavigationController?) -> Bool {
        let navigationItem = self.navigationItem
        let barButtonItems = position == .left ? navigationItem.leftBarButtonItems : navigationItem.rightBarButtonItems
        var nativeBarButtonItems = barButtonItems?.filter { !$0.isFromDanceUI } ?? []
        
        let newItems: [UIBarButtonItem] = []
        



        nativeBarButtonItems.append(contentsOf: newItems)
        if position == .left {
            self.navigationItem.leftBarButtonItems = nativeBarButtonItems
        } else {
            self.navigationItem.rightBarButtonItems = nativeBarButtonItems
        }
        return !nativeBarButtonItems.isEmpty
    }
    
    fileprivate func updateBottomPalette(_ coordinator: UIKitToolbarCoordinator,
                                         in environment: EnvironmentValues,
                                         navController: UINavigationController?) -> Bool {
        false
    }
    
    fileprivate enum BarPosition: Int {
        
        case left = 0
        
        case right = 1
        
    }
}

@available(iOS 13.0, *)
fileprivate func updateBarButtonItem(view: AnyView,
                                     environment: EnvironmentValues,
                                     navController: UINavigationController?,
                                     existingView: _UIHostingView<NavigationBarButtonView>?) -> UIBarButtonItem {
    let rootView = view.environment(\.editMode, environment.editMode).fixedSize() as! NavigationBarButtonView
    existingView?.rootView = rootView
    
    let existingHostingViewView = existingView ?? _UIHostingView(rootView: rootView)
    existingHostingViewView.environmentOverride = environment
    existingHostingViewView.sizeToFit()
    existingHostingViewView.navigationBridge.containingNavControllerOverride = navController
    
    return UIBarButtonItem(customView: existingHostingViewView)
}
