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
    
    @inline(__always)
    internal func map2<ContentGesture: Gesture, PhaseValue>(contentGesture: ContentGesture, transform: @escaping (_ childPhase: GesturePhase<Value>, _ contentPhase: GesturePhase<ContentGesture.Value>) -> GesturePhase<PhaseValue>) -> ModifierGesture<Map2Gesture<Value, ContentGesture, PhaseValue>, Self>{
        modifier(Map2Gesture(content: contentGesture, body: transform))
    }
    
    internal func gated<GateGesture: Gesture>(by gesture: GateGesture) -> ModifierGesture<Map2Gesture<Value, GateGesture, Value>, Self> {
        if DanceUIFeature.gestureContainer.isEnable {
            map2(contentGesture: gesture, transform: gatedByBody2)
        } else {
            map2(contentGesture: gesture, transform: gatedByBody)
        }
    }
    
}

@available(iOS 13.0, *)
private func gatedByBody<Event0, Event1>(childPhase: GesturePhase<Event0>, contentPhase: GesturePhase<Event1>) -> GesturePhase<Event0> {
    switch (childPhase, contentPhase) {
    case (_, .failed):
     return .failed
    case (.possible, _),
         (.active, _),
         (.ended, _):
        return childPhase
    default:
        return childPhase
    }
}

@available(iOS 13.0, *)
private func gatedByBody2<Event0, Event1>(childPhase: GesturePhase<Event0>, contentPhase: GesturePhase<Event1>) -> GesturePhase<Event0> {
    switch contentPhase {
    case .failed:
        return .failed
    default:
        return childPhase
    }
}

#if BINARY_COMPATIBLE_TEST
@available(iOS 13.0, *)
internal func fileprivate_gatedByBody<Value, Value1>(phase0: GesturePhase<Value>, phase1: GesturePhase<Value1>) -> GesturePhase<Value> {
    gatedByBody(phase0: phase0, phase1: phase1)
}

#endif
@available(iOS 13.0, *)
internal struct Map2Gesture<BodyValue, Content: Gesture, PhaseValue>: GestureModifier {
    
    internal typealias Value = PhaseValue
    
    internal var content: Content

    internal var body: (GesturePhase<BodyValue>, GesturePhase<Content.Value>) -> GesturePhase<PhaseValue>
    
    internal static func _makeGesture(modifier: _GraphValue<Map2Gesture<BodyValue, Content, PhaseValue>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<PhaseValue> {
        let outputs1 = body(inputs)
        let inputs2 = inputs
        let outputs2 = if DanceUIFeature.gestureContainer.isEnable {
            Content.makeDebuggableGesture(gesture: modifier[{ .of(&$0.content) }], inputs: inputs2)
        } else {
            Content._makeGesture(gesture: modifier[{ .of(&$0.content) }], inputs: inputs2)
        }
        
        let phase = Attribute(
            Map2Phase(
                body: modifier[\Map2Gesture.body].value,
                phase1: outputs1.phase,
                phase2: outputs2.phase,
                resetSeed: inputs.resetSeed,
                reset: .init(seed: 0)
            )
        )
        
        if DanceUIFeature.gestureContainer.isEnable {
            var base = _GestureOutputs(phase: phase, preferences: PreferencesOutputs())
            
            var visitor = PairwisePreferenceCombinerVisitor_FeatureGestureContainer(outputs: (outputs1.preferences, outputs2.preferences), result: PreferencesOutputs())
            for key in inputs.preferences.keys {
                key.visitKey(&visitor)
            }
            
            base.preferences = visitor.result
            
            return base
        } else {
            return .makeMerged(phase: phase, inputs: inputs, outputs1: outputs1, outputs2: outputs2)
        }
    }

}

@available(iOS 13.0, *)
//CustomStringConvertible
fileprivate struct Map2Phase<A, B, PhaseValue>: ResettableGestureRule {

    internal typealias Value = GesturePhase<PhaseValue>

    @Attribute
    internal var body: (GesturePhase<A>, GesturePhase<B>) -> GesturePhase<PhaseValue>

    @Attribute
    internal var phase1: GesturePhase<A>

    @Attribute
    internal var phase2: GesturePhase<B>

    @Attribute
    internal var resetSeed: UInt32

    internal var reset: GestureReset
    
    internal mutating func updateValue() {
        guard resetIfNeeded(&reset) else {
            return
        }
        value = body(phase1, phase2)
    }

}
