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

@available(iOS 13.0, *)
internal struct IdentityLink : DynamicProperty {

    internal var _value: ViewIdentity

    internal static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        buffer.append(IdentityLinkBox(id: .zero), fieldOffset: fieldOffset)
    }
    
    internal init() {
        _value = .zero
    }
}

@available(iOS 13.0, *)
fileprivate struct IdentityLinkBox : DynamicPropertyBox {

    fileprivate typealias Property = IdentityLink
    
    fileprivate var id: ViewIdentity
    
    fileprivate mutating func update(property: inout IdentityLink, phase: _GraphInputs.Phase) -> Bool {
        let oldID = id
        var newID = id
        if newID == .zero {
            newID = .make()
        }
        property._value = newID
        id = newID
        return newID != oldID
    }

    fileprivate mutating func destroy() {
        _intentionallyLeftBlank()
    }
    
    fileprivate mutating func reset() {
        id = .zero
    }
}
