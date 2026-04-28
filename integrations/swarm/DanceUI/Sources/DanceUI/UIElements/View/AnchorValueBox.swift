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

@usableFromInline
@available(iOS 13.0, *)
internal class AnchorValueBoxBase<Value> {

    internal var defaultValue: Value {
        _abstractFunction()
    }
    
    internal func convert(to: ViewTransform) -> Value {
        _abstractFunction()
    }
    
    internal func isEqual(to: AnchorValueBoxBase<Value>) -> Bool {
        return false
    }
}

@available(iOS 13.0, *)
internal final class AnchorValueBox<P: AnchorProtocol>: AnchorValueBoxBase<P.AnchorValue> {

    internal let value: P.AnchorValue
    
    internal init(value: P.AnchorValue) {
        self.value = value
    }
    
    internal override var defaultValue: P.AnchorValue {
        P.defaultAnchor
    }
    
    internal override func convert(to: ViewTransform) -> P.AnchorValue {
        var copiedValue = value
        
        copiedValue.convert(from: .global, transform: to)
        
        return copiedValue
    }
    
    internal override func isEqual(to: AnchorValueBoxBase<P.AnchorValue>) -> Bool {
        
        guard let valueBox = to as? AnchorValueBox else {
            return false
        }
        
        return P.valueIsEqual(lhs: self.value, rhs: valueBox.value)
    }
}

@available(iOS 13.0, *)
internal final class ArrayAnchorValueBox<Value: Equatable>: AnchorValueBoxBase<[Value]> {

    internal let value: Array<Anchor<Value>>

    internal init(value: Array<Anchor<Value>>) {
        self.value = value
    }
    
    internal override var defaultValue: Array<Value> {
        return value.map { $0.defaultValue }
    }
    
    internal override func convert(to: ViewTransform) -> Array<Value> {
        return value.map {
            $0.box.convert(to: to)
        }
    }
    
    internal override func isEqual(to: AnchorValueBoxBase<Array<Value>>) -> Bool {
        
        guard let valueBox = to as? ArrayAnchorValueBox else {
            return false
        }
        
        return self.value == valueBox.value
    }
}

@available(iOS 13.0, *)
internal final class OptionalAnchorValueBox<Value: Equatable>: AnchorValueBoxBase<Value?> {

    internal let value: Anchor<Value>?
    
    internal init(value: Anchor<Value>?) {
        self.value = value
    }
    
    internal override var defaultValue: Value? {
        value.map { $0.defaultValue }
    }

    internal override func convert(to: ViewTransform) -> Value? {
        return value.map {
            $0.box.convert(to: to)
        }
    }
    
    internal override func isEqual(to: AnchorValueBoxBase<Value?>) -> Bool {
        
        guard let valueBox = to as? OptionalAnchorValueBox else {
            return false
        }
        
        guard let lhsAnchorValue = self.value,
              let rhsAnchorValue = valueBox.value
        else {
            return self.value == nil && valueBox.value == nil
        }
        
        return lhsAnchorValue == rhsAnchorValue
    }
}
