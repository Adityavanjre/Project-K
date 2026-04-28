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

/// A gesture that recognizes a magnification motion and tracks the amount of
/// magnification.
///
/// A magnification gesture tracks how a magnification event sequence changes.
/// To recognize a magnification gesture on a view, create and configure the
/// gesture, and then add it to the view using the
/// ``View/gesture(_:including:)`` modifier.
///
/// Add a magnification gesture to a ``Circle`` that changes its size while the
/// user performs the gesture:
///
///     struct MagnificationGestureView: View {
///
///         @GestureState var magnifyBy = 1.0
///
///         var magnification: some Gesture {
///             MagnificationGesture()
///                 .updating($magnifyBy) { currentState, gestureState, transaction in
///                     gestureState = currentState
///                 }
///         }
///
///         var body: some View {
///             Circle()
///                 .frame(width: 100, height: 100)
///                 .scaleEffect(magnifyBy)
///                 .gesture(magnification)
///         }
///     }
///
/// The circle's size resets to its original size when the gesture finishes.
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(iOS 13.0, *)
public struct MagnificationGesture: PrimitiveGesture {
    
    /// The type of gesture representing the body of `Self`.
    public typealias Body = Never

    /// The type representing the gesture's value.
    public typealias Value = CGFloat
    
    private typealias _Body = _MapGesture<
        SimultaneousGesture<
            TransformBasedMagnifyGesture,
            TouchBasedMagnifyGesture
        >,
        CGFloat
    >

    /// The minimum required delta before the gesture starts.
    public var minimumScaleDelta: CGFloat
    
    private var gesture: _Body
    

    /// Creates a magnification gesture with a given minimum delta for the
    /// gesture to start.
    ///
    /// - Parameter minimumScaleDelta: The minimum scale delta required before
    ///   the gesture starts.
    public init(minimumScaleDelta: CGFloat = 0.01) {
        self.minimumScaleDelta = minimumScaleDelta
        
        let transformGesture = TransformBasedMagnifyGesture(minimumScaleDelta: minimumScaleDelta)
        let touchGesture = TouchBasedMagnifyGesture(minimumScaleDelta: minimumScaleDelta)
        self.gesture = transformGesture
            .simultaneously(with: touchGesture)
            .map { simultaneousGesture -> Value in
                simultaneousGesture.first ?? simultaneousGesture.second!
            }
    }
    
    public static func _makeGesture(gesture: _GraphValue<MagnificationGesture>, inputs: _GestureInputs) -> _GestureOutputs<CGFloat> {
        _Body._makeGesture(gesture: gesture[{ .of(&$0.gesture) }], inputs: inputs)
    }
}

@available(iOS 13.0, *)
fileprivate struct TouchBasedMagnifyGesture: PrimitiveGesture {
    
    fileprivate typealias Value = CGFloat
    
    private typealias _Body = ModifierGesture<
        StateContainerGesture<
            StateType,
            (DragGesture.Value, DragGesture.Value),
            CGFloat
        >,
        _MapGesture<
            TupleGesture<
                DragGesture,
                TupleGesture<DragGesture, EmptyTupleGesture>
            >,
            (DragGesture.Value, DragGesture.Value)
        >
    >
    
    private var minimumScaleDelta: CGFloat
    
    fileprivate init(minimumScaleDelta: CGFloat) {
        self.minimumScaleDelta = minimumScaleDelta
    }
    
    private var _body: _Body {
        let dragGesture = DragGesture(minimumDistance: 1.0)
        let gesture = TupleGesture(
            head: dragGesture,
            tail: TupleGesture(
                head: dragGesture,
                tail: EmptyTupleGesture()
            )
        ).map { value -> (DragGesture.Value, DragGesture.Value) in
            // closure #1 (Tuple<DragGesture.Value, Tuple<DragGesture.Value, EmptyTuple>>) -> (DragGesture.Value, DragGesture.Value)
            (value.head, value.tail.head)
        }
                
        return gesture._updating(state: StateType.self, body: stateBody)
    }
    
    private static func scale(_ value: (DragGesture.Value, DragGesture.Value)) -> CGFloat {
        let left = value.0
        let right = value.1
        
        let distance = sqrt(pow(right.location.y - left.location.y, 2) + pow(right.location.x - left.location.x, 2))
        let startLocationDistance = sqrt(pow(right.startLocation.y - left.startLocation.y, 2) + pow(right.startLocation.x - left.startLocation.x, 2))
        
        return distance / startLocationDistance
    }
    
    fileprivate static func _makeGesture(gesture: _GraphValue<TouchBasedMagnifyGesture>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        _Body._makeGesture(gesture: gesture[\._body], inputs: inputs)
    }
    
    // closure #2 (inout StateType, GesturePhase<(DragGesture.Value, DragGesture.Value)>) -> GesturePhase<CGFloat>
    private func stateBody(state: inout StateType, childPhase: GesturePhase<(DragGesture.Value, DragGesture.Value)>) -> GesturePhase<CGFloat> {
        if !state.isActive,
           case let .active(value) = childPhase,
           abs(TouchBasedMagnifyGesture.scale(value) - 1) > minimumScaleDelta {
            state.isActive = true
        }
        
        return phase(state: state, childPhase: childPhase)
    }
    
    private func phase(state: StateType, childPhase: GesturePhase<(DragGesture.Value, DragGesture.Value)>) -> GesturePhase<CGFloat> {
        if case .failed = childPhase {
            return .failed
        }
        guard state.isActive else {
            return .possible(nil)
        }

        return childPhase.map {
            TouchBasedMagnifyGesture.scale($0)
        }
    }

    
    private struct StateType: GestureStateProtocol {

        fileprivate var isActive: Bool
        
        fileprivate init() {
            self.isActive = false
        }

    }
    
#if BINARY_COMPATIBLE_TEST || DEBUG
    fileprivate static func testable_scale(_ value: (DragGesture.Value, DragGesture.Value)) -> CGFloat {
        scale(value)
    }
    
    fileprivate func testable_stateBody(state_isActive: inout Bool, childPhase: GesturePhase<(DragGesture.Value, DragGesture.Value)>) -> GesturePhase<CGFloat> {
        var state = StateType()
        state.isActive = state_isActive
        let result = stateBody(state: &state, childPhase: childPhase)
        state_isActive = state.isActive
        return result
    }
    
    fileprivate func testable_phase(state_isActive: Bool, childPhase: GesturePhase<(DragGesture.Value, DragGesture.Value)>) -> GesturePhase<CGFloat> {
        var state = StateType()
        state.isActive = state_isActive
        return phase(state: state, childPhase: childPhase)
    }
#endif
    
}

@available(iOS 13.0, *)
fileprivate struct TransformBasedMagnifyGesture: PrimitiveGesture {
    
    fileprivate typealias Value = CGFloat
    
    private typealias _Body = ModifierGesture<
        StateContainerGesture<StateType, TransformEvent, CGFloat>,
        EventListener<TransformEvent>
    >

    private var minimumScaleDelta: CGFloat
    
    fileprivate init(minimumScaleDelta: CGFloat) {
        self.minimumScaleDelta = minimumScaleDelta
    }
    
    private var _body: _Body {
        EventListener()
            ._updating(state: StateType.self, body: stateBody)
    }
    
    fileprivate static func _makeGesture(gesture: _GraphValue<TransformBasedMagnifyGesture>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        _Body._makeGesture(gesture: gesture[\._body], inputs: inputs)
    }

    private func stateBody(state: inout StateType, childPhase: GesturePhase<TransformEvent>) -> GesturePhase<CGFloat> {
        if !state.isActive, case let .active(value) = childPhase {
            if let beginValue = state.beginValue {
                let endValue = value.initialScale * value.scaleDelta
                if endValue - beginValue > minimumScaleDelta {
                    state.isActive = true
                }
            } else {
                state.beginValue = value.initialScale
            }
        }
        
        return phase(state: state, childPhase: childPhase)
    }
    
    private func phase(state: StateType, childPhase: GesturePhase<TransformEvent>) -> GesturePhase<CGFloat> {
        if case .failed = childPhase {
            return .failed
        }
        guard state.isActive else {
            return .possible(nil)
        }

        return childPhase.map { value in
            max(max(value.initialScale * value.scaleDelta, 0) + 1 - state.beginValue!, 0)
        }
    }
    

    private struct StateType: GestureStateProtocol {

        internal var isActive: Bool

        internal var beginValue: CGFloat?
        
        internal init() {
            self.isActive = false
            self.beginValue = nil
        }

    }
    
#if BINARY_COMPATIBLE_TEST || DEBUG
    fileprivate func phase(isActive: Bool, beginValue: CGFloat?, childPhase: GesturePhase<TransformEvent>) -> GesturePhase<CGFloat> {
        var state = StateType()
        state.isActive = isActive
        state.beginValue = beginValue
        return phase(state: state, childPhase: childPhase)
    }
    
    fileprivate func testable_stateBody(isActive: inout Bool, beginValue: inout CGFloat?, childPhase: GesturePhase<TransformEvent>) -> GesturePhase<CGFloat> {
        var state = StateType()
        state.isActive = isActive
        state.beginValue = beginValue
        let result = stateBody(state: &state, childPhase: childPhase)
        isActive = state.isActive
        beginValue = state.beginValue
        return result
    }
    
#endif

}

#if BINARY_COMPATIBLE_TEST || DEBUG
@available(iOS 13.0, *)
internal struct Testable_TransformBasedMagnifyGesture {
    
    private var box: TransformBasedMagnifyGesture

    internal init(minimumScaleDelta: CGFloat) {
        self.box = TransformBasedMagnifyGesture(minimumScaleDelta: minimumScaleDelta)
    }
    
    internal func stateBody(state: inout StateType, childPhase: GesturePhase<TransformEvent>) -> GesturePhase<CGFloat> {
        box.testable_stateBody(isActive: &state.isActive, beginValue: &state.beginValue, childPhase: childPhase)
    }
    
    internal func phase(state: StateType, childPhase: GesturePhase<TransformEvent>) -> GesturePhase<CGFloat> {
        box.phase(isActive: state.isActive, beginValue: state.beginValue, childPhase: childPhase)
    }
    

    internal struct StateType: GestureStateProtocol, Equatable {

        internal var isActive: Bool

        internal var beginValue: CGFloat?
        
        internal init() {
            self.isActive = false
            self.beginValue = nil
        }
        
    }
    
}

@available(iOS 13.0, *)
internal struct Testable_TouchBasedMagnifyGesture {
    
    internal typealias Value = CGFloat
    
    private var box: TouchBasedMagnifyGesture
    
    internal init(minimumScaleDelta: CGFloat) {
        self.box = TouchBasedMagnifyGesture(minimumScaleDelta: minimumScaleDelta)
    }
    
    internal static func scale(_ value: (DragGesture.Value, DragGesture.Value)) -> CGFloat {
        TouchBasedMagnifyGesture.testable_scale(value)
    }
    
    internal func stateBody(state_isActive: inout Bool, childPhase: GesturePhase<(DragGesture.Value, DragGesture.Value)>) -> GesturePhase<CGFloat> {
        box.testable_stateBody(state_isActive: &state_isActive, childPhase: childPhase)
    }
    
    internal func phase(state_isActive: Bool, childPhase: GesturePhase<(DragGesture.Value, DragGesture.Value)>) -> GesturePhase<CGFloat> {
        box.testable_phase(state_isActive: state_isActive, childPhase: childPhase)
    }
    
    internal struct StateType: GestureStateProtocol {

        internal var isActive: Bool
        
        internal init() {
            self.isActive = false
        }
        
    }
    
}
//BDCOV_EXCL_STOP
#endif
