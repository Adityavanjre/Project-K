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
extension UISplitViewController {
    
    @available(iOS 14.0, *)
    internal subscript(_ column: Column) -> UIViewController? {
        get {
            guard self.style != .unspecified else {
                return nil
            }
            
            return self.viewController(for: column)
        }
        set {
            guard self.style != .unspecified else {
                return
            }
            
            self.setViewController(newValue, for: column)
        }
    }
    
    /// DestinationHostingController
    @objc
    internal func makeDetailNavigationControllerWithRoot(root: UIViewController) -> UINavigationController {
        DanceUINavigationController(rootViewController: root)
    }

    internal subscript(_ column: Any) -> UIViewController? {
        guard #available(iOS 14.0, *),
              let column = column as? Column else {
            return nil
        }
        
        return self[column]
    }
    
    @_transparent
    @inline(__always)
    internal var primaryViewController: UIViewController? {
        get {
            guard #available(iOS 14.0, *) else {
                return nil
            }
            
            return self[.primary]
        }
        set {
            guard #available(iOS 14.0, *) else {
                return
            }
            self[.primary] = newValue
        }
        
    }
    
    @_transparent
    @inline(__always)
    internal var secondaryViewController: UIViewController? {
        get {
            guard #available(iOS 14.0, *) else {
                return nil
            }
            
            return self[.secondary]
        }
        set {
            guard #available(iOS 14.0, *) else {
                return
            }
            self[.secondary] = newValue
        }
    }
    
    @_transparent
    @inline(__always)
    internal var supplementaryViewController: UIViewController? {
        get {
            guard #available(iOS 14.0, *) else {
                return nil
            }
            
            return self[.supplementary]
        }
        set {
            guard #available(iOS 14.0, *) else {
                return
            }
            self[.supplementary] = newValue
        }
    }
    
}
