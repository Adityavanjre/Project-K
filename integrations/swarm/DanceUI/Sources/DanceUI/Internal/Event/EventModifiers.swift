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

/// A set of key modifiers that you can add to a gesture.
@frozen
@available(iOS 13.0, *)
public struct EventModifiers : OptionSet {
    
    /// The raw value.
    public let rawValue: Int

    /// Creates a new set from a raw value.
    ///
    /// - Parameter rawValue: The raw value with which to create the key
    ///   modifier.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The Caps Lock key.
    public static let capsLock = EventModifiers(rawValue: 1 << 0)

    /// The Shift key.
    public static let shift = EventModifiers(rawValue: 1 << 1)

    /// The Control key.
    public static let control = EventModifiers(rawValue: 1 << 2)

    /// The Option key.
    public static let option = EventModifiers(rawValue: 1 << 3)

    /// The Command key.
    public static let command = EventModifiers(rawValue: 1 << 4)

    /// Any key on the numeric keypad.
    public static let numericPad = EventModifiers(rawValue: 1 << 5)

    /// The Function key.
    @available(iOS, deprecated: 15.0, message: "Function modifier is reserved for system applications")
    @available(macOS, deprecated: 12.0, message: "Function modifier is reserved for system applications")
    @available(tvOS, deprecated: 15.0, message: "Function modifier is reserved for system applications")
    @available(watchOS, deprecated: 8.0, message: "Function modifier is reserved for system applications")
    public static let function = EventModifiers(rawValue: 1 << 6)

    /// All possible modifier keys.
    public static let all: EventModifiers = [capsLock, shift, control, option, command, numericPad]

    /// The type of the elements of an array literal.
    public typealias ArrayLiteralElement = EventModifiers

    /// The element type of the option set.
    ///
    /// To inherit all the default implementations from the `OptionSet` protocol,
    /// the `Element` type must be `Self`, the default.
    public typealias Element = EventModifiers

    /// The raw type that can be used to represent all values of the conforming
    /// type.
    ///
    /// Every distinct value of the conforming type has a corresponding unique
    /// value of the `RawValue` type, but there may be values of the `RawValue`
    /// type that don't have a corresponding value of the conforming type.
    public typealias RawValue = Int

}
