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
extension Gesture {
    
    /// Updates the provided gesture state property as the gesture's value
    /// changes.
    ///
    /// Use this callback to update transient UI state as described in
    /// <doc:Adding-Interactivity-with-Gestures>.
    ///
    /// - Parameters:
    ///   - state: A binding to a view's ``GestureState`` property.
    ///   - body: The callback that DanceUI invokes as the gesture's value
    ///     changes. Its `currentState` parameter is the updated state of the
    ///     gesture. The `gestureState` parameter is the previous state of the
    ///     gesture, and the `transaction` is the context of the gesture.
    ///
    /// - Returns: A version of the gesture that updates the provided `state` as
    ///   the originating gesture's value changes, and that resets the `state`
    ///   to its initial value when the users cancels or ends the gesture.
    @inlinable
    public func updating<State>(_ state: GestureState<State>, body: @escaping (Self.Value, inout State, inout Transaction) -> Void) -> GestureStateGesture<Self, State> {
        GestureStateGesture(base: self, state: state, body: body)
    }
    
}


/// A property wrapper type that updates a property while the user performs a
/// gesture and resets the property back to its initial state when the gesture
/// ends.
///
/// Declare a property as `@GestureState`, pass as a binding to it as a
/// parameter to a gesture's ``Gesture/updating(_:body:)`` callback, and receive
/// updates to it. A property that's declared as `@GestureState` implicitly
/// resets when the gesture becomes inactive, making it suitable for tracking
/// transient state.
///
/// Add a long-press gesture to a ``Circle``, and update the interface during
/// the gesture by declaring a property as `@GestureState`:
///
///     struct SimpleLongPressGestureView: View {
///         @GestureState var isDetectingLongPress = false
///
///         var longPress: some Gesture {
///             LongPressGesture(minimumDuration: 3)
///                 .updating($isDetectingLongPress) { currentState, gestureState, transaction in
///                     gestureState = currentState
///                 }
///         }
///
///         var body: some View {
///             Circle()
///                 .fill(self.isDetectingLongPress ? Color.red : Color.green)
///                 .frame(width: 100, height: 100, alignment: .center)
///                 .gesture(longPress)
///         }
///     }
@propertyWrapper
@frozen
@available(iOS 13.0, *)
public struct GestureState<Value> : DynamicProperty {
    
    fileprivate var state: State<Value>
    
    fileprivate let reset: (Binding<Value>) -> Void
    
    /// Creates a view state that's derived from a gesture.
    ///
    /// - Parameter wrappedValue: A wrapped value for the gesture state
    ///   property.
    @_alwaysEmitIntoClient
    public init(wrappedValue: Value) {
        self.init(wrappedValue: wrappedValue, resetTransaction: Transaction())
    }
    
    /// Creates a view state that's derived from a gesture with an initial
    /// value.
    ///
    /// - Parameter initialValue: An initial value for the gesture state
    ///   property.
    @_alwaysEmitIntoClient
    public init(initialValue: Value) {
        self.init(wrappedValue: initialValue, resetTransaction: Transaction())
    }
    
    /// Creates a view state that's derived from a gesture with a wrapped state
    /// value and a transaction to reset it.
    ///
    /// - Parameters:
    ///   - wrappedValue: A wrapped value for the gesture state property.
    ///   - resetTransaction: A transaction that provides metadata for view
    ///     updates.
    public init(wrappedValue: Value, resetTransaction: Transaction) {
        self.state = State(wrappedValue: wrappedValue)
        self.reset = { binding in
            binding.transaction(resetTransaction).wrappedValue = wrappedValue
        }
    }
    
    /// Creates a view state that's derived from a gesture with an initial state
    /// value and a transaction to reset it.
    ///
    /// - Parameters:
    ///   - initialValue: An initial state value.
    ///   - resetTransaction: A transaction that provides metadata for view
    ///     updates.
    @_alwaysEmitIntoClient
    public init(initialValue: Value, resetTransaction: Transaction) {
        self.init(wrappedValue: initialValue, resetTransaction: resetTransaction)
    }
    
    /// Creates a view state that's derived from a gesture with a wrapped state
    /// value and a closure that provides a transaction to reset it.
    ///
    /// - Parameters:
    ///   - wrappedValue: A wrapped value for the gesture state property.
    ///   - reset: A closure that provides a ``Transaction``.
    public init(wrappedValue: Value, reset: @escaping (Value, inout Transaction) -> Void) {
        self.state = State(wrappedValue: wrappedValue)
        self.reset = { binding in
            var bindingWithResetTransation = binding
            let value = bindingWithResetTransation.wrappedValue
            reset(value, &bindingWithResetTransation.transaction)
            bindingWithResetTransation.wrappedValue = wrappedValue
        }
    }
    
    /// Creates a view state that's derived from a gesture with an initial state
    /// value and a closure that provides a transaction to reset it.
    ///
    /// - Parameters:
    ///   - initialValue: An initial state value.
    ///   - reset: A closure that provides a ``Transaction``.
    @_alwaysEmitIntoClient
    public init(initialValue: Value, reset: @escaping (Value, inout Transaction) -> Void) {
        self.init(wrappedValue: initialValue, reset: reset)
    }
    
    /// The wrapped value referenced by the gesture state property.
    public var wrappedValue: Value {
        state.wrappedValue
    }
    
    /// A binding to the gesture state property.
    public var projectedValue: GestureState<Value> {
        self
    }
}

@available(iOS 13.0, *)
extension GestureState where Value : ExpressibleByNilLiteral {
    
    /// Creates a view state that's derived from a gesture with a transaction to
    /// reset it.
    ///
    /// - Parameter resetTransaction: A transaction that provides metadata for
    ///   view updates.
    public init(resetTransaction: Transaction = Transaction()) {
        self.init(wrappedValue: nil, resetTransaction: resetTransaction)
    }
    
    /// Creates a view state that's derived from a gesture with a closure that
    /// provides a transaction to reset it.
    ///
    /// - Parameter reset: A closure that provides a ``Transaction``.
    public init(reset: @escaping (Value, inout Transaction) -> Void) {
        self.init(wrappedValue: nil, reset: reset)
    }
    
}

/// A gesture that updates the state provided by a gesture's updating callback.
///
/// A gesture's ``Gesture/updating(_:body:)`` callback returns a
/// `GestureStateGesture` instance for updating a transient state property
/// that's annotated with the ``GestureState`` property wrapper.
@frozen
@available(iOS 13.0, *)
public struct GestureStateGesture<Base: Gesture, State>: Gesture {
    
    /// The type representing the gesture's value.
    public typealias Value = Base.Value
    
    public typealias Body = Never
    
    /// The originating gesture.
    public var base: Base
    
    /// A value that changes as the user performs the gesture.
    public var state: GestureState<State>
    
    /// The updating gesture containing the originating gesture's value, the
    /// updated state of the gesture, and a transaction.
    public var body: (GestureStateGesture<Base, State>.Value, inout State, inout Transaction) -> Void
    
    /// Creates a new gesture that's the result of an ongoing gesture.
    ///
    /// - Parameters:
    ///   - base: The originating gesture.
    ///   - state: The wrapped value of a ``GestureState`` property.
    ///   - body: The callback that DanceUI invokes as the gesture's value
    ///     changes.
    @inlinable
    public init(base: Base, state: GestureState<State>, body: @escaping (GestureStateGesture<Base, State>.Value, inout State, inout Transaction) -> Void) {
        self.base = base
        self.state = state
        self.body = body
    }
    
    public static func _makeGesture(gesture: _GraphValue<GestureStateGesture<Base, State>>, inputs: _GestureInputs) -> _GestureOutputs<GestureStateGesture<Base, State>.Value> {
        
        var childInputs = inputs
        
        if DanceUIFeature.gestureContainer.isEnable {
            childInputs.options.insert(.hasChangedCallbacks)
        }
        
        let outputs = Base._makeGesture(gesture: gesture[{.of(&$0.base)}], inputs: childInputs)
        
        let phase = GestureStatePhase(gesture: gesture.value, phase: outputs.phase, resetSeed: childInputs.resetSeed, useGestureGraph: childInputs.gestureGraph, reset: GestureReset(), callback: nil)
        
        let wrappedPhase = Attribute(phase)
        wrappedPhase.setFlags([.active, .removable], mask: .reserved)
        
        return outputs.withPhase(wrappedPhase)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct GestureStatePhase<Base: Gesture, State>: ResettableGestureRule, RemovableAttribute {
    
    fileprivate typealias PhaseValue = Base.Value
        
    fileprivate typealias Value = GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var gesture: GestureStateGesture<Base, State>
    
    @Attribute
    fileprivate var phase: GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var resetSeed: UInt32
    
    fileprivate let useGestureGraph: Bool
    
    fileprivate var reset: GestureReset
    
    fileprivate var callback: (() -> Void)?
    
    fileprivate static func willRemove(attribute: DGAttribute) {
        let pointer = UnsafeMutableRawPointer(mutating: attribute.info.body).assumingMemoryBound(to: Self.self)
        pointer.pointee.resetState()
    }
    
    fileprivate static func didReinsert(attribute: DGAttribute) {
        _intentionallyLeftBlank()
    }
    
    internal mutating func updateValue() {
        
        var reset = self.reset
        // closure #1
        let hasReset = resetIfNeeded(&reset) {
            resetState()
        }
        self.reset = reset
        
        guard hasReset else {
            return
        }
        
        switch phase {
        case .possible:
            break
        case let .active(value):
            // closure #2
            let gesture = DGGraphRef.withoutUpdate { self.gesture }
            var binding = gesture.state.state.projectedValue
            
            // closure #3
            callback = {
                gesture.state.reset(binding)
            }
            
            var state = binding.wrappedValue
            
            // closure #4
            enqueueAction {
                gesture.body(value, &state, &binding.transaction)
                binding.wrappedValue = state
            }
        case .failed, .ended:
            resetState()
        }
        
        value = phase
    }
    
    fileprivate mutating func resetState() {
        guard let callback = callback else {
            return
        }
        
        Update.enqueueAction(callback)
        
        self.callback = nil
    }
    
    fileprivate func enqueueAction(_ action: @escaping () -> Void) {
        if useGestureGraph {
            GestureGraph.current.enqueueAction(action)
        } else {
            Update.enqueueAction(action)
        }
    }
    
}
