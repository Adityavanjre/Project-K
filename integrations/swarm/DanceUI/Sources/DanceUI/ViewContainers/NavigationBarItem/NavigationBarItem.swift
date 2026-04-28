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

/// A configuration for a navigation bar that represents a view at the top of a
/// navigation stack.
///
/// Use one of the ``TitleDisplayMode`` values to configure a navigation bar
/// title's display mode with the ``View/navigationBarTitleDisplayMode(_:)``
/// view modifier.
@available(macOS, unavailable)
@available(iOS 13.0, *)
public struct NavigationBarItem {
    
    /// A style for displaying the title of a navigation bar.
    ///
    /// Use one of these values with the
    /// ``View/navigationBarTitleDisplayMode(_:)`` view modifier to configure
    /// the title of a navigation bar.
    public enum TitleDisplayMode: Equatable, Hashable {

        /// Inherit the display mode from the previous navigation item.
        case automatic

        /// Display the title within the standard bounds of the navigation bar.
        case inline

        /// Display a large title within an expanded navigation bar.
        case large
        
        @inline(__always)
        internal func toNavigationItemDisplayMode() -> UINavigationItem.LargeTitleDisplayMode {
            switch self {
            case .automatic:
                return .automatic
            case .inline:
                return .never
            case .large:
                return .always
            }
        }

    }
    
    internal struct BarItemStorage {


        internal var leadingView: AnyView?


        internal var trailingView: AnyView?


        internal var environment: EnvironmentValues?

    }


    internal var barItemStorage: BarItemStorage?


    internal var hidesBackButton: Bool

}

@available(iOS 13.0, *)
internal struct NavigationBarItemsKey: HostPreferenceKey {
    
    internal typealias Value = NavigationBarItem.BarItemStorage?
    
    @inline(__always)
    internal static var defaultValue: NavigationBarItem.BarItemStorage? { nil }
    
    internal static func reduce(value: inout NavigationBarItem.BarItemStorage?, nextValue: () -> NavigationBarItem.BarItemStorage?) {
        if value == nil {
            value = nextValue()
        }
        // Really nothing here, just check once if nil
    }
    
}

@available(iOS 13.0, *)
internal struct NavigationBarHiddenKey: HostPreferenceKey {

    internal typealias Value = Bool?
    
    @inline(__always)
    internal static var defaultValue: Bool? { nil }
    
    internal static func reduce(value: inout Bool?, nextValue: () -> Bool?) {
        guard let unwrappedValue = value else {
            value = nextValue()
            return
        }
        value = unwrappedValue || (nextValue() ?? false)
    }
}

@available(iOS 13.0, *)
internal struct NavigationBarBackButtonHiddenKey: HostPreferenceKey {
    
    internal typealias Value = Bool
    
    @inline(__always)
    internal static var defaultValue: Bool { false }
    
    internal static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

@available(iOS 13.0, *)
extension UIBarButtonItem {
    
    internal var isFromDanceUI: Bool {
        guard self.customView == nil else {
            return true
        }
        
        guard let action = self.action else {
            return false
        }
        
        return action == Selector("perform")
    }
}
