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
extension LocalizedStringKey {
    
    /// Represents the contents of a string literal with interpolations
    /// while it’s being built, for use in creating a localized string key.
    public struct StringInterpolation : StringInterpolationProtocol {
        
        internal var key: String
        internal var arguments: [FormatArgument]
        internal var seed: UniqueSeedGenerator = UniqueSeedGenerator()
        
        /// Creates an empty instance ready to be filled with string literal content.
        ///
        /// Don't call this initializer directly. Instead, initialize a variable or
        /// constant using a string literal with interpolated expressions.
        ///
        /// Swift passes this initializer a pair of arguments specifying the size of
        /// the literal segments and the number of interpolated segments. Use this
        /// information to estimate the amount of storage you will need.
        ///
        /// - Parameter literalCapacity: The approximate size of all literal segments
        ///   combined. This is meant to be passed to `String.reserveCapacity(_:)`;
        ///   it may be slightly larger or smaller than the sum of the counts of each
        ///   literal segment.
        /// - Parameter interpolationCount: The number of interpolations which will be
        ///   appended. Use this value to estimate how much additional capacity will
        ///   be needed for the interpolated segments.
        public init(literalCapacity: Int, interpolationCount: Int) {
            key = String()
            key.reserveCapacity(2 * interpolationCount + literalCapacity)
            arguments = []
            arguments.reserveCapacity(interpolationCount)
        }

        /// Appends a literal string.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameter literal: The literal string to append.
        public mutating func appendLiteral(_ literal: String) {
            key.append(literal.replacingOccurrences(of: "%", with: "%%"))
        }

        /// Appends a literal string segment to a string interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameter string: The literal string to append.
        public mutating func appendInterpolation(_ string: String) {
            let storage: LocalizedStringKey.FormatArgument.Storage = .value((string, nil))
            self.appendObject(LocalizedStringKey.FormatArgument(storage: storage))
        }

        /// Appends an optionally-formatted instance of a Foundation type
        /// to a string interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameters:
        ///   - subject: The Foundation object to append.
        ///   - formatter: A formatter to convert `subject` to a string
        ///     representation.
        public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject : ReferenceConvertible {
            let storage: LocalizedStringKey.FormatArgument.Storage = .value((subject as! NSObject, formatter))
            self.appendObject(LocalizedStringKey.FormatArgument(storage: storage))
        }

        /// Appends an optionally-formatted instance of an Objective-C subclass
        /// to a string interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// The following example shows how to use a
        /// <doc://com.apple.documentation/documentation/Foundation/Measurement>
        /// value and a
        /// <doc://com.apple.documentation/documentation/Foundation/MeasurementFormatter>
        /// to create a ``LocalizedStringKey`` that uses the formatter
        /// style
        /// <doc://com.apple.documentation/documentation/foundation/Formatter/UnitStyle/long>
        /// when generating the measurement's string representation. Rather than
        /// calling `appendInterpolation(_:formatter)` directly, the code
        /// gets the formatting behavior implicitly by using the `\()`
        /// string interpolation syntax.
        ///
        ///     let siResistance = Measurement(value: 640, unit: UnitElectricResistance.ohms)
        ///     let formatter = MeasurementFormatter()
        ///     formatter.unitStyle = .long
        ///     let key = LocalizedStringKey ("Resistance: \(siResistance, formatter: formatter)")
        ///     let text1 = Text(key) // Text contains "Resistance: 640 ohms"
        ///
        /// - Parameters:
        ///   - subject: An <doc://com.apple.documentation/documentation/objectivec/NSObject>
        ///     to append.
        ///   - formatter: A formatter to convert `subject` to a string
        ///     representation.
        public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject : NSObject {
            let storage: LocalizedStringKey.FormatArgument.Storage = .value((subject, formatter))
            self.appendObject(LocalizedStringKey.FormatArgument(storage: storage))
        }

        /// Appends the formatted representation  of a nonstring type
        /// supported by a corresponding format style.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// The following example shows how to use a string interpolation to
        /// format a
        /// <doc://com.apple.documentation/documentation/Foundation/Date>
        /// with a
        /// <doc://com.apple.documentation/documentation/Foundation/Date/FormatStyle> and
        /// append it to static text. The resulting interpolation implicitly
        /// creates a ``LocalizedStringKey``, which a ``Text`` uses to provide
        /// its content.
        ///
        ///     Text("The time is \(myDate, format: Date.FormatStyle(date: .omitted, time:.complete))")
        ///
        /// - Parameters:
        ///   - input: The instance to format and append.
        ///   - format: A format style to use when converting `input` into a string
        ///   representation.
        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        internal mutating func appendInterpolation<F>(_ input: F.FormatInput, format: F) where F : FormatStyle, F.FormatInput : Equatable, F.FormatOutput == String {
            _notImplemented()
        }

        /// Appends a type, convertible to a string by using a default format
        /// specifier, to a string interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameters:
        ///   - value: A primitive type to append, such as
        ///     <doc://com.apple.documentation/documentation/swift/Int>,
        ///     <doc://com.apple.documentation/documentation/swift/UInt32>, or
        ///     <doc://com.apple.documentation/documentation/swift/Double>.
        @available(iOS 15, *) // apply iOS 14 substitute in other place
        public mutating func appendInterpolation<T>(_ value: T) where T : _FormatSpecifiable {
            appendInterpolation(value, specifier: formatSpecifier(value))
        }

        /// Appends a type, convertible to a string with a format specifier,
        /// to a string interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameters:
        ///   - value: The value to append.
        ///   - specifier: A format specifier to convert `subject` to a string
        ///     representation, like `%f` for a
        ///     <doc://com.apple.documentation/documentation/swift/Double>, or
        ///     `%x` to create a hexidecimal representation of a
        ///     <doc://com.apple.documentation/documentation/swift/UInt32>. For a
        ///     list of available specifier strings, see
        ///     [String Format Specifers](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265).
        @available(iOS 15, *)
        public mutating func appendInterpolation<T>(_ value: T, specifier: String) where T : _FormatSpecifiable {
            self.key.append(specifier)
            let storage: FormatArgument.Storage = .value((value._arg, nil))
            self.arguments.append(FormatArgument(storage: storage))
        }

        /// Appends the string displayed by a text view to a string
        /// interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameters:
        ///   - value: A ``Text`` instance to append.
        public mutating func appendInterpolation(_ text: Text) {
            let id = seed.generateNextID()
            let storage: LocalizedStringKey.FormatArgument.Storage = .text((text, FormatArgument.Token(id: id)))
            self.appendObject(LocalizedStringKey.FormatArgument(storage: storage))
        }

        /// Appends an AttributedString to a string interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameter attributedString: The AttributedString to append.
        @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
        public mutating func appendInterpolation(_ attributedString: AttributedString) {
            appendInterpolation(NSAttributedString(attributedString))
        }
        
        /// Appends an NSAttributedString to a string interpolation.
        ///
        /// Don't call this method directly; it's used by the compiler when
        /// interpreting string interpolations.
        ///
        /// - Parameter attributedString: The NSAttributedString to append.
        public mutating func appendInterpolation(_ attributedString: NSAttributedString) {
            appendInterpolation(Text(.anyTextStorage(Text.AttributedStringTextStorage(attributedString: attributedString)), modifiers: []))
        }

        /// The type that should be used for literal segments.
        public typealias StringLiteralType = String
        
        private mutating func appendObject(_ argument: LocalizedStringKey.FormatArgument) {
            key.append("%@")
            arguments.append(argument)
        }
    }
}

@available(iOS 13.0, *)
extension LocalizedStringKey.StringInterpolation {

    /// Appends an image to a string interpolation.
    ///
    /// Don't call this method directly; it's used by the compiler when
    /// interpreting string interpolations.
    ///
    /// - Parameter image: The image to append.
    public mutating func appendInterpolation(_ image: Image) {
        appendInterpolation(Text(image))
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension LocalizedStringKey.StringInterpolation {

    // TODO: _notImplemented StringInterpolation.appendInterpolation(_:style:) unused
//    internal mutating func appendInterpolation(_ date: Date, style: Text.DateStyle) {
//        _notImplemented()
//    }

    // TODO: _notImplemented StringInterpolation.appendInterpolation(_:) unused
//    internal mutating func appendInterpolation(_ dates: ClosedRange<Date>) {
//        _notImplemented()
//    }

    // TODO: _notImplemented StringInterpolation.appendInterpolation(_:) unused
//    internal mutating func appendInterpolation(_ interval: DateInterval) {
//        _notImplemented()
//    }
}

@available(iOS 13.0, *)
extension LocalizedStringKey.StringInterpolation {
    
    public mutating func appendInterpolation(_ value: CVarArg, specifier: String) {
        self.key.append(specifier)
        let storage: LocalizedStringKey.FormatArgument.Storage = .value((value, nil))
        self.arguments.append(LocalizedStringKey.FormatArgument(storage: storage))
    }
    
    public mutating func appendInterpolation(_ value: Int) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: Int8) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: Int16) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: Int32) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: Int64) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: UInt) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: UInt8) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: UInt16) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: UInt32) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: UInt64) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: Float) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: Double) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
    
    public mutating func appendInterpolation(_ value: CGFloat) {
        appendInterpolation(value, specifier: formatSpecifier(value))
    }
}

@inline(__always)
@available(iOS 13.0, *)
internal func formatSpecifier<A>(_ value: A) -> String {
    switch value {
    case is Int: return "%lld"
    case is Int8: return "%d"
    case is Int16: return "%d"
    case is Int32: return "%d"
    case is Int64: return "%lld"
    case is UInt: return "%llu"
    case is UInt8: return "%u"
    case is UInt16: return "%u"
    case is UInt32: return "%u"
    case is UInt64: return "%llu"
    case is Float: return "%f"
    case is Double: return "%lf"
    case is CGFloat: return "%lf"
    default: _danceuiFatalError("[DanceUI Localization] not find suitable specifier for \(value) : \(type(of: value)).") // should never run here
    }
}
