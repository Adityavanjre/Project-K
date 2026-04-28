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

#if DEBUG

@available(iOS 13.0, *)
internal final class EnvMock {
    
    private class AnyEnvMockup {
        
    }

    private final class EnvMockup<Key: EnvKey>: AnyEnvMockup {
        
        fileprivate var value: Key.Value
        
        @inline(__always)
        fileprivate init(value: Key.Value = Key.defaultValue) {
            self.value = value
        }
        
    }
    
    internal static let shared = EnvMock()
    
    private var mockups: [ObjectIdentifier : AnyEnvMockup] = [:]
    
    internal func enableMock<Key: EnvKey>(_ key: Key.Type) {
        mockups[ObjectIdentifier(key)] = EnvMockup<Key>()
    }
    
    internal func disableMock<Key: EnvKey>(_ key: Key.Type) {
        mockups[ObjectIdentifier(key)] = nil
    }
    
    internal func isMock<Key: EnvKey>(_ key: Key.Type) -> Bool {
        mockups.keys.contains(ObjectIdentifier(key))
    }
    

    internal func value<Key: EnvKey>(for key: Key.Type) -> Key.Value {
        if let mockup = mockups[ObjectIdentifier(key)] {
            let castedMockup = unsafeDowncast(mockup, to: EnvMockup<Key>.self)
            return castedMockup.value
        }
        return Key.defaultValue
    }
    

    @discardableResult
    internal func setValue<Key: EnvKey>(_ value: Key.Value, for key: Key.Type) -> Bool {
        if let mockup = mockups[ObjectIdentifier(key)] {
            let castedMockup = unsafeDowncast(mockup, to: EnvMockup<Key>.self)
            castedMockup.value = value
            return true
        }
        return false
    }
}

#endif

@available(iOS 13.0, *)
internal struct EnvValue<K: EnvKey> {
    
    private let _value: K.Value = {
        Env[K.self]
    }()
    
    @inline(__always)
    internal var value: K.Value {
#if DEBUG
        if EnvMock.shared.isMock(K.self) {
            return EnvMock.shared.value(for: K.self)
        } else {
            return _value
        }
#else
        _value
#endif
    }
}

// MARK: - Env

/// Environment variable quick reader
@available(iOS 13.0, *)
private struct Env {
    
    @inline(__always)
    fileprivate static subscript<Key: EnvKey>(_ key: Key.Type) -> Key.Value {
        guard Key.availability.isAvailable else {
            return Key.defaultValue
        }
        
        let value = Key.raw
            .withCString(getenv)
            .map { rawValueInCString -> Key.Value in
                let rawValue = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault,
                                                               UnsafePointer(rawValueInCString),
                                                               kCFStringEncodingASCII,
                                                               kCFAllocatorNull)! as String
                return Key.makeValue(rawValue: rawValue)
            }
        
        guard let value = value else {
            return Key.defaultValue
        }
        
        return value
    }
}

// MARK: - EnvKey

@available(iOS 13.0, *)
internal protocol EnvKey {
    
    associatedtype Value
    
    /// The avilability of the environment variable key.
    ///
    static var availability: EnvKeyAvailability { get }
    
    /// The raw key of the environment variable key.
    static var raw: String { get }
    
    /// The default value of the environment variable.
    static var defaultValue: Value { get }
    
    /// Raw-value-to-value transformer of the environment variable.
    static func makeValue(rawValue: String) -> Value
    
}

@available(iOS 13.0, *)
extension EnvKey {
    
    /// The avilability of the environment variable key.
    ///
    /// - note: Default value is `.always`
    ///
    @inlinable
    internal static var availability: EnvKeyAvailability {
        .always
    }
    
}

// MARK: - EnvKeyAvailability


@available(iOS 13.0, *)
internal struct EnvKeyAvailability {
    
    internal var isAvailable: Bool
    
    @inline(__always)
    internal init(isAvailable eval: () -> Bool) {
        isAvailable = eval()
    }
    

    internal static let debugOnly = EnvKeyAvailability {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    internal static let debugAndInhouse = EnvKeyAvailability {
#if DEBUG || DANCE_UI_INHOUSE
        return true
#else
        return false
#endif
    }
    
    internal static let nonDebugOnly = EnvKeyAvailability {
#if DEBUG
        return false
#else
        return true
#endif
    }
    
    internal static let binaryCompatibleTestOnly = EnvKeyAvailability {
#if BINARY_COMPATIBLE_TEST
        return true
#else
        return false
#endif
    }
    

    internal static let always = EnvKeyAvailability {
        return true
    }
    
}

// MARK: - BoolEnvKey

/// Convenient encapsulation for boolean environment variable keys.
@available(iOS 13.0, *)
internal protocol BoolEnvKey: EnvKey where Value == Bool {
    
}

@available(iOS 13.0, *)
extension BoolEnvKey {
    
    @inlinable
    internal static func makeValue(rawValue: String) -> Bool {
        // Some ppl like to use TRUE/FALSE/true/false to fill a boolean env var
        // and some ppl like to use 0/non-0. Let's support them both.
        return Bool(rawValue.lowercased()) ?? (Int(rawValue) != 0)
    }
    
}

// MARK: - DefaultFalseBoolEnvKey

/// Convenient encapsulation for boolean environment variable keys with its
/// default value is `false`.
@available(iOS 13.0, *)
internal protocol DefaultFalseBoolEnvKey: BoolEnvKey {
    
}

@available(iOS 13.0, *)
extension DefaultFalseBoolEnvKey {
    
    @inlinable
    internal static var defaultValue: Value {
        false
    }
    
}

// MARK: - DefaultTrueBoolEnvKey

/// Convenient encapsulation for boolean environment variable keys with its
/// default value is `true`.
@available(iOS 13.0, *)
internal protocol DefaultTrueBoolEnvKey: BoolEnvKey {
    
}

@available(iOS 13.0, *)
extension DefaultTrueBoolEnvKey {
    
    @inlinable
    internal static var defaultValue: Value {
        true
    }
    
}

// MARK: - BoolOrOptionsEnvKey

internal protocol EnvOptions: Equatable {
    
    associatedtype OptionValue
    
    static var allOptions: Self { get }
    
    init()
    
    init?(rawValue: String)
    
    var containsAllOptions: Bool { get }
    
    var explicitlyEnabledOptions: [OptionValue] { get }
    
}

/// Supports the following grammar:
///
/// ```
///
/// // To represent all options, use `*`
/// export MY_ENVIRONMENT_VARIABLE=*
///
/// // To represent explicit options, use: `Option1;Option2;Option3`
/// export MY_ENVIRONMENT_VARIABLE=Option1;Option2;Option3
///
/// ```
internal struct SemicolonSeparatedEnvOptions<OptionValue: RawRepresentable>: EnvOptions where OptionValue.RawValue == String {
    
    /// Whether the environment variable contains `*`
    private let refersToAllOptions: Bool
    
    private let explicitOptions: [OptionValue]
    
    internal static var allOptions: Self {
        Self(allOptions: true, options: [])
    }
    
    internal init() {
        self.init(allOptions: false, options: [])
    }
    
    internal init?(rawValue: String) {
        var options: [OptionValue] = []
        var refersToAllOptions = false
        let components = rawValue.split(separator: ";")
        for eachComponent in components {
            if eachComponent == "*" {
                refersToAllOptions = true
            } else if let optionValue = OptionValue(rawValue: String(eachComponent)) {
                options.append(optionValue)
            }
        }
        if options.isEmpty && !refersToAllOptions {
            return nil
        }
        self.init(allOptions: refersToAllOptions, options: options)
    }
    
    @inlinable
    internal init(allOptions: Bool, options: [OptionValue]) {
        self.refersToAllOptions = allOptions
        self.explicitOptions = options
    }
    
    internal var containsAllOptions: Bool {
        refersToAllOptions
    }
    
    internal var explicitlyEnabledOptions: [OptionValue] {
        explicitOptions
    }
    
    internal static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.refersToAllOptions == rhs.refersToAllOptions &&
            lhs.explicitOptions.elementsEqual(rhs.explicitOptions) {
                $0.rawValue == $1.rawValue
            }
    }
    
    
}

internal enum BoolOrOptions<Options: EnvOptions>: Equatable {
    
    case boolean(Bool)
    
    case options(Options)
    
    internal static func make(from boolean: Bool) -> BoolOrOptions<Options> {
        .boolean(boolean)
    }
    
    internal static func make(from string: String) -> BoolOrOptions<Options>? {
        guard let options = Options(rawValue: string) else {
            return nil
        }
        return .options(options)
    }
    
    internal var isOn: Bool {
        switch self {
        case .boolean(let bool):
            return bool
        case .options:
            return true
        }
    }
    
    internal var options: Options {
        switch self {
        case .boolean(let bool):
            return bool ? Options.allOptions : Options()
        case .options(let options):
            return options
        }
    }
    
}

/// Convenient encapsulation for boolean-options-mixed environment
/// variable keys.
@available(iOS 13.0, *)
internal protocol BoolOrOptionsEnvKey: EnvKey where Value == BoolOrOptions<Options> {
    
    associatedtype Options: EnvOptions
    
    static var defaultBooleanValue: Bool { get }
    
}

@available(iOS 13.0, *)
extension BoolOrOptionsEnvKey {
    
    @inlinable
    internal static func makeValue(rawValue: String) -> Value {
        // Some ppl like to use TRUE/FALSE/true/false to fill a boolean env var
        // and some ppl like to use 0/non-0. Let's support them both.
        
        if let boolean = Bool(rawValue.lowercased()) {
            return .make(from: boolean)
        }
        
        if let int = Int(rawValue) {
            return .make(from: int != 0)
        }
        
        return .make(from: rawValue) ?? .make(from: defaultBooleanValue)
    }
    
    internal static var defaultValue: BoolOrOptions<Options> {
        BoolOrOptions.boolean(defaultBooleanValue)
    }
    
}

@available(iOS 13.0, *)
internal protocol DefaultFalseBoolOrOptionsEnvKey: BoolOrOptionsEnvKey {
    
}

@available(iOS 13.0, *)
extension DefaultFalseBoolOrOptionsEnvKey {
    
    internal static var defaultBooleanValue: Bool {
        false
    }
    
}

@available(iOS 13.0, *)
internal protocol DefaultTrueBoolOrOptionsEnvKey: BoolOrOptionsEnvKey {
    
}

@available(iOS 13.0, *)
extension DefaultTrueBoolOrOptionsEnvKey {
    
    internal static var defaultBooleanValue: Bool {
        true
    }
    
}
