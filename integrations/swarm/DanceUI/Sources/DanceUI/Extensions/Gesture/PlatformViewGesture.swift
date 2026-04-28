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

internal import DanceUIGraph

@available(iOS 13.0, *)
public protocol PlatformViewGesture {
    
    /// The type representing the gesture's value.
    associatedtype Value
    
    static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value>
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Attaches a platform view gesture to the view with a lower
    /// precedence than gestures defined by the view.
    ///
    /// - Parameters:
    ///    - gesture: A platform view gesture to attach to the view.
    ///    - mask: A value that controls how adding this gesture to the view
    ///      affects other gestures recognized by the view and its subviews.
    ///      Defaults to ``DanceUI/GestureMask/all``.
    ///    - extendedConfigs: Extended configs like conflicts resovling to
    ///      the gesture.
    public func gesture<GestureType: PlatformViewGesture>(
        _ gesture: GestureType,
        including mask: GestureMask = .all,
        extendedConfigs: GestureExtendedConfigs = .init()
    ) -> some View {
        let wrappedGesture = PlatformViewGestureWrapper(platformViewGesture: gesture)
        return self.gesture(wrappedGesture, including: mask, extendedConfigs: extendedConfigs)
            .recognizingPlatformViewGesture()
    }
    
    /// Attaches a platform view gesture to the view to process
    /// simultaneously with gestures defined by the view.
    ///
    /// - Parameters:
    ///    - gesture: A platform view gesture to attach to the view.
    ///    - mask: A value that controls how adding this gesture to the view
    ///      affects other gestures recognized by the view and its subviews.
    ///      Defaults to ``DanceUI/GestureMask/all``.
    ///    - extendedConfigs: Extended configs like conflicts resovling to
    ///      the gesture.
    public func simultaneousGesture<GestureType: PlatformViewGesture>(
        _ gesture: GestureType,
        including mask: GestureMask = .all,
        extendedConfigs: GestureExtendedConfigs = .init()
    ) -> some View {
        let wrappedGesture = PlatformViewGestureWrapper(platformViewGesture: gesture)
        return simultaneousGesture(wrappedGesture, including: mask, extendedConfigs: extendedConfigs)
            .recognizingPlatformViewGesture()
    }
    
    /// Attaches a platform view gesture to the view with a higher
    /// precedence than gestures defined by the view.
    ///
    /// - Parameters:
    ///    - gesture: A platform view gesture to attach to the view.
    ///    - mask: A value that controls how adding this gesture to the view
    ///      affects other gestures recognized by the view and its subviews.
    ///      Defaults to ``DanceUI/GestureMask/all``.
    ///    - extendedConfigs: Extended configs like conflicts resovling to
    ///      the gesture.
    public func highPriorityGesture<GestureType: PlatformViewGesture>(
        _ gesture: GestureType,
        including mask: GestureMask = .all,
        extendedConfigs: GestureExtendedConfigs = .init()
    ) -> some View {
        let wrappedGesture = PlatformViewGestureWrapper(platformViewGesture: gesture)
        return highPriorityGesture(wrappedGesture, including: mask, extendedConfigs: extendedConfigs)
            .recognizingPlatformViewGesture()
    }

}

@available(iOS 13.0, *)
extension View {
    
    fileprivate func recognizingPlatformViewGesture() -> some View {
        modifier(PlatformViewGestureViewModifier())
    }
    
}

@available(iOS 13.0, *)
private struct PlatformViewGestureViewModifier: MultiViewModifier {
    
    fileprivate typealias Body = Never
    
    fileprivate static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var childInputs = inputs
        childInputs.isRecognizingPlatformViewGesture = true
        return body(_Graph(), childInputs)
    }
    
}

@available(iOS 13.0, *)
private struct PlatformViewGestureWrapper<PlatformViewGestureType: PlatformViewGesture>: Gesture {
    
    fileprivate typealias Value = PlatformViewGestureType.Value
    
    fileprivate typealias Body = Never
    
    fileprivate var platformViewGesture: PlatformViewGestureType
    
    fileprivate static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        PlatformViewGestureType._makeGesture(gesture: gesture[{.of(&$0.platformViewGesture)}], inputs: inputs)
    }
    
}

/// Organizes the `-touchesBegan:withEvents`, `-touchesMoved:withEvents`
/// `-touchesEnded:withEvents` and `-touchesCancelled:withEvents` of the
/// uderlying `UIView` of the touched `UIViewRepresentable` or
/// `UIViewControllerRepresentable` to a gesture that can be managed with
/// DanceUI gesture primitives like `View.gesture(_: including:)`,
///  `View.highPriorityGesture(_: including:)` and
///  `View.simultaneousGesture(_: including:)`.
///
/// - Note: Some critial legacy components like YYText handles user
/// gesture by handling raw touches instead of using `UIGestureRecognizer`.
/// This design leave them alone with the DanceUI gesture system. However,
/// with this gesture, you can organize the raw touches handling logic on
/// those views into a DanceUI gesture and put this gesture in DanceUI's
/// gesture system, resolving conflicts with DanceUI gesture primitives.
///
@available(iOS 13.0, *)
public struct UITouchGesture: PlatformViewGesture {
    
    public typealias Value = Void
    
    public init() {
        
    }
    
    public static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        let child = Attribute(Child(gesture: gesture.value))
        return Child.Value._makeGesture(gesture: _GraphValue(child), inputs: inputs)
    }
    
    fileprivate class PlatformViewTouchesDispatchGroup {
        
        fileprivate var view: UIView
        
        fileprivate var touches: Set<UITouch>
        
        @inline(__always)
        fileprivate init(view: UIView, touches: Set<UITouch>) {
            self.view = view
            self.touches = touches
        }
        
    }
    
    fileprivate class UITouchStateType: GestureStateProtocol {
        
        fileprivate var mayHaveDelayedTouchesBegan: Bool = false
        
        fileprivate var hasBeganTouches: Bool = false
        
        /// Gesture container involves true gesture recognizer conflicts.
        /// Cancel shall only be dispatched when touches has been dispatched.
        fileprivate var hasDispatchedTouches: Bool = false
        
        private var cachedViews: [EventID: UIView] = [:]
        
        private var platformViewDispatchGroups: [ObjectIdentifier: PlatformViewTouchesDispatchGroup] = [:]
        
        fileprivate required init() {
            
        }
        
        fileprivate func updatePlatformViewDispatchGroup(for events: [EventID : TouchEvent]) {
            // Haven found further bottleneck in this function.
            // We may introduce cache policy in this function.
            var dispatchGroups: [ObjectIdentifier: PlatformViewTouchesDispatchGroup] = [:]
            
            for (_, event) in events {
                if let platformView = platformView(for: event) {
                    let key = ObjectIdentifier(platformView)
                    
                    if let platformTouch = event.platform {
                        if let index = dispatchGroups.index(forKey: key) {
                            dispatchGroups.values[index].touches.insert(platformTouch)
                        } else {
                            dispatchGroups[key] = PlatformViewTouchesDispatchGroup(view: platformView, touches: [platformTouch])
                        }
                    }
                }
            }
            
            self.platformViewDispatchGroups = dispatchGroups
        }
        
        fileprivate func platformView(for event: TouchEvent) -> UIView? {
            return event.binding?.responder.asUIViewResponder?.representedView
        }
        
        fileprivate func dispatchTouchesBegan() -> () -> Void {
            return { [platformViewDispatchGroups, unowned self] in
                if DanceUIFeature.gestureContainer.isEnable {
                    self.hasDispatchedTouches = true
                }
                for dispatchGroup in platformViewDispatchGroups.values {
                    dispatchGroup.view.touchesBegan(dispatchGroup.touches, with: nil)
                }
            }
        }
        
        fileprivate func dispatchTouchesMoved() -> () -> Void {
            return { [platformViewDispatchGroups] in
                for dispatchGroup in platformViewDispatchGroups.values {
                    dispatchGroup.view.touchesMoved(dispatchGroup.touches, with: nil)
                }
            }
        }
        
        fileprivate func dispatchTouchesEnded() -> () -> Void {
            let needsCompensateTouchesBegan = mayHaveDelayedTouchesBegan && !hasBeganTouches
            return { [platformViewDispatchGroups] in
                if needsCompensateTouchesBegan {
                    for dispatchGroup in platformViewDispatchGroups.values {
                        // Compensate a -touchesBegan:withEvent: if the gesture
                        // needs to dispatch a -touchesEnded:withEvent: without
                        // prior -touchesBegan:withEvent: dispatched.
                        dispatchGroup.view.touchesBegan(dispatchGroup.touches, with: nil)
                    }
                }
                for dispatchGroup in platformViewDispatchGroups.values {
                    dispatchGroup.view.touchesEnded(dispatchGroup.touches, with: nil)
                }
            }
        }
        
        fileprivate func dispatchTouchesCancelled() -> (() -> Void)? {
            guard hasBeganTouches else {
                return nil
            }
            
            return { [platformViewDispatchGroups] in
                for dispatchGroup in platformViewDispatchGroups.values {
                    dispatchGroup.view.touchesCancelled(dispatchGroup.touches, with: nil)
                }
            }
        }
    }
    
    fileprivate struct UITouchCallbacks: GestureCallbacks {
        
        fileprivate typealias StateType = UITouchStateType
        
        fileprivate typealias Value = (mayHaveDelayedTouchesBegan: Bool, events: [EventID : TouchEvent])
        
        /// Never use a stored property here. `StateType` needs to get
        /// current event binding manager dynamically.
        fileprivate static var initialState: StateType {
            StateType()
        }
        
        @inline(__always)
        fileprivate init() {
            
        }
        
        fileprivate func dispatch(phase: GesturePhase<Value>, state: inout StateType) -> (() -> Void)? {
            let phaseValueOrNil = phase.phaseValue
            
            state.mayHaveDelayedTouchesBegan = phaseValueOrNil?.mayHaveDelayedTouchesBegan ?? false
            
            switch phase {
            case .possible:
                return nil
            case .active(let phaseValue):
                if state.hasBeganTouches == false {
                    state.hasBeganTouches = true
                    state.updatePlatformViewDispatchGroup(for: phaseValue.events)
                    return state.dispatchTouchesBegan()
                } else {
                    return state.dispatchTouchesMoved()
                }
            case .ended(let phaseValue):
                state.updatePlatformViewDispatchGroup(for: phaseValue.events)
                return state.dispatchTouchesEnded()
            case .failed:
                return state.dispatchTouchesCancelled()
            }
        }
        
        fileprivate func cancel(state: StateType) -> (() -> Void)? {
            if DanceUIFeature.gestureContainer.isEnable {
                if !state.hasDispatchedTouches {
                    return nil
                }
            }
            
            return state.dispatchTouchesCancelled()
        }
        
    }
    
    fileprivate struct Child: Rule {
        
        @Attribute
        fileprivate var gesture : UITouchGesture
        
        fileprivate var value: _MapGesture<ModifierGesture<CallbacksGesture<UITouchGesture.UITouchCallbacks>, ModifierGesture<DependentGesture<UITouchGesture.UITouchCallbacks.Value>, ModifierGesture<MapGesture<MultiEventListener<TouchEvent>.Value, UITouchGesture.UITouchCallbacks.Value>, MultiEventListener<TouchEvent>>>>, Void> {
            MultiEventListener<TouchEvent>()
                .mapPhase { phase in
                    switch phase {
                    case .possible(let events):
                        return .possible(events.map {(mayHaveDelayedTouchesBegan: false, events: $0)})
                    case .active(let events):
                        return .active((mayHaveDelayedTouchesBegan: true, events: events))
                    case .ended(let events):
                        return .ended((mayHaveDelayedTouchesBegan: true, events: events))
                    case .failed:
                        return .failed
                    }
                }
                .dependency(.pausedUntilFailed)
                .callbacks(UITouchCallbacks())
                .map { _ in
                    Void()
                }
        }
        
    }
    
}
