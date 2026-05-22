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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal class UIKitNavigationBridge<ContentView: View>: NSObject {

    internal weak var host: _UIHostingView<ContentView>?

    internal var hasNavigationTitle: Bool

    internal var hidingBackButton: Bool

    internal var statusBarHidden: Bool

    internal var activePresentation: BridgedPresentation? {
        didSet {
            guard let activePresentation = oldValue else {
                return
            }
            activePresentation.content.onDismiss()
        }
    }

    fileprivate var destinations: PreferenceList.Value<[Namespace.ID: NavigationDestinationContent]>

    fileprivate var lastToolbarSeed: VersionSeed

    fileprivate var navigationBarSeedTracker: VersionSeedTracker

    fileprivate var focusedValuesSeed: VersionSeed

    internal var lastEnvironment: EnvironmentValues

    internal var environmentOverride: EnvironmentValues?

    internal var shouldHideNavigationBar: Bool?

    internal weak var containingNavControllerOverride: UINavigationController?

    internal weak var containingNavControllerFromLastAttemptedPop: UINavigationController?

    internal var incomingPushTarget: PushTarget?

    internal weak var containingSplitControllerOverride: UISplitViewController?
    
    internal var containingVC: UIViewController? {
        host!.my__viewControllerForAncestor()
    }
    
    internal var containingSplitViewController: UISplitViewController? {
        guard let splitViewController = containingVC?.splitViewController else {
            return nil
        }
        
        if let _ = splitViewController as? NotificationSendingSplitViewController {
            return splitViewController
        }
        
        if let _ = splitViewController as? NotifyingMulticolumnSplitViewController {
            return splitViewController
        }
        
        return nil
    }
    
    
    internal var containingNavController: UINavigationController? {
        if let override = containingNavControllerOverride {
            return override
        }
        
        if let lastAttempPopController = containingNavControllerFromLastAttemptedPop {
            return lastAttempPopController
        }
        
        let containingNavVC = containingVC?.navigationController
        guard let containingSplitViewController = containingSplitViewController else {
            return containingNavVC
        }
        
        guard let containingNavVC = containingNavVC else {
            return nil
        }
        
        guard let parentNavVC = containingNavVC.parent as? UINavigationController,
              parentNavVC.parent == containingSplitViewController else {
                  return containingNavVC
              }
        
        return parentNavVC
    }
    
    internal var inferredPreferenceBridge: PreferenceBridge? {
        guard let containingSplitVC = containingSplitViewController else {
            return containingNavController?.traitCollection.baseEnvironment.preferenceBridge
        }
        return containingSplitVC.traitCollection.baseEnvironment.preferenceBridge
    }
    
    fileprivate var supportsToolbar: Bool {
        guard let vc = host!.viewController else {
            return false
        }
        
        return vc.allowedBehaviors.contains(.customToolbarManagement)
    }
    
    internal var isBeingPresented: Bool {
        guard let containingVC = containingVC else {
            return false
        }
        
        if let containingSplitVC = containingSplitViewController {
            return containingVC.view.isDescendant(of: containingSplitVC.view)
        }
        
        guard let containingNavVC = containingVC.navigationController,
              containingNavVC.viewControllers.count > 1,
              let topVC = containingNavVC.topViewController else {
                  return false
              }
        
        return containingVC.view.isDescendant(of: topVC.view)
    }
    
    internal var toolbarCoordinator: UIKitToolbarCoordinator? {
        guard supportsToolbar else {
            return nil
        }
        
        return host!.viewController?.toolbarCoordinator
    }
    
    internal override init() {
        host = nil
        hasNavigationTitle = false
        hidingBackButton = false
        statusBarHidden = false
        activePresentation = nil
        destinations = PreferenceList.Value(value: [:])
        lastToolbarSeed = .invalid
        navigationBarSeedTracker = VersionSeedTracker(values: [])
        focusedValuesSeed = .zero
        lastEnvironment = EnvironmentValues()
        environmentOverride = nil
        shouldHideNavigationBar = nil
        containingNavControllerOverride = nil
        containingNavControllerFromLastAttemptedPop = nil
        incomingPushTarget = nil
        containingSplitControllerOverride = nil
        super.init()
    }
    
    internal func updateForNavigationBarRelatedPreferences(updating: inout NavigationBarUpdateFlags, _ : PreferenceList) {
        _abstractFunction()
    }

    internal func pushTarget(isDetail: Bool) -> PushTarget? {
        guard let lastAttemp = containingNavControllerFromLastAttemptedPop else {
            return nil
        }
        
        return PushTarget(navController: lastAttemp, shouldReplaceRoot: false, column: nil)
    }
    
    @objc
    internal func updateTopItem(notification: NSNotification) {
        let navVC = notification.object! as! UINavigationController
        navVC.title = navVC.topViewController?.navigationItem.title ?? ""
    }
    
    internal func addPreferences(to viewGraph: ViewGraph) {
        viewGraph.addPreference(NavigationTitleKey.self)
        navigationBarSeedTracker.addPreference(NavigationTitleKey.self)
        
        viewGraph.addPreference(NavigationDestinationsKey.self)
        navigationBarSeedTracker.addPreference(NavigationDestinationsKey.self)
        
        viewGraph.addPreference(NavigationBarHiddenKey.self)
        navigationBarSeedTracker.addPreference(NavigationBarHiddenKey.self)
        
        viewGraph.addPreference(NavigationBarItemsKey.self)
        navigationBarSeedTracker.addPreference(NavigationBarItemsKey.self)
        
        viewGraph.addPreference(ToolbarKey.self)
        
        viewGraph.addPreference(NavigationBarBackButtonHiddenKey.self)
        navigationBarSeedTracker.addPreference(NavigationBarBackButtonHiddenKey.self)
    }
    
    internal func popDestination(animated: Bool) {
        _abstractFunction()
    }
    
    @objc
    internal func navigationChanged(notification: NSNotification) {
        _abstractFunction()
    }
    
    internal func updateContentHost(host: BridgedPresentation.ContentHost,
                                    destination: NavigationDestinationContent,
                                    animated: Bool) -> Bool {
        _abstractFunction()
    }
    
    internal func preferencesDidChange(preferenceList: PreferenceList) {
        defer {
            navigationBarSeedTracker.updateSeeds(to: preferenceList)
        }
        
        @inline(__always)
        func popCurrentView() {
            let animated = !Transaction.current.disablesAnimations
            popDestination(animated: animated)
            
            let defaultNotificationCenter = NotificationCenter.default
            let didShowVCNotification = Notification.Name("UINavigationControllerDidShowViewControllerNotification")
            defaultNotificationCenter.removeObserver(self, name: didShowVCNotification, object: nil)
            
            let willShowVCNotification = Notification.Name("UINavigationControllerWillShowViewControllerNotification")
            defaultNotificationCenter.removeObserver(self, name: willShowVCNotification, object: nil)
            self.activePresentation = nil
        }

        let destination = preferenceList[NavigationDestinationsKey.self]
        
        if destination.seed != destinations.seed || destination.seed == .invalid {
            self.destinations = destination
            if let nextNavigationDestination = nextNavigationDestination(activePresentation: self.activePresentation,
                                                                         possibleDestinations: self.destinations.value) {
                let disableAnimations = nextNavigationDestination.transaction.disablesAnimations
                updatePresentedContent(nextNavigationDestination, animated: !disableAnimations)
            } else {
                if self.activePresentation != nil {
                    popCurrentView()
                }
            }
        }
        
        var flag: NavigationBarUpdateFlags = .bottomPalette
        if navigationBarSeedTracker.hasChanges(in: preferenceList) {
            updateForNavigationBarRelatedPreferences(updating: &flag, preferenceList)
        }
        
        let toolBar = preferenceList[ToolbarKey.self]
        if toolBar.seed != lastToolbarSeed || toolBar.seed == .invalid {
            if let containingVC = self.containingVC,
               let toolbarCoordinator = self.toolbarCoordinator {
                containingVC.updateNavigationBar(toolbarCoordinator,
                                                 in: lastEnvironment,
                                                 avoiding: flag,
                                                 pushTarget: incomingPushTarget,
                                                 overrideSplitController: containingSplitControllerOverride,
                                                 overrideNavController: incomingPushTarget?.navController)
            }
        }
        
        lastToolbarSeed = toolBar.seed
    }
    
    internal func updatePresentedContent(_ content: NavigationDestinationContent, animated: Bool) {
        guard let target = pushTarget(isDetail: content.isDetail) else {
            return
        }
        
        if let contentHost = activePresentation?.contentHost,
           updateContentHost(host: contentHost, destination: content, animated: animated) {
            return
        }
        
        push(content, onto: target, animated: animated)
        
        var navigationController: UINavigationController? = target.navController
        if let containingSplitViewController = containingSplitViewController,
           containingSplitViewController.isCollapsed,
           !containingSplitViewController.viewControllers.contains(target.navController) {
            if let lastNav = containingSplitViewController.viewControllers.last as? UINavigationController {
                navigationController = lastNav
            } else {
                navigationController = nil
            }
        }
        
        let defaultNotificationCenter = NotificationCenter.default
        let didShowVCNotification = Notification.Name("UINavigationControllerDidShowViewControllerNotification")
        defaultNotificationCenter.addObserver(self, selector: #selector(navigationChanged(notification:)), name: didShowVCNotification, object: navigationController)
        
        let willShowVCNotification = Notification.Name("UINavigationControllerWillShowViewControllerNotification")
        defaultNotificationCenter.addObserver(self, selector: #selector(updateTopItem(notification:)), name: willShowVCNotification, object: navigationController)
    }
    
    internal func update(environment: inout EnvironmentValues) {
        lastEnvironment = environment
        lastEnvironment.preferenceBridge = nil
        
        let block: () -> PresentationMode = { [weak self] in
            var isPresented = false
            guard let strongSelf = self else {
                return PresentationMode(isPresented: isPresented)
            }
            isPresented = strongSelf.isBeingPresented
            return PresentationMode(isPresented: isPresented)
        }
        let presentationMode = block()
        
        let location = FunctionalLocation(getValue: block) { [weak self] (mode: PresentationMode, transaction: Transaction) in
            guard !mode.isPresented,
                  let strongSelf = self else {
                      return
                  }
            
            strongSelf.popSelf(animated: true)
        }
        
        let locationBox = LocationBox(location)
        environment.presentationMode = Binding(value: presentationMode, location: locationBox)
        if environment.navigationEnabled == .unknown && pushTarget(isDetail: true) != nil {
            environment.navigationEnabled = .enabled
        }
        
        guard let toolbarCoordinator = self.toolbarCoordinator,
              toolbarCoordinator.hasUpdatesBasedOnEnvironment == true,
              let containingVC = self.containingVC else {
                  return
              }
        
        containingVC.updateNavigationBar(toolbarCoordinator,
                                         in: environment,
                                         avoiding: .none,
                                         pushTarget: nil,
                                         overrideSplitController: nil,
                                         overrideNavController: nil)
    }
    
    internal func push(_: NavigationDestinationContent,
                       onto: PushTarget,
                       animated: Bool) {
        _abstractFunction()
    }

    internal func popSelf(animated: Bool) {
        _abstractFunction()
    }
    
}

@available(iOS 13.0, *)
internal func nextNavigationDestination(activePresentation: BridgedPresentation?,
                                        possibleDestinations: [Namespace.ID: NavigationDestinationContent]) -> NavigationDestinationContent? {
    guard !possibleDestinations.isEmpty else {
        return nil
    }
    
    guard let activePresentation = activePresentation,
          let value = possibleDestinations[activePresentation.content.id] else {
              return possibleDestinations.values[possibleDestinations.startIndex]
          }

    guard possibleDestinations.count == 2 else {
        return value
    }
    
    let matched = possibleDestinations.first { (key, value) in
        key != activePresentation.content.id
    }
    
    return matched!.value
}

@available(iOS 13.0, *)
internal final class NotificationSendingSplitViewController: UISplitViewController {
    
    internal override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        let defaultCenter = NotificationCenter.default
        let userInfo = ["baseWritingDirection": vc]
        defaultCenter.post(name: DoubleColumnNavigationViewStyle.willShowDetailNotification,
                           object: self,
                           userInfo: userInfo)
        super.showDetailViewController(vc, sender: sender)
    }
    
}

@available(iOS 13.0, *)
internal final class NotifyingMulticolumnSplitViewController: UISplitViewController {

    @objc
    internal override func makeDetailNavigationControllerWithRoot(root: UIViewController) -> UINavigationController {
        super.makeDetailNavigationControllerWithRoot(root: root)
    }

    internal override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        let defaultCenter = NotificationCenter.default
        let userInfo = ["baseWritingDirection": vc]
        defaultCenter.post(name: ColumnNavigationViewStyle.willShowDetailNotification,
                           object: self,
                           userInfo: userInfo)
        super.showDetailViewController(vc, sender: sender)
    }
}

@available(iOS 13.0, *)
internal struct PushTarget {

    internal var navController: UINavigationController

    internal var shouldReplaceRoot: Bool

    private(set) var _column: Any?

    @available(iOS 14.0, *)
    internal var column: UISplitViewController.Column? {
        get {
            guard let column = _column else {
                return nil
            }
            return (column as! UISplitViewController.Column)
        }
        set {
            _column = newValue
        }
    }

    @inline(__always)
    internal func isColumnNil() -> Bool {
        return _column == nil
    }
    
    internal init(navController: UINavigationController, shouldReplaceRoot: Bool, column: Any?) {
        self.navController = navController
        self.shouldReplaceRoot = shouldReplaceRoot
        
        if #available(iOS 14.0, *) {
            self.column = column as? UISplitViewController.Column
        } else {
            _column = nil
        }
    }
    
}

@available(iOS 13.0, *)
internal struct BridgedPresentation {

    internal enum ContentHost {

        case push(UIHostingController<AnyView>)

        case split((UINavigationController, UIHostingController<AnyView>))

    }

    internal var content: NavigationDestinationContent

    internal var contentHost: BridgedPresentation.ContentHost?

}


@available(iOS 13.0, *)
internal struct NavigationBarUpdateFlags: OptionSet {
    
    internal let rawValue: Int
    
    internal static let none = NavigationBarUpdateFlags([])
    
    internal static let title = NavigationBarUpdateFlags(rawValue: 0x1 << 0)
    
    internal static let leftBarItems = NavigationBarUpdateFlags(rawValue: 0x1 << 1)
    
    internal static let rightBarItems = NavigationBarUpdateFlags(rawValue: 0x1 << 2)
    
    internal static let bottomPalette = NavigationBarUpdateFlags(rawValue: 0x1 << 3)
    
}
