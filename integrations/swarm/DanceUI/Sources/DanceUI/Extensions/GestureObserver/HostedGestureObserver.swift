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

import MyShims

/// `AnyHostedGestureObserver` is named with any hosted-gesture observer because
/// you only use this class to observe a gesture hosted by DanceUI and this is a
/// type-erasing class of `HostedGestureObserver`.
///
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@objc(DanceUIAnyHostedGestureObserver)
@available(iOS 13.0, *)
open class AnyHostedGestureObserver: UIGestureRecognizer, AnyHostedGestureObserving {
    private enum TouchesEventPhase {
        
        case began
        
        case moved
        
        case ended
        
        case cancelled
        
    }
    
    private final class ProxiedDelegate: UIGestureRecognizerDelegateMiddleMan {
        
        fileprivate override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if otherGestureRecognizer is UIKitGestureRecognizer {
                return true
            }
            return target?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false
        }
        
    }
    
    private var phases: [_AnyGestureID : ObservedGesturePhase<Void>]
    
    private var activeCount: UInt
    
    public override init(target: Any?, action: Selector?) {
        phases = [:]
        activeCount = 0
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }
    
    open override var delegate: UIGestureRecognizerDelegate? {
        get {
            proxiedDelegate
        }
        set {
            if let newValue = newValue {
                installProxiedDelegate(newValue)
            } else {
                uninstallProxiedDelegate()
            }
        }
    }
    
    /// Retain helper
    private var proxiedDelegate: ProxiedDelegate?
    
    @inline(__always)
    private func installProxiedDelegate(_ destination: UIGestureRecognizerDelegate) {
        if let oldProxiedDelegate = proxiedDelegate {
            oldProxiedDelegate.proxiedDelegateCleanUp.removeObserver(self)
        }
        proxiedDelegate = ProxiedDelegate(target: destination)
        destination.proxiedDelegateCleanUp.addObserver(self)
        super.delegate = proxiedDelegate
    }
    
    @inline(__always)
    fileprivate func uninstallProxiedDelegate() {
        proxiedDelegate = nil
        super.delegate = nil
    }
    
    open func _observedValue<AnyValue>(of valueType: AnyValue.Type) -> AnyValue {
        guard let value = Void() as? AnyValue else {
            _danceuiPreconditionFailure("AnyHostedGestureObserver can only receive Void observed value.")
        }
        return value
    }
    
    open func _updateObservedValue<AnyValue>(_ value: AnyValue) {
        
    }
    
    public func _updatePhase(_ phase: ObservedGesturePhase<Void>, forID id: _AnyGestureID) {
        updatePhase(for: phase)
    }
    
    @inline(__always)
    private func resetActiveCount() {
        self.activeCount = 0
    }
    
    /// Reduces updated phases into `UIGestureRecognizer.State` and set it to
    /// the underlying `UIGestureRecognizer` object.
    ///
    private func updatePhase(for phase: ObservedGesturePhase<Void>) {
        let oldState = state
        switch phase {
        case .possible:
            state = oldState
        case .active:
            state = oldState == .possible ? .began : .changed
        case .ended:
            state = .ended
        case .failed:
            state = oldState == .possible ? .failed : .cancelled
        }
    }
    
    private var waitingForReset: Bool = false
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        waitingForReset = true
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        // do nothing just to prevent interface break change.
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            if self.waitingForReset {
                if self.state != .possible {
                    self.state = .ended
                }
                waitingForReset = false
            }
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            if self.waitingForReset {
                if self.state != .possible {
                    self.state = .cancelled
                }
                waitingForReset = false
            }
        }
    }
    
    open override func reset() {
        // do nothing just to prevent interface break change.
    }
    
}

/// `HostedGestureObserver` is named with hosted-gesture observer because
/// you only use this class to observe a gesture hosted by DanceUI.
///
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(iOS 13.0, *)
open class HostedGestureObserver<Value: GestureRecognizerValue>:
    AnyHostedGestureObserver, HostedGestureObserving
{
    open private(set) var value: Value = Value()
    
    open override func reset() {
        super.reset()
        value = Value()
    }
    
    open override func _observedValue<AnyValue>(of valueType: AnyValue.Type) -> AnyValue {
        guard let value = (value as? AnyValue) else {
            /// The following precondition may only be triggered by a mismatch
            /// of
            /// `_GestureRecognizerObserverBasedGestureObserver`'s `observe`
            _danceuiPreconditionFailure("\(_typeName(type(of: self))) can only receive \(_typeName(Value.self)) typed observed value.")
        }
        return value
    }
    
    open override func _updateObservedValue<AnyValue>(_ value: AnyValue) {
        guard let value = value as? Value else {
            return
        }
        
        self.value = value
    }
    
}

@available(iOS 13.0, *)
private final class ProxiedDelegateCleanUp {
    
    fileprivate static var key = "com.DanceUI.GestureObserver.ProxiedDelegateCleanUpKey"
    
    private var observers: [ObjectIdentifier : WeakBox<AnyHostedGestureObserver>]
    
    @inline(__always)
    fileprivate init() {
        self.observers = [:]
    }
    
    @inline(__always)
    fileprivate func addObserver(_ observer: AnyHostedGestureObserver) {
        observers[ObjectIdentifier(observer)] = WeakBox(observer)
    }
    
    @inline(__always)
    fileprivate func removeObserver(_ observer: AnyHostedGestureObserver) {
        observers[ObjectIdentifier(observer)] = nil
    }
    
    deinit {
        /// `ProxiedDelegate` holds a weak reference to its `target`. This
        /// means that the `target` can be set to `nil` when it was
        /// released. But the `ProxiedDelegate` cannot be set to `nil` when
        /// the `target` is released.
        for (_, box) in observers {
            box.base?.uninstallProxiedDelegate()
        }
    }
    
}

@available(iOS 13.0, *)
extension UIGestureRecognizerDelegate {
    
    @inline(__always)
    fileprivate var proxiedDelegateCleanUp: ProxiedDelegateCleanUp {
        let cleanUp: ProxiedDelegateCleanUp
        if let object = objc_getAssociatedObject(self, &ProxiedDelegateCleanUp.key) as? ProxiedDelegateCleanUp {
            cleanUp = object
        } else {
            cleanUp = ProxiedDelegateCleanUp()
            objc_setAssociatedObject(self, &ProxiedDelegateCleanUp.key, cleanUp, .OBJC_ASSOCIATION_RETAIN)
        }
        return cleanUp
    }
    
}
