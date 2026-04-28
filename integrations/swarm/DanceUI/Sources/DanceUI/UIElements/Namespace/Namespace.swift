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

import Foundation
internal import DanceUIGraph

/// A dynamic property type that allows access to a namespace defined
/// by the persistent identity of the object containing the property
/// (e.g. a view).
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct Namespace: DynamicProperty {
    
    /// A namespace defined by the persistent identity of an
    /// `@Namespace` dynamic property.
    @frozen
    public struct ID: Hashable, Equatable {
        
        fileprivate var id: Int
        
        internal init() {
            id = 0
        }
        
        internal init(id: Int) {
            self.id = id
        }
    }
    
    fileprivate struct Box: DynamicPropertyBox {
        
        typealias Property = Namespace
        
        internal var id: Int
        
        internal init() {
            id = 0
        }
        
        internal mutating func reset() {
            self.id = 0
        }
        
        internal mutating func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
            var updated = false
            if self.id == 0 {
                self.id = numericCast(DGMakeUniqueID().rawValue)
                updated = true
            }
            
            property.id = self.id
            return updated
        }
    }
    
    @usableFromInline
    internal var id: Int
    
    public var wrappedValue: ID {
        guard id == 0 else {
            return ID(id: self.id)
        }
        
        return ID(id: numericCast(DGMakeUniqueID().rawValue))
    }
    
    @inlinable
    public init() {
        id = 0
    }
    
    public static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        buffer.append(Box(), fieldOffset: fieldOffset)
    }
}
