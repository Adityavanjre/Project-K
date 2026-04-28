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
@_spi(DanceUI) import DanceUIObservation

/// A container that animates its content with keyframes.
///
/// The `content` closure updates every frame while
/// animating, so avoid performing any expensive operations directly within
/// `content`.
@available(iOS 13.0, *)
public struct KeyframeAnimator<Value, KeyframePath: Keyframes, Content: View>: PrimitiveView, UnaryView where Value == KeyframePath.Value {
    
    internal var initialValue: Value

    internal var path: (Value) -> KeyframePath
    
    private var playback: PlaybackMode
    
    internal var content : (Value) -> Content
    
    public init(initialValue: Value,
                trigger: some Equatable,
                @ViewBuilder content: @escaping (Value) -> Content,
                @KeyframesBuilder<Value> keyframes: @escaping (Value) -> KeyframePath) {
        self.initialValue = initialValue
        self.path = keyframes
        self.playback = .onChange(trigger: .init(value: trigger))
        self.content = content
    }
    
    public init(initialValue: Value,
                repeating: Bool = true,
                @ViewBuilder content: @escaping (Value) -> Content,
                @KeyframesBuilder<Value> keyframes: @escaping (Value) -> KeyframePath) {
        self.initialValue = initialValue
        self.path = keyframes
        self.playback = .repeating(paused: !repeating)
        self.content = content
    }
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let animator = AnimatorAttribute(view: view.value,
                                         playback: view[\.playback].value,
                                         phase: inputs.phase,
                                         time: inputs.time,
                                         resetSeed: 0,
                                         currentState: .initial)
        let attribute = Attribute(animator)
        attribute.flags = [.active, .removable]
        return Content.makeDebuggableView(value: .init(attribute), inputs: inputs)
    }
    
}

@available(iOS 13.0, *)
private struct CustomModifier<R: View>: MultiViewModifier, PrimitiveViewModifier {
    
    fileprivate var result: R
    
    fileprivate static func _makeView(modifier: _GraphValue<CustomModifier<R>>,
                                      inputs: _ViewInputs,
                                      body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInputs = inputs
        newInputs.append(.view(body), for: BodyInput.self)
        let outputs = R.makeDebuggableView(value: modifier[\.result], inputs: newInputs)
        return outputs
    }
}

@available(iOS 13.0, *)
private struct AnimatorAttribute<Value,
                                 KeyframePath: Keyframes,
                                 Content: View>: StatefulRule, ObservationAttribute where Value == KeyframePath.Value {

    fileprivate typealias Value = Content

    @Attribute
    private var view: KeyframeAnimator<Value, KeyframePath, Content>

    @Attribute
    private var playback: PlaybackMode

    @Attribute
    private var phase: _GraphInputs.Phase

    @Attribute
    private var time: Time

    private var resetSeed: UInt32

    private var currentState: KeyframeTrackState<Value, KeyframePath>

    internal var previousObservationTrackings: [ObservationTracking]?

    internal var deferredObservationGraphMutation: DeferredObservationGraphMutation?
    
    internal init(view: Attribute<KeyframeAnimator<Value, KeyframePath, Content>>,
                  playback: Attribute<PlaybackMode>,
                  phase: Attribute<_GraphInputs.Phase>,
                  time: Attribute<Time>,
                  resetSeed: UInt32,
                  currentState: KeyframeTrackState<Value, KeyframePath>) {
        self._view = view
        self._playback = playback
        self._phase = phase
        self._time = time
        self.resetSeed = resetSeed
        self.currentState = currentState
    }

    fileprivate mutating func updateValue() {
        let phase = self.phase
        if phase.seed != resetSeed {
            resetSeed = phase.seed
            currentState = .initial
        }
        let time = DGGraphRef.withoutUpdate {
            self.time
        }
        let playback = self.$playback.changedValue()

        let (view, isViewChanged) = self.$view.changedValue()
        
        if playback.changed || currentState.isInitial { // run
            currentState.updatePlayBack(playback.value,
                                        time: time,
                                        initialValue: view.initialValue,
                                        plan: view.path)
        }
        
        if currentState.isAnimating {
            let time = self.time
            currentState.updateAnimation(time: time) // check stop
            let newTime = time.advanced(by: 0.00833333)
            ViewGraph.current.scheduleNextViewUpdate(byTime: newTime)
        }
        let value = currentState.value(at: time, initialValue: view.initialValue)
        self.value = withObservation(shouldCancelPrevious: isViewChanged) {
            // AsyncAttribute
            view.content(value)
            // end
        }
    }

  }

internal enum PlaybackMode: Equatable {
    
    case repeating(paused: Bool)
    
    case onChange(trigger: AnyEquatable)

}

@available(iOS 13.0, *)
extension View {
    #if compiler(>=5.3)
    /// Plays the given keyframes when the given trigger value changes, updating
    /// the view using the modifiers you apply in `body`.
    ///
    /// Note that the `content` closure will be updated on every frame while
    /// animating, so avoid performing any expensive operations directly within
    /// `content`.
    ///
    /// If the trigger value changes while animating, the `keyframes` closure
    /// will be called with the current interpolated value, and the keyframes
    /// that you return define a new animation that replaces the old one. The
    /// previous velocity will be preserved, so cubic or spring keyframes will
    /// maintain continuity from the previous animation if they do not specify
    /// a custom initial velocity.
    ///
    /// When a keyframe animation finishes, the animator will remain at the
    /// end value, which becomes the initial value for the next animation.
    ///
    /// - Parameters:
    ///   - initialValue: The initial value that the keyframes will animate
    ///     from.
    ///   - trigger: A value to observe for changes.
    ///   - content: A view builder closure that takes two parameters. The first
    ///     parameter is a proxy value representing the modified view. The
    ///     second parameter is the interpolated value generated by the
    ///     keyframes.
    ///   - keyframes: Keyframes defining how the value changes over time. The
    ///     current value of the animator is the single argument, which is
    ///     equal to `initialValue` when the view first appears, then is equal
    ///     to the end value of the previous keyframe animation on subsequent
    ///     calls.
    public func keyframeAnimator<Value>(initialValue: Value,
                                        trigger: some Equatable,
                                        @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Value) -> some View,
                                        @KeyframesBuilder<Value> keyframes: @escaping (Value) -> some Keyframes<Value>) -> some View {
        KeyframeAnimator(initialValue: initialValue, trigger: trigger) { value in
            let c = content(PlaceholderContentView<Self>(), value)
            modifier(CustomModifier(result: c))
        } keyframes: { value in
            keyframes(value)
        }
    }
    #endif


    /// Loops the given keyframes continuously, updating
    /// the view using the modifiers you apply in `body`.
    ///
    /// Note that the `content` closure will be updated on every frame while
    /// animating, so avoid performing any expensive operations directly within
    /// `content`.
    ///
    /// - Parameters:
    ///   - initialValue: The initial value that the keyframes will animate
    ///     from.
    ///   - repeating: Whether the keyframes are currently repeating. If false,
    ///     the value at the beginning of the keyframe timeline will be
    ///     provided to the content closure.
    ///   - content: A view builder closure that takes two parameters. The first
    ///     parameter is a proxy value representing the modified view. The
    ///     second parameter is the interpolated value generated by the
    ///     keyframes.
    ///   - keyframes: Keyframes defining how the value changes over time. The
    ///     current value of the animator is the single argument, which is
    ///     equal to `initialValue` when the view first appears, then is equal
    ///     to the end value of the previous keyframe animation on subsequent
    ///     calls.
    public func keyframeAnimator<Value>(initialValue: Value, 
                                        repeating: Bool = true,
                                        @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Value) -> some View,
                                        @KeyframesBuilder<Value> keyframes: @escaping (Value) -> some Keyframes<Value>) -> some View {
        KeyframeAnimator(initialValue: initialValue, repeating: repeating) { value in
            let c = content(PlaceholderContentView<Self>(), value)
            modifier(CustomModifier(result: c))
        } keyframes: { value in
            keyframes(value)
        }
    }

}
