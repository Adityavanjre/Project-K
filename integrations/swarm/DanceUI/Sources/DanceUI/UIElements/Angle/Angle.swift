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

/// A geometric angle whose value you access in either radians or degrees.
@frozen
@available(iOS 13.0, *)
public struct Angle: Hashable, Comparable {
    
    /// Returns a Boolean value indicating whether the value of the first
    /// argument is less than that of the second argument.
    ///
    /// This function is the only requirement of the `Comparable` protocol. The
    /// remainder of the relational operator functions are implemented by the
    /// standard library for any type that conforms to `Comparable`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    @inlinable
    public static func < (lhs: Angle, rhs: Angle) -> Bool {
        return lhs.radians < rhs.radians
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    @inlinable
    public static func == (a: Angle, b: Angle) -> Bool {
        a.radians == b.radians
    }
    
    public var radians: Double

    @inlinable
    public var degrees: Double {
        get {
            radians * (180.0 / .pi)
        }
        set {
            radians = newValue * (.pi / 180.0)
        }
    }

    @inlinable
    public init() {
        radians = 0
    }

    @inlinable
    public init(radians: Double) {
        self.radians = radians
    }

    @inlinable
    public init(degrees: Double) {
        self.init(radians: degrees * (Double.pi / 180.0))
    }

    @inlinable
    public static func radians(_ radians: Double) -> Angle {
        Angle(radians: radians)
    }

    @inlinable
    public static func degrees(_ degrees: Double) -> Angle {
        Angle(degrees: degrees)
    }
    
    /// The type defining the data to be animated.
    public typealias AnimatableData = Double
    
    /// The data to be animated.
    public var animatableData: Double {
        get {
            radians * Double(128.0)
        }
        set {
            radians = newValue / Double(128.0)
        }
    }
}

@available(iOS 13.0, *)
extension Angle: Animatable, _VectorMath {
    
    @inlinable
    public static var zero: Angle {
        .init()
    }
}
