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
internal struct StatusBarKey: HostPreferenceKey {
    
    internal struct StatusBar: Equatable {
        
        internal var isHidden: Bool
        
        internal var isAnimated: Bool
    }
    
    internal typealias Value = StatusBar?
    
    internal static var defaultValue: Value {
        nil
    }
    
    internal static func reduce(value: inout Value, nextValue: () -> Value) {
        if value == nil {
            value = nextValue()
        }
    }
}

@available(iOS 13.0, *)
internal struct HostingStatusBarContentKey: HostPreferenceKey {
    
    internal typealias Value = Bool
    
    @inline(__always)
    internal static var defaultValue: Value { false }
    
    internal static func reduce(value: inout Value, nextValue: () -> Value) {
        guard value == false else {
            return
        }
        value = nextValue()
    }
}

@available(iOS 13.0, *)
internal final class UIKitStatusBarBridge<ContentView: View> {
    
    internal var statusBarHidden: Bool
    
    internal var deferToChildViewController: Bool
    
    internal var previousStatusBarSeed: VersionSeed
    
    internal var previousHostingContentSeed: VersionSeed
    
    internal weak var host: _UIHostingView<ContentView>?
    
    internal init() {
        statusBarHidden = false
        deferToChildViewController = false
        previousStatusBarSeed = .invalid
        previousHostingContentSeed = .invalid
        host = nil
    }
    
    internal func addPreferences(to viewGraph: ViewGraph) {
        DGGraphRef.withoutUpdate {
            viewGraph.addPreference(StatusBarKey.self)
        }
        DGGraphRef.withoutUpdate {
            viewGraph.addPreference(HostingStatusBarContentKey.self)
        }
    }
    
    internal func preferencesDidChange(_ preferenceList: PreferenceList) {
        let statusBarValue = preferenceList[StatusBarKey.self]
        let navigationDestinationValue = preferenceList[NavigationDestinationsKey.self]
        if previousStatusBarSeed != statusBarValue.seed {
            
            if !statusBarValue.seed.isVaild ||
                !previousStatusBarSeed.isVaild ||
                navigationDestinationValue.seed != statusBarValue.seed ||
                !navigationDestinationValue.seed.isVaild {
                
                var animated = false
                if let statusBar = statusBarValue.value {
                    statusBarHidden = statusBar.isHidden
                    animated = statusBar.isAnimated
                } else {
                    statusBarHidden = false
                }
                deferToChildViewController = preferenceList.valueIfPresent(for: HostingStatusBarContentKey.self)?.value ?? false
                
                updateStatusBar(animated: animated)
            }
        }
        previousStatusBarSeed = statusBarValue.seed
        previousHostingContentSeed = navigationDestinationValue.seed
    }
    
    internal func updateStatusBar(animated: Bool) {
        guard animated else {
            host!.viewController?.setNeedsStatusBarAppearanceUpdate()
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.host!.viewController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
}
