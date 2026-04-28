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

@frozen
@available(iOS 13.0, *)
public struct _AnyAnimatableData : VectorArithmetic {
    
    internal var vtable: _AnyAnimatableDataVTable.Type
    
    internal var value: Any
    
    public static var zero: _AnyAnimatableData {
        .init(vtable: ZeroVTable.self, value: ZeroVTable())
    }
    
    public static func == (lhs: _AnyAnimatableData, rhs: _AnyAnimatableData) -> Bool {
        guard lhs.vtable == rhs.vtable else {
            return false
        }
        return withValue(value: lhs.value, vtableType: lhs.vtable) { (lhsValue: _AnyAnimatableDataVTable) in
            withValue(value: rhs.value, vtableType: rhs.vtable) { (rhsValue: _AnyAnimatableDataVTable) in
                lhsValue.isEqual(rhs: rhsValue)
            } ?? false
        } ?? false
    }
    
    public static func += (lhs: inout _AnyAnimatableData, rhs: _AnyAnimatableData) {
        guard lhs.vtable == rhs.vtable else {
            return
        }
        withValue(value: lhs.value, vtableType: lhs.vtable) { (lhsValue: _AnyAnimatableDataVTable) in
            withValue(value: rhs.value, vtableType: rhs.vtable) { (rhsValue: _AnyAnimatableDataVTable) in
                lhs.value = lhsValue.adding(rhs: rhsValue)
            }
        }
    }
    
    public static func -= (lhs: inout _AnyAnimatableData, rhs: _AnyAnimatableData) {
        guard lhs.vtable == rhs.vtable else {
            return
        }
        withValue(value: lhs.value, vtableType: lhs.vtable) { (lhsValue: _AnyAnimatableDataVTable) in
            withValue(value: rhs.value, vtableType: rhs.vtable) { (rhsValue: _AnyAnimatableDataVTable) in
                lhs.value = lhsValue.subtracting(rhs: rhsValue)
            }
        }
    }
    
    @_transparent
    public static func + (lhs: _AnyAnimatableData, rhs: _AnyAnimatableData) -> _AnyAnimatableData {
        var ret = lhs
        ret += rhs
        return ret
    }
    
    @_transparent
    public static func - (lhs: _AnyAnimatableData, rhs: _AnyAnimatableData) -> _AnyAnimatableData {
        var ret = lhs
        ret -= rhs
        return ret
    }
    
    public mutating func scale(by rhs: Double) {
        _AnyAnimatableData.withValue(value: value, vtableType: vtable) { (lhsValue: _AnyAnimatableDataVTable) in
            self.value = lhsValue.scale(by: rhs)
        }
    }
    
    public var magnitudeSquared: Double {
        _AnyAnimatableData.withValue(value: value, vtableType: vtable) { (lhsValue: _AnyAnimatableDataVTable) in
            lhsValue.magnitudeSquared
        } ?? 0
    }
    
    static func withValue<T: _AnyAnimatableDataVTable, R>(value: Any, vtableType: T.Type, body: (T) -> R) -> R? {
        guard let value = value as? T else {
            return nil
        }
        return body(value)
    }
}

@usableFromInline
@available(iOS 13.0, *)
internal class _AnyAnimatableDataVTable {
    
    internal func isEqual(rhs: _AnyAnimatableDataVTable) -> Bool {
        _abstractFunction()
    }
    
    internal func adding(rhs: _AnyAnimatableDataVTable) -> _AnyAnimatableData {
        _abstractFunction()
    }
    
    internal func subtracting(rhs: _AnyAnimatableDataVTable) -> _AnyAnimatableData {
        _abstractFunction()
    }
    
    internal func scale(by rhs: Double) {
        _abstractFunction()
    }
    
    internal var magnitudeSquared: Double {
        _abstractFunction()
    }
}

@available(iOS 13.0, *)
private final class ZeroVTable: _AnyAnimatableDataVTable {
    
    internal override func isEqual(rhs: _AnyAnimatableDataVTable) -> Bool {
        true
    }
    
    internal override func adding(rhs: _AnyAnimatableDataVTable) -> _AnyAnimatableData {
        .zero
    }
    
    internal override func subtracting(rhs: _AnyAnimatableDataVTable) -> _AnyAnimatableData {
        .zero
    }
    
    internal override func scale(by rhs: Double) {
        _intentionallyLeftBlank()
    }
    
    internal override var magnitudeSquared: Double {
        0
    }

}

@available(iOS 13.0, *)
private final class VTable: _AnyAnimatableDataVTable { //BDCOV_EXCL_BLOCK 没有调用点
    
    internal override func isEqual(rhs: _AnyAnimatableDataVTable) -> Bool {
        true
    }
    
    internal override func adding(rhs: _AnyAnimatableDataVTable) -> _AnyAnimatableData {
        .zero
    }
    
    internal override func subtracting(rhs: _AnyAnimatableDataVTable) -> _AnyAnimatableData {
        .zero
    }
    
    internal override func scale(by rhs: Double) {
        _intentionallyLeftBlank()
    }
    
    internal override var magnitudeSquared: Double {
        0
    }

}
