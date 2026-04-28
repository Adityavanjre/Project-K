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
internal class PlatformViewResponderBase<ViewType>: ViewResponder {
    
    internal struct PlatformHitTestResult {
        internal var key: UInt32
        internal var globalPoint: CGPoint
        internal weak var hitView: UIView?
    }

    internal weak var hostView: UIView?

    internal weak var representedView: UIView?

    internal var helper: ContentResponderHelper<TrivialContentResponder>!
    
    internal var lastResult: PlatformHitTestResult?
    
    internal weak var preferredFocusableView: UIView?
    
    internal override init() {
        hostView = nil
        representedView = nil
        super.init()
        helper = .init(identifier: ObjectIdentifier(self))
    }
    
    internal var platformViewIsEnabled: Bool {
        hostView != nil
    }
    
    private func hitPlatformView(globalPoint: CGPoint, cacheKey: UInt32?) -> UIView? {
        var shouldHitTest: Bool = true
        if !platformViewIsEnabled {
            shouldHitTest = false
        }
        if let lastResult, let cacheKey, lastResult.key == cacheKey {
            return lastResult.hitView
        } else {
            if shouldHitTest {
                return platformViewHitTest(globalPoint: globalPoint, cacheKey: cacheKey)
            } else {
                return nil
            }
        }
    }
    
    internal override func containsGlobalPoints(_ globalPoints: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        if DanceUIFeature.unifiedHitTesting.isEnable {
            var result = ViewResponder.ContainsPointsResult.passthrough(to: children)
            
            let point = globalPoints.first ?? .zero
            
            let hitView = hitPlatformView(globalPoint: point, cacheKey: cacheKey)
            
            if let hitView {
                guard let hostView else {
                    return result
                }
                result = helper.containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: cacheKey, children: children)
                if !children.isEmpty, !hitView.isDescendant(of: hostView) {
                    result.children = []
                }
            }
            
            if result.mask == .zero /*, !options.contains(.useZDistanceAsPriority)*/ {
                result.priority = 16 // ViewResponder.gestureContainmentPriority
            }
            
            if let cacheKey {
                self.lastResult = PlatformHitTestResult(key: cacheKey, globalPoint: point, hitView: hitView)
            }
            
            return result
        } else {
            return super.containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: cacheKey)
        }
    }
    
    internal var hitTestingHostView : UIView? {
        representedView
    }
    
    internal func platformViewHitTest(globalPoint: CGPoint, cacheKey: UInt32?) -> UIView? {
        nil
    }
    
    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: (any ContentPathObserver)?) {
        helper.addContentPath(to: &path, in: coordinateSpace, observer: observer)
    }
}

internal protocol CurrentEventProvider {
    
    var currentEvent : UIEvent? { get }
    
}
