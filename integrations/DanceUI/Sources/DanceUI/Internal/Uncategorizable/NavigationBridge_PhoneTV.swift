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
internal final class NavigationBridge_PhoneTV<ContentView: View>: UIKitNavigationBridge<ContentView> {
    
    internal override var shouldHideNavigationBar: Bool? {
        didSet {
            guard let containingNavController = self.containingNavController,
                  self.host!.isDescendant(of: containingNavController.view),
                  let shouldHideNavigationBar = self.shouldHideNavigationBar else {
                      return
                  }
            
            self.containingVC?.danceuiNavigationBarHiddenSet = true
            containingNavController.my_setNavigationBarHidden(shouldHideNavigationBar)
        }
    }
    
    internal override func pushTarget(isDetail: Bool) -> PushTarget? {
        if #available(iOS 14, *) {
            let navVC = containingNavControllerOverride ?? containingVC?.navigationController
            guard let containingSplitVC = containingSplitViewController,
                  containingSplitVC.style != .unspecified,
                  isDetail else {
                      return navVC.map { PushTarget(navController: $0, shouldReplaceRoot: false, column: nil) } ?? nil
                  }

            let primaryViewController = containingSplitVC[.primary]
            if navVC == primaryViewController {
                if let supplementaryViewController = containingSplitVC[.supplementary] {
                    guard let supplementaryNavVC = supplementaryViewController as? UINavigationController else {
                        return nil
                    }
                    let column = UISplitViewController.Column.supplementary
                    return PushTarget(navController: supplementaryNavVC, shouldReplaceRoot: true, column: column)
                } else {
                    return _secondaryPushTarget(splitVC: containingSplitVC)
                }
            } else {
                let supplementaryVC = containingSplitVC[.supplementary]
                if let navVC = navVC {
                    guard let supplementaryVC = supplementaryVC,
                          supplementaryVC == navVC else {
                              return PushTarget(navController: navVC, shouldReplaceRoot: false, column: nil)
                          }
                    return _secondaryPushTarget(splitVC: containingSplitVC)
                } else {
                    guard let supplementaryVC = supplementaryVC else {
                        return nil
                    }
                    return _secondaryPushTarget(splitVC: containingSplitVC)
                }
            }
        } else {
            guard let containingNavController = self.containingNavController else {
                return nil
            }
            return PushTarget(navController: containingNavController, shouldReplaceRoot: false, column: nil)
        }
    }

    @inline(__always)
    @available(iOS 14.0, *)
    private func _secondaryPushTarget(splitVC: UISplitViewController) -> PushTarget? {
        guard let secondaryVC = splitVC[.secondary],
              let secondaryNavVC = secondaryVC as? UINavigationController else {
                  return nil
              }
        
        let column = UISplitViewController.Column.secondary
        return PushTarget(navController: secondaryNavVC, shouldReplaceRoot: true, column: column)
    }
    
    @objc
    fileprivate func detailChanged(notification: NSNotification) {
        let vc = notification.userInfo?["baseWritingDirection"] as? UIViewController ?? nil
        guard let activePresentation = self.activePresentation,
              case let .split((navigationController, _)) = activePresentation.contentHost,
              vc != navigationController else {
                  return
              }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: DoubleColumnNavigationViewStyle.willShowDetailNotification,
                                                  object: nil)
        self.activePresentation = nil
    }
    
    internal override func popSelf(animated: Bool) {
        guard isBeingPresented else {
            return
        }

        containingNavController?.popViewController(animated: animated)
    }

    internal override func popDestination(animated: Bool) {
        guard let containingNavController = self.containingNavController,
              let containingVC = self.containingVC else {
                  return
              }
        
        var toCompare = containingVC
        if let parent = containingVC.parent,
           parent is UINavigationController,
           parent != containingNavController {
            toCompare = parent
        }
        
        guard toCompare != containingNavController else {
            return
        }
        
        let viewControllers = containingNavController.viewControllers
        guard viewControllers.last != toCompare else {
            return
        }
        
        if viewControllers.contains(toCompare) {
            containingNavController.popToViewController(toCompare, animated: animated)
        }
    }
    
    internal override func navigationChanged(notification: NSNotification) {
        let object = notification.object!
        let navVC = object as? UINavigationController
        guard let activePresentation = self.activePresentation,
              let currentHost = activePresentation.contentHost else {
                  return
              }
        
        switch currentHost {
        case let .split((navController, hostController)):
            if navController == navVC {
                guard navController.topViewController != hostController else {
                    return
                }
            } else {
                let viewControllers = navVC?.viewControllers ?? []
                let contains = viewControllers.contains(navController)
                guard !contains else {
                    return
                }
            }
        case let .push(navController):
            let viewControllers = navVC?.viewControllers ?? []
            let contains = viewControllers.contains(navController)
            guard !contains else {
                return
            }
        }
        
        Update.enqueueAction {
            activePresentation.content.onDismiss()
        }
    }
    
    internal override func updateContentHost(host: BridgedPresentation.ContentHost, destination: NavigationDestinationContent, animated: Bool) -> Bool {
        guard let activePresentation = self.activePresentation,
              activePresentation.content.id == destination.id else {
                  let pushTarget = pushTarget(isDetail: destination.isDetail)
                  pushTarget?.navController.popViewController(animated: animated)
                  return false
              }
        
        if case .push(let hostingVC) = host {
            hostingVC.rootView = self.content(for: destination, targeting: hostingVC.navigationController)
            return true
        } else if case .split(let (navVC, hostingVC)) = host {
            guard let lastVC = navVC.viewControllers.last,
                  lastVC == hostingVC else {
                      return false
                  }
            hostingVC.rootView = self.content(for: destination, targeting: navVC)
            return true
        } else {
            // undefined behaviour
            return false
        }
    }
    
    internal override func updateForNavigationBarRelatedPreferences(updating: inout NavigationBarUpdateFlags,
                                                                    _ preferenceList: PreferenceList) {
        let title = preferenceList[NavigationTitleKey.self].value
        let barItems = preferenceList[NavigationBarItemsKey.self].value
        let backButtonHidden = preferenceList[NavigationBarBackButtonHiddenKey.self].value
        
        guard title != nil || self.hasNavigationTitle || barItems != nil || backButtonHidden != self.hidingBackButton else {
            guard let navigationBarHidden = preferenceList[NavigationBarHiddenKey.self].value else {
                return
            }
            
            self.shouldHideNavigationBar = navigationBarHidden
            return
        }
        
        self.hasNavigationTitle = true
        self.hidingBackButton = backButtonHidden
        
        guard let containingVC = self.containingVC else {
            self.shouldHideNavigationBar = preferenceList[NavigationBarHiddenKey.self].value ?? false
            return
        }
        
        let barItem = NavigationBarItem(barItemStorage: barItems, hidesBackButton: backButtonHidden)
        let titleStorage = NavigationTitleStorage(title: title?.title, transaction: title?.transaction, displayMode: title?.displayMode)
        var updateFlag = containingVC.updateNavigationBar(item: barItem,
                                                          title: titleStorage,
                                                          transaction: title?.transaction,
                                                          environment: self.lastEnvironment,
                                                          navController: self.containingNavController)
        _ = updateFlag.remove(.title)
        updating.insert(updateFlag)

        if let navigationBarHidden = preferenceList[NavigationBarHiddenKey.self].value {
            self.shouldHideNavigationBar = navigationBarHidden
        }
    }
    
    fileprivate var isContainedInDetailViewController: Bool {
        guard let containingSplitViewController = self.containingSplitViewController else {
            return false
        }
        
        let viewControllers = containingSplitViewController.viewControllers
        guard viewControllers.count >= 2 else {
            return false
        }
        
        return self.host!.isDescendant(of: viewControllers.last!.view)
    }
    
    internal override func push(_ destinationContent: NavigationDestinationContent, onto pushTarget: PushTarget, animated: Bool) {
        let content = self.content(for: destinationContent, targeting: pushTarget.navController)
        let hostingController = DestinationHostingController(rootView: content)
        
        func withUpdatedNavigationBar(perform: @escaping () -> ()) {
            if let inferredPreferenceBridge = self.inferredPreferenceBridge {
                hostingController.host.setPreferenceBridge(inferredPreferenceBridge)
            }
            
            hostingController.host.environmentOverride = self.lastEnvironment
            hostingController.host.navigationBridge.environmentOverride = self.lastEnvironment
            
            Update.enqueueAction {
                hostingController.host.navigationBridge.incomingPushTarget = pushTarget
                hostingController.host.navigationBridge.containingSplitControllerOverride = self.containingSplitViewController
#warning("hostingController.toolbarBridge.navControllerOverride = pushTarget.navController")
                
                hostingController.host.bounds = pushTarget.navController.view.bounds
                
                var resolvedEnvironment = pushTarget.navController.traitCollection.resolvedEnvironment(base: self.lastEnvironment)
                hostingController.toolbarCoordinator.update(in: resolvedEnvironment)
                
                hostingController.host.navigationBridge.update(environment: &resolvedEnvironment)
#warning("hostingController.toolbarBridge.update(environment: resolvedEnvironment)")
                let preferenceValues = hostingController.host.viewGraph.preferenceValues()
                let toolbarStorage = preferenceValues[ToolbarKey.self]
                hostingController.toolbarCoordinator.updateIfNeeded(storage: toolbarStorage)
                
                hostingController.host.navigationBridge.preferencesDidChange(preferenceList: preferenceValues)
#warning("hostingController.toolbarBridge.preferencesDidChange(preferenceList: preferenceValues)")
                
                hostingController.host.navigationBridge.incomingPushTarget = nil
                hostingController.host.navigationBridge.containingSplitControllerOverride = nil
#warning("hostingController.toolbarBridge.navControllerOverride = nil")
                perform()
            }
        }
        
        guard !pushTarget.shouldReplaceRoot else {
            withUpdatedNavigationBar {
                pushTarget.navController.title = hostingController.title ?? ""
                pushTarget.navController.viewControllers = [hostingController]
                
                guard pushTarget._column != nil else {
                    return
                }
                UIApplication.shared._myShims_performBlockAfterCATransactionCommits { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    if #available(iOS 14.0, *) {
                        ///  先过编译，这里 column 不可能为 nil，因为之前有一个 guard 判断了 _column，其实可以写成 guard let 的格式
                        strongSelf.containingSplitViewController?.show(pushTarget.column!)
                    } else {
                        runtimeIssue(type: .error, "this logic branch should never be reached")
                    }
                }
            }
            
            let currentHost: BridgedPresentation.ContentHost = .split((pushTarget.navController, hostingController))
            self.activePresentation = BridgedPresentation(content: destinationContent, contentHost: currentHost)
            return
        }
        
        guard self.containingNavControllerOverride == nil,
              let containingSplitViewController = self.containingSplitViewController,
              destinationContent.isDetail,
              !isContainedInDetailViewController else {
                  withUpdatedNavigationBar {
                      pushTarget.navController.title = hostingController.title ?? ""
                      pushTarget.navController.pushViewController(hostingController, animated: animated)
                  }
                  
                  let currentHost: BridgedPresentation.ContentHost = .push(hostingController)
                  self.activePresentation = BridgedPresentation(content: destinationContent, contentHost: currentHost)
                  return
              }
        
        let navVC = containingSplitViewController.makeDetailNavigationControllerWithRoot(root: hostingController)
        withUpdatedNavigationBar {
            if !containingSplitViewController.isCollapsed {
                hostingController.navigationItem.leftBarButtonItem = containingSplitViewController.displayModeButtonItem
                hostingController.navigationItem.leftItemsSupplementBackButton = true
            }

            containingSplitViewController.showDetailViewController(navVC, sender: nil)
        }
        let currentHost: BridgedPresentation.ContentHost = .split((navVC, hostingController))
        self.activePresentation = BridgedPresentation(content: destinationContent, contentHost: currentHost)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(detailChanged(notification:)),
                                               name: DoubleColumnNavigationViewStyle.willShowDetailNotification,
                                               object: containingSplitViewController)
    }
    
    fileprivate func content(for content: NavigationDestinationContent, targeting: UINavigationController?) -> AnyView {
        guard let targetNavVC = targeting,
              let splitNavVC = targetNavVC as? SplitViewNavigationController else {
                  return content.generateContent(true)
              }
        
        let content = content.generateContent(false)
        return splitNavVC.applyStyleContextModifier(to: content)
    }
    
    // MARK: - CallBack
    internal func hostingControllerDidAppear() {
        guard self.isBeingPresented else {
            return
        }
        
        self.host!.environmentOverride = nil
    }
    
    internal func hostingControllerWillDisappear() {
        self.host!.environmentOverride = self.environmentOverride
    }
    
    internal func hostingControllerWillAppear(transitionCoordinator: UIViewControllerTransitionCoordinator?,
                                              animated: Bool) {
        guard self.isBeingPresented,
              let viewController = self.host!.viewController,
              let scrollView = viewController.contentScrollView(),
              let tableView = scrollView as? UITableView,
              let indexPath = tableView.indexPathForSelectedRow else {
                  return _setNavigationBarHidden(animated: animated)
              }
        
        guard let coordinator = transitionCoordinator else {
            tableView.deselectRow(at: indexPath, animated: animated)
            return _setNavigationBarHidden(animated: animated)
        }
        
        coordinator.animate { context in
            tableView.deselectRow(at: indexPath, animated: true)
        } completion: { context in
            guard !context.isCancelled else {
                return
            }
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        return _setNavigationBarHidden(animated: animated)
    }
    
    fileprivate func danceuiSetNavigationBarHiddenStrategy() -> (shouldSet: Bool, hiddenValue: Bool?) {
        if let shouldHideNavigationBar = self.shouldHideNavigationBar {
            return (true, shouldHideNavigationBar)
        }

        var target = self.containingVC
        while target != nil {
            guard !(target is UINavigationController) else {
                break
            }

            if target?.danceuiNavigationBarHiddenSet == true {
                return (false, nil)
            }

            target = target?.parent
        }

        return (false, false)
    }

    @inline(__always)
    private func _setNavigationBarHidden(animated: Bool) {
        let (shouldSet, hiddenValue) = danceuiSetNavigationBarHiddenStrategy()
        if shouldSet {
            self.containingVC?.danceuiNavigationBarHiddenSet = true
        }
         
        let hostIsInstantiated = hostIsInstantiated
        guard let hiddenValue = hiddenValue,
              hostIsInstantiated else {
            return
        }
        
        self.containingNavController?.setNavigationBarHidden(hiddenValue, animated: animated)
    }
    
    @inline(__always)
    private var hostIsInstantiated: Bool {
        guard let isInstantiated = self.host?.viewGraph.isInstantiated else {
            return false
        }
        return isInstantiated
    }
}

@available(iOS 13.0, *)
private var danceuiNavigationBarHiddenSetKey: String = ""
@available(iOS 13.0, *)
extension UIViewController {

    internal var danceuiNavigationBarHiddenSet: Bool? {
        get {
            objc_getAssociatedObject(self, &danceuiNavigationBarHiddenSetKey) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &danceuiNavigationBarHiddenSetKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
}
