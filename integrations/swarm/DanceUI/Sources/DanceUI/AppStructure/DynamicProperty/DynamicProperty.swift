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

/// An interface for a stored variable that updates an external property of a
/// view.
///
/// The view gives values to these properties prior to recomputing the view's
/// ``View/body-swift.property``.
@available(iOS 13.0, *)
public protocol DynamicProperty {

    /// - Parameter name: The name of the field.
    ///
    static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs)

    /// Updates the underlying value of the stored value.
    ///
    /// DanceUI calls this function before rendering a view's
    /// ``View/body-swift.property`` to ensure the view has the most recent
    /// value.
    mutating func update()
    
    static var _propertyBehaviors: UInt32 { get }
    
}

@available(iOS 13.0, *)
extension DynamicProperty {
    
    /// Updates the underlying value of the stored value.
    ///
    /// DanceUI calls this function before rendering a view's
    /// ``View/body-swift.property`` to ensure the view has the most recent
    /// value.
    public mutating func update() {
        _intentionallyLeftBlank()
    }
    
    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<V>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        makeEmbeddedProperties(in: &buffer, container: container, fieldOffset: fieldOffset, inputs: &inputs)
        buffer.append(EmbeddedDynamicPropertyBox<Self>(), fieldOffset: fieldOffset)
    }
    
    internal static func makeEmbeddedProperties<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, inputs: inout _GraphInputs) {
        let fields = DynamicPropertyCache.fields(of: self)
        buffer.addFields(fields, container: container, inputs: &inputs, baseOffset: fieldOffset)
    }
    
    public static var _propertyBehaviors: UInt32 {
        0
    }
    
}

@available(iOS 13.0, *)
fileprivate struct EmbeddedDynamicPropertyBox<Property: DynamicProperty>: DynamicPropertyBox {
    
    fileprivate func destroy() {
        
    }
    
    fileprivate func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
        property.update()
        return false
    }
    
}
