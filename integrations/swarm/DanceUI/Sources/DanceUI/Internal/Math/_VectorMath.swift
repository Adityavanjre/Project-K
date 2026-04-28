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
public protocol _VectorMath : Animatable {
}

@available(iOS 13.0, *)
extension _VectorMath {

    @inlinable
    public var magnitude: Double {
        animatableData.magnitudeSquared.squareRoot()
    }

    @inlinable
    public mutating func negate() {
        animatableData = .zero - animatableData
    }

    @inlinable
    prefix public static func - (operand: Self) -> Self {
        var result = operand
        result.negate()
        return result
    }

    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs.animatableData += rhs.animatableData
    }

    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result += rhs
        return result
    }

    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.animatableData -= rhs.animatableData
    }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result -= rhs
        return result
    }

    @inlinable
    public static func *= (lhs: inout Self, rhs: Double) {
        lhs.animatableData.scale(by: rhs)
    }

    @inlinable
    public static func * (lhs: Self, rhs: Double) -> Self {
        var result = lhs
        result *= rhs
        return result
    }

    @inlinable
    public static func /= (lhs: inout Self, rhs: Double) {
        lhs *= (1.0 / rhs)
    }

    @inlinable
    public static func / (lhs: Self, rhs: Double) -> Self {
        var result = lhs
        result /= rhs
        return result
    }
}
