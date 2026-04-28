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

/// A dragging motion that invokes an action as the drag-event sequence changes.
///
/// To recognize a drag gesture on a view, create and configure the gesture, and
/// then add it to the view using the ``View/gesture(_:including:)`` modifier.
///
/// Add a drag gesture to a ``Circle`` and change its color while the user
/// performs the drag gesture:
///
///     struct DragGestureView: View {
///         @State var isDragging = false
///
///         var drag: some Gesture {
///             DragGesture()
///                 .onChanged { _ in self.isDragging = true }
///                 .onEnded { _ in self.isDragging = false }
///         }
///
///         var body: some View {
///             Circle()
///                 .fill(self.isDragging ? Color.red : Color.blue)
///                 .frame(width: 100, height: 100, alignment: .center)
///                 .gesture(drag)
///         }
///     }
@available(tvOS, unavailable)
@available(iOS 13.0, *)
public struct DragGesture: PrimitiveGesture {
    
    /// The attributes of a drag gesture.
    public struct Value : Equatable {

        /// The time associated with the drag gesture's current event.
        public var time: Date

        /// The location of the drag gesture's current event.
        public var location: CGPoint

        /// The location of the drag gesture's first event.
        public var startLocation: CGPoint

        internal var _velocity: _Velocity<CGSize>
        
        /// The current drag velocity.
        public var velocity: CGSize {
            _velocity.valuePerSecond
        }
        
        /// The total translation from the start of the drag gesture to the
        /// current event of the drag gesture.
        ///
        /// This is equivalent to `location.{x,y} - startLocation.{x,y}`.
        public var translation: CGSize {
            CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }

        /// A prediction, based on the current drag velocity, of where the final
        /// location will be if dragging stopped now.
        public var predictedEndLocation: CGPoint {
            let location = self.location
            let velocity = self.velocity
            return CGPoint(
                x: velocity.width * 0.25 + location.x,
                y: velocity.height * 0.25 + location.y
            )
        }

        /// A prediction, based on the current drag velocity, of what the final
        /// translation will be if dragging stopped now.
        public var predictedEndTranslation: CGSize {
            let translation = self.translation
            let velocity = self.velocity
            return CGSize(
                width: velocity.width * 0.25 + translation.width,
                height: velocity.height * 0.25 + translation.height
            )
        }

    }

    /// The minimum dragging distance before the gesture succeeds.
    public var minimumDistance: CGFloat

    /// The coordinate space in which to receive location values.
    public var coordinateSpace: CoordinateSpace

    internal var allowedDirections: _EventDirections

    /// Creates a dragging gesture with the minimum dragging distance before the
    /// gesture succeeds and the coordinate space of the gesture's location.
    ///
    /// - Parameters:
    ///   - minimumDistance: The minimum dragging distance for the gesture to
    ///     succeed.
    ///   - coordinateSpace: The coordinate space of the dragging gesture's
    ///     location.
    public init(minimumDistance: CGFloat = 10, coordinateSpace: CoordinateSpace = .local) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
        self.allowedDirections = .all
    }

    /// The type of gesture representing the body of `Self`.
    public typealias Body = Never
    
    private typealias _Body = ModifierGesture<
        DependentGesture<Value>,
        ModifierGesture<
            StateContainerGesture<DragGesture.StateType, SpatialEvent, DragGesture.Value>,
            ModifierGesture<
                CoordinateSpaceGesture<SpatialEvent>,
                ModifierGesture<EventFilter<SpatialEvent>, EventListener<SpatialEvent>>
            >
        >
    >
    
    private var _body: _Body {
        EventListener<SpatialEvent>()
            .eventFilter(MouseEvent.self, allowOtherTypes: true, DragGesture_body_closure1)
            .coordinateSpace(coordinateSpace)
            ._updating(state: StateType.self, body: phase)
            .dependency(.pausedUntilFailed)
    }
    
    private func testDistance(_ event0: SpatialEvent, _ event1: SpatialEvent) -> Bool {
        guard minimumDistance > 0 else {
            return true
        }
        
        let location0 = event0.globalLocation
        let location1 = event1.globalLocation
        let distance = sqrt(pow((location1.x - location0.x), 2) + pow((location1.y - location0.y), 2))
        if distance >= minimumDistance {
            return CGSize(width: location1.x - location0.x, height: location1.y - location0.y).withinRange(axes: allowedDirections, rangeCosine: 0.5)
        }
        return false
    }
    
    private func phase(state: inout StateType, event: GesturePhase<SpatialEvent>) -> GesturePhase<Value> {
        switch event {
        case .possible:
            guard !allowedDirections.isEmpty else {
                return .failed
            }
            return .possible(state.value)
        case .active(let value), .ended(let value):
            if state.start == nil {
                state.start = value
            }
            let start = state.start ?? value
            
            state.sampler.addSample(.init(value.location.x, value.location.y), time: value.timestamp)
        
            let velocity = state.sampler.velocity
            
            let newValue = Value(
                time: Date(timeIntervalSinceReferenceDate: value.timestamp.seconds),
                location: value.location,
                startLocation: start.location,
                _velocity: .init(valuePerSecond: CGSize(width: velocity.valuePerSecond.first, height: velocity.valuePerSecond.second))
            )
            
            if state.value == nil && !testDistance(value, start) {
                if case .ended = event {
                    return .failed
                } else {
                    return .possible(state.value)
                }
            }
            state.value = newValue
            return event.set(newValue)
        case .failed:
            return .failed
        }
    }
    
    public static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        _Body._makeGesture(gesture: gesture[\._body], inputs: inputs)
    }
}

@available(iOS 13.0, *)
extension DragGesture {
    
    fileprivate struct StateType: GestureStateProtocol {
        
        internal var start: SpatialEvent?

        internal var value: DragGesture.Value?

        internal var sampler: VelocitySampler<AnimatablePair<CGFloat, CGFloat>>
        
        init() {
            self.start = nil
            self.value = nil
            self.sampler = VelocitySampler(
                sample1: nil,
                sample2: nil,
                sample3: nil,
                lastTime: nil,
                previousSampleWeight: 0.75
            )
        }
    }
}

@available(iOS 13.0, *)
private func DragGesture_body_closure1(_ event: MouseEvent) -> Bool {
    event.button.rawValue == 0x1
}

@available(iOS 13.0, *)
extension CGSize {
    
    internal func withinRange(axes: _EventDirections, rangeCosine: CGFloat) -> Bool {
        
        if axes == .all {
            return true
        }
        
        
        let hypotenuseSquare = pow(width, 2) + pow(height, 2)
        
        var cosWidth = width
        var cosHeight = height
        
        if hypotenuseSquare > 0 {
            let reciprocal = 1 / sqrt(hypotenuseSquare)
            cosWidth = width * reciprocal
            cosHeight = height * reciprocal
        }
        
        if axes.contains(.left) && -cosWidth > rangeCosine {
            return true
        }
        
        if axes.contains(.right) && cosWidth > rangeCosine {
            return true
        }
        
        if axes.contains(.up) && -cosHeight > rangeCosine {
            return true
        }
        
        if axes.contains(.down) && cosHeight > rangeCosine {
            return true
        }
        
        return false
    }
    
}

@available(iOS 13.0, *)
extension DragGesture {
        
#if BINARY_COMPATIBLE_TEST
    internal func private_testDistance(_ event0: SpatialEvent, _ event1: SpatialEvent) -> Bool {
        testDistance(event0, event1)
    }
    
    internal struct FilePrivate_StateType: GestureStateProtocol {
        
        internal var start: SpatialEvent?

        internal var value: DragGesture.Value?

        internal var sampler: VelocitySampler<AnimatablePair<CGFloat, CGFloat>>
        
        init() {
            self.start = nil
            self.value = nil
            self.sampler = VelocitySampler(
                sample1: nil,
                sample2: nil,
                sample3: nil,
                lastTime: nil,
                previousSampleWeight: 0.75
            )
        }
    }
    
    internal func private_phase(state: inout FilePrivate_StateType, event: GesturePhase<SpatialEvent>) -> GesturePhase<Value> {
        
        var newState = StateType()
        newState.start = state.start
        newState.value = state.value
        newState.sampler = state.sampler
        
        let result = phase(state: &newState, event: event)
        
        state.start = newState.start
        state.value = newState.value
        state.sampler = newState.sampler
        return result
        
    }
#endif

}
