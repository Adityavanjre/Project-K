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

/// A gesture that recognizes one or more taps.
///
/// To recognize a tap gesture on a view, create and configure the gesture, and
/// then add it to the view using the ``View/gesture(_:including:)`` modifier.
/// The following code adds a tap gesture to a ``Circle`` that toggles the color
/// of the circle.
///
///     struct TapGestureView: View {
///         @State var tapped = false
///
///         var tap: some Gesture {
///             TapGesture(count: 1)
///                 .onEnded { _ in self.tapped = !self.tapped }
///         }
///
///         var body: some View {
///             Circle()
///                 .fill(self.tapped ? Color.blue : Color.red)
///                 .frame(width: 100, height: 100, alignment: .center)
///                 .gesture(tap)
///         }
///     }
@available(tvOS, unavailable)
@available(iOS 13.0, *)
public struct TapGesture : PrimitiveGesture {

    /// The required number of tap events.
    public var count: Int
    
    /// The maximum duration of the tap events.
    public let maximumDuration: Double

    /// Creates a tap gesture with the number of required taps.
    /// - Parameters:
    ///   - count: The required number of taps to complete the tap gesture.
    ///   - maximumDuration: The maximum duration of the tap gesture that elapse
    ///   before the gesture fails.
    public init(count: Int = 1, maximumDuration: Double = 0.75) {
        self.count = count
        self.maximumDuration = maximumDuration
    }
    
    /// The type of gesture representing the body of `Self`.
    public typealias Body = Never

    /// The type representing the gesture's value.
    public typealias Value = Void
    
    public static func _makeGesture(gesture: _GraphValue<TapGesture>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        
        let child = Attribute(Child(gesture: gesture.value))
        
        // Child.Value is expanded as a ModifierGesture
        let outputs = if DanceUIFeature.gestureContainer.isEnable {
            Child.Value.makeDebuggableGesture(gesture: _GraphValue(child), inputs: inputs)
        } else {
            ModifierGesture._makeGesture(gesture: _GraphValue(child), inputs: inputs)
        }
        let phase = Attribute(Phase(phase: outputs.phase))
        return outputs.withPhase(phase)
    }
    
    internal struct SingleTap: Gesture {

        internal var maximumDuration: Double

        internal var maximumDistance: CGFloat
        
        internal typealias Value = SpatialEvent

        internal typealias _Body = ModifierGesture<
            EventFilter<SpatialEvent>,
            ModifierGesture<
                Map2Gesture<
                    SpatialEvent,
                    ModifierGesture<
                        CoordinateSpaceGesture<CGFloat>,
                        DistanceGesture
                    >,
                    SpatialEvent
                >,
                ModifierGesture<
                    Map2Gesture<
                        SpatialEvent,
                        ModifierGesture<
                            DurationGesture<Event>,
                            EventListener<Event>
                        >,
                        SpatialEvent
                    >,
                    ModifierGesture<
                        DependentGesture<SpatialEvent>,
                        ModifierGesture<
                            MapGesture<SpatialEvent, SpatialEvent>,
                            EventListener<SpatialEvent>
                        >
                    >
                >
            >
        >
        
        internal var body: _Body {
            EventListener<SpatialEvent>()
                .discrete(true)
                .dependency(DanceUIFeature.gestureContainer.isEnable ? .failIfActive : .pausedUntilFailed)
                .gated(by: EventListener<Event>().duration(minimumDuration: 0, maximumDuration: maximumDuration))
                .gated(by: DistanceGesture(minimumDistance: 0, maximumDistance: maximumDistance).coordinateSpace(.global))
                .eventFilter(MouseEvent.self, allowOtherTypes: true) { event in
                    event.button == .element1
                }
        }
    }

    private struct Child: Rule {
        
        internal typealias Value = ModifierGesture<RepeatGesture<SpatialEvent>, SingleTap>

        @Attribute
        internal var gesture: TapGesture
        
        internal var value: Value {
            SingleTap(
                maximumDuration: gesture.maximumDuration,
                maximumDistance: tapMovementThreshold
            ).repeatCount(gesture.count, maximumDelay: 0.35)
        }

    }

    private struct Phase: Rule {
                
        internal typealias Value = GesturePhase<Void>

        @Attribute
        internal var phase: GesturePhase<SpatialEvent>
        
        internal var value: GesturePhase<Void> {
            phase.set(())
        }

    }

}

@available(iOS 13.0, *)
extension View {
    
    /// Adds an action to perform when this view recognizes a tap gesture.
    ///
    /// Use this method to perform a specific `action` when the user clicks or
    /// taps on the view or container `count` times.
    ///
    /// > Note: If you are creating a control that's functionally equivalent
    /// to a ``Button``, use ``ButtonStyle`` to create a customized button
    /// instead.
    ///
    /// In the example below, the color of the heart images changes to a random
    /// color from the `colors` array whenever the user clicks or taps on the
    /// view twice:
    ///
    ///     struct TapGestureExample: View {
    ///         let colors: [Color] = [.gray, .red, .orange, .yellow,
    ///                                .green, .blue, .purple, .pink]
    ///         @State private var fgColor: Color = .gray
    ///
    ///         var body: some View {
    ///             Image(systemName: "heart.fill")
    ///                 .resizable()
    ///                 .frame(width: 200, height: 200)
    ///                 .foregroundColor(fgColor)
    ///                 .onTapGesture(count: 2, perform: {
    ///                     fgColor = colors.randomElement()!
    ///                 })
    ///         }
    ///     }
    ///
    ///
    /// - Parameters:
    ///    - count: The number of taps or clicks required to trigger the action
    ///      closure provided in `action`. Defaults to `1`.
    ///    - action: The action to perform.
    ///    - maximumDuration: The maximum duration of the tap gesture that
    ///    elapse before the gesture fails.
    @inlinable
    public func onTapGesture(count: Int = 1, maximumDuration: Double = 0.75, perform action: @escaping () -> Void) -> some View {
        let tap = TapGesture(count: count, maximumDuration: maximumDuration)
            .onEnded(action)
        return gesture(tap)
    }
    
}

@available(iOS 13.0, *)
internal let tapMovementThreshold: CGFloat = 45
@available(iOS 13.0, *)
extension Gesture {
    
    internal func repeatCount(_ count: Int, maximumDelay: Double) -> ModifierGesture<RepeatGesture<Body.Value>, Self> where Self.Body.Value == Self.Value {
        _danceuiPrecondition(count > 0, "Fatal error: count must be positive")
        return modifier(RepeatGesture(count: count, maximumDelay: maximumDelay))
    }
}

@available(iOS 13.0, *)
extension Gesture {
    
    internal func discrete(_ isDiscrete: Bool) -> ModifierGesture<MapGesture<Value, Value>, Self> {
        modifier(MapGesture(body: { phase in
            if isDiscrete, case .active(let value) = phase {
                return .possible(value)
            } else {
                return phase
            }
        }))
    }
    
}
