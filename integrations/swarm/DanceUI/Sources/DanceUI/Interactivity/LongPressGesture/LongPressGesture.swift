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

/// A gesture that succeeds when the user performs a long press.
///
/// To recognize a long-press gesture on a view, create and configure the
/// gesture, then add it to the view using the ``View/gesture(_:including:)``
/// modifier.
///
/// Add a long-press gesture to a ``Circle`` to animate its color from blue to
/// red, and then change it to green when the gesture ends:
///
///     struct LongPressGestureView: View {
///         @GestureState var isDetectingLongPress = false
///         @State var completedLongPress = false
///
///         var longPress: some Gesture {
///             LongPressGesture(minimumDuration: 3)
///                 .updating($isDetectingLongPress) { currentState, gestureState,
///                         transaction in
///                     gestureState = currentState
///                     transaction.animation = Animation.easeIn(duration: 2.0)
///                 }
///                 .onEnded { finished in
///                     self.completedLongPress = finished
///                 }
///         }
///
///         var body: some View {
///             Circle()
///                 .fill(self.isDetectingLongPress ?
///                     Color.red :
///                     (self.completedLongPress ? Color.green : Color.blue))
///                 .frame(width: 100, height: 100, alignment: .center)
///                 .gesture(longPress)
///         }
///     }
@available(iOS 13.0, *)
public struct LongPressGesture: PrimitiveGesture {

    /// The minimum duration of the long press that must elapse before the
    /// gesture succeeds.
    public var minimumDuration: Double
    
    private var _maximumDistance: CGFloat

    /// The maximum distance that the long press can move before the gesture
    /// fails.
    @available(tvOS, unavailable)
    public var maximumDistance: CGFloat {
        get {
            _maximumDistance
        }
        set {
            _maximumDistance = newValue
        }
    }
    
    /// Creates a long-press gesture with a minimum duration and a maximum
    /// distance that the interaction can move before the gesture fails.
    ///
    /// - Parameters:
    ///   - minimumDuration: The minimum duration of the long press that must
    ///     elapse before the gesture succeeds.
    ///   - maximumDistance: The maximum distance that the fingers or cursor
    ///     performing the long press can move before the gesture fails.
    @available(tvOS, unavailable)
    public init(minimumDuration: Double = 0.5, maximumDistance: CGFloat = 10) {
        self.minimumDuration = minimumDuration
        self._maximumDistance = maximumDistance
    }
    
    @available(iOS, unavailable)
    @available(OSX, unavailable)
    @available(watchOS, unavailable)
    public init(minimumDuration: Double = 0.5) {
        self.minimumDuration = minimumDuration
        self._maximumDistance = 10.0
    }

    /// The type representing the gesture's value.
    public typealias Value = Bool

    /// The type of gesture representing the body of `Self`.
    public typealias Body = Never
    
    private typealias _Body = ModifierGesture<
        DependentGesture<Bool>,
        ModifierGesture<
            EventFilter<Bool>,
            ModifierGesture<
                Map2Gesture<
                    Bool,
                    ModifierGesture<
                        CoordinateSpaceGesture<CGFloat>,
                        DistanceGesture
                    >,
                    Bool
                >,
                ModifierGesture<
                    Map2Gesture<
                        Bool,
                        ModifierGesture<
                            DurationGesture<Event>,
                            EventListener<Event>
                        >,
                        Bool
                    >,
                    ModifierGesture<
                        MapGesture<SpatialEvent, Bool>,
                        EventListener<SpatialEvent>
                    >
                >
            >
        >
    >
    
    private var _body: _Body {
        let globalDistance = DistanceGesture(minimumDistance: .zero, maximumDistance: _maximumDistance)
            .coordinateSpace(.global)
        
        let duration = EventListener<Event>()
            .duration(minimumDuration: minimumDuration, maximumDuration: .infinity)
        
        return EventListener<SpatialEvent>()
            .longPressPhase()
            .ended(by: duration)
            .gated(by: globalDistance)
            .eventFilter(MouseEvent.self, allowOtherTypes: true, LongPressGesture_body_closure1)
            .dependency(.pausedUntilFailed) // Dependency iOS 18.5 checked
    }
    
    public static func _makeGesture(gesture: _GraphValue<LongPressGesture>, inputs: _GestureInputs) -> _GestureOutputs<Bool> {
        if DanceUIFeature.gestureContainer.isEnable {
            let primitiveChild = Child(longPressGesture: gesture.value).makeAttribute()
            return PrimitiveLongPressGesture._makeGesture(gesture: _GraphValue(primitiveChild), inputs: inputs)
        } else {
            return _Body._makeGesture(gesture: gesture[\Self._body], inputs: inputs)
        }
    }
    
    private struct Child: Rule {
        
        @Attribute
        fileprivate var longPressGesture: LongPressGesture
        
        fileprivate var value: PrimitiveLongPressGesture {
            PrimitiveLongPressGesture(longPressGesture: longPressGesture)
        }
        
    }
    
}

private struct PrimitiveLongPressGesture: Gesture {
    
    fileprivate let longPressGesture: LongPressGesture
    
    fileprivate var body: some Gesture<Bool> {
        let globalDistance = DistanceGesture(minimumDistance: .zero, maximumDistance: longPressGesture.maximumDistance)
            .coordinateSpace(.global)
        
        let duration = EventListener<Event>()
            .duration(minimumDuration: longPressGesture.minimumDuration, maximumDuration: .infinity)
        
        return EventListener<SpatialEvent>()
            .longPressPhase()
            .ended_featureGestureContainer(by: duration)
            .gated(by: globalDistance)
            .eventFilter(MouseEvent.self, allowOtherTypes: true, LongPressGesture_body_closure1)
            .dependency(.pausedUntilFailed) // Dependency iOS 18.5 checked
    }
    
}

@available(iOS 13.0, *)
extension View {

    /// Adds an action to perform when this view recognizes a long press
    /// gesture.
    @available(iOS, deprecated: 100000.0, renamed: "onLongPressGesture(minimumDuration:maximumDistance:perform:onPressingChanged:)")
    @available(macOS, deprecated: 100000.0, renamed: "onLongPressGesture(minimumDuration:maximumDistance:perform:onPressingChanged:)")
    @available(tvOS, unavailable)
    @available(watchOS, deprecated: 100000.0, renamed: "onLongPressGesture(minimumDuration:maximumDistance:perform:onPressingChanged:)")
    @_disfavoredOverload
    public func onLongPressGesture(minimumDuration: Double = 0.5, maximumDistance: CGFloat = 10, pressing: ((Bool) -> Void)? = nil, perform action: @escaping () -> Void) -> some View {
        _onLongPressGesture(minimumDuration: minimumDuration, maximumDistance: maximumDistance, perform: action, onPressingChanged: pressing)
    }
    
    /// Adds an action to perform when this view recognizes a long press
    /// gesture.
    ///
    /// - Parameters:
    ///     - minimumDuration: The minimum duration of the long press that must
    ///     elapse before the gesture succeeds.
    ///     - maximumDistance: The maximum distance that the fingers or cursor
    ///     performing the long press can move before the gesture fails.
    ///     - action: The action to perform when a long press is recognizes
    ///     - onPressingChanged:  A closure to run when the pressing state of the
    ///     gesture changes, passing the current state as a parameter.
    @available(tvOS, unavailable)
    public func onLongPressGesture(minimumDuration: Double = 0.5, maximumDistance: CGFloat = 10, perform action: @escaping () -> Void, onPressingChanged: ((Bool) -> Void)? = nil) -> some View {
        _onLongPressGesture(minimumDuration: minimumDuration, maximumDistance: maximumDistance, perform: action, onPressingChanged: onPressingChanged)
    }
    
    /// ⚠️
    /// This function first discovered in iOS15.
    /// But implemented is iOS14
    private func _onLongPressGesture(minimumDuration: Double, maximumDistance: CGFloat, perform action: @escaping () -> (), onPressingChanged: ((Bool) -> ())?) -> some View {
        self.modifier(ViewLongPressGestureViewModifier(minimumDuration: minimumDuration, maximumDistance: maximumDistance, action: action, onPressingChanged: onPressingChanged))
    }
    
}

// Dispatch different features
private struct ViewLongPressGestureViewModifier: PrimitiveViewModifier, UnaryViewModifier {
    
    fileprivate var minimumDuration: Double
    
    fileprivate var maximumDistance: CGFloat
    
    fileprivate var action: () -> Void
    
    fileprivate var onPressingChanged: ((Bool) -> Void)?
    
    fileprivate static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        if DanceUIFeature.gestureContainer.isEnable {
            let child = GestureContainerChild(modifier: modifier.value).makeAttribute()
            return GestureContainerChild.Value._makeView(modifier: _GraphValue(child), inputs: inputs, body: body)
        } else {
            let child = GestureChild(modifier: modifier.value).makeAttribute()
            return GestureChild.Value._makeView(modifier: _GraphValue(child), inputs: inputs, body: body)
        }
        
    }
    
    private struct GestureChild: Rule {
        
        @Attribute
        var modifier: ViewLongPressGestureViewModifier
        
        var value: LongPressGestureViewModifier {
            LongPressGestureViewModifier(minimumDuration: modifier.minimumDuration, maximumDistance: modifier.maximumDistance, action: modifier.action, onPressingChanged: modifier.onPressingChanged)
        }
        
    }
    
    private struct GestureContainerChild: Rule {
        
        @Attribute
        var modifier: ViewLongPressGestureViewModifier
        
        var value: GestureContainerLongPressGestureViewModifier {
            GestureContainerLongPressGestureViewModifier(minimumDuration: modifier.minimumDuration, maximumDistance: modifier.maximumDistance, action: modifier.action, onPressingChanged: modifier.onPressingChanged)
        }
        
    }
    
    
}

private struct LongPressGestureViewModifier: ViewModifier {
    
    fileprivate var minimumDuration: Double
    
    fileprivate var maximumDistance: CGFloat
    
    fileprivate var action: () -> Void
    
    fileprivate var onPressingChanged: ((Bool) -> Void)?
    
    fileprivate func body(content: Content) -> some View {
        content
            .gesture(
                LongPressGesture(
                    minimumDuration: minimumDuration,
                    maximumDistance: maximumDistance
                ).pressable(pressing: onPressingChanged, pressed: action)
            )
    }
    
    
}

private struct GestureContainerLongPressGestureViewModifier: ViewModifier {
    
    @GestureCancellation
    fileprivate var cancellation: Bool = false
    
    fileprivate var minimumDuration: Double
    
    fileprivate var maximumDistance: CGFloat
    
    fileprivate var action: () -> Void
    
    fileprivate var onPressingChanged: ((Bool) -> Void)?
    
    fileprivate func body(content: Content) -> some View {
        content
            .simultaneousGesture(pressingGesture.canBeCancelled(by: $cancellation), name: "pressing gesture of View.onLongPressGesture")
            .gesture(longPressGesture.canCancell($cancellation, on: .failed), name: "long press gesture of View.onLongPressGesture")
    }
    
    private var pressingGesture: some Gesture {
        PressableGesture(hasBoundary: false, pressingAction: onPressingChanged)
    }
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: minimumDuration, maximumDistance: maximumDistance)
            .pressable(pressing: nil, pressed: action)
    }
    
}

@available(iOS 13.0, *)
extension Gesture {
    
    fileprivate func longPressPhase() -> ModifierGesture<MapGesture<Value, Bool>, Self> {
        mapPhase(LongPressGesture_longPressPhase_closure1)
    }
    
}

@available(iOS 13.0, *)
extension Gesture {
    
    internal func eventFilter<E: EventType>(_ eventType: E.Type, allowOtherTypes: Bool, _ predicate: @escaping (E) -> Bool) -> ModifierGesture<EventFilter<Value>, Self> {
        modifier(EventFilter { event in
            if let event = E(event) {
                return predicate(event)
            } else {
                return allowOtherTypes
            }
        })
    }
    
    internal func ended<ConditionGesture: Gesture>(by gesture: ConditionGesture) -> ModifierGesture<Map2Gesture<Value, ConditionGesture, Value>, Self> {
        map2(contentGesture: gesture, transform: endedBybody)
    }
    
    // swift-format-ignore: AlwaysUseLowerCamelCase
    internal func ended_featureGestureContainer<ConditionGesture: Gesture>(by gesture: ConditionGesture) -> EndedByWrapper<Self, ConditionGesture> {
        EndedByWrapper(base: self, condition: gesture)
    }
    
    internal func ended<A1: Gesture>(by gesture: A1, advanceImmediately: Bool) -> ModifierGesture<Map2Gesture<Value, A1, Value>, Self> {
        if DanceUIFeature.gestureContainer.isEnable {
            return map2(contentGesture: gesture) { childPhase, contentPhase in
                switch contentPhase {
                case .possible:
                    if !advanceImmediately && DanceUIFeature.gestureContainer.isEnable {
                        return childPhase.paused()
                    } else {
                        if case .ended(let event) = childPhase {
                            return .active(event)
                        } else {
                            return childPhase
                        }
                    }
                case .failed:
                    return .failed
                default:
                    return childPhase
                }
            }
        } else {
            return map2(contentGesture: gesture, transform: endedBybody)
        }
    }
    
}

internal struct EndedByWrapper<BaseGesture: Gesture, ConditionGesture: Gesture>: Gesture {
    
    internal var base: BaseGesture
    
    internal var condition: ConditionGesture
    
    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<BaseGesture.Value> {
        
        let hasChangedCallbacks = inputs.options.contains(.hasChangedCallbacks)
        
        let child = Child(wrapper: gesture.value, hasChangedCallbacks: hasChangedCallbacks).makeAttribute()
        
        let outputs = Child.Value._makeGesture(gesture: _GraphValue(child), inputs: inputs)
        
        return outputs
    }
    
    private struct Child: Rule {
        
        @Attribute
        fileprivate var wrapper: EndedByWrapper<BaseGesture, ConditionGesture>
        
        fileprivate var hasChangedCallbacks: Bool
        
        fileprivate var value: some Gesture<BaseGesture.Value> {
            wrapper.base.ended(by: wrapper.condition, advanceImmediately: hasChangedCallbacks)
        }
        
    }
    
}

@available(iOS 13.0, *)
private func endedBybody<Value, Value1>(childPhase: GesturePhase<Value>, contentPhase: GesturePhase<Value1>) -> GesturePhase<Value> {
    switch (childPhase, contentPhase) {
    case (_, .failed):
        return .failed
    case let (.ended(value0), .ended):
        return .ended(value0)
    case let (.ended(value0), .possible):
        return .active(value0)
    default:
        return childPhase
    }
}

@available(iOS 13.0, *)
private func LongPressGesture_body_closure1(_ event: MouseEvent) -> Bool {
    event.button == .init(rawValue: 0x1)
}

@available(iOS 13.0, *)
private func LongPressGesture_longPressPhase_closure1<Event>(_ phase: GesturePhase<Event>) -> GesturePhase<Bool> {
    switch phase {
    case .active:
        return .ended(true)
    case .failed:
        return .failed
    default:
        return phase.set(false)
    }
}

#if BINARY_COMPATIBLE_TEST
@available(iOS 13.0, *)
internal func fileprivate_LongPressGesture_longPressPhase_closure1<Event>(_ phase: GesturePhase<Event>) -> GesturePhase<Bool> {
    LongPressGesture_longPressPhase_closure1(phase)
}

@available(iOS 13.0, *)
internal func fileprivate_endedByBody<Value, Value1>(phase0: GesturePhase<Value>, phase1: GesturePhase<Value1>) -> GesturePhase<Value> {
    endedBybody(phase0: phase0, phase1: phase1)
}

@available(iOS 13.0, *)
internal func fileprivate_LongPressGesture_body_closure1(_ event: MouseEvent) -> Bool {
    LongPressGesture_body_closure1(event)
}


#endif
