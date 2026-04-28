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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal final class SheetBridge<ContentView: View>: NSObject, PresentationHostingControllerDelegate, UIHostingViewDelegate {

    internal weak var host: _UIHostingView<ContentView>?

    internal var seed: VersionSeed

    internal var isShown: Bool

    internal var isPresentingAfterDismiss: Bool

    internal var presentedVC: PresentationHostingController<AnyView>? {
        willSet {
            if let presentationViewController = presentedVC {
                presentationViewController.host.render(interval: 0, updateDisplayList: false)
            }
        }
    }
    
    internal var lastPresentation: SheetPreference? {
        willSet {
            if newValue == nil {
                if let lastPresentationValue = lastPresentation,
                   let onDismissCallback = lastPresentationValue.onDismiss {
                    let isPresented = !self.isPresentingAfterDismiss
                    onDismissCallback(isPresented)
                }
            }
        }
    }
    
    internal weak var presenterOverride: UIViewController?

    internal var lastEnvironment: EnvironmentValues
    
    internal override init() {
        self.seed = .zero
        self.isShown = false
        self.isPresentingAfterDismiss = false
        self.lastEnvironment = EnvironmentValues()
        super.init()
    }
    
    deinit {
        
    }
    
    func adjustAnchorIfNeeded(_ controller: UIViewController, idealSize: CGSize) { }
    
    internal func didDismissViewController() {
        if !isPresentingAfterDismiss {
            isShown = false
            presentedVC = nil
        }
        
        lastPresentation = nil
    }
    
    // HostingViewDelegate
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didChangePreferences preference :PreferenceList) where ViewType : View {
        if let colorScheme = preference[PreferredColorSchemeKey.self].value {
            hostingView.colorScheme = colorScheme
        }
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didMoveTo window :UIWindow?) where ViewType : View {
        if window != nil {
            hostingView.viewGraph.addPreference(PreferredColorSchemeKey.self)
        } else {
            hostingView.viewGraph.removePreference(PreferredColorSchemeKey.self)
        }
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, willUpdate: inout EnvironmentValues) where ViewType : View {

    }

    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didUpdate: inout EnvironmentValues) where ViewType : View {

    }

    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didChangePlatformItemList: PlatformItemList) where ViewType : View {

    }
    
    internal func addPreferences(to graph: ViewGraph) {
        DGGraphRef.withoutUpdate {
            graph.addPreference(SheetPreference.Key.self)
        }
    }
    
    internal func preferencesDidChange(_ preferenceList: PreferenceList) {
        let preferenceValue = preferenceList[SheetPreference.Key.self]
        
        var transcation: Transaction
        
        var currentSheetPreference: SheetPreference?
        
        switch preferenceValue.value {
        case .empty(let t):
            transcation = t
        case .sheet(let sheetPreference):
            currentSheetPreference = sheetPreference
            transcation = sheetPreference.transaction
        }
        
        defer {
            lastPresentation = currentSheetPreference
        }
        
        if seed.isVaild || preferenceValue.seed.isVaild || seed != preferenceValue.seed {
            let enabledAnimations = !transcation.disablesAnimations
            
            seed = preferenceValue.seed
            
            if let presentedViewController = presentedVC,
               !presentedViewController.dismissedProgramatically {
                
                let lastItemID = lastPresentation?.itemID
                
                let currentItemID = currentSheetPreference?.itemID
                
                let isEqualItem = lastItemID == currentItemID
                
                if isEqualItem {
                    if let currentSheetPreferenceValue = currentSheetPreference {
                        presentedViewController.host.setRootView(currentSheetPreferenceValue.content,
                                                                 transaction: transcation)
                        presentedViewController.host.environmentOverride = currentSheetPreferenceValue.environment
                        
                        if presentedViewController.host.colorScheme == nil,
                           let explicitColorScheme = lastEnvironment.explicitPreferredColorScheme {
                            presentedViewController.host.colorScheme = explicitColorScheme
                        }
                        
                        if !isShown,
                            let presenterViewController = presenter {
                            isShown = true
                            let style: UIModalPresentationStyle = currentSheetPreferenceValue.overFullscreen ? .overFullScreen : .pageSheet
                            presentedViewController.prepareModalPresentationStyle(style)
                            presenterViewController.present(presentedViewController, animated: enabledAnimations, completion: nil)
                        }
                        
                    } else {
                        // Dismiss after present goes here
                        if isShown {
                            isShown = false
                            presentedViewController.dismissedProgramatically = true
                            DispatchQueue.main.async { [weak self] in
                                NotificationCenter.default.post(name: SheetBridgeNotifications.willDismiss, object: nil)
                                presentedViewController.dismiss(animated: enabledAnimations) {
                                    guard let self = self else {
                                        return
                                    }
                                    
                                    if let presentedVCValue = self.presentedVC,
                                     presentedViewController == presentedVCValue {
                                        self.presentedVC = nil
                                    }
                                    
                                    if let hostingView = self.host {
                                        hostingView.invalidateProperties(.transform, mayDeferUpdate: false)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    
                    if let presenterViewController = presenter {
                        dismissAndPresentAgain(preference: currentSheetPreference,
                                               presented: presentedViewController,
                                               animated: enabledAnimations,
                                               presenter: presenterViewController)
                    }
                }
                
            } else {
                if let presenterViewController = presenter {
                    
                    guard !isShown else {
                        _danceuiFatalError("temp to present another modal ViewController when isShown.")
                    }
                    
                    if let currentSheetPreferenceValue = currentSheetPreference {
                        let presentationViewController = PresentationHostingController(rootView: currentSheetPreferenceValue.content, delegate: self, drawsBackground: currentSheetPreferenceValue.drawsBackground)
                        
                        let style: UIModalPresentationStyle = currentSheetPreferenceValue.overFullscreen ? .overFullScreen : .pageSheet
                        presentationViewController.prepareModalPresentationStyle(style)
                        presentationViewController.host.environmentOverride = currentSheetPreferenceValue.environment
                        
                        if let explicitColorScheme = lastEnvironment.explicitPreferredColorScheme {
                            presentationViewController.host.colorScheme = explicitColorScheme
                        }
                        
                        presenterViewController.present(presentationViewController, animated: enabledAnimations, completion: nil)
                        
                        seed = preferenceValue.seed
                        
                        presentedVC = presentationViewController
                        
                        isShown = true
                    }
                }
            }
        }
    }
    
    fileprivate func dismissAndPresentAgain(preference: SheetPreference?,
                                            presented: PresentationHostingController<AnyView>,
                                            animated: Bool,
                                            presenter: UIViewController) {
        if preference != nil {
            isShown = true
            isPresentingAfterDismiss = true
        } else {
            isShown = false
            isPresentingAfterDismiss = false
            presentedVC?.dismissedProgramatically = true
            presentedVC = nil
        }
        
        DispatchQueue.main.async {
            presented.dismiss(animated: animated) {
                if let preferenceValue = preference {
                    presented.rootView = preferenceValue.content
                    presented.host.environmentOverride = preferenceValue.environment
                    presenter.present(presented, animated: animated, completion: nil)
                }
            }
        }
    }
    
    internal func update(environment: inout EnvironmentValues) {
        lastEnvironment = environment
    }
    
    fileprivate var presenter: UIViewController? {
        
        if let overridePresenter = presenterOverride {
            return overridePresenter
        }
        
        guard let hostingView = host else {
            _danceuiFatalError("HostingView in SheetBridge is nil.")
        }
        
        guard let viewController = hostingView.viewController else {
            return hostingView.my__viewControllerForAncestor()
        }
        
        return viewController
    }
}

@available(iOS 13.0, *)
internal struct SheetBridgeNotifications {
    internal static let willDismiss: NSNotification.Name = .init(rawValue: "DanceUISheetWillDismiss")
}
