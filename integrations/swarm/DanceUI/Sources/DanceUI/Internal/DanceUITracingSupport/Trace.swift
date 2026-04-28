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

internal import DanceUIGraph
internal import _SwiftOSOverlayShims
internal import os

@available(iOS 13.0, *)
internal struct Trace {
    
    // MARK: Global Properties
    
    internal static var isEnabled: Bool {
#if DEBUG || DANCE_UI_INHOUSE
        return EnvValue.traceOptions.isOn
#else
        return false
#endif
    }
    
    internal static var enabledModules: [ModuleName] {
#if DEBUG || DANCE_UI_INHOUSE
        return EnvValue.traceOptions.options.explicitlyEnabledOptions
#else
        return []
#endif
    }
    
    internal static var enablesAllModules: Bool {
#if DEBUG || DANCE_UI_INHOUSE
        return EnvValue.traceOptions.options.containsAllOptions
#else
        return false
#endif
    }
    
    // MARK: Creating Scoped Trace
    
#if DEBUG || DANCE_UI_INHOUSE
    fileprivate let scopedTrace: ScopedTrace
#endif
    
    @inline(__always)
    internal init(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName) {
#if DEBUG || DANCE_UI_INHOUSE
        self.scopedTrace = ScopedTrace(module: module(), component: component())
#endif
    }
    
    // MARK: Data Structures Used in a Trace Info
    
    /// An `ID` identifies a trace event or interval.
    ///
    internal struct ID: Comparable {
        
        private static var seed: UInt64 {
#if DEBUG || DANCE_UI_INHOUSE
            struct Static {
                // On Darwin-based OS:
                // User-space memory: 0x0 ~ 0x7FFF_FFFF_FFFF_FFFF
                // Kernel-space memory: 0x8000_0000_0000_0000 ~ 0xFFFF_FFFF_FFFF_FFFF
                static var seed: UInt64 = 0x8000_0000_0000_0000
            }
            defer {
                Static.seed &+= 1
            }
            return Static.seed
#else
            0
#endif
        }
        
#if DEBUG || DANCE_UI_INHOUSE
        internal var value: UInt64
#endif
        
        internal static let null: ID = ID(0)
        
        internal static let invalid: ID = ID(UInt64.max)
        
        internal static var exclusive: ID {
            ID(ID.seed)
        }
        
        @inlinable
        internal init(_ value: UInt64) {
#if DEBUG || DANCE_UI_INHOUSE
            self.value = value
#endif
        }
        
        /// If we offer an empty struct in non-debug and non-in-house
        /// build, then `==` should always return `true`.
        ///
        @inlinable
        internal static func == (lhs: Trace.ID, rhs: Trace.ID) -> Bool {
#if DEBUG || DANCE_UI_INHOUSE
            lhs.value == rhs.value
#else
            true
#endif
        }
        
        /// If we offer an empty struct in non-debug and non-in-house
        /// build, then whether `<` and `>` should both return `false`.
        ///
        @inlinable
        internal static func < (lhs: Trace.ID, rhs: Trace.ID) -> Bool {
#if DEBUG || DANCE_UI_INHOUSE
            lhs.value < rhs.value
#else
            false
#endif
        }
        
        /// If we offer an empty struct in non-debug and non-in-house
        /// build, then whether `<` and `>` should both return `false`.
        ///
        @inlinable
        internal static func > (lhs: Trace.ID, rhs: Trace.ID) -> Bool {
#if DEBUG || DANCE_UI_INHOUSE
            lhs.value > rhs.value
#else
            false
#endif
        }
        
    }
    
    /// Creating an exclusive trace ID.
    ///
    @inlinable
    internal static func makeTraceID() -> ID {
        ID.exclusive
    }
    
    /// Create a trace ID from an object.
    ///
    @inlinable
    internal static func makeTraceID(from object: AnyObject) -> ID {
        // TODO: Verify the assembly code-gen is trivial
#if DEBUG || DANCE_UI_INHOUSE
        ID(UInt64(bitPattern: Int64(ObjectIdentifier(object).hashValue)))
#else
        ID(0)
#endif
    }
    
    internal typealias ModuleName = Module
    
    internal struct ComponentName: Equatable {
        
        internal typealias ComponentName = Trace.ComponentName
        
#if DEBUG || DANCE_UI_INHOUSE
        internal let rawValue: String
#endif
        
        @inline(__always)
        internal init(_ value: String) {
#if DEBUG || DANCE_UI_INHOUSE
            assert(value.isCamelCased(firstLetterCase: .uppercase), "Component name starts with a capital letter.")
            self.init(rawValue: value)
#endif
        }
        
        @inline(__always)
        internal init(type: Any.Type) {
#if DEBUG || DANCE_UI_INHOUSE
            self.init(rawValue: _typeName(type))
#endif
        }
        
#if DEBUG || DANCE_UI_INHOUSE
        @inline(__always)
        private init(rawValue: String) {
            self.rawValue = rawValue
        }
#endif
        
        /// The `unspecified` component name is used for checking whether
        /// infrastructures that offering tracing conveniences have
        /// correctly set their component name.
        ///
        /// - WARNING: Developers shall never use this module name.
        ///
        internal static let unspecified = ComponentName("Unspecified")
        
    }
    
    internal struct SubjectName: Equatable {
        
        internal typealias SubjectName = Trace.SubjectName
        
#if DEBUG || DANCE_UI_INHOUSE
        internal let rawValue: String
#endif
        
        @inline(__always)
        internal init(_ type: Any.Type) {
#if DEBUG || DANCE_UI_INHOUSE
            self.init(rawValue: _typeName(type, qualified: false))
#endif
        }
        
        @inline(__always)
        internal init(_ value: String) {
#if DEBUG || DANCE_UI_INHOUSE
            assert(value.isCamelCased(), "\(value) is not camel-cased.")
            self.init(rawValue: value)
#endif
        }
        
#if DEBUG || DANCE_UI_INHOUSE
        @inline(__always)
        private init(rawValue: String) {
            self.rawValue = rawValue
        }
#endif
        
#if DEBUG
        @inline(__always)
        internal init(testableRawValue rawValue: String) {
            self.rawValue = rawValue
        }
#endif
        
        /// The `invalid` subject name is used for internal verification.
        /// Using this subject name could make your merge request get
        /// rejected in the future.
        ///
        /// - WARNING: Developers shall never use this subject name.
        ///
        internal static let invalid = SubjectName("invalid")
        
    }
    
    #if DEBUG || DANCE_UI_INHOUSE
    internal enum EventName {
        
        case will(ActionName)
        
        case did(ActionName)
        
        fileprivate var primitiveEventName: String {
            switch self {
            case .will(let actionName):
                return "Will\(actionName.rawValue)"
            case .did(let actionName):
                return "Did\(actionName.rawValue)"
            }
        }
        
        #if DEBUG
        internal var testablePrimitiveEventName: String {
            primitiveEventName
        }
        #endif
        
    }
    #else
    internal struct EventName {
        
        internal static func will(_ actionName: ActionName) -> EventName {
            EventName()
        }
        
        internal static func did(_ actionName: ActionName) -> EventName {
            EventName()
        }
        
    }
    #endif
    
    internal struct ActionName {
        
        internal typealias ActionName = Trace.ActionName
        
#if DEBUG || DANCE_UI_INHOUSE
        internal let rawValue: String
#endif
        
        @inline(__always)
        private init(rawValue: String) {
            #if DEBUG || DANCE_UI_INHOUSE
            self.rawValue = rawValue
            #endif
        }
        
        @inline(__always)
        internal init(_ value: String) {
            #if DEBUG || DANCE_UI_INHOUSE
            assert(value.isCamelCased(firstLetterCase: .uppercase), "Use a verb prototype starts with a capital letter as an action name.")
            #endif
            self.init(rawValue: value)
        }
        
#if DEBUG
        @inline(__always)
        internal init(testableRawValue rawValue: String) {
            self.rawValue = rawValue
        }
#endif
        
        /// The `invalid` interval name is used for internal verification.
        /// Using this subject name could make your merge request get
        /// rejected in the future.
        ///
        /// - WARNING: Developers shall never use this interval name.
        ///
        internal static let invalid = ActionName(rawValue: "Invalid")
        
    }
    
#if DEBUG || DANCE_UI_INHOUSE
    /// The metadata represents a message in a traced interval or event.
    /// It is usually created using string literals.
    ///
    /// Example creating a `Trace.Metadata`:
    ///
    ///     let world: String = "world"
    ///     let myLogMessage: Trace.Metadata = "Hello \(world)"
    ///
    /// Most commonly, `Trace.Metadata`s appear simply as the parameter to
    /// a logging method such as:
    ///
    ///     logger.info("Hello \(world)")
    ///
    internal struct Metadata: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        
        internal var value: String
        
        internal typealias StringLiteralType = String
        
        internal init(stringLiteral value: String) {
            self.value = value
        }
        
        // Cannot find effective way to invoke the following function.
        // BDCOV_EXCL_FUNC
        internal init(unicodeScalarLiteral value: Unicode.Scalar) {
            self.value = ""
            value.write(to: &self.value)
        }
        
        
        // Cannot find effective way to invoke the following function.
        // BDCOV_EXCL_FUNC
        internal init(extendedGraphemeClusterLiteral value: Character) {
            self.value = ""
            value.write(to: &self.value)
        }
        
        internal init(stringInterpolation: DefaultStringInterpolation) {
            self.value = stringInterpolation.description
        }
        
    }
#else
    internal typealias Metadata = String
#endif
    
    // MARK: Tracing Intervals
    
    // Purely forward
    
    @inlinable
    internal static func beginInterval(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.beginInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), nil, file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inlinable
    internal static func beginInterval(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive,  _ metadata: @autoclosure () -> Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.beginInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inlinable
    internal static func beginAnimationInterval(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.beginAnimationInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), nil, file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inlinable
    internal static func beginAnimationInterval(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive,  _ metadata: @autoclosure () -> Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.beginAnimationInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    
    @inlinable
    internal static func endInterval(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.endInterval(module: module(), component: component(), subject: subject(), name: name(), nil, file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inlinable
    internal static func endInterval(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName,  _ metadata: @autoclosure () -> Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.endInterval(module: module(), component: component(), subject: subject(), name: name(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    
    @inlinable
    internal static func withIntervalTrace<T>(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive, around task: () throws -> T, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) rethrows -> T {
#if DEBUG || DANCE_UI_INHOUSE
        beginInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), file: file, function: function, line: line)
        defer {
            endInterval(module: module(), component: component(), subject: subject(), name: name(), file: file, function: function, line: line)
        }
#endif
        return try task()
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inlinable
    internal static func withIntervalTrace<T>(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive, _ metadata: @autoclosure () -> Metadata, around task: () throws -> T, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) rethrows -> T {
#if DEBUG || DANCE_UI_INHOUSE
        beginInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
        defer {
            endInterval(module: module(), component: component(), subject: subject(), name: name(), metadata(), file: file, function: function, line: line)
        }
#endif
        return try task()
    }
    
    // MARK: Emitting Events
    
    // Purely forward
    
    @inlinable
    internal static func emitEvent(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> EventName, id: @autoclosure () -> ID = .exclusive, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.emitEvent(module: module(), component: component(), subject: subject(), name: name(), id: id(), nil, file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inlinable
    internal static func emitEvent(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> EventName, id: @autoclosure () -> ID = .exclusive, _ metadata: @autoclosure () -> Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.emitEvent(module: module(), component: component(), subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // MARK: Scoped Tracing without Metadata
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginInterval(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.beginInterval(subject: subject(), name: name(), id: id(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginAnimationInterval(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.beginAnimationInterval(subject: subject(), name: name(), id: id(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func endInterval(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.endInterval(subject: subject(), name: name(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    
    @inline(__always)
    internal func withIntervalTrace<T>(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive, around task: () throws -> T, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) rethrows -> T {
#if DEBUG || DANCE_UI_INHOUSE
        try scopedTrace.withIntervalTrace(subject: subject(), name: name(), id: id(), around: task, file: file, function: function, line: line)
#else
        try task()
#endif
    }
    
    // Purely forward
    
    @inline(__always)
    internal func emitEvent(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.EventName, id: @autoclosure () -> Trace.ID = .exclusive, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.emitEvent(subject: subject(), name: name(), id: id(), file: file, function: function, line: line)
#endif
    }
    
    // MARK: Scoped Tracing with string-literal-based and string-interpolation-literal-based Metadata
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginInterval(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive,  _ metadata: @autoclosure () -> Trace.Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.beginInterval(subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginAnimationInterval(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive,  _ metadata: @autoclosure () -> Trace.Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.beginAnimationInterval(subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func endInterval(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, _ metadata: @autoclosure () -> Trace.Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.endInterval(subject: subject(), name: name(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func withIntervalTrace<T>(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive, _ metadata: @autoclosure () -> Trace.Metadata, around task: () throws -> T, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) rethrows -> T {
#if DEBUG || DANCE_UI_INHOUSE
        try scopedTrace.withIntervalTrace(subject: subject(), name: name(), id: id(), metadata(), around: task, file: file, function: function, line: line)
#else
        try task()
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func emitEvent(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.EventName, id: @autoclosure () -> Trace.ID = .exclusive, _ metadata: @autoclosure () -> Trace.Metadata, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.emitEvent(subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // MARK: Scoped Tracing with Structured Metadata
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginInterval<MetadataType: TraceMetadataProtocol>(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive,  _ metadata: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.beginInterval(subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginAnimationInterval<MetadataType: TraceMetadataProtocol>(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive,  _ metadata: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.beginAnimationInterval(subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func endInterval<MetadataType: TraceMetadataProtocol>(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, _ metadata: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.endInterval(subject: subject(), name: name(), metadata(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func withIntervalTrace<T, MetadataType: TraceMetadataProtocol>(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.ActionName, id: @autoclosure () -> Trace.ID = .exclusive, _ metadata: @autoclosure () -> MetadataType, around task: () throws -> T, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) rethrows -> T {
#if DEBUG || DANCE_UI_INHOUSE
        try scopedTrace.withIntervalTrace(subject: subject(), name: name(), id: id(), metadata(), around: task, file: file, function: function, line: line)
#else
        try task()
#endif
    }
    
    // Purely forward
    
    @inline(__always)
    internal func emitEvent<MetadataType: TraceMetadataProtocol>(subject: @autoclosure () -> Trace.SubjectName, name: @autoclosure () -> Trace.EventName, id: @autoclosure () -> Trace.ID = .exclusive, _ metadata: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        scopedTrace.emitEvent(subject: subject(), name: name(), id: id(), metadata(), file: file, function: function, line: line)
#endif
    }
    
}

// MARK: - Structured-Metadata-Based Tracing

#if DEBUG || DANCE_UI_INHOUSE

// swift-format-ignore: UseSynthesizedInitializer
@available(iOS 13.0, *)
internal struct TraceMetadataPrivacy {
    
    internal enum Mask: Equatable {
        
        case hash
        case none
        
    }
    
    internal enum Kind: Equatable {
        
        case auto
        case `private`
        case `public`
        case sensitive
        
    }
    
    fileprivate enum VariantPrivacy {
        
        case auto(Mask)
        case `private`(Mask)
        case `public`
        case sensitive(Mask)
        
    }
    
    fileprivate let variant: VariantPrivacy
    
    fileprivate init(variant: VariantPrivacy) {
        self.variant = variant
    }
    
    @inline(__always)
    internal var mask: Mask {
        switch variant {
        case .auto(let mask):       return mask
        case .private(let mask):    return mask
        case .public:               return .none
        case .sensitive(let mask):  return mask
        }
    }
    
    @inline(__always)
    internal var kind: Kind {
        switch variant {
        case .auto:                 return .auto
        case .private:              return .private
        case .public:               return .public
        case .sensitive:            return .sensitive
        }
    }
    
    internal static let auto = TraceMetadataPrivacy(variant: .auto(.hash))
    
    internal static let `private` = TraceMetadataPrivacy(variant: .private(.hash))
    
    internal static let `public` = TraceMetadataPrivacy(variant: .public)
    
    internal static let sensitive = TraceMetadataPrivacy(variant: .sensitive(.hash))
    
    @inlinable
    internal static func auto(mask: Mask) -> TraceMetadataPrivacy {
        TraceMetadataPrivacy(variant: .auto(mask))
    }
    
    @inlinable
    internal static func `private`(mask: Mask) -> TraceMetadataPrivacy {
        TraceMetadataPrivacy(variant: .private(mask))
    }
    
    @inlinable
    internal static func sensitive(mask: Mask) -> TraceMetadataPrivacy {
        TraceMetadataPrivacy(variant: .sensitive(mask))
    }
    
}

#endif

#if DEBUG || DANCE_UI_INHOUSE
@available(iOS 13.0, *)
internal protocol TraceMetadataProtocol: Codable, _TraceMetadataExtractable {

    static var privacyForFieldName: [String : TraceMetadataPrivacy] { get }

}
#else
@available(iOS 13.0, *)
internal typealias TraceMetadataProtocol = Codable
#endif

#if DEBUG || DANCE_UI_INHOUSE
private let metadataFieldAllowedTypes: Set<ObjectIdentifier> = [
    ObjectIdentifier(Int.self),
    ObjectIdentifier(Int8.self),
    ObjectIdentifier(Int16.self),
    ObjectIdentifier(Int32.self),
    ObjectIdentifier(Int64.self),
    ObjectIdentifier(UInt.self),
    ObjectIdentifier(UInt8.self),
    ObjectIdentifier(UInt16.self),
    ObjectIdentifier(UInt32.self),
    ObjectIdentifier(UInt64.self),
    ObjectIdentifier(Bool.self),
    ObjectIdentifier(String.self),
    ObjectIdentifier(Float.self),
    ObjectIdentifier(Double.self),
]
#endif

#if DEBUG || DANCE_UI_INHOUSE
@available(iOS 13.0, *)
extension TraceMetadataProtocol {
    
    internal func _makeDictionary() -> [String : Any] {
        var info: [String : Any] = [:]
        let mirror = Mirror(reflecting: self)
        for eachChild in mirror.children {
            if let label = eachChild.label,
               metadataFieldAllowedTypes.contains(ObjectIdentifier(type(of: eachChild.value))) {
                info[label] = eachChild.value
            }
        }
        return info
    }
    
}
#endif

#if DEBUG || DANCE_UI_INHOUSE
// TODO: Consider simplifying the privacy control configuration with macro
//
// ```
// @TraceMetadata
// struct Foo {
//  @TracePrivacy(.public)
//  var bar: Int
// }
// ```
//
@available(iOS 13.0, *)
extension TraceMetadataProtocol {
    
    @inlinable
    internal static var privacyForFieldName: [String : TraceMetadataPrivacy] {
        [:]
    }
    
}
#endif

#if DEBUG || DANCE_UI_INHOUSE
@available(iOS 13.0, *)
internal protocol IntervalTraceMetadataProtocol: TraceMetadataProtocol {
    
    associatedtype IntervalMetadataType: TraceMetadataProtocol = EmptyTraceMetadata
    
    static func makeInterval(begin: Self, end: Self) -> IntervalMetadataType
    
}

@available(iOS 13.0, *)
extension IntervalTraceMetadataProtocol where IntervalMetadataType == EmptyTraceMetadata {
    
    @inlinable
    internal static func makeInterval(begin: Self, end: Self) -> EmptyTraceMetadata {
        EmptyTraceMetadata()
    }
    
}
#else
@available(iOS 13.0, *)
internal typealias IntervalTraceMetadataProtocol = TraceMetadataProtocol
#endif

@available(iOS 13.0, *)
internal struct EmptyTraceMetadata: TraceMetadataProtocol, Equatable {
    
}

@available(iOS 13.0, *)
extension Trace {
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    internal static func beginInterval<MetadataType: TraceMetadataProtocol>(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive,  _ message: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.beginInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), message(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    internal static func beginAnimationInterval<MetadataType: TraceMetadataProtocol>(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive,  _ message: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.beginAnimationInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), message(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    internal static func endInterval<MetadataType: TraceMetadataProtocol>(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, _ message: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.endInterval(module: module(), component: component(), subject: subject(), name: name(), message(), file: file, function: function, line: line)
#endif
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    internal static func withIntervalTrace<T, MetadataType: TraceMetadataProtocol>(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> ActionName, id: @autoclosure () -> ID = .exclusive, _ message: @autoclosure () -> MetadataType, around task: () throws -> T, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) rethrows -> T {
#if DEBUG || DANCE_UI_INHOUSE
        beginInterval(module: module(), component: component(), subject: subject(), name: name(), id: id(), message(), file: file, function: function, line: line)
        defer {
            endInterval(module: module(), component: component(), subject: subject(), name: name(), message(), file: file, function: function, line: line)
        }
#endif
        return try task()
    }
    
    // Purely forward
    
    internal static func emitEvent<MetadataType: TraceMetadataProtocol>(module: @autoclosure () -> ModuleName, component: @autoclosure () -> ComponentName, subject: @autoclosure () -> SubjectName, name: @autoclosure () -> EventName, id: @autoclosure () -> ID = .exclusive, _ message: @autoclosure () -> MetadataType, file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        UnscopedTrace.emitEvent(module: module(), component: component(), subject: subject(), name: name(), id: id(), message(), file: file, function: function, line: line)
#endif
    }
    
}

// MARK: - Tracing Conveniences

#if DEBUG || DANCE_UI_INHOUSE

@available(iOS 13.0, *)
internal protocol TraceModuleNameOffering {
    
    static var moduleName: Trace.ModuleName { get }
    
}

@available(iOS 13.0, *)
extension TraceModuleNameOffering {
    
    internal static var moduleName: Trace.ModuleName {
        .unspecified
    }
    
}

@available(iOS 13.0, *)
internal protocol TraceComponentNameOffering {
    
    static var componentName: Trace.ComponentName { get }
    
}

@available(iOS 13.0, *)
extension TraceComponentNameOffering {
    
    internal static var componentName: Trace.ComponentName {
        .unspecified
    }
    
}

// MARK: Scoped Trace

/// Scoped trace with preset module name and component name.
///
@available(iOS 13.0, *)
private struct ScopedTrace {
    
    fileprivate let module: Trace.ModuleName
    
    fileprivate let component: Trace.ComponentName
    
    // MARK: Scoped Tracing without Metadata
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginInterval(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID = .exclusive, file: StaticString, function: StaticString, line: UInt) {
        Trace.beginInterval(module: module, component: component, subject: subject, name: name, id: id, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginAnimationInterval(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID = .exclusive, file: StaticString, function: StaticString, line: UInt) {
        Trace.beginAnimationInterval(module: module, component: component, subject: subject, name: name, id: id, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func endInterval(subject: Trace.SubjectName, name: Trace.ActionName, file: StaticString, function: StaticString, line: UInt) {
        Trace.endInterval(module: module, component: component, subject: subject, name: name, file: file, function: function, line: line)
    }
    
    // Purely forward
    
    @inline(__always)
    internal func withIntervalTrace<T>(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID = .exclusive, around task: () throws -> T, file: StaticString, function: StaticString, line: UInt) rethrows -> T {
        try Trace.withIntervalTrace(module: module, component: component, subject: subject, name: name, id: id, around: task, file: file, function: function, line: line)
    }
    
    // Purely forward
    
    @inline(__always)
    internal func emitEvent(subject: Trace.SubjectName, name: Trace.EventName, id: Trace.ID = .exclusive, file: StaticString, function: StaticString, line: UInt) {
        Trace.emitEvent(module: module, component: component, subject: subject, name: name, id: id, file: file, function: function, line: line)
    }
    
    // MARK: Scoped Tracing with string-literal-based and String-interpolation-literal-based Metadata
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginInterval(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID = .exclusive,  _ metadata: Trace.Metadata, file: StaticString, function: StaticString, line: UInt) {
        Trace.beginInterval(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginAnimationInterval(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID,  _ metadata: Trace.Metadata, file: StaticString, function: StaticString, line: UInt) {
        Trace.beginAnimationInterval(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func endInterval(subject: Trace.SubjectName, name: Trace.ActionName, _ metadata: Trace.Metadata, file: StaticString, function: StaticString, line: UInt) {
        Trace.endInterval(module: module, component: component, subject: subject, name: name, metadata, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func withIntervalTrace<T>(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID, _ metadata: Trace.Metadata, around task: () throws -> T, file: StaticString, function: StaticString, line: UInt) rethrows -> T {
        try Trace.withIntervalTrace(module: module, component: component, subject: subject, name: name, id: id, metadata, around: task, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func emitEvent(subject: Trace.SubjectName, name: Trace.EventName, id: Trace.ID = .exclusive, _ metadata: Trace.Metadata, file: StaticString, function: StaticString, line: UInt) {
        Trace.emitEvent(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
    }
    
    // MARK: Scoped Tracing with Structured Metadata
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginInterval<MetadataType: TraceMetadataProtocol>(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID,  _ metadata: MetadataType, file: StaticString, function: StaticString, line: UInt) {
        Trace.beginInterval(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func beginAnimationInterval<MetadataType: TraceMetadataProtocol>(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID,  _ metadata: MetadataType, file: StaticString, function: StaticString, line: UInt) {
        Trace.beginAnimationInterval(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func endInterval<MetadataType: TraceMetadataProtocol>(subject: Trace.SubjectName, name: Trace.ActionName, _ metadata: MetadataType, file: StaticString, function: StaticString, line: UInt) {
        Trace.endInterval(module: module, component: component, subject: subject, name: name, metadata, file: file, function: function, line: line)
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    @inline(__always)
    internal func withIntervalTrace<T, MetadataType: TraceMetadataProtocol>(subject: Trace.SubjectName, name: Trace.ActionName, id: Trace.ID, _ metadata: MetadataType, around task: () throws -> T, file: StaticString, function: StaticString, line: UInt) rethrows -> T {
        try Trace.withIntervalTrace(module: module, component: component, subject: subject, name: name, id: id, metadata, around: task, file: file, function: function, line: line)
    }
    
    // Purely forward
    
    @inline(__always)
    internal func emitEvent<MetadataType: TraceMetadataProtocol>(subject: Trace.SubjectName, name: Trace.EventName, id: Trace.ID, _ metadata: MetadataType, file: StaticString, function: StaticString, line: UInt) {
        Trace.emitEvent(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
    }
    
}

// MARK: - Unscoped Trace

/// Unscoped trace
///
@available(iOS 13.0, *)
private struct UnscopedTrace {
    
    fileprivate typealias ID = Trace.ID
    
    fileprivate typealias ModuleName = Trace.ModuleName
    
    fileprivate typealias ComponentName = Trace.ComponentName
    
    fileprivate typealias SubjectName = Trace.SubjectName
    
    fileprivate typealias EventName = Trace.EventName
    
    fileprivate typealias ActionName = Trace.ActionName
    
    fileprivate typealias IntervalName = Trace.ActionName
    
    // Purely forward
    
    fileprivate static func beginInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: ActionName, id: ID,  _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        forEachStream { stream in
            stream.beginInterval(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
        }
    }
    
    // Purely forward
    // BDCOV_EXCL_FUNC
    fileprivate static func beginAnimationInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: ActionName, id: ID,  _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        forEachStream { stream in
            stream.beginAnimationInterval(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
        }
    }
    
    // Purely forward
    
    fileprivate static func endInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: ActionName, _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        forEachStream { stream in
            stream.endInterval(module: module, component: component, subject: subject, name: name, metadata, file: file, function: function, line: line)
        }
    }
    
    // Purely forward
    
    fileprivate static func emitEvent(module: ModuleName, component: ComponentName, subject: SubjectName, name: EventName, id: ID = .exclusive, _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        forEachStream { stream in
            stream.emitEvent(module: module, component: component, subject: subject, name: name, id: id, metadata, file: file, function: function, line: line)
        }
    }
    
    // MARK: Trace Output Streams
    
    fileprivate static let streams: [TraceOutputStream] = [
        LogServiceTraceOutputStream()
    ]
    
    fileprivate static func forEachStream(do body: (TraceOutputStream) -> Void) {
        for eachStream in streams {
            body(eachStream)
        }
    }
    
}

// MARK: - Output Streams

@available(iOS 13.0, *)
internal class TraceOutputStream {
    
    internal typealias ID = Trace.ID
    
    internal typealias ModuleName = Trace.ModuleName
    
    internal typealias ComponentName = Trace.ComponentName
    
    internal typealias SubjectName = Trace.SubjectName
    
    internal typealias EventName = Trace.EventName
    
    internal typealias IntervalName = Trace.ActionName
    
    internal typealias PrimitiveMetadata = [String: Any]
    
    internal var isEnabled: Bool
    
    internal var enablesAllModules: Bool
    
    internal var enabledModules: Set<ModuleName>
    
    internal init() {
        self.isEnabled = Trace.isEnabled
        self.enablesAllModules = Trace.enablesAllModules
        self.enabledModules = Set(Trace.enabledModules)
    }
    
    internal func shouldTrace(for moduleName: ModuleName) -> Bool {
        if enablesAllModules {
            return true
        }
        return enabledModules.contains(moduleName)
    }
    
    // Abstract function, test coverage should not include this
    // BDCOV_EXCL_FUNC
    internal func beginInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: IntervalName, id: ID,  _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        _abstract(self)
    }
    
    // Abstract function, test coverage should not include this
    // BDCOV_EXCL_FUNC
    internal func beginAnimationInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: IntervalName, id: ID,  _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        _abstract(self)
    }
    
    // Abstract function, test coverage should not include this
    // BDCOV_EXCL_FUNC
    internal func endInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: IntervalName, _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        _abstract(self)
    }
    
    // Abstract function, test coverage should not include this
    // BDCOV_EXCL_FUNC
    internal func emitEvent(module: ModuleName, component: ComponentName, subject: SubjectName, name: EventName, id: ID, _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        _abstract(self)
    }
    
}

@available(iOS 13.0, *)
private final class LogServiceTraceOutputStream: TraceOutputStream {
    
    // FIXME: Temporarily excluded
    // BDCOV_EXCL_FUNC
    private func makeIndicatorName(module: ModuleName, component: ComponentName, subject: SubjectName, name: String) -> String {
        return "\(module.rawValue).\(component.rawValue).\(subject.rawValue).\(name)"
    }
    
    // FIXME: Temporarily excluded
    // BDCOV_EXCL_FUNC
    private func makeInfo(id: Trace.ID, indicatorName: String, addition: _TraceMetadataExtractable?) -> [String : Any] {
        let base: [String : Any] = [
            "trace_id": id.value,
            "indicator_name": indicatorName,
        ]
        if let addition = addition?._makeDictionary() {
            return base.merging(addition, uniquingKeysWith: { a, _ in a })
        }
        return base
    }
    
    // FIXME: Temporarily excluded
    // BDCOV_EXCL_FUNC
    private func makeInfo(indicatorName: String, addition: _TraceMetadataExtractable?) -> [String : Any] {
        if let addition = addition?._makeDictionary() {
            return addition
        }
        return [:]
    }
    
    // FIXME: Temporarily excluded
    // BDCOV_EXCL_FUNC
    fileprivate override func beginInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: IntervalName, id: ID,  _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        guard shouldTrace(for: module) else {
            return
        }
        let indicatorName = makeIndicatorName(module: module, component: component, subject: subject, name: name.rawValue)
        LogService.info(module: .trace, keyword: .beginInterval, "", info: makeInfo(id: id, indicatorName: indicatorName, addition: metadata), file: file.stringValue, function: function.stringValue, line: line)
    }
    
    // FIXME: Temporarily excluded
    // BDCOV_EXCL_FUNC
    fileprivate override func beginAnimationInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: IntervalName, id: ID,  _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        guard shouldTrace(for: module) else {
            return
        }
        let indicatorName = makeIndicatorName(module: module, component: component, subject: subject, name: name.rawValue)
        LogService.info(module: .trace, keyword: .beginInterval, "isAnimation=YES", info: makeInfo(id: id, indicatorName: indicatorName, addition: metadata), file: file.stringValue, function: function.stringValue, line: line)
    }
    
    // FIXME: Temporarily excluded
    // BDCOV_EXCL_FUNC
    fileprivate override func endInterval(module: ModuleName, component: ComponentName, subject: SubjectName, name: IntervalName, _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        guard shouldTrace(for: module) else {
            return
        }
        let indicatorName = makeIndicatorName(module: module, component: component, subject: subject, name: name.rawValue)
        LogService.info(module: .trace, keyword: .endInterval, "", info: makeInfo(indicatorName: indicatorName, addition: metadata), file: file.stringValue, function: function.stringValue, line: line)
        // TODO: Reducing the interval into a duration
    }
    
    // FIXME: Temporarily excluded
    // BDCOV_EXCL_FUNC
    fileprivate override func emitEvent(module: ModuleName, component: ComponentName, subject: SubjectName, name: EventName, id: ID, _ metadata: _TraceMetadataExtractable?, file: StaticString, function: StaticString, line: UInt) {
        guard shouldTrace(for: module) else {
            return
        }
        let indicatorName = makeIndicatorName(module: module, component: component, subject: subject, name: name.primitiveEventName)
        LogService.info(module: .trace, keyword: .emitEvent, "", info: makeInfo(id: id, indicatorName: indicatorName, addition: metadata), file: file.stringValue, function: function.stringValue, line: line)
    }
    
}

/// Tracing info metadata implementation detail. Not meant for being used
/// by DanceUI DSL author.
///
@available(iOS 13.0, *)
internal protocol _TraceMetadataExtractable {
    
    /// Not for DanceUI DSL author.
    ///
    func _makeDictionary() -> [String : Any]
    
}

@available(iOS 13.0, *)
extension Trace.Metadata: _TraceMetadataExtractable {
    
    internal func _makeDictionary() -> [String : Any] {
        ["message" : value]
    }
    
}

@available(iOS 13.0, *)
private enum LogKeywords: String, LogKeyword {
    
    case beginInterval
    case endInterval
    case emitEvent
    
    // Used in reading environment variable. Difficult to construct test cases.
    // BDCOV_EXCL_FUNC
    fileprivate static var moduleName: String {
        "Trace"
    }
    
}

@available(iOS 13.0, *)
extension LogService.Module where K == LogKeywords {
    
    fileprivate static let trace: Self = .init()
    
}

// TODO: not implemented
@available(iOS 13.0, *)
private final class OSSignpostTraceOutputStream: TraceOutputStream {
    
}

// MARK: Utilities

extension String {
    
    internal enum FirstLetterCase {
        case uppercase
        case lowercase
    }
    
    internal func isCamelCased(firstLetterCase: FirstLetterCase? = nil) -> Bool {
        if isEmpty {
            return false
        }
        
        var firstLetterStart = 0
        var checkedFirstLetter = false
        
        for (index, eachChar) in self.enumerated() {
            if let firstLetterCase {
                if eachChar == "_" && !checkedFirstLetter {
                    firstLetterStart += 1
                } else {
                    if index == firstLetterStart {
                        switch firstLetterCase {
                        case .uppercase:
                            if !eachChar.isUppercase {
                                return false
                            }
                        case .lowercase:
                            if !eachChar.isLowercase {
                                return false
                            }
                        }
                    }
                    checkedFirstLetter = true
                }
            }
            if !eachChar.isNumber && !eachChar.isLetter && eachChar != "." && eachChar != "_" {
                return false
            }
        }
        
        return true
    }
    
}

// MARK: - Environment Variable

@available(iOS 13, *)
private struct TraceKey: DefaultFalseBoolOrOptionsEnvKey {
    
    internal typealias Options = SemicolonSeparatedEnvOptions<Trace.ModuleName>
    
    internal static var raw: String {
        "DANCEUI_TRACE"
    }
    
}

@available(iOS 13.0, *)
extension Trace.ModuleName: RawRepresentable {
    
    // Used in reading environment variable. Difficult to construct test cases.
    // BDCOV_EXCL_BLOCK
    internal init(rawValue: String) {
        self.rawValue = rawValue
    }
    
}


@available(iOS 13, *)
extension EnvValue where K == TraceKey {
    
    private static let singleton: Self = .init()
    
    @inline(__always)
    fileprivate static var traceOptions: BoolOrOptions<SemicolonSeparatedEnvOptions<Trace.ModuleName>> {
        singleton.value
    }
    
}

#if DEBUG
// Test helper function

@available(iOS 13, *)
internal func testableSetTraceEnabled(modules: [Trace.ModuleName] = []) {
    EnvMock.shared.enableMock(TraceKey.self)
    if modules.isEmpty {
        EnvMock.shared.setValue(.boolean(true), for: TraceKey.self)
    } else {
        EnvMock.shared.setValue(.options(SemicolonSeparatedEnvOptions(allOptions: false, options: modules)), for: TraceKey.self)
    }
}

// Test helper function

@available(iOS 13, *)
internal func testableSetTraceEnabledAll() {
    EnvMock.shared.enableMock(TraceKey.self)
    EnvMock.shared.setValue(.options(SemicolonSeparatedEnvOptions(allOptions: true, options: [])), for: TraceKey.self)
}

// Test helper function

@available(iOS 13, *)
internal func testableSetTraceDisabled() {
    EnvMock.shared.disableMock(TraceKey.self)
}
#endif

#endif
