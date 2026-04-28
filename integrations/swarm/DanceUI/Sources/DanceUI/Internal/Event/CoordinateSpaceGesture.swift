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
    
    internal func coordinateSpace(_ space: CoordinateSpace) -> ModifierGesture< CoordinateSpaceGesture<Value>, Self> {
        modifier(CoordinateSpaceGesture(coordinateSpace: space))
    }
    
}

@available(iOS 13.0, *)
internal struct CoordinateSpaceGesture<A>: GestureModifier {
    
    internal typealias Value = A
    
    internal typealias BodyValue = A

    internal var coordinateSpace: CoordinateSpace
    
    internal static func _makeGesture(modifier: _GraphValue<CoordinateSpaceGesture<A>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<A>) -> _GestureOutputs<A> {
        
        let animatedPosition = inputs.animatedPosition()
        
        let events = Attribute(
            CoordinateSpaceEvents(
                modifier: modifier.value,
                events: inputs.events,
                position: animatedPosition,
                transform: inputs.transform
            )
        )
        
        var newInputs = inputs
        newInputs.events = events
        newInputs.preconvertedEventLocations = true
        
        return body(newInputs)
    }

}

@available(iOS 13.0, *)
fileprivate struct CoordinateSpaceEvents<A>: Rule {

    fileprivate typealias Value = [EventID: EventType]

    @Attribute
    fileprivate var modifier: CoordinateSpaceGesture<A>

    @Attribute
    fileprivate var events: [EventID: EventType]

    @Attribute
    fileprivate var position: ViewOrigin

    @Attribute
    fileprivate var transform: ViewTransform
    
    fileprivate var value: [EventID : EventType] {

        var transform = self.transform
        
        transform.appendViewOrigin(position)
        
        var events = self.events
        
        defaultConvertEventLocations(&events) { points in
            transform.convert(.toGlobal, space: modifier.coordinateSpace, points: &points)
        }
        
        return events
    }

}
