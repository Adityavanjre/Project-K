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
public struct _ButtonGesture: Gesture {
    
    public var action: () -> Void
    
    public var pressingAction: ((Bool) -> Void)?
    
    public static func _makeGesture(gesture: _GraphValue<_ButtonGesture>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        let child = Attribute(Child(gesture: gesture.value))
        
        let outputs = Child.Value._makeGesture(gesture: _GraphValue(child), inputs: inputs)
        
        let phase = Attribute(Phase(phase: outputs.phase))
        
        return outputs.withPhase(phase)
    }
    
    internal struct Recognizer: Gesture {
        
        internal typealias Body = ModifierGesture<
            EventFilter<Value>,
            ModifierGesture<
                DependentGesture<Value>,
                SizeGesture<
                    ModifierGesture<
                        MapGesture<SpatialEvent, Value>,
                        EventListener<SpatialEvent>
                    >
                >
            >
        >
        
        internal var bounds: CGRect?
        
        internal var outsetWidth: CGFloat
        
        internal var body: Body {
            SizeGesture { size in
                EventListener<SpatialEvent>()
                    .mapPhase { phase -> GesturePhase<Value> in
                    switch phase {
                    case .possible(.none):
                        return .possible(nil)
                    case let .active(spatialEvent),
                         let .possible(.some(spatialEvent)):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside)
                        return .possible(inside ? value : nil)
                    case let .ended(spatialEvent):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside)
                        return inside ? .ended(value) : .failed
                    case .failed:
                        return .failed
                    }
                }
            }
            .dependency(.failIfActive) // iOS 18.5 verified
            .eventFilter(MouseEvent.self, allowOtherTypes: true) { mouseEvent in
                mouseEvent.button.rawValue == 0x1
            }
        }
        
        internal struct Value: PressableEventValue {
            
            internal var location: CGPoint
            
            internal var timestamp: Time
            
            internal var inside: Bool
            
        }
        
    }
    
    fileprivate struct Child: Rule {
        
        fileprivate typealias Value = ModifierGesture<
            CallbacksGesture<PressableGestureCallbacks<Recognizer.Value>>,
            Recognizer
        >
                
        @Attribute
        fileprivate var gesture: _ButtonGesture
        
        fileprivate var value: Value {
            let gesture = self.gesture
            return Recognizer(bounds: nil, outsetWidth: 70)
                .pressable(pressing: gesture.pressingAction, pressed: gesture.action)
        }

    }
    
    fileprivate struct Phase: Rule {
        
        fileprivate typealias Value = GesturePhase<Void>
        
        @Attribute
        fileprivate var phase: GesturePhase<Recognizer.Value>
        
        fileprivate var value: GesturePhase<Void> {
            phase.set(Void())
        }

    }
    
}
