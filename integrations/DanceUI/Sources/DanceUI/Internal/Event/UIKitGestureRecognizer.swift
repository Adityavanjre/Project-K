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

internal import Resolver
import UIKit
import UIKit.UIGestureRecognizerSubclass

// swift-format-ignore: NoBlockComments
@available(iOS 13.0, *)
internal class UIKitGestureRecognizer: UIGestureRecognizer, EventBindingSource {
    
    internal weak var eventBridge: EventBindingBridge?
    
    internal var initialScale: CGFloat
    
    internal var initialAngle: Angle
    
    internal var gestureCategory: GestureCategory

    internal var lastInheritedPhase: _GestureInputs.InheritedPhase?

    internal var lastState: UIGestureRecognizer.State?

    @objc
    internal init() {
        self.eventBridge = nil
        self.initialScale = 1.0
        self.initialAngle = Angle()
        self.gestureCategory = GestureCategory(rawValue: 0)
        self.lastInheritedPhase = nil
        self.lastState = nil
        
        super.init(target: nil, action: nil)
        
        self.allowedPressTypes = UIPress.PressType.allValues.map { NSNumber(value: $0.rawValue) }
        self.delaysTouchesEnded = false
    }
    
    @objc
    internal init?(coder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIGestureRecognizer override
    
    // MARK: touches
    
    override var state: State {
        get {
            super.state
        }
        set {
            gestureGraphLog("state = \(newValue)")
            super.state = newValue
        }
    }
    
    @objc
    internal override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        gestureGraphLog("BEGAN")
        defer {
            gestureGraphLog("ENDED")
        }
        withCompliantInfoTransformer { transformer in
            for eachTouch in touches {
                let info = transformer.collectCompliantInfo { transformer in
                    [transformer.transformUITouchProperty(.majorRadius(eachTouch.majorRadius))]
                } supplementary: {
                    [CompliantInfo.string(name: .identifier, value: ObjectIdentifier(eachTouch).debugDescription)]
                }
                
                if let info {
                    LogService.info(module: .gesture, keyword: .uiKitGestureRecognizer, "touches-began", info: transformer.buildLogInfo(with: info))
                }
            }
        }
        // gestureGraphLog("[\(Self.self)] [\(#function)]")
        // PerThreadOSCallback.traceInterval("touchesBegan", identifier: signpostIdentifier) {
            send(touches: touches, event: event, phase: .active)
        // }
    }
    
    @objc
    internal override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        gestureGraphLog("BEGAN")
        defer {
            gestureGraphLog("ENDED")
        }
        gestureGraphLog()
        // gestureGraphLog("[\(Self.self)] [\(#function)]")
        // PerThreadOSCallback.traceInterval("touchesMoved", identifier: signpostIdentifier) {
            send(touches: touches, event: event, phase: .active)
        // }
    }
    
    @objc
    internal override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        gestureGraphLog("BEGAN")
        defer {
            gestureGraphLog("ENDED")
        }
        // gestureGraphLog("[\(Self.self)] [\(#function)]")
        // PerThreadOSCallback.traceInterval("touchesEnded", identifier: signpostIdentifier) {
            send(touches: touches, event: event, phase: .ended)
        // }
    }
    
    @objc
    internal override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        gestureGraphLog("BEGAN")
        defer {
            gestureGraphLog("ENDED")
        }
        // gestureGraphLog("[\(Self.self)] [\(#function)]")
        // PerThreadOSCallback.traceInterval("touchesCancelled", identifier: signpostIdentifier) {
            send(touches: touches, event: event, phase: .failed)
        // }
    }
    // TODO: internal override func my_hoverEntered(_ touches: Set<UITouch>, with event: UIEvent)
    
    // TODO: internal override func my_hoverMoved(_ touches: Set<UITouch>, with event: UIEvent)
    
    // TODO: internal override func my_hoverExited(_ hovers: Set<UITouch>, with event: UIEvent)
    
    // TODO: internal override func my_hoverCancelled(_ hovers: Set<UITouch>, with event: UIEvent)
    
    @objc
    internal override func reset() {
        let eventBridgeLives = eventBridge != nil
        gestureGraphLog("event bridge lives: \(eventBridgeLives)")
        eventBridge?.reset(eventSource: self, resetForwardedEventDispatchers: false)
        if DanceUIFeature.gestureContainer.isEnable {
            self.lastInheritedPhase = nil
        }
    }
    
    internal override func my_transformChanged(with event: UIEvent) {
        _missingImplementationCheckpoint(())
    }
    
    private func send(touches: Set<UITouch>, event: UIEvent, phase: EventPhase) {
        let events = convert(touches: touches, with: event, phase: phase)
        gestureGraphLog()
        eventBridge?.send(events, source: self)
    }
    
    private func convert(touches: Set<UITouch>, with event: UIEvent, phase: EventPhase) -> [EventID : TouchEvent] {
        var result: [EventID: TouchEvent] = [:]
        
        touches.forEach { touch in
            let value = makeTouchEvent(touch, for: phase)
            let key = EventID(type: DanceUITransformEvent.self, serial: Int(bitPattern: ObjectIdentifier(touch)))
            result[key] = value
        }
        
        return result
    }
    
    private func makeTouchEvent<Touch: UIKitTouch>(_ touch: Touch, for phase: EventPhase) -> TouchEvent {
        let radius = DanceUIFeature.fixedUITouchMajorRadius.isEnable ? defaultMajorRadius : touch.majorRadius
        
        return TouchEvent(
            timestamp: touch.timestamp.toTime(),
            phase: phase,
            binding: nil,
            location: .zero,
            globalLocation: touch.location(in: nil),
            radius: radius,
            force: Double(touch.force),
            maximumPossibleForce: Double(touch.maximumPossibleForce),
            platform: touch.platform
        )
    }
    
    #if DEBUG
    internal func testableMakeTouchEvent<Touch: UIKitTouch>(_ touch: Touch, for phase: EventPhase) -> TouchEvent {
        makeTouchEvent(touch, for: phase)
    }
    #endif
    
    internal func `as`<A1>(_ otherType: A1.Type) -> A1? {
        if ObjectIdentifier(otherType) == ObjectIdentifier(UIGestureRecognizer.self) {
            return unsafeBitCast(self, to: A1.self)
        }
        return nil
    }
    
    internal func didUpdate(phase: GesturePhase<Void>, in: EventBindingBridge) {
        let nextState = self.state.nextState(for: phase)
        self.state = nextState
        self.lastState = nextState
    }
    
    internal func didUpdate(gestureCategory: GestureCategory, in: EventBindingBridge) {
        self.gestureCategory = gestureCategory
    }
    
    internal func attach(to bridge: EventBindingBridge) {
        self.eventBridge = bridge
        didAttach(to: bridge)
    }
    
    internal func didAttach(to bridge: EventBindingBridge) {
        _intentionallyLeftBlank()
    }
    
#if DEBUG
    internal static var gestureRecognizerLogEnabled: Bool {
        EnvValue.isGestureRecognizerLogEnabled
    }
#endif

    internal func gestureGraphLog(_ message: @autoclosure () -> String, _ function: StaticString = #function) {
#if DEBUG
        if Self.gestureRecognizerLogEnabled {
            print("[\(_typeName(type(of: self), qualified: false))] [\(function)] [\(Unmanaged.passUnretained(self).toOpaque())] [\(name ?? "anonymous")] \(message())")
        }
#endif
    }
    
    internal func gestureGraphLog(_ function: StaticString = #function) {
#if DEBUG
        if Self.gestureRecognizerLogEnabled {
            print("[\(_typeName(type(of: self), qualified: false))] [\(Unmanaged.passUnretained(self).toOpaque())] [\(function)] [\(name ?? "anonymous")]")
        }
#endif
    }
    
}

// A protocol to make testing easy
internal protocol UIKitTouch {
    
    var timestamp: TimeInterval { get }
    
    var majorRadius: CGFloat { get }
    
    var force: CGFloat { get }
    
    var maximumPossibleForce: CGFloat { get }
    
    func location(in view: UIView?) -> CGPoint
    
    var platform: UITouch? { get }
    
}

extension UITouch: UIKitTouch {
    
    var platform: UITouch? {
        self
    }
    
}

/// Read from iPhone simulator.
internal let defaultMajorRadius: CGFloat = 20

/// private final class from UIKit
/// Just used for ID
@available(iOS 13.0, *)
internal final class DanceUITransformEvent {

    init() {
        _danceuiFatalError()
    }

}

@available(iOS 13.0, *)
extension CompliantInfoName {
    
    fileprivate static let identifier = CompliantInfoName("identifier")
    
}

@available(iOS 13.0, *)
internal enum GestureLogKeyword: String, LogKeyword {
    
    case uiKitGestureRecognizer = "UIKitGestureRecognizer"
    
    case uiKitResponderGestureRecognizer = "UIKitResponderGestureRecognizer"
    
    case responder = "Responder"
    
    case hitTest = "HitTest"
    
    internal static var moduleName: String { "Gesture" }
    
}

@available(iOS 13.0, *)
extension LogService.Module where K == GestureLogKeyword {
    
    internal static let gesture: Self = .init()
    
}

@available(iOS 13.0, *)
extension UIGestureRecognizer.State {
    
    internal func nextState(for phase: GesturePhase<Void>) -> UIGestureRecognizer.State {
        if DanceUIFeature.gestureContainer.isEnable {
            switch phase {
            case .possible:
                return .possible
                
            case .active:
                return self == .possible ? .began : .changed
                
            case .ended:
                return .ended
                
            case .failed:
                if self == .possible || self == .failed {
                    return .failed
                } else {
                    return .cancelled
                }
            @unknown default:
                fatalError("Unknown gesture phase")
            }
        } else {
            switch phase {
            case .possible:
                return self
            case .active:
                return self == .possible ? .began : .changed
            case .ended:
                return .ended
            case .failed:
                return self == .possible ? .failed : .cancelled
            @unknown default:
                fatalError("Unknown gesture phase")
            }
        }
    }
    
}

@available(iOS 13.0, *)
internal class UIKitResponderGestureRecognizer: UIKitGestureRecognizer {
    
    internal weak var responder: AnyGestureResponder_FeatureGestureContainer?
    
    internal override init() {
        super.init()
        gestureGraphLog()
    }
    
    internal override init?(coder: NSCoder) {
        nil
    }
    
    internal override func didAttach(to bridge: EventBindingBridge) {
        self.addTarget(bridge, action: #selector(UIKitResponderEventBindingBridge.flushActions))
    }
    
    internal override var name: String? {
        get {
            guard let responder else {
                return super.name
            }
            
            if let label = Update.ensure({
                return responder.label
            }) {
                return label
            }
            
            return _typeName(responder.gestureType, qualified: false)
        }
        set {
            super.name = newValue
        }
    }
    
    internal override func canPrevent(_ other: UIGestureRecognizer) -> Bool {
        gestureGraphLog("\(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
        guard let responder = self.responder else {
            let result = super.canPrevent(other)
            gestureGraphLog(" > \(result) : super.canPrevent since no responder,: \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            return result
        }
        
        if let other = other as? UIKitResponderGestureRecognizer,
           let otherResponder = other.responder {
            gestureGraphLog(" | \(Self.myTypeName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            
            let otherPolicy = otherResponder.exclusionPolicy
            
            gestureGraphLog(" | \(Self.myTypeName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") exclusionPolicy: \(responder.exclusionPolicy)")
            gestureGraphLog(" | \(Self.myTypeName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") isCompanionGesture: \(responder.isCompanionGesture)")
            gestureGraphLog(" | \(Self.myTypeName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") otherExclusionPolicy: \(otherPolicy)")
            gestureGraphLog(" | \(Self.myTypeName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") otherIsCompanionGesture: \(otherResponder.isCompanionGesture)")
            
            let result = responder.canPrevent(otherResponder, otherExclusionPolicy: otherPolicy, isCompanionGesture: otherResponder.isCompanionGesture)
            
            gestureGraphLog(" > \(result) : responder.canPrevent \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            return result
        } else if let hostingScrollView = other.view as? HostingScrollView, let scrollViewResponder = hostingScrollView.responder, other === hostingScrollView.panGestureRecognizer {
            gestureGraphLog(" | \(Self.hostingScrollName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            
            gestureGraphLog(" | \(Self.hostingScrollName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") : responder.isCancellable \(responder.isCancellable)")
            gestureGraphLog(" | \(Self.hostingScrollName) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") : responder.exclusionPolicy \(responder.exclusionPolicy)")
            
            let policy: GestureResponderExclusionPolicy = responder.isCancellable ? .simultaneous : .default
            
            let result = responder.canPrevent(scrollViewResponder, otherExclusionPolicy: policy)
            gestureGraphLog(" > \(result) : responder.canPrevent \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            return result
        } else if let scrollView = other.view as? UIScrollView, let viewResponder = (scrollView.superview as? AnyPlatformViewHost)?.responder, other === scrollView.panGestureRecognizer {
            gestureGraphLog(" | UIScrollView in UIViewRepresentable \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            
            gestureGraphLog(" | UIScrollView \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") : responder.isCancellable \(responder.isCancellable)")
            gestureGraphLog(" | UIScrollView \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil") : responder.exclusionPolicy \(responder.exclusionPolicy)")
            
            let policy: GestureResponderExclusionPolicy = responder.isCancellable ? .simultaneous : .default
            
            let result = responder.canPrevent(viewResponder, otherExclusionPolicy: policy)
            gestureGraphLog(" > \(result) : responder.canPrevent \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            return result
        } else if responder.isCancellable || responder.exclusionPolicy == .highPriority || !other.isCancallingGesture {
            gestureGraphLog(" | General \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            
            if responder.exclusionPolicy == .simultaneous {
                gestureGraphLog(" > false : responder.exclusionPolicy == simultaneous \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
                return false
            }
            
            if let isPrioritized = responder.isPrioritized(over: other) {
                gestureGraphLog(" > \(isPrioritized) : responder.isPrioritized \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
                return isPrioritized
            }
            
            if isKindOfUITextFieldTapGesture(other) {
                gestureGraphLog(" > false : is \(type(of: other)) \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
                return false
            }
            
            let result = super.canPrevent(other)
            gestureGraphLog(" > \(result) : super.canPrevent \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            return result
        } else {
            gestureGraphLog(" | Final \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            gestureGraphLog(" > false \(type(of: self)) -> \(type(of: other)) \(self.name ?? "nil") -> \(other.name ?? "nil")")
            return false
        }
    }
    
    internal override func canBePrevented(by otherGesture: UIGestureRecognizer) -> Bool {
        gestureGraphLog("\(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
        guard let responder = self.responder else {
            // Fallback: no responder, defer to UIKit superclass
            let result = super.canBePrevented(by: otherGesture)
            gestureGraphLog(" > no responder, super.canBePrevented -> \(result) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            return result
        }

        if let other = otherGesture as? UIKitResponderGestureRecognizer,
           let otherResponder = other.responder {
            gestureGraphLog(" | other is \(type(of: self)) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")

            let selfPolicy = responder.exclusionPolicy
            let otherPolicy = otherResponder.exclusionPolicy
            gestureGraphLog(" | selfPolicy: \(selfPolicy), otherPolicy: \(otherPolicy) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")

            let result = otherResponder.canPrevent(responder, otherExclusionPolicy: selfPolicy)
            gestureGraphLog(" > \(result) : responder.canPrevent \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            return result
        } else {
            
            if responder.exclusionPolicy == .simultaneous {
                gestureGraphLog(" > false : responder.exclusionPolicy == .simultaneous \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
                return false
            }
            
            // Priority comparison (returns Bool?)
            if let prioritized = responder.isPrioritized(over: otherGesture) {
                let result = !prioritized
                gestureGraphLog(" > \(result) : responder.isPrioritized \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
                return result
            }
            
            gestureGraphLog(" | isPrioritized is nil \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")

            // If isPrioritized returned nil, fallback to superclass
            let result = super.canBePrevented(by: otherGesture)
            gestureGraphLog(" > \(result) : fallback to super.canBePrevented \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            return result
        }
    }
    
    internal override func shouldRequireFailure(of otherGesture: UIGestureRecognizer) -> Bool {
        gestureGraphLog("\(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
        
        
        guard let responder = self.responder else {
            gestureGraphLog(" | no self.responder \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            let result = super.shouldRequireFailure(of: otherGesture)
            gestureGraphLog(" > \(result) : super.shouldRequireFailure(of:) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            return result
        }
        
        if let other = otherGesture as? UIKitResponderGestureRecognizer,
           let otherResponder = other.responder {
            gestureGraphLog(" | found other.responder \(Self.myTypeName) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            let result = responder.shouldRequireFailure(of: otherResponder)
            gestureGraphLog(" > \(result) : responder.shouldRequireFailure(of:) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            return result
        } else if responder.isCancellable {
            // Special-case: UIScrollViewDelayedTouchesBeganGestureRecognizer always requires failure
            if let t = NSClassFromString(Self.scrollViewDelayedTouchesBeganName), ObjectIdentifier(type(of: otherGesture)) == ObjectIdentifier(t) {
                gestureGraphLog(" > true : \(Self.scrollViewDelayedTouchesBeganName) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
                return true
            }
            
            // Otherwise, inspect the name
            if let name = otherGesture.name {
                if isUISwitchLongPressGestureName(name) {
                    gestureGraphLog(" > true : \(name) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
                    return true
                }
            }
        }
        
        // Fallback to UIKit logic
        let result = super.shouldRequireFailure(of: otherGesture)
        gestureGraphLog(" > \(result) : super.shouldRequireFailure(of:) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
        
        return result
    }
    
    internal override func shouldBeRequiredToFail(by otherGesture: UIGestureRecognizer) -> Bool {
        gestureGraphLog("\(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
        
        guard let responder = self.responder else {
            let result = super.shouldBeRequiredToFail(by: otherGesture)
            gestureGraphLog(" > \(result) : super.shouldBeRequiredToFail(by:) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            return result
        }
        
        if let other = otherGesture as? UIKitResponderGestureRecognizer,
           let otherResponder = other.responder {
            let result = otherResponder.shouldRequireFailure(of: responder)
            gestureGraphLog(" > \(result) : otherResponder.shouldRequireFailure(of:) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
            return result
        }
        
        // Fallback to UIKit behavior
        let result = super.shouldBeRequiredToFail(by: otherGesture)
        gestureGraphLog(" > \(result) : super.shouldBeRequiredToFail(by:) \(type(of: self)) -> \(type(of: otherGesture)) \(self.name ?? "nil") -> \(otherGesture.name ?? "nil")")
        
        return result
    }
    
#if DEBUG
    // @available(iOS 13.4, *)
    // internal override func buttonMaskRequired() -> UIEvent.ButtonMask
    
    // internal override func numberOfTapsRequired() -> Int
    
    // internal override func numberOfTouchesRequired() -> Int
    
    // internal override func _gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, canBeCancelledBy another: UIGestureRecognizer) -> Bool
#endif
    
    @available(iOS 13.4, *)
    @objc
    internal var buttonMaskRequired: UIEvent.ButtonMask {
        .secondary
    }
    
    @objc
    internal var numberOfTapsRequired: Int {
        return 1
    }
    
    @objc
    internal var numberOfTouchesRequired: Int {
        return 1
    }
    
    internal override func _myShims__isGestureType(_ type: Int) -> Bool {
        // 0: tap gesture
        guard type == 0 else {
            return false
        }
        guard let responder else {
            return false
        }
        return responder.requiredTapCount == 1
    }
    
    internal override func isKind(of type: AnyObject.Type) -> Bool {
        if type === UITapGestureRecognizer.self {
            if let tapCount = responder?.requiredTapCount {
                return true
            }
        }
        return super.isKind(of: type)
    }
    
}

extension UIGestureRecognizer {
    
    fileprivate var isCancallingGesture: Bool {
        if let name {
            return isCancellingGestureName(name)
        }
        return type(of: self) == UIPanGestureRecognizer.self
    }
    
    internal static let myTypeName: String = {
        ["UIKit", "Responder", "GestureRecognizer"].joined()
    }()
    
    internal static let scrollViewDelayedTouchesBeganName: String = {
        ["UI", "ScrollView", "Delayed", "Touches", "Began", "GestureRecognizer"].joined()
    }()
    
    internal static let hostingScrollName: String = {
        ["Hosting", "ScrollView"].joined()
    }()
    
}

@available(iOS 13.0, *)
public protocol DanceUIGestureDynamicInfo {
        
    var cancellingGestureNames: Set<String> { get }

    var uiSwitchLongPressGestureNames: Set<String> { get }

    var uiTextFieldTapGestureClassNames: Set<String> { get }

}

private let dynamicInfo: DanceUIGestureDynamicInfo? = {
    Resolver.services.optional(DanceUIGestureDynamicInfo.self)
}()

private func isCancellingGestureName(_ name: String) -> Bool {
    struct Static {
        static var predefinedNames: Set<String> = [
            ["com", "apple", "UIKit", "dragInitiation"].joined(separator: "."),
            ["com", "apple", "UIKit", "clickPresentationExclusion"].joined(separator: "."),
            ["com", "apple", "UIKit", "dragExclusionRelationships"].joined(separator: "."),
        ]
    }
    let dynamicNames = dynamicInfo?.cancellingGestureNames ?? []
    let predefinedNames = Static.predefinedNames
    let names = dynamicNames.union(predefinedNames)
    return names.contains(name)
}

private func isUISwitchLongPressGestureName(_ name: String) -> Bool {
    struct Static {
        static let predefinedName: String = {
            ["UISwitch", "longPress"].joined(separator: "-")
        }()
    }
    let dynamicNames = dynamicInfo?.uiSwitchLongPressGestureNames ?? []
    let predefinedNames = Set([Static.predefinedName])
    let names = dynamicNames.union(predefinedNames)
    return names.contains(name)
}

private func isKindOfUITextFieldTapGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    struct Static {
        static let predefinedClass: String = {
            ["UI", "Text", "Multi", "Tap", "Recognizer"].joined()
        }()
    }
    
    let dynamicClasses = dynamicInfo?.uiTextFieldTapGestureClassNames ?? []
    let predefinedClasses = Set([Static.predefinedClass])
    let names = dynamicClasses.union(predefinedClasses)
    for eachClass in names.compactMap(NSClassFromString) {
        if gestureRecognizer.isKind(of: eachClass) {
            return true
        }
    }
    
    return false
}

@available(iOS 13.0, *)
extension AnyGestureResponder_FeatureGestureContainer {
    
    fileprivate func isPrioritized(over other: UIGestureRecognizer) -> Bool? {
        let typeTag = 2
        var isLongPress: Bool {
            guard typeTag == 2 else {
                return false
            }
            
            // Try to get the `view` from the associated UIGestureRecognizer
            guard let name = other.name else {
                return false
            }
            
            // Check if the name matches "UISwitch-longPress"
            return isUISwitchLongPressGestureName(name)
        }
        
        guard exclusionPolicy == .highPriority || isLongPress else {
            gestureGraphLog("self.exclusionPolicy != .highPriority && !isLongPress")
            return nil
        }
        if exclusionPolicy == .highPriority {
            gestureGraphLog("exclusionPolicy == .highPriority")
        }
        if isLongPress {
            gestureGraphLog("isLongPress")
        }
        
        guard let otherGestureView = other.view, let container = self.gestureContainer else {
            gestureGraphLog("other.view == nil || self.gestureContainer == nil")
            return nil
        }
        
        gestureGraphLog("other.view != nil & self.gestureContainer != nil")
        
        let result = danceUIViewHierarchyOrderCompare(container, otherGestureView)
        
        if isLongPress {
            gestureGraphLog("isLongPress == true")
            if result == .orderedAscending {
                gestureGraphLog("result == .orderedAscending")
                return false
            } else {
                gestureGraphLog("result != .orderedAscending")
                return nil
            }
        } else {
            gestureGraphLog("isLongPress == false")
            if result == .orderedAscending {
                gestureGraphLog("result == .orderedAscending")
                return true
            } else {
                gestureGraphLog("result != .orderedAscending")
                return nil
            }
        }
    }
    
    internal func gestureGraphLog(_ message: @autoclosure () -> String, _ function: StaticString = #function) {
#if DEBUG
        if UIKitGestureRecognizer.gestureRecognizerLogEnabled {
            print("[\(_typeName(type(of: self), qualified: false))] [\(function)] [\(Unmanaged.passUnretained(self).toOpaque())] \(message())")
        }
#endif
    }
    
    internal func gestureGraphLog(_ function: StaticString = #function) {
#if DEBUG
        if UIKitGestureRecognizer.gestureRecognizerLogEnabled {
            print("[\(_typeName(type(of: self), qualified: false))] [\(Unmanaged.passUnretained(self).toOpaque())] [\(function)]")
        }
#endif
    }
    
}

internal func danceUIViewHierarchyOrderCompare(_ lhs: UIView, _ rhs: UIView) -> ComparisonResult {
    if lhs === rhs {
        return .orderedSame
    }
    
    // Helper to walk up the superview chain
    func isAncestor(_ ancestor: UIView, of descendant: UIView) -> Bool {
        var view = descendant.superview
        while let v = view {
            if v === ancestor {
                return true
            }
            view = v.superview
        }
        return false
    }
    
    if isAncestor(lhs, of: rhs) {
        return .orderedAscending
    }
    
    if isAncestor(rhs, of: lhs) {
        return .orderedDescending
    }
    
    // Get the ancestor chains
    func superviewChain(_ view: UIView) -> [UIView] {
        var result: [UIView] = []
        var current: UIView? = view
        while let v = current {
            result.append(v)
            current = v.superview
        }
        return result.reversed()  // from root down to view
    }
    
    let lhsChain = superviewChain(lhs)
    let rhsChain = superviewChain(rhs)
    
    let count = min(lhsChain.count, rhsChain.count)
    var commonAncestor: UIView?
    
    for i in 0..<count {
        if lhsChain[i] === rhsChain[i] {
            commonAncestor = lhsChain[i]
        } else {
            break
        }
    }
    
    if let ancestor = commonAncestor {
        // Find immediate children of the common ancestor
        let lhsIndex = ancestor.subviews.firstIndex(of: lhs)
        let rhsIndex = ancestor.subviews.firstIndex(of: rhs)

        if let lhsIndex = lhsIndex, let rhsIndex = rhsIndex {
            if lhsIndex < rhsIndex {
                return .orderedAscending
            } else if lhsIndex > rhsIndex {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }
    
    return .orderedSame
}

@available(iOS 13.0, *)
private struct UIKitGestureRecognizerLogEnabledKey: DefaultFalseBoolEnvKey {
    
    static var raw: String {
        "DANCEUI_PRINT_GESTURE_LOGS"
    }
}

@available(iOS 13.0, *)
extension EnvValue where K == UIKitGestureRecognizerLogEnabledKey {
    
    private static let store: Self = .init()
    
    fileprivate static var isGestureRecognizerLogEnabled: Bool {
        store.value
    }
}
