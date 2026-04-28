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

/// Responder provides utility methods for finding and managing view controller hierarchy
internal enum Responder {

    // MARK: - Public Methods

    /// Find navigation controller of responder
    /// - Parameter responder: A View or ViewController
    /// - Returns: Found navigation controller, nil if none
    public static func topNavigationController(for responder: UIResponder?) -> UINavigationController? {
        guard let topViewController = topViewController(forResponder: responder) else {
            return nil
        }

        if let navigationController = topViewController as? UINavigationController {
            return navigationController
        } else if let navigationController = topViewController.navigationController {
            return navigationController
        } else {
            return nil
        }
    }

    /// Return topmost view controller in current view controller stack
    /// - Returns: Topmost view controller
    public static func topViewController() -> UIViewController? {
        guard let rootViewController = UIWindow.danceuiKeyWindow()?.rootViewController else {
            return nil
        }
        return topViewController(forController: rootViewController)
    }

    /// Determine if given view controller is the topmost view controller
    /// - Parameter viewController: View controller to check
    /// - Returns: true if is topmost view controller
    public static func isTopViewController(_ viewController: UIViewController) -> Bool {
        return topViewController() === viewController
    }

    /// Return topmost view controller in current view controller stack's view
    /// - Returns: View of topmost view controller
    public static func topView() -> UIView? {
        return topViewController()?.view
    }

    /// Recursively find topmost view controller starting from given root view controller
    /// - Parameter controller: Root view controller
    /// - Returns: The topmost view controller found
    public static func topViewController(forController controller: UIViewController) -> UIViewController {
        // If navigation controller, recursively find its top view controller
        if let navigationController = controller as? UINavigationController {
            if let visibleViewController = navigationController.viewControllers.last {
                return topViewController(forController: visibleViewController)
            }
        }

        // If tab bar controller, recursively find its selected view controller
        if let tabBarController = controller as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return topViewController(forController: selectedViewController)
            }
        }

        // If there is modally presented view controller, recursively find
        if let presentedViewController = controller.presentedViewController {
            return topViewController(forController: presentedViewController)
        }

        return controller
    }

    /// Find topmost view controller that the given view belongs to
    /// - Parameter view: View to find
    /// - Returns: The topmost view controller found
    public static func topViewController(forView view: UIView) -> UIViewController? {
        // Find view controller along responder chain
        var responder: UIResponder? = view
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return topViewController(forController: viewController)
            }
            responder = currentResponder.next
        }

        // If not found, use keyWindow root view controller
        if let rootViewController = UIWindow.danceuiKeyWindow()?.rootViewController {
            return topViewController(forController: rootViewController)
        }

        return nil
    }

    /// Find topmost view controller starting from given responder
    /// - Parameter responder: UIResponder object (can be View or ViewController)
    /// - Returns: The topmost view controller found
    public static func topViewController(forResponder responder: UIResponder?) -> UIViewController? {
        guard let responder = responder else {
            return topViewController()
        }

        if let view = responder as? UIView {
            return topViewController(forView: view)
        } else if let viewController = responder as? UIViewController {
            return topViewController(forController: viewController)
        } else {
            return topViewController()
        }
    }
}

@available(iOS 13.0, *)
extension UIWindow {

    /// Get application key window
    ///
    /// - For iOS 13- devices, find application key window
    /// - For iOS 13+ devices, find key window from first foreground active connected scene
    /// - When multiple connected scenes are foreground active simultaneously (e.g. iPad split screen),
    ///   This method returns the key window of current focused window scene
    ///
    /// - Returns: Application key window, nil if not found
    static func danceuiKeyWindow() -> UIWindow? {
        // Find activated key window from UIScene
        var keyWindow: UIWindow?
        let connectedScenes = UIApplication.shared.connectedScenes

        for scene in connectedScenes {
            if scene.activationState == .foregroundActive,
               let windowScene = scene as? UIWindowScene {
                if keyWindow == nil,
                   let foundKeyWindow = _keyWindow(from: windowScene) {
                    keyWindow = foundKeyWindow
                    break
                }
            }
        }

        // Still nil? Add protection, fallback to application delegate window
        // Delegate may not respond to window, so adding protection here
        if keyWindow == nil,
           let delegate = UIApplication.shared.delegate,
           delegate.responds(to: #selector(getter: UIApplicationDelegate.window)),
           let delegateWindow = delegate.window {
            keyWindow = delegateWindow
        }

        return keyWindow
    }

    /// Find key window from given window scene
    /// - Parameter windowScene: Window scene
    /// - Returns: Found key window, nil if none
    private static func _keyWindow(from windowScene: UIWindowScene) -> UIWindow? {
        for window in windowScene.windows {
            if window.isKeyWindow {
                return window
            }
        }

        return nil
    }
}
