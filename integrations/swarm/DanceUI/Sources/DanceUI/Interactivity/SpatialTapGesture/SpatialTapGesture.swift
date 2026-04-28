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

/// A gesture that recognizes one or more taps and reports their location.
///
/// To recognize a tap gesture on a view, create and configure the gesture, and
/// then add it to the view using the ``View/gesture(_:including:)`` modifier.
/// The following code adds a tap gesture to a ``Circle`` that toggles the color
/// of the circle based on the tap location:
///
///     struct TapGestureView: View {
///         @State private var location: CGPoint = .zero
///
///         var tap: some Gesture {
///             SpatialTapGesture()
///                 .onEnded { event in
///                     self.location = event.location
///                  }
///         }
///
///         var body: some View {
///             Circle()
///                 .fill(self.location.y > 50 ? Color.blue : Color.red)
///                 .frame(width: 100, height: 100, alignment: .center)
///                 .gesture(tap)
///         }
///     }
@available(tvOS, unavailable)
@available(iOS 13.0, *)
public struct SpatialTapGesture : PrimitiveGesture {
    
    /// The attributes of a tap gesture.
    public struct Value : Equatable {
        
        /// The location of the tap gesture's current event.
        public var location: CGPoint
        
    }
    
    /// The required number of tap events.
    public var count: Int

    /// The coordinate space in which to receive location values.
    public var coordinateSpace: CoordinateSpace
    
    /// Creates a tap gesture with the number of required taps and the
    /// coordinate space of the gesture's location.
    ///
    /// - Parameters:
    ///   - count: The required number of taps to complete the tap
    ///     gesture.
    ///   - coordinateSpace: The coordinate space of the tap gesture's location.
    public init(count: Int = 1, coordinateSpace: CoordinateSpace = .local) {
        self.count = count
        self.coordinateSpace = coordinateSpace
    }
    
    public static func _makeGesture(gesture: _GraphValue<SpatialTapGesture>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        let child = Attribute(Child(gesture: gesture.value))
        let outputs = ModifierGesture._makeGesture(gesture: _GraphValue(child), inputs: inputs)
        let phase = Attribute(Phase(phase: outputs.phase))
        return outputs.withPhase(phase)
    }
    
    fileprivate struct Child: Rule {
        
        fileprivate typealias Value = ModifierGesture<
            CoordinateSpaceGesture<TappableSpatialEvent>,
            ModifierGesture<
                RepeatGesture<TappableSpatialEvent>,
                SingleTapGesture<TappableSpatialEvent>
            >
        >
        
        @Attribute
        fileprivate var gesture : SpatialTapGesture
        
        fileprivate var value: Value {
            SingleTapGesture<TappableSpatialEvent>(
                maximumDuration: 0.75,
                maximumDistance: tapMovementThreshold
            ).repeatCount(gesture.count, maximumDelay: 0.35)
            .coordinateSpace(gesture.coordinateSpace)
        }
        
    }
    
    fileprivate struct Phase: Rule {
        
        fileprivate typealias Value = GesturePhase<SpatialTapGesture.Value>
        
        @Attribute
        fileprivate var phase : GesturePhase<TappableSpatialEvent>
        
        fileprivate var value: Value {
            phase.map { event in
                SpatialTapGesture.Value(location: event.location)
            }
        }
        
    }
    
}


@available(tvOS, unavailable)
@available(iOS 13.0, *)
extension View {
    
    /// Adds an action to perform when this view recognizes a tap gesture,
    /// and provides the action with the location of the interaction.
    ///
    /// Use this method to perform the specified `action` when the user clicks
    /// or taps on the modified view `count` times. The action closure receives
    /// the location of the interaction.
    ///
    /// > Note: If you create a control that's functionally equivalent
    /// to a ``Button``, use ``ButtonStyle`` to create a customized button
    /// instead.
    ///
    /// The following code adds a tap gesture to a ``Circle`` that toggles the color
    /// of the circle based on the tap location.
    ///
    ///     struct TapGestureExample: View {
    ///         @State private var location: CGPoint = .zero
    ///
    ///         var body: some View {
    ///             Circle()
    ///                 .fill(self.location.y > 50 ? Color.blue : Color.red)
    ///                 .frame(width: 100, height: 100, alignment: .center)
    ///                 .onTapGesture { location in
    ///                     self.location = location
    ///                 }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - count: The number of taps or clicks required to trigger the action
    ///      closure provided in `action`. Defaults to `1`.
    ///    - coordinateSpace: The coordinate space in which to receive
    ///      location values. Defaults to ``CoordinateSpace/local``.
    ///    - action: The action to perform. This closure receives an input
    ///      that indicates where the interaction occurred.
    public func onTapGesture(count: Int = 1, coordinateSpace: CoordinateSpace = .local, perform action: @escaping (CGPoint) -> Void) -> some View {
        gesture(SpatialTapGesture(count: count, coordinateSpace: coordinateSpace).onEnded({ v in action(v.location) }))
    }
    
}

@available(iOS 13.0, *)
internal struct SingleTapGesture<Event: EventType>: Gesture {
    
    internal var maximumDuration: Double
    
    internal var maximumDistance: CGFloat
    
    internal typealias Value = Event
    
    internal typealias _Body = ModifierGesture<
        EventFilter<Event>,
        ModifierGesture<
            Map2Gesture<
                Event,
                ModifierGesture<
                    CoordinateSpaceGesture<CGFloat>,
                    DistanceGesture
                >,
                Event
            >,
            ModifierGesture<
                Map2Gesture<
                    Event,
                    ModifierGesture<
                        DurationGesture<Event>,
                        EventListener<Event>
                    >,
                    Event
                >,
                ModifierGesture<
                    DependentGesture<Event>,
                    ModifierGesture<
                        MapGesture<Event, Event>,
                        EventListener<Event>
                    >
                >
            >
        >
    >
    
    internal var body: _Body {
        EventListener<Event>()
            .discrete(true)
            .dependency(DanceUIFeature.gestureContainer.isEnable ? .failIfActive : .pausedUntilFailed)
            .gated(by: EventListener<Event>().duration(minimumDuration: 0, maximumDuration: maximumDuration))
            .gated(by: DistanceGesture(minimumDistance: 0, maximumDistance: maximumDistance).coordinateSpace(.global))
            .eventFilter(MouseEvent.self, allowOtherTypes: true) { event in
                event.button == .element1
            }
    }
    
}
