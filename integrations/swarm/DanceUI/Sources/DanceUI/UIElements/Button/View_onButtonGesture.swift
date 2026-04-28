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
    
    @ViewBuilder
    public func _onButtonGesture(pressing: ((Bool) -> Void)? = nil,
                                 perform action: @escaping () -> Void) -> some View {
        if DanceUIFeature.gestureContainer.isEnable {
            buttonActionGestureContainer(
                highlight: PressableGesture(pressingAction: pressing),
                action: ButtonActionGesture(action: action)
            )
        } else {
            buttonAction(_ButtonGesture(action: action, pressingAction: pressing))
        }
    }
    
}

@available(iOS 13.0, *)
internal struct PressableGesture: PrimitiveGesture {
    
    internal let hasBoundary: Bool
    
    internal let pressingAction: ((Bool) -> Void)?
    
    internal init(hasBoundary: Bool = true, pressingAction: ((Bool) -> Void)?) {
        self.hasBoundary = hasBoundary
        self.pressingAction = pressingAction
    }
    
    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        let child = Attribute(Child(gesture: gesture.value))
        
        let outputs = Child.Value._makeGesture(gesture: _GraphValue(child), inputs: inputs)
        
        let phase = Attribute(Phase(phase: outputs.phase))
        
        return outputs.withPhase(phase)
    }
    
    internal struct Recognizer: Gesture {
        
        internal typealias _Body = ModifierGesture<
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
        
        internal let hasBoundary: Bool
        
        internal var _body: _Body {
            SizeGesture { size in
                EventListener<SpatialEvent>()
                    .mapPhase { phase -> GesturePhase<Value> in
                    switch phase {
                    case .possible(.none):
                        return .possible(nil)
                    case .possible(.some(let spatialEvent)):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside, hasBoundary: hasBoundary)
                        return .possible(inside ? value : nil)
                    case .active(let spatialEvent):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside, hasBoundary: hasBoundary)
                        return .active(value)
                    case .ended(let spatialEvent):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside, hasBoundary: hasBoundary)
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
            
            internal let hasBoundary: Bool
            
            private var isPressing: Bool {
                if hasBoundary {
                    return inside
                } else {
                    return true
                }
            }
            
            static func isPressing(_ phase: GesturePhase<Self>) -> Bool {
                switch phase {
                case .possible(.none):
                    return false
                case .possible(.some(let event)), .active(let event), .ended(let event):
                    return event.isPressing
                case .failed:
                    return false
                }
            }
            
        }
        
        internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
            _Body._makeGesture(gesture: gesture[\._body], inputs: inputs)
        }
        
    }
    
    fileprivate struct Child: Rule {
        
        fileprivate typealias Value = ModifierGesture<
            CallbacksGesture<PressableGestureCallbacks<Recognizer.Value>>,
            Recognizer
        >
                
        @Attribute
        fileprivate var gesture: PressableGesture
        
        fileprivate var value: Value {
            let gesture = self.gesture
            return Recognizer(bounds: nil, outsetWidth: 70, hasBoundary: gesture.hasBoundary)
                .pressable(pressing: gesture.pressingAction, pressed: nil)
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

@available(iOS 13.0, *)
internal struct ButtonActionGesture: PrimitiveGesture {
    
    internal let hasBoundary: Bool
    
    internal var action: () -> Void
    
    internal init(hasBoundary: Bool = true, action: @escaping (() -> Void)) {
        self.hasBoundary = hasBoundary
        self.action = action
    }
    
    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        let child = Attribute(Child(gesture: gesture.value))
        
        let outputs = Child.Value._makeGesture(gesture: _GraphValue(child), inputs: inputs)
        
        let phase = Attribute(Phase(phase: outputs.phase))
        
        return outputs.withPhase(phase)
    }
    
    internal struct Recognizer: Gesture {
        
        internal typealias _Body = ModifierGesture<
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
        
        internal let hasBoundary: Bool
        
        internal var _body: _Body {
            SizeGesture { size in
                EventListener<SpatialEvent>()
                    .mapPhase { phase -> GesturePhase<Value> in
                    switch phase {
                    case .possible(.none):
                        return .possible(nil)
                    case .possible(.some(let spatialEvent)):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside, hasBoundary: hasBoundary)
                        return .possible(inside ? value : nil)
                    case .active(let spatialEvent):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside, hasBoundary: hasBoundary)
                        return .possible(value)
                    case .ended(let spatialEvent):
                        let rect = (bounds ?? CGRect(origin: .zero, size: size))
                        let insetRect = rect.insetBy(dx: -outsetWidth, dy: -outsetWidth)
                        let inside = insetRect.contains(spatialEvent.location)
                        let value = Value(location: spatialEvent.location, timestamp: spatialEvent.timestamp, inside: inside, hasBoundary: hasBoundary)
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
            
            internal let hasBoundary: Bool
            
            private var isPressing: Bool {
                if hasBoundary {
                    return inside
                } else {
                    return true
                }
            }
            
        }
        
        internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
            _Body._makeGesture(gesture: gesture[\._body], inputs: inputs)
        }
        
    }
    
    fileprivate struct Child: Rule {
        
        fileprivate typealias Value = ModifierGesture<
            CallbacksGesture<PressableGestureCallbacks<Recognizer.Value>>,
            Recognizer
        >
                
        @Attribute
        fileprivate var gesture: ButtonActionGesture
        
        fileprivate var value: Value {
            let gesture = self.gesture
            return Recognizer(bounds: nil, outsetWidth: 70, hasBoundary: gesture.hasBoundary)
                .pressable(pressing: nil, pressed: gesture.action)
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
