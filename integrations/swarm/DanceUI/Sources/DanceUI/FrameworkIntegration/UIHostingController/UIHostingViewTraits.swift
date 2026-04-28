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

///
@available(iOS 13.0, *)
public protocol UIHostingViewTraits {
    
    var explicitSafeAreaInsets: EdgeInsets? { get set }
    
    ///
    /// The configuration for the UIGestureRecognizer used for
    /// implementing the gestures in a DanceUI DSL host (
    /// `UIHostingController`, `_UIHostingView` or `UIView` instances
    /// created by `UIHostingConfiguration`.)
    var gestureRecognizerConfiguration: UIHostingGestureRecognizerConfiguration { get set }
    
    ///
    /// Set `true` to use hit-testing logic provided by DanceUI ``View`` that
    /// hosted by this view controller.
    ///
    var _usesContentHitTesting: Bool { get set }
    
    ///
    /// A collection of `UIGestureRecognizer` instances and propagated through a
    /// view hierarchy. Instances in the collection can be accessed with
    /// `@GestureObserver` dynamic property in DanceUI and used as gesture
    /// observer with `Gesture.observed(by:, body:)` modifier.
    ///
    var gestureObservers: GestureObservers { get set }
    
}
