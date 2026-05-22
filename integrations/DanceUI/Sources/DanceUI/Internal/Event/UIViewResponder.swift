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

/// Converging the differences between `UIViewResponder` &
/// `UIViewResponder_FeatureGestureContainer`.
@available(iOS 13.0, *)
internal protocol AnyUIViewResponder: ViewResponder {
    
    var hostView: UIView? { get set }
    
    var representedView: UIView? { get set }
    
    var helper: ContentResponderHelper<TrivialContentResponder>! { get set }
    
}

@available(iOS 13.0, *)
internal func makeAnyUIViewResponder() -> AnyUIViewResponder {
    if DanceUIFeature.gestureContainer.isEnable {
        return UIViewResponder_FeatureGestureContainer()
    } else {
        return UIViewResponder()
    }
}

@available(iOS 13.0, *)
internal class UIViewResponder: UnaryViewResponder, FocusResponder, AnyUIViewResponder {

    internal weak var hostView: UIView?

    internal weak var representedView: UIView?

    internal weak var focusAccessibilityNode: AccessibilityNode?

    internal var helper: ContentResponderHelper<TrivialContentResponder>!
    
    internal override var asUIViewResponder: AnyUIViewResponder? {
        self
    }
    
    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {

        let result: ContainsPointsResult

        if let hostView = hostView {
            if hostView.isUserInteractionEnabled {
                var result = helper.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey, children: [])

                if !result.mask.isEmpty {
                    result.priority = max(result.priority, 16)
                }

                return result
            } else {
                result = ContainsPointsResult()
            }

        } else {
            result = ContainsPointsResult()
        }
        
        let superResult = super.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey)
        
        return ContainsPointsResult(mask: result.mask.union(superResult.mask), priority: max(result.priority, superResult.priority), children: children)
    }
    
    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        super.addContentPath(to: &path, in: coordinateSpace, observer: observer)
        if let observer = observer {
            helper.observers.add(observer: observer)
        }
        guard helper.data == nil else {
            return
        }

        var newPath = Path(CGRect(origin: .zero, size: helper.size))
        newPath.convert(to: coordinateSpace, transform: helper.transform)
        path.union(path: newPath)
    }
    
    internal override init() {
        hostView = nil
        representedView = nil
        super.init()
        helper = ContentResponderHelper(identifier: ObjectIdentifier(self))
    }
    
    // MARK: BaseFocusResponder
    
    internal var platformItem : UIFocusItem? {
        focusItem?.platformItem
    }
    
    internal var viewItem : FocusItem.ViewItem? {
        focusItem?.viewItem
    }
    
    internal var prefersDefaultFocus : Bool {
        false
    }

    internal var defaultFocusNamespace : Namespace.ID? {
        nil
    }

    internal var focusGroupID : FocusGroupID? {
        nil
    }

    // MARK: FocusResponder

    internal var focusItem: FocusItem? {
        guard let representedView = representedView else {
            return nil
        }

        if #available(iOS 11.0, *) {
            guard representedView.platformFocusSystem == nil else {
                return FocusItem(item: representedView, responder: self)
            }
        }

        guard representedView.canBecomeFirstResponder else {
            return nil
        }

        return FocusItem(platformResponder: representedView, responder: self)
    }

    // MARK: Responder Node Debug

    internal override var visualDebugID: ObjectIdentifier {
        ObjectIdentifier(self)
    }

    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        [helper.globalGeometry]
    }

}

@available(iOS 13.0, *)
internal class UIViewResponder_FeatureGestureContainer: PlatformViewResponderBase<UIView>, FocusResponder, AnyUIViewResponder {

    internal weak var focusAccessibilityNode: AccessibilityNode?

    internal override var asUIViewResponder: AnyUIViewResponder? {
        self
    }

    internal override var platformViewIsEnabled: Bool {
        if let hostView {
            return hostView.isUserInteractionEnabled
        } else {
            return false
        }
    }


    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        if DanceUIFeature.unifiedHitTesting.isEnable {
            return super.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey)
        } else {
            let result: ContainsPointsResult

            if let hostView = hostView {
                if hostView.isUserInteractionEnabled {
                    var result = helper.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey, children: [])

                    if !result.mask.isEmpty {
                        result.priority = max(result.priority, 16)
                    }

                    return result
                } else {
                    result = ContainsPointsResult()
                }

            } else {
                result = ContainsPointsResult()
            }

            let superResult = super.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey)

            return ContainsPointsResult(mask: result.mask.union(superResult.mask), priority: max(result.priority, superResult.priority), children: children)
        }
    }

    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        super.addContentPath(to: &path, in: coordinateSpace, observer: observer)
        if let observer = observer {
            helper.observers.add(observer: observer)
        }
        guard helper.data == nil else {
            return
        }

        var newPath = Path(CGRect(origin: .zero, size: helper.size))
        newPath.convert(to: coordinateSpace, transform: helper.transform)
        path.union(path: newPath)
    }

    internal override func platformViewHitTest(globalPoint: CGPoint, cacheKey: UInt32?) -> UIView? {
        guard let hostView, let window = hostView.window else {
            return nil
        }
        let localPoint = hostView.convert(globalPoint, from: window)
        let eventProvider = host?.as(CurrentEventProvider.self)
        let hitTestView = hostView.hitTest(localPoint, with: eventProvider?.currentEvent)
        return hitTestView
    }

    internal override init() {
        super.init()
        helper = ContentResponderHelper(identifier: ObjectIdentifier(self))
    }

    // MARK: BaseFocusResponder

    internal var platformItem : UIFocusItem? {
        focusItem?.platformItem
    }

    internal var viewItem : FocusItem.ViewItem? {
        focusItem?.viewItem
    }

    internal var prefersDefaultFocus : Bool {
        false
    }

    internal var defaultFocusNamespace : Namespace.ID? {
        nil
    }

    internal var focusGroupID : FocusGroupID? {
        nil
    }

    // MARK: FocusResponder

    internal var focusItem: FocusItem? {
        guard let representedView = representedView else {
            return nil
        }

        if #available(iOS 11.0, *) {
            guard representedView.platformFocusSystem == nil else {
                return FocusItem(item: representedView, responder: self)
            }
        }

        guard representedView.canBecomeFirstResponder else {
            return nil
        }

        return FocusItem(platformResponder: representedView, responder: self)
    }

    // MARK: Responder Node Debug

    internal override var visualDebugID: ObjectIdentifier {
        ObjectIdentifier(self)
    }

    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        [helper.globalGeometry]
    }
}

@available(iOS 13.0, *)
internal struct TrivialContentResponder: ContentResponder {
    
}
