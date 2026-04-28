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
internal import DanceUIGraph

@available(iOS 13.0, *)
extension Gesture {
    
    @inlinable
    public func observed<GestureRecognizer: UIGestureRecognizer & AnyHostedGestureObserving>(
        by observer: GestureObserver<GestureRecognizer>,
        update: @escaping (ObservedGesturePhase<Value>) -> Void
    ) -> _PlatformGestureRecognizerObservedGesture<Self, GestureRecognizer, Void> {
        _PlatformGestureRecognizerObservedGesture(
            base: self,
            observer: observer,
            update: { phase, _ in update(phase) }
        )
    }
    
    @inlinable
    public func observed<GestureRecognizer: UIGestureRecognizer & HostedGestureObserving>(
        by observer: GestureObserver<GestureRecognizer>,
        update: @escaping (ObservedGesturePhase<Value>, inout GestureRecognizer.Value) -> Void
    ) -> _PlatformGestureRecognizerObservedGesture<Self, GestureRecognizer, GestureRecognizer.Value> {
        _PlatformGestureRecognizerObservedGesture(
            base: self,
            observer: observer,
            update: update
        )
    }
    
}

/// A DanceUI gesture observes another DanceUI gesture with a
/// `UIGestureRecognizer`-based observer.
///
/// - Note: There are some duplicate logics in `_ObservedGesture` and
/// `_PlatformGestureRecognizerObservedGesture`. But before we done dynamic
/// property support in `Gesture`, we cannot ship design like that there is
/// a protocol called `GestureObserver`:
///
/// ```
/// protocol GestureObserver: AnyObject {
/// }
/// ```
///
/// and generalize both closure-based and `UIGestureRecognizer`-based observers
/// with this `GestureObserver` with the following API:
///
/// ```
/// extension Gesture {
///
///     public func observed<Observer: GestureObserver>(by observer: Observer)
///         -> _ObservedGesture<Self>
///
/// }
/// ```
///
/// This is because `Gesture` instance cannot help manage the life-cycle of a
/// given object -- which likes `@StateObject` in `View`.
///
@available(iOS 13.0, *)
public struct _PlatformGestureRecognizerObservedGesture<
    Base: Gesture,
    GestureRecognizer: UIGestureRecognizer & AnyHostedGestureObserving,
    ObserverValue
>: Gesture {
    
    public typealias Value = Base.Value
    
    public typealias Body = Never
    
    public var base: Base
    
    public let observer: GestureObserver<GestureRecognizer>
    
    public let update: (ObservedGesturePhase<Value>, inout ObserverValue) -> Void
    
    public init(base: Base,
                observer: GestureObserver<GestureRecognizer>,
                update: @escaping (ObservedGesturePhase<Value>, inout ObserverValue) -> Void) {
        self.base = base
        self.observer = observer
        self.update = update
    }
    
    private typealias _Body = ModifierGesture<
        GestureRecognizerObserverGesture<Base.Value>,
        ModifierGesture<
            GestureRecognizerGesture<Base.Value>,
            ModifierGesture<
                GestureRecognitionWitnessGesture<Base.Value>,
                PlatformGestureRecognizerObservedGesture<Base, GestureRecognizer, ObserverValue
                >
            >
        >
    >
    
    private var _body: _Body {
        PlatformGestureRecognizerObservedGesture(base: base, observer: observer, update: update)
            .gestureRecognitionWitness(shouldRecognizeSimultaneouslyWith: simultaneousGestureIDs)
            .gestureRecognizer(gestureRecognizer)
            .gestureRecognizerObserver(observer.wrappedValue)
    }
    
    @inline(__always)
    private var simultaneousGestureIDs: Set<GestureID> {
        gestureRecognizer.map({[.identifier(ObjectIdentifier($0))]}) ?? Set()
    }
    
    @inline(__always)
    private var gestureRecognizer: UIGestureRecognizer? {
        observer.wrappedValue
    }
    
    public static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Self.Value> {
        _Body._makeGesture(gesture: gesture[\._body], inputs: inputs)
    }
    
}

@available(iOS 13.0, *)
private struct PlatformGestureRecognizerObservedGesture<
    Base: Gesture,
    GestureRecognizer: UIGestureRecognizer & AnyHostedGestureObserving,
    ObserverValue>: Gesture
{
    
    fileprivate typealias Value = Base.Value
    
    fileprivate typealias Body = Never
    
    fileprivate var base: Base
    
    fileprivate let observer: GestureObserver<GestureRecognizer>
    
    fileprivate let update: (ObservedGesturePhase<Value>, inout ObserverValue) -> Void
    
    @inline(__always)
    fileprivate init(base: Base, observer: GestureObserver<GestureRecognizer>, update: @escaping (ObservedGesturePhase<Value>, inout ObserverValue) -> Void) {
        self.base = base
        self.observer = observer
        self.update = update
    }
    
    fileprivate static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Self.Value> {
        let baseInputs = inputs
        
        let outputs = Base._makeGesture(gesture: gesture[{.of(&$0.base)}], inputs: baseInputs)
        
        let phase = PlatformGestureRecognizerObservingPhase(gesture: gesture.value,
                                                            phase: outputs.phase,
                                                            resetSeed: inputs.resetSeed)
        
        let wrappedPhase = Attribute(phase)
        wrappedPhase.setFlags([.active, .removable], mask: .reserved)
        
        return outputs.withPhase(wrappedPhase)
    }
    
}

@available(iOS 13.0, *)
private struct PlatformGestureRecognizerObservingPhase<
    Base: Gesture,
    GestureRecognizer: UIGestureRecognizer & AnyHostedGestureObserving,
    ObserverValue
>: ResettableGestureRule, RemovableAttribute {
    
    fileprivate typealias PhaseValue = Base.Value
    
    fileprivate typealias Value = GesturePhase<PhaseValue>
    
    private final class Session {
        
        fileprivate var gestureRecognizer: GestureRecognizer?
        
        fileprivate var activeCount: UInt
        
        @inline(__always)
        fileprivate init(gestureRecognizer: GestureRecognizer?) {
            self.gestureRecognizer = gestureRecognizer
            self.activeCount = 0
        }
        
        @inline(__always)
        fileprivate func matches(_ gestureRecognizer: GestureRecognizer?) -> Bool {
            self.gestureRecognizer === gestureRecognizer
        }
        
    }
    
    /// Helps members in `mutating self` to escape.
    @propertyWrapper
    private final class UpdateBox {
        
        fileprivate let id: DGAttribute
        
        fileprivate let gestureRecognizer: GestureRecognizer
        
        fileprivate let action: (ObservedGesturePhase<PhaseValue>, inout ObserverValue) -> Void
        
        @inline(__always)
        fileprivate var wrappedValue: (_ phase: ObservedGesturePhase<PhaseValue>) -> Void {
            update
        }
        
        @inline(__always)
        fileprivate init(id: DGAttribute,
                         gestureRecognizer: GestureRecognizer,
                         action: @escaping (ObservedGesturePhase<PhaseValue>, inout ObserverValue) -> Void) {
            self.id = id
            self.gestureRecognizer = gestureRecognizer
            self.action = action
        }
        
        private func update(_ phase: ObservedGesturePhase<PhaseValue>) {
            var observedValue = gestureRecognizer._observedValue(of: ObserverValue.self)
            action(phase, &observedValue)
            gestureRecognizer._updateObservedValue(observedValue)
            gestureRecognizer._updatePhase(phase.set(Void()), forID: _AnyGestureID(id: id))
        }
        
    }
    
    @Attribute
    fileprivate var gesture: PlatformGestureRecognizerObservedGesture<Base, GestureRecognizer, ObserverValue>
    
    @Attribute
    fileprivate var phase: GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var resetSeed: UInt32
    
    fileprivate var reset: GestureReset
    
    fileprivate var resetCallback: ((PhaseValue?) -> Void)?
    
    private var session: Session?
    
    fileprivate init(gesture: Attribute<PlatformGestureRecognizerObservedGesture<Base, GestureRecognizer, ObserverValue>>,
                     phase: Attribute<GesturePhase<PhaseValue>>,
                     resetSeed: Attribute<UInt32>) {
        self._gesture = gesture
        self._phase = phase
        self._resetSeed = resetSeed
        self.reset = GestureReset()
        self.resetCallback = nil
        self.session = nil
    }
    
    fileprivate static func willRemove(attribute: DGAttribute) {
        let pointer = UnsafeMutableRawPointer(mutating: attribute.info.body).assumingMemoryBound(to: Self.self)
        pointer.pointee.resetObserver(nil)
    }
    
    fileprivate static func didReinsert(attribute: DGAttribute) {
        
    }
    
    fileprivate mutating func updateValue() {
        
        var reset = self.reset
        
        let hasReset = resetIfNeeded(&reset) {
            resetObserver(nil)
        }
        self.reset = reset
        
        guard hasReset else {
            return
        }
        
        let phase = self.phase
        
        defer {
            value = phase
        }
        
        let gesture = DGGraphRef.withoutUpdate { self.gesture }
        
        let observer = gesture.observer
        
        let gestureRecognizerOrNil = observer.wrappedValue
        
        let session = engageSession(gestureRecognizerOrNil)
        
        defer {
            if phase.isTerminal {
                dropSession(session)
            }
        }
        
        guard let gestureRecognizer = session.gestureRecognizer else {
            return
        }
        
        @UpdateBox(id: $gesture.identifier,
                   gestureRecognizer: gestureRecognizer,
                   action: gesture.update)
        var update
        
        self.resetCallback = { phaseValue in
            update(phaseValue.map({.ended($0)}) ?? .failed)
        }
        
        // Observing gesture phase
        // Do not need to dispatch to the underlying UIGestureRecognizer's
        // target-action
        
        switch phase {
        case .possible(let value):
            Update.enqueueAction {
                update(.possible(value))
            }
        case .active(let value):
            Update.enqueueAction {
                update(.active(value))
            }
        case .ended(let value):
            resetObserver(value)
        case .failed:
            resetObserver(nil)
        }
    }
    
    fileprivate mutating func resetObserver(_ phaseValue: PhaseValue?) {
        guard let callback = resetCallback else {
            return
        }
        
        Update.enqueueAction {
            callback(phaseValue)
        }
        
        self.resetCallback = nil
    }
    
    private func update(_ phase: ObservedGesturePhase<PhaseValue>,
                        gestureRecognizer: GestureRecognizer,
                        action: (ObservedGesturePhase<PhaseValue>, inout ObserverValue) -> Void) {
        var observedValue = gestureRecognizer._observedValue(of: ObserverValue.self)
        action(phase, &observedValue)
        gestureRecognizer._updateObservedValue(observedValue)
    }
    
    private mutating func engageSession(_ gestureRecognizer: GestureRecognizer?) -> Session {
        if let session = session {
            if !session.matches(gestureRecognizer) {
            }
            return session
        }
        
        let session = Session(gestureRecognizer: gestureRecognizer)
        self.session = session
        return session
    }
    
    private mutating func dropSession(_ session: Session) {
        if self.session === session {
            self.session = nil
        }
    }
    
}
