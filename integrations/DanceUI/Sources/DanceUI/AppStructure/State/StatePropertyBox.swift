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
internal struct StatePropertyBox<Value>: DynamicPropertyBox {
    
    internal typealias Property = State<Value>
    
    internal var signal: WeakAttribute<Void>

    internal var location: StoredLocation<Value>?
    
    internal mutating func update(property: inout Property,
                                  phase: _GraphInputs.Phase) -> Bool {
        let updatedLocation: StoredLocation<Value>
        
        let isNewLocation: Bool
        
        if let location = location {
            updatedLocation = location
            isNewLocation = false
        } else {
            if let propertyLocation = property._location as? StoredLocation {
                updatedLocation = propertyLocation
            } else {
                updatedLocation = StoredLocation(initialValue: property._value,
                                                 host: GraphHost.currentHost,
                                                 signal: signal)
                location = updatedLocation
            }
            isNewLocation = true
        }
        
        let isChanged = self.signal.attribute?.changedValue().changed ?? false
        
        Trace.emitEvent(module: .dataFlow, 
                        component: .state,
                        subject: .statePropertyBoxSignal,
                        name: .did(.test),
                        SignalAttributeChangedValueTraceMetadata(attribute: signal, isChanged: isChanged))
        
        let updateValue = updatedLocation.updateValue
        
        property._value = updateValue
        
        property._location = updatedLocation
        
        return isNewLocation || (isChanged ? updatedLocation.wasRead : false)
    }
    
    internal func getState<OtherValue>(type: OtherValue.Type) -> Binding<OtherValue>? {
        if let location = location as? AnyLocation<OtherValue> {
            let value = location.get()
            return Binding(value: value, location: location, transaction: Transaction())
        } else {
            return nil
        }
    }
    
    internal mutating func reset() {
        location = nil
    }
    
}
