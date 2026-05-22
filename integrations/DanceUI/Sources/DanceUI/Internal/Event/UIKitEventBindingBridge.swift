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
internal final class UIKitEventBindingBridge: EventBindingBridge,
                                              UIGestureRecognizerDelegate {

    internal var gestureRecognizer: UIKitGestureRecognizer?
    
    internal override init(eventBindingManager: EventBindingManager) {
        assert(!DanceUIFeature.gestureContainer.isEnable)
        self.gestureRecognizer = UIKitGestureRecognizer()
        super.init(eventBindingManager: eventBindingManager)
        self.gestureRecognizer?.delegate = self
    }
    
    internal override func reset(eventSource: EventBindingSource, resetForwardedEventDispatchers: Bool) {
        super.reset(eventSource: eventSource, resetForwardedEventDispatchers: resetForwardedEventDispatchers)
    }

    internal override func source(for type: EventSourceType) -> (any EventBindingSource)? {
        switch type {
        case .platformGestureRecognizer:
            return gestureRecognizer
        default:
            return nil // Other event source type is not implemented.
        }
    }
    
    internal override var eventSources: [EventBindingSource] {
        return gestureRecognizer.map({[$0]}) ?? []
    }
    
    @inline(__always)
    internal func attach(to view: UIView) {
        if let gestureRecognizer {
            view.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer !== self.gestureRecognizer {
            runtimeIssue(type: .error, "gestureRecognizer(_, shouldRequireFailureOf): gestureRecognizer is not equal to self.gestureRecognizer.")
        }

        guard let hostingView = gestureRecognizer.view else {
            runtimeIssue(type: .error, "UIKitGestureRecognizer shall be attached to a view.")
            return false
        }
        
        if otherGestureRecognizer.view?.isDescendant(of: hostingView) != false {
            // true or nil goes to this branch
            // God knows why `otherGestureRecognizer` could have no view.
            return withGestureRecognitionWitness(for: otherGestureRecognizer) { gestureRecognitionWitness, ids in
                !gestureRecognitionWitness.shouldRequireFailureOf.intersection(ids).isEmpty
            } ?? false
        } else {
            if let host = eventBindingManager?.host as? UIKitEventGraphHost {
                let config = host.gestureRecognizerConfiguration
                return config.gestureRecognizersShouldRequireFailureOf.contains(otherGestureRecognizer)
            }
            return false
        }
    }

    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer !== self.gestureRecognizer {
            runtimeIssue(type: .error, "gestureRecognizer(_, shouldBeRequiredToFailBy): gestureRecognizer is not equal to self.gestureRecognizer.")
        }

        guard let hostingView = gestureRecognizer.view else {
            runtimeIssue(type: .error, "UIKitGestureRecognizer shall be attached to a view.")
            return false
        }
        
        if otherGestureRecognizer.view?.isDescendant(of: hostingView) != false {
            // true or nil goes to this branch
            // God knows why `otherGestureRecognizer` could have no view.
            return withGestureRecognitionWitness(for: otherGestureRecognizer) { gestureRecognitionWitness, ids in
                !gestureRecognitionWitness.shouldBeRequiredToFailBy.intersection(ids).isEmpty
            } ?? false
        } else {
            if let host = eventBindingManager?.host as? UIKitEventGraphHost {
                let config = host.gestureRecognizerConfiguration
                return config.gestureRecognizersShouldBeRequiredToFailBy.contains(otherGestureRecognizer)
            }
            return false
        }
    }

    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer !== self.gestureRecognizer {
            runtimeIssue(type: .error, "gestureRecognizer(_, shouldRecognizeSimultaneouslyWith): gestureRecognizer is not equal to self.gestureRecognizer.")
        }

        guard let hostingView = gestureRecognizer.view else {
            runtimeIssue(type: .error, "UIKitGestureRecognizer shall be attached to a view.")
            return false
        }
        
        if otherGestureRecognizer.view?.isDescendant(of: hostingView) != false {
            // true or nil goes to this branch
            // God knows why `otherGestureRecognizer` could have no view.
            return withGestureRecognitionWitness(for: otherGestureRecognizer) { gestureRecognitionWitness, ids in
                !gestureRecognitionWitness.shouldRecognizeSimultaneouslyWith.intersection(ids).isEmpty
            } ?? false
        } else {
            if let host = eventBindingManager?.host as? UIKitEventGraphHost {
                let config = host.gestureRecognizerConfiguration
                return config.gestureRecognizersShouldRecognizeSimultaneouslyWith.contains(otherGestureRecognizer)
            }
            return false
        }
    }

    internal func withGestureRecognitionWitness<R>(for otherGestureRecognizer: UIGestureRecognizer,
                                                   _ body: (GestureRecognitionWitness, Set<GestureID>) -> R) -> R? {
        if DanceUIFeature.gestureContainer.isEnable {
            guard let host = eventBindingManager?.host as? UIKitEventGraphHost else {
                return nil
            }
            guard let gestureRecognitionWitness = host.rootGestureRecognitionWitness else {
                return nil
            }
            guard let gestureRecognizerList = host.gestureRecognizerList else {
                return nil
            }
            guard let ids = gestureRecognizerList.ids(for: otherGestureRecognizer) else {
                return nil
            }

            let retVal = body(gestureRecognitionWitness, ids)
            return retVal
        } else {
            guard let host = eventBindingManager?.host as? ViewRendererHost else {
                return nil
            }
            return host.updateViewGraph { viewGraph in
                return viewGraph.withTransaction {
                    guard let gestureRecognitionWitness = viewGraph.rootGestureRecognitionWitness else {
                        return nil
                    }
                    guard let gestureRecognizerList = viewGraph.gestureRecognizerList else {
                        return nil
                    }
                    guard let ids = gestureRecognizerList.ids(for: otherGestureRecognizer) else {
                        return nil
                    }

                    let retVal = body(gestureRecognitionWitness, ids)
                    return retVal
                }
            }
        }
    }
    
}

@available(iOS 13.0, *)
internal final class UIKitResponderEventBindingBridge: EventBindingBridge, GestureGraphDelegate {
    
    internal override var eventSources: [any EventBindingSource] {
        guard let gestureRecognizer else {
            return []
        }
        return [gestureRecognizer]
    }
    
    private let gestureRecognizer: UIKitResponderGestureRecognizer?
    
    private var actions: [() -> Void] = []
    
    /// - Parameter gestureRecognizer: Since we are unable to backport
    /// UIGestureRecognizerContainer at this moment.
    internal init(eventBindingManager: EventBindingManager, responder: AnyGestureResponder_FeatureGestureContainer, gestureRecognizer: UIKitResponderGestureRecognizer?) {
        assert(DanceUIFeature.gestureContainer.isEnable)
        self.gestureRecognizer = gestureRecognizer
        self.gestureRecognizer?.responder = responder
        super.init(eventBindingManager: eventBindingManager)
        self.gestureRecognizer?.attach(to: self)
    }
    
    internal override init(eventBindingManager: EventBindingManager) {
        _unimplementedInitializer(className: "UIKitResponderEventBindingBridge")
    }

    internal init() {
        _unimplementedInitializer(className: "UIKitResponderEventBindingBridge")
    }
    
    internal func enqueueAction(_ action: @escaping () -> Void) {
        actions.append(action)
    }
    
    /// - Parameter gestureRecognizer: For the debugging purpose.
    @objc
    internal func flushActions(_ gestureRecognizer: UIKitResponderGestureRecognizer) {
        if !actions.isEmpty {
            let actions: [() -> Void]
            (actions, self.actions) = (self.actions, [])
            
            if !Update.hasEnqueuedActionsInTargetedActionOfUIGestureRecognizer {
                Update.hasEnqueuedActionsInTargetedActionOfUIGestureRecognizer = true
            }
            
            Update.enqueueAction {
                for each in actions {
                    each()
                }
            }
        } else {
            if gestureRecognizer.state == .failed {
                gestureRecognizer.reset()
            }
        }
    }
    
    internal override func reset(eventSource: EventBindingSource, resetForwardedEventDispatchers: Bool) {
        super.reset(eventSource: eventSource, resetForwardedEventDispatchers: resetForwardedEventDispatchers)
        self.actions = []
    }
    
    
}

@available(iOS 13.0, *)
extension Update {
    
    internal static fileprivate(set) var hasEnqueuedActionsInTargetedActionOfUIGestureRecognizer: Bool = false
    
}
