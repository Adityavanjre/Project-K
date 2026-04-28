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

import CoreGraphics
internal import DanceUIGraph

@available(iOS 13.0, *)
public protocol VectorArithmetic : AdditiveArithmetic {

    /// Multiplies each component of `self` by the scalar `rhs`.
    mutating func scale(by rhs: Double)

    /// Returns the dot-product of `self` with itself.
    var magnitudeSquared: Double { get }
    
    #if DEBUG
    var _descriptionComponents: [String] { get }

    static var _typeDescriptionComponents: [String] { get }
    #endif
}

@available(iOS 13.0, *)
extension VectorArithmetic {

    /// Returns a value with each component of this value multiplied by the
    /// given value.
    public func scaled(by rhs: Double) -> Self {
        var result = self
        result.scale(by: rhs)
        return result
    }

    /// Interpolates this value with `other` by the specified `amount`.
    ///
    /// This is equivalent to `self = self + (other - self) * amount`.
    public mutating func interpolate(towards other: Self, amount: Double) {
        self = self + (other - self).scaled(by: amount)
    }

    /// Returns this value interpolated with `other` by the specified `amount`.
    ///
    /// This result is equivalent to `self + (other - self) * amount`.
    public func interpolated(towards other: Self, amount: Double) -> Self {
        self + (other - self).scaled(by: amount)
    }
    
    #if DEBUG
    public var _descriptionComponents: [String] {
        []
    }

    public static var _typeDescriptionComponents: [String] {
        []
    }
    #endif
}

#if DEBUG
@available(iOS 13.0, *)
extension VectorArithmetic {

    /// Flattend description for instance of nested type.
    internal var _vectorDescription: String {
        return "(\(_descriptionComponents.joined(separator: ", ")))"
    }

    /// Flattend description for nested type.
    internal static var _typeVectorDescription: String {
        return "(\(_typeDescriptionComponents.joined(separator: ", ")))"
    }

}

@available(iOS 13.0, *)
extension CustomStringConvertible where Self: VectorArithmetic {

    public var _descriptionComponents: [String] {
        return [description]
    }

    public static var _typeDescriptionComponents: [String] {
        return ["\(Self.self)"]
    }

}
#endif
@available(iOS 13.0, *)
extension Float : VectorArithmetic {

    /// Multiplies each component of `self` by the scalar `rhs`.
    public mutating func scale(by rhs: Double) {
        self *= Float(rhs)
    }

    /// Returns the dot-product of `self` with itself.
    @_transparent
    public var magnitudeSquared: Double {
        Double(self * self)
    }
    
}

@available(iOS 13.0, *)
extension CGFloat : VectorArithmetic {

    /// Multiplies each component of `self` by the scalar `rhs`.
    public mutating func scale(by rhs: Double) {
        self *= CGFloat(rhs)
    }

    /// Returns the dot-product of `self` with itself.
    public var magnitudeSquared: Double {
        Double(self * self)
    }
    
    @inline(__always)
    internal func formalize() -> CGFloat {
        if self >= .infinity {
            return .greatestFiniteMagnitude
        } else if self <= 0 {
            return .leastNonzeroMagnitude
        }
        return self
    }
    
}

@available(iOS 13.0, *)
extension Double : VectorArithmetic {

    /// Multiplies each component of `self` by the scalar `rhs`.
    public mutating func scale(by rhs: Double) {
        self *= rhs
    }

    /// Returns the dot-product of `self` with itself.
    @_transparent
    public var magnitudeSquared: Double {
        self * self
    }
    
}

/// A type that can be animated
@available(iOS 13.0, *)
public protocol Animatable {
    
    /// The type defining the data to be animated.
    associatedtype AnimatableData : VectorArithmetic
    
    var animatableData: AnimatableData { get set }
    
    static func _makeAnimatable(value: inout _GraphValue<Self>, inputs: _GraphInputs)
    
}

@available(iOS 13.0, *)
extension Animatable {
    
    internal static func makeAnimatable(value: _GraphValue<Self>, inputs: _GraphInputs) -> Attribute<Self> {
        var mutableValue: _GraphValue<Self> = value
        _makeAnimatable(value: &mutableValue, inputs: inputs)
        return mutableValue.value
    }
    
    public static func _makeAnimatable(value: inout _GraphValue<Self>, inputs: _GraphInputs) {
        guard !inputs.disableAnimations && MemoryLayout<AnimatableData>.size > 0 else {
            return
        }
        value = _GraphValue(AnimatableAttribute(source: value.value, phase: inputs.phase, time: inputs.time, transaction: inputs.transaction, environment: inputs.environment))
        value.setFlags(.active, mask: .reserved)
    }
    
}

@frozen
@available(iOS 13.0, *)
public struct EmptyAnimatableData: VectorArithmetic {
    
    @inlinable
    public init() {
    }

    @inlinable
    public static var zero: EmptyAnimatableData {
        EmptyAnimatableData()
    }

    @inlinable
    public static func += (lhs: inout EmptyAnimatableData, rhs: EmptyAnimatableData) {
    }

    @inlinable
    public static func -= (lhs: inout EmptyAnimatableData, rhs: EmptyAnimatableData) {
    }

    @inlinable
    public static func + (lhs: EmptyAnimatableData, rhs: EmptyAnimatableData) -> EmptyAnimatableData {
        .zero
    }

    @inlinable
    public static func - (lhs: EmptyAnimatableData, rhs: EmptyAnimatableData) -> EmptyAnimatableData {
        .zero
    }

    @inlinable
    public mutating func scale(by rhs: Double) {
    }

    @inlinable
    public var magnitudeSquared: Double {
        0
    }

    public static func == (a: EmptyAnimatableData, b: EmptyAnimatableData) -> Bool {
        true
    }
}

@available(iOS 13.0, *)
extension Animatable where Self.AnimatableData == EmptyAnimatableData {
    
    /// The data to be animated.
    @inlinable
    public var animatableData: EmptyAnimatableData {
        get {
            EmptyAnimatableData()
        }
        set {
        }
    }
    
}

@frozen
@available(iOS 13.0, *)
/// A pair of animatable values, which is itself animatable.
public struct AnimatablePair<First, Second>: VectorArithmetic, AdditiveArithmetic where First : VectorArithmetic, Second : VectorArithmetic {

    /// The first value.
    public var first: First

    /// The second value.
    public var second: Second

    /// Initializes with `first` and `second`.
    @inlinable
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }

    /// The zero value.
    ///
    /// Zero is the identity element for addition. For any value,
    /// `x + .zero == x` and `.zero + x == x`.
    @_transparent
    public static var zero: AnimatablePair<First, Second> {
        .init(First.zero, Second.zero)
    }

    /// Adds two values and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    public static func += (lhs: inout AnimatablePair<First, Second>, rhs: AnimatablePair<First, Second>) {
        lhs.first += rhs.first
        lhs.second += rhs.second
    }

    /// Subtracts the second value from the first and stores the difference in the
    /// left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    public static func -= (lhs: inout AnimatablePair<First, Second>, rhs: AnimatablePair<First, Second>) {
        lhs.first -= rhs.first
        lhs.second -= rhs.second
    }

    /// Adds two values and produces their sum.
    ///
    /// The addition operator (`+`) calculates the sum of its two arguments. For
    /// example:
    ///
    ///     1 + 2                   // 3
    ///     -10 + 15                // 5
    ///     -15 + -5                // -20
    ///     21.5 + 3.25             // 24.75
    ///
    /// You cannot use `+` with arguments of different types. To add values of
    /// different types, convert one of the values to the other value's type.
    ///
    ///     let x: Int8 = 21
    ///     let y: Int = 1000000
    ///     Int(x) + y              // 1000021
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    public static func + (lhs: AnimatablePair<First, Second>, rhs: AnimatablePair<First, Second>) -> AnimatablePair<First, Second> {
        .init(lhs.first + rhs.first, lhs.second + rhs.second)
    }

    /// Subtracts one value from another and produces their difference.
    ///
    /// The subtraction operator (`-`) calculates the difference of its two
    /// arguments. For example:
    ///
    ///     8 - 3                   // 5
    ///     -10 - 5                 // -15
    ///     100 - -5                // 105
    ///     10.5 - 100.0            // -89.5
    ///
    /// You cannot use `-` with arguments of different types. To subtract values
    /// of different types, convert one of the values to the other value's type.
    ///
    ///     let x: UInt8 = 21
    ///     let y: UInt = 1000000
    ///     y - UInt(x)             // 999979
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    public static func - (lhs: AnimatablePair<First, Second>, rhs: AnimatablePair<First, Second>) -> AnimatablePair<First, Second> {
        .init(lhs.first - rhs.first, lhs.second - rhs.second)
    }

    /// Multiplies each component of `self` by the scalar `rhs`.
    public mutating func scale(by rhs: Double) {
        first.scale(by: rhs)
        second.scale(by: rhs)
    }

    /// Returns the dot-product of `self` with itself.
    @_transparent
    public var magnitudeSquared: Double {
        first.magnitudeSquared + second.magnitudeSquared
    }
    
#if DEBUG
    
    public var _descriptionComponents: [String] {
        return first._descriptionComponents + second._descriptionComponents
    }

    public static var _typeDescriptionComponents: [String] {
        return First._typeDescriptionComponents + Second._typeDescriptionComponents
    }
    
#endif
    
}

@available(iOS, introduced: 10.0, deprecated: 100000.0, message: "use Animatable directly")
@available(iOS 13.0, *)
public protocol AnimatableModifier : Animatable, ViewModifier {
    
}

@available(iOS 13.0, *)
extension ViewModifier where Self: Animatable {
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let animatable = makeAnimatable(value: modifier, inputs: inputs.base)
        return makeView(modifier: _GraphValue(animatable), inputs: inputs, body: body)
    }
    
    public static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        let animatable = makeAnimatable(value: modifier, inputs: inputs.base)
        return makeViewList(modifier: _GraphValue(animatable), inputs: inputs, body: body)
    }
}

@available(iOS 13.0, *)
extension View where Self: Animatable {
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let animatable = makeAnimatable(value: view, inputs: inputs.base)
        return makeView(view: _GraphValue(animatable), inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let animatable = makeAnimatable(value: view, inputs: inputs.base)
        return makeViewList(view: _GraphValue(animatable), inputs: inputs)
    }
}

@available(iOS 13.0, *)
extension CGSize: Animatable {
    
    public typealias AnimatableData = AnimatablePair<CGFloat, CGFloat>
    
    @inlinable
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(width, height)
        }
        
        set {
            width = newValue.first
            height = newValue.second
        }
    }
}

@available(iOS 13.0, *)
extension Double: Animatable {
    
    public typealias AnimatableData = Double
    
    @inlinable
    public var animatableData: Double {
        get {
            self
        }
        
        set {
            self = newValue
        }
    }
}

@available(iOS 13.0, *)
extension CGRect: Animatable {

    public typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>

    @inlinable
    public var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(AnimatablePair(origin.x, origin.y), AnimatablePair(size.width, size.height))
        }
        set {
            self = CGRect(
                x: newValue.first.first,
                y: newValue.first.second,
                width: newValue.second.first,
                height: newValue.second.second
            )
        }
    }

}
