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
extension UINavigationController {
    
    internal func update<Root: View>(with root: Root, in environment: EnvironmentValues) {
        if #available(iOS 11.0, *) {
            self.navigationBar.prefersLargeTitles = true
        }
        
        guard let firtViewController = self.viewControllers.first,
              let hostingViewController = firtViewController as? UIHostingController<Root> else {
                  let hostingController = UIHostingController(rootView: root)
                  self.viewControllers = [hostingController]
                  return
              }
        
        hostingViewController.rootView = root
        Update.enqueueAction {
            let titleStorage = hostingViewController.host.preferenceValue(keyType: NavigationTitleKey.self)
            guard let title = titleStorage?.title else {
                hostingViewController.navigationItem.title = nil
                return
            }
            
            switch title.storage {
            case .anyTextStorage(_):
                let attributedString = title.resolveString(in: environment, includeDefaultAttributes: false, options: .zero)
                hostingViewController.navigationItem.title = attributedString?.string ?? ""
            case .verbatim(let content):
                hostingViewController.navigationItem.title = content
            }
        }
    }
}
