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
    
    internal func dependency<Event>(_ dependency: GestureDependency) -> ModifierGesture<DependentGesture<Event>, Self> {
        modifier(DependentGesture(dependency: dependency))
    }
    
}

@available(iOS 13.0, *)
internal struct DependentGesture<Event>: GestureModifier {
    
    internal typealias Value = Event
    
    internal typealias BodyValue = Event
    
    internal var dependency: GestureDependency
    
    internal static func _makeGesture(modifier: _GraphValue<DependentGesture<Event>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<Event>) -> _GestureOutputs<Event> {
        
        var outputs = body(inputs)
        
        let phase = Attribute(
            DependentPhase(
                modifier: modifier.value,
                phase: outputs.phase,
                inheritedPhase: inputs.inheritedPhase
            )
        )
        
        if DanceUIFeature.gestureContainer.isEnable {
            if inputs.preferences.requiresGestureDependency {
                outputs.preferences.gestureDependency = modifier.value.dependency
            }
        }
        
        return outputs.withPhase(phase)
    }
    
}

@available(iOS 13.0, *)
extension PreferencesInputs {
    
    fileprivate var requiresGestureDependency: Bool {
        get {
            self.keys.contains(GestureDependency.Key.self)
        }
        mutating set {
            if newValue {
                add(GestureDependency.Key.self)
            } else {
                remove(GestureDependency.Key.self)
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension PreferencesOutputs {
    
    fileprivate var gestureDependency: Attribute<GestureDependency>? {
        get {
            return self[GestureDependency.Key.self]
        }
        set {
            self[GestureDependency.Key.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct DependentPhase<Event>: Rule {

    fileprivate typealias Value = GesturePhase<Event>

    @Attribute
    fileprivate var modifier: DependentGesture<Event>

    @Attribute
    fileprivate var phase: GesturePhase<Event>

    @Attribute
    fileprivate var inheritedPhase: _GestureInputs.InheritedPhase
    
    fileprivate var value: GesturePhase<Event> {
        inheritedPhase.phase(phase, with: modifier.dependency)
    }

}

@available(iOS 13.0, *)
extension _GestureInputs.InheritedPhase {
    
    fileprivate func phase<Event>(_ phase: GesturePhase<Event>, with dependency: GestureDependency) -> GesturePhase<Event> {
        switch dependency {
        case .none:
            return phase
        case .pausedWhileActive:
            if contains(.active) {
                return phase.paused()
            } else {
                return phase
            }
        case .pausedUntilFailed:
            if !contains(.failed) {
                return phase.paused()
            } else {
                return phase
            }
        case .failIfActive:
            if contains(.active) {
                return .failed
            } else if !contains(.failed) {
                return phase.paused()
            } else {
                return phase
            }
        }
    }
    
    
    #if BINARY_COMPATIBLE_TEST
    internal func fileprivate_phase<Event>(_ phase: GesturePhase<Event>, with dependency: GestureDependency) -> GesturePhase<Event> {
        self.phase(phase, with: dependency)
    }
    #endif
}

@available(iOS 13.0, *)
extension GesturePhase {
    
    internal func paused() -> GesturePhase {
        switch self {
        case let .active(event), let .ended(event):
            return .possible(event)
        default:
            return self
        }
    }
    
#if BINARY_COMPATIBLE_TEST
    internal func fileprivate_paused() -> GesturePhase {
        paused()
    }
#endif
    
}
