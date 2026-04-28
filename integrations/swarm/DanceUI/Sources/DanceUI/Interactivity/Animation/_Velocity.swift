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
public struct _Velocity<Value>: Equatable where Value: Equatable {

    public var valuePerSecond: Value

    @inlinable
    public init(valuePerSecond: Value) {
        self.valuePerSecond = valuePerSecond
    }

}

@available(iOS 13.0, *)
extension _Velocity: Hashable where Value: Hashable {

}

@available(iOS 13.0, *)
extension _Velocity: Comparable where Value: Comparable {

    public static func < (lhs: _Velocity<Value>, rhs: _Velocity<Value>) -> Bool {
        lhs.valuePerSecond < rhs.valuePerSecond
    }

}

@available(iOS 13.0, *)
extension _Velocity: Animatable where Value: Animatable {

    public typealias AnimatableData = Value.AnimatableData

    public var animatableData: _Velocity<Value>.AnimatableData {
        @inlinable
        get {
            valuePerSecond.animatableData
        }
        @inlinable
        set {
            valuePerSecond.animatableData = newValue
        }
    }

}

@available(iOS 13.0, *)
extension _Velocity: AdditiveArithmetic where Value: AdditiveArithmetic {

    @inlinable
    public init() {
        self.init(valuePerSecond: .zero)
    }

    @inlinable
    public static var zero: _Velocity<Value> {
        self.init(valuePerSecond: .zero)
    }

    @inlinable
    public static func += (lhs: inout _Velocity<Value>, rhs: _Velocity<Value>) {
        lhs.valuePerSecond += rhs.valuePerSecond
    }

    @inlinable
    public static func -= (lhs: inout _Velocity<Value>, rhs: _Velocity<Value>) {
        lhs.valuePerSecond -= rhs.valuePerSecond
    }

    @inlinable
    public static func + (lhs: _Velocity<Value>, rhs: _Velocity<Value>) -> _Velocity<Value> {
        var r = lhs; r += rhs; return r
    }

    @inlinable
    public static func - (lhs: _Velocity<Value>, rhs: _Velocity<Value>) -> _Velocity<Value> {
        var r = lhs; r -= rhs; return r
    }

}

@available(iOS 13.0, *)
extension _Velocity: VectorArithmetic where Value: VectorArithmetic {

    @inlinable
    public mutating func scale(by rhs: Double) {
        valuePerSecond.scale(by: rhs)
    }

    @inlinable
    public var magnitudeSquared: Double {
        valuePerSecond.magnitudeSquared
    }

#if DEBUG

    public var _descriptionComponents: [String] {
        return ["\(valuePerSecond)"]
    }

    public static var _typeDescriptionComponents: [String] {
        return ["\(Self.self)"]
    }

#endif

}
