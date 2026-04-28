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
    
    internal func gestureRecognizerObserver(_ observer: AnyUIGestureRecognizerObserver?) -> ModifierGesture<GestureRecognizerObserverGesture<Value>, Self> {
        modifier(GestureRecognizerObserverGesture(observer: observer))
    }
    
}

@available(iOS 13.0, *)
internal struct GestureRecognizerObserverGesture<Value>: GestureModifier {
    
    internal typealias BodyValue = Value
    
    internal var observer: AnyUIGestureRecognizerObserver?
    
    internal static func _makeGesture(modifier: _GraphValue<Self>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<Value>) -> _GestureOutputs<Value> {
        var base = body(inputs)
        if inputs.requiresActiveGestureRecognizerObservers {
            let attribute = Attribute(
                ActiveGestureRecognizerObserverFilter(
                    phase: base.phase,
                    observer: modifier.value.observer,
                    previous: OptionalAttribute(base.activeGestureRecognizerObservers)
                )
            )
            base = base.withActiveGestureRecognizerObservers(attribute)
        }
        return base
    }
    
}
@available(iOS 13.0, *)
internal typealias AnyUIGestureRecognizerObserver = UIGestureRecognizer & AnyHostedGestureObserving
@available(iOS 13.0, *)
extension Optional where Wrapped == [AnyUIGestureRecognizerObserver] {
    
    internal static func + (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case (.some(let lhs), .some(let rhs)): return lhs + rhs
        case (.some(let lhs), .none): return lhs
        case (.none, .some(let rhs)): return rhs
        case (.none, .none): return nil
        }
    }
    
}

@available(iOS 13.0, *)
private struct ActiveGestureRecognizerObserverFilter<PhaseValue>: Rule {
    
    fileprivate typealias Value = [AnyUIGestureRecognizerObserver]
    
    @Attribute
    fileprivate var phase: GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var observer: AnyUIGestureRecognizerObserver?
    
    @OptionalAttribute
    fileprivate var previous: [AnyUIGestureRecognizerObserver]?
    
    @inline(__always)
    fileprivate init(phase: Attribute<GesturePhase<PhaseValue>>,
                     observer: Attribute<AnyUIGestureRecognizerObserver?>,
                     previous: OptionalAttribute<[AnyUIGestureRecognizerObserver]>) {
        self._phase = phase
        self._observer = observer
        self._previous = previous
    }
    
    fileprivate var value: Value {
        guard phase.hasBegan else {
            return []
        }
        
        switch (previous, observer) {
        case (.some(var previous), .some(let observer)):
            previous.append(observer)
            return previous
        case (.some(let previous), .none):
            return previous
        case (.none, .some(let observer)):
            return [observer]
        case (.none, .none):
            return []
        }
        
    }
    
}
