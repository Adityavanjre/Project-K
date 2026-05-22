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
extension View {
    
    @inline(__always)
    internal func buttonAction<G: Gesture>(_ gesture: G, gestureMask: GestureMask = [.all]) -> some View {
        modifier(ButtonActionModifier(gesture: gesture, gestureMask: gestureMask))
    }
    
    @inline(__always)
    internal func buttonActionGestureContainer<HighlightGesture: Gesture, ActionGesture: Gesture>(
        highlight highlightGesture: HighlightGesture,
        action actionGesture: ActionGesture,
        gestureMask: GestureMask = [.all]
    ) -> some View {
        modifier(ButtonActionModifierGestureContainer(highlightGesture: highlightGesture, actionGesture: actionGesture))
    }
    
}

@available(iOS 13.0, *)
internal struct ButtonActionModifier<G: Gesture>: GestureViewModifier, ViewModifier {
    
    internal typealias Combiner = DefaultGestureCombiner
    
    internal typealias Body = Never
    
    internal typealias ContentGesture = G
    
    internal var gesture: G
    
    internal var name: String?

    internal var gestureMask: GestureMask
    
}

@available(iOS 13.0, *)
internal struct ButtonActionModifierGestureContainer<HighlightGestureType: Gesture, ActionGestureType: Gesture>: ViewModifier {
    
    @GestureCancellation
    internal var cancellation: Bool = false
    
    internal var highlightGesture: HighlightGestureType
    
    internal var actionGesture: ActionGestureType
    
    internal func body(content: Content) -> some View {
        content
            .simultaneousGesture(highlightGesture.canBeCancelled(by: $cancellation).isCompanion(), name: "ButtonHighlightGesture")
            .gesture(actionGesture.canCancell($cancellation, on: .failed), name: "ButtonActionGesture")
    }
    
}

@available(iOS 13.0, *)
extension Gesture {
    
    internal func canCancell(_ cancellation: GestureCancellation, on condition: GestureCancellation.Condition) -> some Gesture<Value> {
        self.onReset { phase in
            switch (condition, phase) {
            case (.failed, .failed):
                cancellation.isCancelled = true
            case (.ended, .ended):
                cancellation.isCancelled = true
            default:
                break
            }
        }
    }
    
    internal func canBeCancelled(by cancellation: GestureCancellation) -> some Gesture<Value> {
        modifier(CancellationReadingGestureModifier<Value>(cancellation: cancellation))
    }
    
    internal func onReset(do action: @escaping (_: GesturePhase<Value>) -> Void) -> some Gesture<Value> {
        ResetGesture(_body: callbacks(ResetCallbacks(reset: action)))
    }
}

@propertyWrapper
@available(iOS 13.0, *)
internal struct GestureCancellation : DynamicProperty {
    
    internal enum Condition {
        
        case failed
        
        case ended
        
    }
    
    internal typealias Value = Bool
    
    @State
    internal var isCancelled: Value
    
    internal let reset: (Binding<Value>) -> Void
    
    internal init(wrappedValue: Value) {
        self._isCancelled = State(wrappedValue: wrappedValue)
        self.reset = { $0.wrappedValue = wrappedValue }
    }
    
    internal init(initialValue: Value) {
        self.init(wrappedValue: initialValue)
    }
    
    internal var wrappedValue: Value {
        get { isCancelled }
        set { isCancelled = newValue }
    }
    
    internal var projectedValue: GestureCancellation {
        self
    }
}

@available(iOS 13.0, *)
internal struct ResetGesture<Content: Gesture>: Gesture {
    
    internal typealias Value = Content.Value
    
    internal typealias Body = Never
    
    fileprivate var _body: ModifierGesture<CallbacksGesture<ResetCallbacks<Content.Value>>, Content>

    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Content.Value> {
        ModifierGesture._makeGesture(gesture: gesture[{.of(&$0._body)}], inputs: inputs)
    }

}

@available(iOS 13.0, *)
private struct ResetCallbacks<Value>: GestureCallbacks {
    
    internal let reset: (GesturePhase<Value>) -> Void

    internal static var initialState: StateType {
        .possible(nil)
    }
    
    internal func dispatch(phase: GesturePhase<Value>, state: inout StateType) -> (() -> Void)? {
        state = phase
        return nil
    }
    
    internal func cancel(state: StateType) -> (() -> Void)? {
        return {
            reset(state)
        }
    }
    
    internal typealias StateType = GesturePhase<Value>

}

@available(iOS 13.0, *)
internal struct CancellationReadingGestureModifier<BodyValue>: GestureModifier {
    
    internal typealias BodyValue = BodyValue
    
    internal typealias Value = BodyValue
    
    internal var cancellation: GestureCancellation
    
    internal static func _makeGesture(modifier: _GraphValue<CancellationReadingGestureModifier<BodyValue>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<BodyValue> {
        let outputs = body(inputs)
        
        let phase = CancallationReadingPhase(modifier: modifier.value, phase: outputs.phase, resetSeed: inputs.resetSeed)
        
        let wrappedPhase = Attribute(phase)
        wrappedPhase.setFlags([.active, .removable], mask: .reserved)
    
        return outputs.withPhase(wrappedPhase)
    }
    
}

@available(iOS 13.0, *)
private struct CancallationReadingPhase<BodyValue>: ResettableGestureRule, RemovableAttribute {
    
    fileprivate typealias PhaseValue = BodyValue
    fileprivate typealias Value = GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var modifier: CancellationReadingGestureModifier<BodyValue>
    
    @Attribute
    fileprivate var phase: GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var resetSeed: UInt32
    
    fileprivate var reset: GestureReset = GestureReset()
    
    fileprivate var resetCallback: (() -> Void)? = nil
    
    fileprivate static func willRemove(attribute: DGAttribute) {
        let instancePtr = attribute.info.body.assumingMemoryBound(to: CancallationReadingPhase.self)
        guard let resetCallback = instancePtr.pointee.resetCallback else {
            return
        }
        
        Update.enqueueAction(resetCallback)
    }
    
    fileprivate static func didReinsert(attribute: DGAttribute) {
        _intentionallyLeftBlank()
    }
    
    internal mutating func updateValue() {
        var reset = self.reset
        let hasReset = resetIfNeeded(&reset) {
            resetCancallation()
        }
        self.reset = reset
        
        guard hasReset else {
            return
        }
        
        let modifier = DGGraphRef.withoutUpdate {
            self.modifier
        }
        let cancallation = modifier.cancellation
        
        resetCallback = {
            cancallation.isCancelled = false
        }
        
        // Check if cancellation is triggered and update phase
        if modifier.cancellation.wrappedValue {
            value = .failed
        } else {
            value = phase
        }
    }
    
    private func resetCancallation() {
        guard let resetCallback else {
            return
        }
        Update.enqueueAction {
            resetCallback()
        }
    }
    
}
