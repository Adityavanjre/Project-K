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

import UIKit

@available(iOS 13.0, *)
internal final class AlertBridge<ViewType: View, PresentationType: AlertControllerConvertible>: NSObject, CustomRecursiveStringConvertible, AlertActionDelegate {
    
    internal weak var host: _UIHostingView<ViewType>?
    
    internal var isShown: Bool
    
    internal var seed: VersionSeed
    
    internal var alertController: PlatformAlertController?
    
    internal var lastEnvironment: EnvironmentValues
    
    internal var lastPresentation: PresentationType?
    
    internal var isChangingIdentity: Bool
    
    internal var style: UIAlertController.Style
    
    internal var presenter: UIViewController? {
        
        guard let hostingView = host else {
            _danceuiFatalError("HostingView in AlertBridge is nil.")
        }
        
        guard let viewControllerValue = hostingView.viewController else {
            return hostingView.my__viewControllerForAncestor()
        }
        
        return viewControllerValue
    }
    
    internal override init() {
        _unimplementedInitializer(className: "DanceUI.AlertBridge")
    }
    
    internal init(style: UIAlertController.Style) {
        host = nil
        
        isShown = false
        
        seed = .zero
        
        alertController = nil
        
        lastEnvironment = .init(propertyList: .init())
        
        lastPresentation = nil
        
        isChangingIdentity = false
        
        self.style = style
        
        super.init()
    }
    
    internal func addPreferences(to: ViewGraph) {
        to.addPreference(PresentationType.Key.self)
    }
    
    internal func preferencesDidChange(preferencesList: PreferenceList) {
        
        guard let presenterViewController = presenter else {
            return
        }
        
        if !isChangingIdentity {
            
            let preferenceValue = preferencesList[PresentationType.Key.self]
            
            defer {
                lastPresentation = preferenceValue.value
            }
            
            if seed != preferenceValue.seed || !seed.isVaild || !preferenceValue.seed.isVaild {
                
                seed = preferenceValue.seed
                
                if let plateformAlertController = alertController {
                    
                    let lastItemID = lastPresentation?.itemID
                    
                    let currentItemID = preferenceValue.value?.itemID
                    
                    if lastItemID != currentItemID {
                        if let presentationValue = preferenceValue.value {
                            
                            if let onDismissCallback = presentationValue.onDismiss {
                                onDismissCallback()
                            }
                            
                            if currentItemID != nil {
                                isChangingIdentity = true
                                presentAlertControllAfterDismiss(with: plateformAlertController,
                                                                 presentation: presentationValue,
                                                                 presenterViewController: presenterViewController)
                                isShown = true
                            } else {
                                plateformAlertController.update(presentation: presentationValue, with: lastEnvironment, environmentChanged: false)
                                
                                plateformAlertController.dismiss(animated: true, completion: nil)
                                
                                alertController = nil
                                
                                isShown = false
                            }
                            
                        } else {
                            isShown = false
                            
                            alertController = nil
                        }
                    } else {
                        
                        if let presentationValue = preferenceValue.value {
                            plateformAlertController.update(presentation: presentationValue, with: lastEnvironment, environmentChanged: false)
                        }
                        
                        let hasPresentation = (preferenceValue.value == nil) ? false : true
                        
                        if hasPresentation != isShown {
                            isShown = !isShown
                            if isShown {
                                plateformAlertController.popoverPresentationController?.sourceView = host
                                
                                presenterViewController.present(plateformAlertController, animated: true, completion: nil)
                            } else {
                                if let onDismissCallback = preferenceValue.value?.onDismiss {
                                    onDismissCallback()
                                }
                                
                                plateformAlertController.dismiss(animated: true, completion: nil)
                                
                                alertController = nil
                            }
                        }
                    }
                } else {
                    
                    if isShown {
                        _danceuiFatalError("DanceUI isChangingIdentity.")
                    }
                    
                    if let presentationValue = preferenceValue.value {
                        
                        let newAlertController: PlatformAlertController = .init(title: nil, message: nil, preferredStyle: style)
                        
                        newAlertController.update(presentation: presentationValue, with: lastEnvironment, environmentChanged: false)
                        
                        newAlertController.popoverPresentationController?.sourceView = host
                        
                        presenterViewController.present(newAlertController, animated: true, completion: nil)
                        
                        seed = preferenceValue.seed
                        
                        alertController = newAlertController
                        
                        isShown = true
                    }
                }
            }
        }
    }
    
    @inline(__always)
    private func presentAlertControllAfterDismiss(with plateformAlertController: PlatformAlertController,
                                                  presentation: PresentationType,
                                                  presenterViewController: UIViewController) {
        
        if #available(iOS 13.0, *) {
            plateformAlertController.dismiss(animated: true) { [weak self] () -> () in
                if let selfValue = self {
                    plateformAlertController.update(presentation: presentation, with: selfValue.lastEnvironment, environmentChanged: false)
                    selfValue.isChangingIdentity = false
                    presenterViewController.present(plateformAlertController, animated: true, completion: nil)
                }
            }
        } else {
            plateformAlertController.update(presentation: presentation, with: self.lastEnvironment, environmentChanged: false)
            self.isChangingIdentity = false
            presenterViewController.present(plateformAlertController, animated: true, completion: nil)
        }
    }
    
    internal func update(environment: EnvironmentValues) {
        
        lastEnvironment = environment
        
        if let lastPresentationValue = lastPresentation {
            
            if !isChangingIdentity {
                alertController?.update(presentation: lastPresentationValue, with: environment, environmentChanged: true)
            }
        }
    }
}
