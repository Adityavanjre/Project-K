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
internal final class RootViewDelegate: UIHostingViewDelegate {
    
    internal var focusedValuesSeed: VersionSeed = .invalid
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didMoveTo window: UIWindow?) where ViewType : View {
        if window != nil {
            if let viewController = hostingView.viewController {
                viewController.allowedBehaviors.formUnion(.keyboardShortcutManagement)
            }
            DGGraphRef.withoutUpdate {
                hostingView.viewGraph.addPreference(PreferredColorSchemeKey.self)
            }
        } else {
            DGGraphRef.withoutUpdate {
                hostingView.viewGraph.removePreference(PreferredColorSchemeKey.self)
            }
            guard let viewController = hostingView.viewController else {
                return
            }
            viewController.allowedBehaviors.subtract(.keyboardShortcutManagement)
        }
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, willUpdate: inout EnvironmentValues) where ViewType : View {
        // no-operation
        _intentionallyLeftBlank()
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didUpdate: inout EnvironmentValues) where ViewType : View {
        // no-operation
        _intentionallyLeftBlank()
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didChangePreferences preferenceList: PreferenceList) where ViewType : View {
        if let colorScheme = preferenceList[PreferredColorSchemeKey.self].value {
            hostingView.colorScheme = colorScheme
        }
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didChangePlatformItemList: PlatformItemList) where ViewType : View {
        // no-operation
        _intentionallyLeftBlank()
    }
    
}
