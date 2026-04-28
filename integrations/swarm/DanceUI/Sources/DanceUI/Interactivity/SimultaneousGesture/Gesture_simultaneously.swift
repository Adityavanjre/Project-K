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
    
    /// Combines a gesture with another gesture to create a new gesture that
    /// recognizes both gestures at the same time.
    ///
    /// - Parameter other: A gesture that you want to combine with your gesture
    ///   to create a new, combined gesture.
    ///
    /// - Returns: A gesture with two simultaneous gestures.
    @inlinable
    public func simultaneously<Other>(with other: Other) -> SimultaneousGesture<Self, Other> where Other : Gesture {
        SimultaneousGesture(self, other)
    }
    
}


/// A gesture containing two gestures that can happen at the same time with
/// neither of them preceding the other.
///
/// A simultaneous gesture is a container-event handler that evaluates its two
/// child gestures at the same time. Its value is a struct with two optional
/// values, each representing the phases of one of the two gestures.
@frozen
@available(iOS 13.0, *)
public struct SimultaneousGesture<First: Gesture, Second: Gesture>: Gesture {
    
    /// The value of a simultaneous gesture that indicates which of its two
    /// gestures receives events.
    @frozen
    public struct Value {
        
        /// The value of the first gesture.
        public var first: First.Value?
        
        /// The value of the second gesture.
        public var second: Second.Value?
        
    }
    
    /// The first of two gestures that can happen simultaneously.
    public var first: First
    
    /// The second of two gestures that can happen simultaneously.
    public var second: Second
    
    /// Creates a gesture with two gestures that can receive updates or succeed
    /// independently of each other.
    ///
    /// - Parameters:
    ///   - first: The first of two gestures that can happen simultaneously.
    ///   - second: The second of two gestures that can happen simultaneously.
    @inlinable
    public init(_ first: First, _ second: Second) {
        (self.first, self.second) = (first, second)
    }
    
    public static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        if DanceUIFeature.gestureContainer.isEnable {
            let firstOutputs = First._makeGesture(gesture: gesture[{.of(&$0.first)}], inputs: inputs)
            let secondOutputs = Second._makeGesture(gesture: gesture[{.of(&$0.second)}], inputs: inputs)
            let phase = SimultaneousPhase<First, Second>(phase1: firstOutputs.phase, phase2: secondOutputs.phase)
            
            var visitor = SimultaneousPreferenceCombinerVisitor<First, Second>(phase1: firstOutputs.phase, phase2: secondOutputs.phase, outputs: (firstOutputs.preferences, secondOutputs.preferences), result: PreferencesOutputs())
            
            for key in inputs.preferences.keys {
                key.visitKey(&visitor)
            }
            
            return _GestureOutputs(phase: Attribute(phase), preferences: visitor.result)
        } else {
            return .makeBinaryFiltered(
                style: .simultaneous,
                parent: gesture,
                inputs: inputs) { gesture, inputs in
                    First._makeGesture(gesture: gesture[{.of(&$0.first)}], inputs: inputs)
                } makeOutputs2: { gesture, inputs in
                    Second._makeGesture(gesture: gesture[{.of(&$0.second)}], inputs: inputs)
                } makePhase: { outputs1, outputs2, _, _, _ in
                    Attribute(SimultaneousPhase<First, Second>(phase1: outputs1.phase,
                                                               phase2: outputs2.phase))
                }
        }
    }
    
    /// The type of gesture representing the body of `Self`.
    public typealias Body = Never
}

@available(iOS 13.0, *)
internal struct SimultaneousPhase<A: Gesture, B: Gesture>: Rule {
    
    internal typealias Value = GesturePhase<SimultaneousGesture<A, B>.Value>
    
    @Attribute
    internal var phase1: GesturePhase<A.Value>

    @Attribute
    internal var phase2: GesturePhase<B.Value>
    
    internal var value: Value {
        let phase1 = self.phase1
        let phase2 = self.phase2
        
        let phase: GesturePhase<SimultaneousGesture<A, B>.Value>
        
        switch (phase1, phase2) {
        case (.active(_), _), (_, .active(_)):
            phase = .active(.init(first: phase1.unwrapped, second: phase2.unwrapped))
        case (.possible(_), _), (_, .possible(_)):
            phase = .possible(nil)
        case let (.ended(phase1Value), .ended(phase2Value)):
            phase = .ended(.init(first: phase1Value, second: phase2Value))
        case let (.ended(phase1Value), .failed):
            phase = .ended(.init(first: phase1Value, second: nil))
        case let (.failed, .ended(phase2Value)):
            phase = .ended(.init(first: nil, second: phase2Value))
        case (.failed, .failed):
            phase = .failed
        }
        
        return phase
    }
}

@available(iOS 13.0, *)
extension SimultaneousGesture.Value: Equatable where First.Value: Equatable, Second.Value: Equatable {
    
}

@available(iOS 13.0, *)
extension SimultaneousGesture.Value: Hashable where First.Value: Hashable, Second.Value: Hashable {
    
}

@available(iOS 13.0, *)
private struct SimultaneousPreference<Gesture1: Gesture, Gesture2: Gesture, Key: PreferenceKey>: Rule {
    
    internal typealias PhaseValue = ExclusiveGesture<Gesture1, Gesture2>.Value
    
    internal typealias Value = Key.Value
    
    @OptionalAttribute
    var value1: Value?
    
    @OptionalAttribute
    var value2: Value?
    
    @Attribute
    internal var phase1: GesturePhase<Gesture1.Value>

    @Attribute
    internal var phase2: GesturePhase<Gesture2.Value>

    internal var value: Value {
        switch phase1 {
        case .possible:
            // If gesture1 is 'possible', the outcome depends on gesture2.
            switch phase2 {
            case .active:
                // If gesture2 is 'active', its value is used.
                return value2 ?? Key.defaultValue
            default:
                // In other cases (.possible, .ended, .failed), the values are merged.
                return mergedValue ?? Key.defaultValue
            }

        case .active:
            // If gesture1 is 'active', its value is often prioritized.
            switch phase2 {
            case .possible, .failed:
                // If gesture2 is 'possible' or 'failed', use gesture1's value.
                return value1 ?? Key.defaultValue
            default:
                // If gesture2 is also 'active' or has 'ended', merge the values.
                return mergedValue ?? Key.defaultValue
            }

        case .ended:
            // If gesture1 has 'ended', gesture2 takes precedence if active.
            switch phase2 {
            case .active:
                // If gesture2 is 'active', use its value.
                return value2 ?? Key.defaultValue
            default:
                // Otherwise, merge the values. This handles cases where both have ended.
                return mergedValue ?? Key.defaultValue
            }

        case .failed:
            // If gesture1 has 'failed', the result is determined by gesture2.
            switch phase2 {
            case .failed:
                // If both failed, return the default value.
                return Key.defaultValue
            default:
                // Otherwise, use gesture2's value.
                return value2 ?? Key.defaultValue
            }
        }
    }

    internal var mergedValue: Value? {
        var resultOrNil: Value? = nil
        
        if !phase1.isFailed {
            resultOrNil = self.value1
        }
        
        if !phase2.isFailed {
            if let value2 = self.value2 {
                if var result = resultOrNil {
                    Key.reduce(value: &result, nextValue: {value2})
                    resultOrNil = result
                } else {
                    resultOrNil = self.value2
                }
            }
        }
        
        return resultOrNil
    }

}

@available(iOS 13.0, *)
internal struct SimultaneousPreferenceCombinerVisitor<Gesture1: Gesture, Gesture2: Gesture>: PreferenceKeyVisitor {
    
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
        
        result[key] = .init(SimultaneousPreference<Gesture1, Gesture2, Key>(value1: OptionalAttribute(value0), value2: OptionalAttribute(value1), phase1: $phase1, phase2: $phase2))
    }
    
}
