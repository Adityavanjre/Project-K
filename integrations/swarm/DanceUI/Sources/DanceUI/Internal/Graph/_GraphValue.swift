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

@available(iOS 13.0, *)
public struct _GraphValue<Value> : Equatable {
    
    internal private(set) var value: Attribute<Value>
    
    @inline(__always)
    internal init(_ attribute: Attribute<Value>) {
        value = attribute
    }
    
    @inline(__always)
    internal init<RuleType: Rule>(_ rule: RuleType) where RuleType.Value == Value {
        value = .init(rule)
    }
    
    @inline(__always)
    internal init<Rule: StatefulRule>(_ rule: Rule) where Rule.Value == Value {
        value = .init(rule)
    }
    
    @inline(__always)
    internal init(value: Value)  {
        self.value = Attribute(value: value)
    }
    
    @inline(__always)
    internal subscript<Member>(_ offset: (inout Value) -> PointerOffset<Value, Member>) -> _GraphValue<Member> {
        .init(value[offset])
    }
    
    @inline(__always)
    internal subscript<Member>(_ keyPath: KeyPath<Value, Member>) -> _GraphValue<Member> {
        return .init(value[keyPath])
    }
    
    @inline(__always)
    internal mutating func makeReusable(indirectMap: _ViewList_IndirectMap?) {
        value.makeReusable(indirectMap: indirectMap)
    }
    
    @inline(__always)
    internal func tryToReuse(by value: _GraphValue<Value>, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        self.value.tryToReuse(by: value.value, indirectMap: indirectMap, testOnly: testOnly)
    }
    
    @inline(__always)
    internal func unsafeBitCast<A1>(to type: A1.Type) -> _GraphValue<A1> {
        _GraphValue<A1>(value.unsafeBitCast(to: type))
    }
    
    @inline(__always)
    internal func setFlags(_ flags: DGAttributeFlags, mask: DGAttributeFlags) {
        value.setFlags(flags, mask: mask)
    }
}

@available(iOS 13.0, *)
extension Attribute {
    
    @inline(__always)
    internal func unsafeBitCast<OtherValue>(to type: OtherValue.Type) -> Attribute<OtherValue> {
        unsafeOffset(at: 0, as: type)
    }
    
    @inline(__always)
    internal mutating func makeReusable(indirectMap: _ViewList_IndirectMap?) {
        guard let map = indirectMap else {
            return
        }
        if let identifier = map.map[self.identifier] {
            self.identifier = identifier
            return
        }
        let reusedAttribute = DGGraphRef.withoutUpdate {
            map.subgraph.apply({ IndirectAttribute(source: self) })
        }
        map.map[self.identifier] = reusedAttribute.identifier
        self.identifier = reusedAttribute.identifier
    }
    
    @inline(__always)
    internal func tryToReuse(by attribute: Attribute<Value>, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        guard let reusableIdentifier = indirectMap.map[self.identifier] else {
            return false
        }
        if !testOnly {
            reusableIdentifier.source = attribute.identifier
        }
        return true
    }
    
}
