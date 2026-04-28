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

/// An instance that matches a sequence of events to a gesture, and returns a
/// stream of values for each of its states.
///
/// Create custom gestures by declaring types that conform to the `Gesture`
/// protocol.
@available(iOS 13.0, *)
public protocol Gesture<Value> {
    
    /// The type representing the gesture's value.
    associatedtype Value
    
    static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Self.Value>
    
    /// The type of gesture representing the body of `Self`.
    associatedtype Body : Gesture
    
    /// The content and behavior of the gesture.
    var body: Self.Body { get }
    
}

@available(iOS 13.0, *)
extension Gesture {
    
    internal static func makeDebuggableGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        guard DanceUIFeature.gestureContainer.isEnable else {
            return Self._makeGesture(gesture: gesture, inputs: inputs)
        }
        
        var gestureOutputs = Self._makeGesture(gesture: gesture, inputs: inputs)
        
        gestureOutputs.wrapDebugOutputs(Self.self, properties: nil, inputs: inputs)
        
        return gestureOutputs
    }
    
}

@available(iOS 13.0, *)
extension Gesture where Value == Body.Value {
    
    public static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Body.Value> {
        let value = _GraphValue(Child(gesture: gesture.value))
        
        return Body._makeGesture(gesture: value, inputs: inputs)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct Child<G: Gesture>: Rule {
        
    fileprivate typealias Value = G.Body
    
    @Attribute
    fileprivate var gesture: G
    
    fileprivate var value: G.Body {
        gesture.body
    }

}

@available(iOS 13.0, *)
extension Gesture where Body == Never {

    public var body: Body {
        _terminatedViewNode()
    }

}

@available(iOS 13.0, *)
extension Never: Gesture {
    
    public typealias Value = Never
    
}

@available(iOS 13.0, *)
extension Optional: Gesture where Wrapped : Gesture {
    
    public typealias Value = Wrapped.Value
    
    public static func _makeGesture(gesture: _GraphValue<Wrapped?>, inputs: _GestureInputs) -> _GestureOutputs<Wrapped.Value> {
        AnyGesture._makeGesture(gesture: _GraphValue(Child(gesture: gesture.value)), inputs: inputs)
    }
    
    
    private struct Child: Rule {
        
        fileprivate typealias Value = AnyGesture<Wrapped.Value>

        @Attribute
        fileprivate var gesture: Wrapped?
        
        fileprivate var value: AnyGesture<Wrapped.Value> {
            gesture.map {
                AnyGesture($0)
            } ?? AnyGesture(Empty())
        }

    }
    
    
    private struct Empty: Gesture {

        fileprivate typealias Value = Wrapped.Value
        
        fileprivate static func _makeGesture(gesture: _GraphValue<Empty>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
            if DanceUIFeature.gestureContainer.isEnable {
                inputs.makeDefaultOutputs()
            } else {
                .makeTerminal(from: inputs, with: Attribute(value: .failed))
            }
        }
        
    }
    
}


/// Options that control how adding a gesture to a view affect's other gestures
/// recognized by the view and its subviews.
@frozen
@available(iOS 13.0, *)
public struct GestureMask : OptionSet {
    
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    /// Disable all gestures in the subview hierarchy, including the added
    /// gesture.
    public static let none: GestureMask = .init()
    
    /// Enable the added gesture but disable all gestures in the subview
    /// hierarchy.
    public static let gesture: GestureMask = GestureMask(rawValue: 0x1)
    
    /// Enable all gestures in the subview hierarchy but disable the added
    /// gesture.
    public static let subviews: GestureMask = GestureMask(rawValue: 0x2)
    
    /// Enable both the added gesture as well as all other gestures on the view
    /// and its subviews.
    public static let all: GestureMask = [gesture, subviews]
    
    public typealias Element = GestureMask
    
    public typealias ArrayLiteralElement = GestureMask
    
    public typealias RawValue = UInt32
    
}

@available(iOS 13.0, *)
internal struct GestureReset {

    internal var seed: UInt32

    @inline(__always)
    internal init(seed: UInt32) {
        self.seed = seed
    }
    
    @inline(__always)
    internal init() {
        self.seed = 0
    }
}

@available(iOS 13.0, *)
internal protocol PrimitiveGesture: Gesture {
    
    
}

@available(iOS 13.0, *)
extension PrimitiveGesture {

    public var body: Never {
        _danceuiFatalError()
    }

}
