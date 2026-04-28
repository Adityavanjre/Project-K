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
    
    /// Combines two gestures exclusively to create a new gesture where only one
    /// gesture succeeds, giving precedence to the first gesture.
    ///
    /// - Parameter other: A gesture you combine with your gesture, to create a
    ///   new, combined gesture.
    ///
    /// - Returns: A gesture that's the result of combining two gestures where
    ///   only one of them can succeed. DanceUI gives precedence to the first
    ///   gesture.
    @inlinable
    public func exclusively<Other>(before other: Other) -> ExclusiveGesture<Self, Other> where Other : Gesture {
        ExclusiveGesture(self, other)
    }
    
}

/// A gesture that consists of two gestures where only one of them can succeed.
///
/// The `ExclusiveGesture` gives precedence to its first gesture.
@frozen
@available(iOS 13.0, *)
public struct ExclusiveGesture<First: Gesture, Second: Gesture> : Gesture {
    
    /// The value of an exclusive gesture that indicates which of two gestures
    /// succeeded.
    @frozen
    public enum Value {
        
        /// The first of two gestures succeeded.
        case first(First.Value)
        
        /// The second of two gestures succeeded.
        case second(Second.Value)
    }
    
    /// The first of two gestures.
    public var first: First
    
    /// The second of two gestures.
    public var second: Second
    
    /// Creates a gesture from two gestures where only one of them succeeds.
    ///
    /// - Parameters:
    ///   - first: The first of two gestures. This gesture has precedence over
    ///     the other gesture.
    ///   - second: The second of two gestures.
    @inlinable
    public init(_ first: First, _ second: Second) {
        (self.first, self.second) = (first, second)
    }
    
    public static func _makeGesture(gesture: _GraphValue<ExclusiveGesture<First, Second>>, inputs: _GestureInputs) -> _GestureOutputs<ExclusiveGesture<First, Second>.Value> {
        if DanceUIFeature.gestureContainer.isEnable {
            let firstGesturePhase = First._makeGesture(gesture: gesture[{.of(&$0.first)}], inputs: inputs)
            
            let exclusiveState = ExclusiveState(state: inputs.inheritedPhase, phase: firstGesturePhase.phase)
            
            let exclusiveInheritedPhase = DanceUIGraph.Attribute(exclusiveState)
            
            var copiedInputs = inputs
            copiedInputs.inheritedPhase = exclusiveInheritedPhase
            
            let secondGesturePhase = Second._makeGesture(gesture: gesture[{.of(&$0.second)}], inputs: copiedInputs)
            
            let exclusivePhase = ExclusivePhase<First, Second>(phase1: firstGesturePhase.phase, phase2: secondGesturePhase.phase)
            
            var visitor = ExclusivePreferenceCombinerVisitor<First, Second>(phase1: firstGesturePhase.phase, phase2: secondGesturePhase.phase, outputs: (firstGesturePhase.preferences, secondGesturePhase.preferences), result: PreferencesOutputs())
            
            for key in inputs.preferences.keys {
                key.visitKey(&visitor)
            }
            
            return _GestureOutputs(phase: Attribute(exclusivePhase), preferences: visitor.result)
        } else {
            return .makeBinaryFiltered(
                style: .exclusive,
                parent: gesture,
                inputs: inputs) { gesture, inputs in
                    let outputs = First._makeGesture(gesture: gesture[{.of(&$0.first)}], inputs: inputs)
                    let state = Attribute(ExclusiveState(state: inputs.inheritedPhase, phase: outputs.phase))
                    inputs.inheritedPhase = state
                    return outputs
                } makeOutputs2: { gesture, inputs in
                    Second._makeGesture(gesture: gesture[{.of(&$0.second)}], inputs: inputs)
                } makePhase: { outputs1, outputs2, _, _, _ in
                    Attribute(ExclusivePhase<First, Second>(phase1: outputs1.phase,
                                                            phase2: outputs2.phase))
                }
        }
    }
    
    public typealias Body = Never
    
}

@available(iOS 13.0, *)
extension ExclusiveGesture.Value : Equatable where First.Value : Equatable, Second.Value : Equatable {
    
}

@available(iOS 13.0, *)
internal struct ExclusiveState<Event>: Rule {
    
    internal typealias Value = _GestureInputs.InheritedPhase
    
    @Attribute
    internal var state: Value

    @Attribute
    internal var phase: GesturePhase<Event>
    
    internal var value: _GestureInputs.InheritedPhase {
        
        let ancestorInheritedPhase = self.state
        
        let ancestorGesturePhase = self.phase
        
        let noFailed: Value
        
        switch ancestorGesturePhase {
        case .failed:
            noFailed = ancestorInheritedPhase
        default:
            noFailed = ancestorInheritedPhase.subtracting(.failed)
        }
        
        let hasActive: Value
        
        switch ancestorGesturePhase {
        case .active:
            hasActive = noFailed.union(.active)
        default:
            hasActive = noFailed
        }
        
        return noFailed.contains(.active) ? noFailed : hasActive
    }
    
}

@available(iOS 13.0, *)
internal struct ExclusivePhase<Gesture1: Gesture, Gesture2: Gesture>: Rule {
    
    internal typealias PhaseValue = ExclusiveGesture<Gesture1, Gesture2>.Value
    
    internal typealias Value = GesturePhase<PhaseValue>
        
    @Attribute
    internal var phase1: GesturePhase<Gesture1.Value>

    @Attribute
    internal var phase2: GesturePhase<Gesture2.Value>
    
    internal var value: Value {
        let phase1 = self.phase1
        let phase2 = self.phase2
        
        let phase: GesturePhase<PhaseValue>
        
        switch (phase1, phase2) {
        case let (.active(value1), _):
            phase = .active(.first(value1))
        case let (.ended(value1), _):
            phase = .ended(.first(value1))
        case (.failed, .possible(.some(_))):
            phase = .possible(nil)
        case (.failed, _):
            phase = phase2.map { .second($0) }
        case (.possible, let .active(value2)):
            phase = .active(.second(value2))
        case (.possible, _):
            phase = .possible(nil)
        }
        
        return phase
    }

}

@available(iOS 13.0, *)
private struct ExclusivePreference<Gesture1: Gesture, Gesture2: Gesture, Key: PreferenceKey>: Rule {
    
    internal typealias PhaseValue = ExclusiveGesture<Gesture1, Gesture2>.Value
    
    internal typealias Value = Key.Value
        
    @DanceUIGraph.Attribute
    internal var phase1: GesturePhase<Gesture1.Value>

    @DanceUIGraph.Attribute
    internal var phase2: GesturePhase<Gesture2.Value>
    
    @OptionalAttribute
    var value1: Value?
    
    @OptionalAttribute
    var value2: Value?
    
    internal var value: Value {
        let value1 = self.value1
        let value2 = self.value2
        
        let value: Value
        
        switch (phase1, phase2) {
        case (.active, _):
            value = value1 ?? Key.defaultValue
        case (.ended, _):
            value = value1 ?? Key.defaultValue
        case (.failed, .possible(.some(_))):
            value = Key.defaultValue
        case (.failed, _):
            value = value2 ?? Key.defaultValue
        case (.possible, .active):
            value = value2 ?? Key.defaultValue
        case (.possible, _):
            value = Key.defaultValue
        }
        
        return value
    }

}

@available(iOS 13.0, *)
internal struct ExclusivePreferenceCombinerVisitor<Gesture1: Gesture, Gesture2: Gesture>: PreferenceKeyVisitor {
    
    @DanceUIGraph.Attribute
    internal var phase1: GesturePhase<Gesture1.Value>
    
    @DanceUIGraph.Attribute
    internal var phase2: GesturePhase<Gesture2.Value>

    internal var outputs: (PreferencesOutputs, PreferencesOutputs)

    internal var result: PreferencesOutputs
    
    @inline(__always)
    internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
        
        let value0 = outputs.0[key]
        let value1 = outputs.1[key]
        
        guard value0 != nil || value1 != nil else {
            return
        }
        
        result[key] = .init(ExclusivePreference<Gesture1, Gesture2, Key>(phase1: $phase1, phase2: $phase2, value1: OptionalAttribute(value0), value2: OptionalAttribute(value1)))
    }
    
}
