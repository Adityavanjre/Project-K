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
import os.signpost
#if DANCE_UI_INHOUSE || DEBUG
internal import _SwiftOSOverlayShims
#endif

@available(iOS 13.0, *)
public final class DanceUIScrollViewScrollState {
    public init() {
        self.isScrolling = false
    }
    
    public var isScrolling: Bool
}

@available(iOS 13.0, *)
public let danceUIScrollViewScrollState = DanceUIScrollViewScrollState()

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public struct Signpost {
    
    // MARK: Signposts
    
    internal static let platformUpdate: Signpost = .makePublished(name: "PlatformUpdate")
    
    internal static let linkDestroy: Signpost = .makePublished(name: "LinkDestroy")
    
    internal static let linkUpdate: Signpost = .makePublished(name: "LinkUpdate")
    
    internal static let linkCreate: Signpost = .makePublished(name: "LinkCreate")
    
    internal static let bodyInvoke: Signpost = .makePublished(name: "BodyInvoke")
    
    internal static let viewGraph: Signpost = .makePublished(name: "ViewGraph")
    
    internal static let graphHost: Signpost = .makePublished(name: "GraphHost")
    
    internal static let viewRenderer: Signpost = .makePublished(name: "ViewRenderer")
    
    internal static let resolvedText: Signpost = .makePublished(name: "ResolvedText")
    
    internal static let viewInfoTrace: Signpost = . makePermanentInhouse(name: "ViewInfoTrace")
    
    // MARK: Properties
    
#if DANCE_UI_INHOUSE || DEBUG
    
    @_spi(DanceUICompose)
    public let style: Style
    
    private let stability: Stability
    
#endif
    
    // MARK: Tracing
    
    @_transparent
    @_spi(DanceUICompose)
    public func traceInterval<T>(object: AnyObject? = nil,
                                   _ message: @autoclosure () -> StaticString,
                                   _ args: @autoclosure () -> [CVarArg],
                                   closure: () -> T) -> T {
#if DANCE_UI_INHOUSE || DEBUG
        guard isEnabled else {
            return closure()
        }
        switch style {
        case .os_log(let name):
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return closure()
            }
            let id: OSSignpostID = .makeExclusive(object)
            let msg = message()
            let args2 = args()
            withVaList(args2) { argsPtr in
                os_signpost(.begin, log: signpostLog, name: name, signpostID: id, msg, argsPtr)
            }
            defer {
                withVaList(args2) { argsPtr in
                    os_signpost(.end, log: signpostLog, name: name, signpostID: id, msg, argsPtr)
                }
            }
            return closure()
#if DEBUG
        case .test(let name):
            if let type = args().first as? String {
                SignpostManager.update(name, type: type)
            }
            return closure()
#endif
        case .kdebug:
            return closure()
        }
#else
        return closure()
#endif
    }

    @_transparent
    @_spi(DanceUICompose)
    public func traceInterval<T>(object: AnyObject? = nil,
                                   _ meesage: @autoclosure () -> StaticString?,
                                   closure: () -> T) -> T {
#if DANCE_UI_INHOUSE || DEBUG
        guard isEnabled else {
            return closure()
        }
        let log = signpostLog
        switch style {
        case .os_log(let name):
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return closure()
            }
            
            let id = OSSignpostID.makeExclusive(object)
            let message = meesage()
            if let message = message {
                os_signpost(.begin,
                            log: log,
                            name: name,
                            signpostID: id,
                            message)
            } else {
                os_signpost(.begin,
                            log: log,
                            name: name,
                            signpostID: id)
            }
            
            defer {
                if let message = message {
                    os_signpost(.end,
                                log: log,
                                name: name,
                                signpostID: id,
                                message)
                } else {
                    os_signpost(.end,
                                log: log,
                                name: name,
                                signpostID: id)
                }
            }
            return closure()
#if DEBUG
        case .test(_):
            fallthrough
#endif
        case .kdebug:
            return closure()
        }
#else
        return closure()
#endif
    }

    @_transparent
    @_spi(DanceUICompose)
    public func tracePoiBegin(object: AnyObject? = nil,
                                _ message: @autoclosure () -> StaticString?,
                                _ args: @autoclosure () -> [CVarArg]) -> OSSignpostID? {
#if DANCE_UI_INHOUSE || DEBUG
        guard isPoiEnabled else {
            return nil
        }
        let log = poiLog
        switch style {
        case .os_log(let name):
            let id = OSSignpostID.makeExclusive(object)
            let message = message()
            let args2 = args()
            withVaList(args2) { argsPtr in
                if let message = message {
                    os_signpost(.begin,
                                log: log,
                                name: name,
                                signpostID: id,
                                message,
                                argsPtr)
                } else {
                    os_signpost(.begin,
                                log: log,
                                name: name,
                                signpostID: id)
                }
            }
            return id
            
#if DEBUG
        case .test(_):
            return nil
#endif
        case .kdebug:
            return nil
        }
#endif
        return nil
    }

    @_transparent
    @_spi(DanceUICompose)
    public func tracePoiEnd(object: AnyObject? = nil,
                              id: OSSignpostID?,
                              _ message: @autoclosure () -> StaticString?,
                              _ args: @autoclosure () -> [CVarArg]) {
#if DANCE_UI_INHOUSE || DEBUG
        guard isPoiEnabled, let id else {
            return
        }
        let log = poiLog
        switch style {
        case .os_log(let name):
            let message = message()
            let args2 = args()
            return withVaList(args2) { argsPtr in
                if let message = message {
                    os_signpost(.end,
                                log: log,
                                name: name,
                                signpostID: id,
                                message,
                                argsPtr)
                } else {
                    os_signpost(.end,
                                log: log,
                                name: name,
                                signpostID: id)
                }
            }
            
            
#if DEBUG
        case .test(_):
            fallthrough
#endif
        case .kdebug:
            return
        }
#endif
    }

    @_transparent
    public func tracePoi<T>(object: AnyObject? = nil,
                              _ message: @autoclosure () -> StaticString?,
                              _ args: @autoclosure () -> [CVarArg],
                              closure: () -> T) -> T {
#if DANCE_UI_INHOUSE || DEBUG
        guard isPoiEnabled else {
            return closure()
        }
        switch style {
        case .os_log(let name):
            let id = tracePoiBegin(message(), args())
            defer {
                tracePoiEnd(id: id, message(), args())
            }
            
            return closure()
#if DEBUG
        case .test(_):
            fallthrough
#endif
        case .kdebug:
            return closure()
        }
#else
        return closure()
#endif
    }

    @_transparent
    internal func traceEvent(object: AnyObject? = nil,
                             _ meesage: @autoclosure () -> StaticString) {
#if DANCE_UI_INHOUSE || DEBUG
        guard isEnabled else {
            return
        }
        
        switch style {
        case .os_log(let name):
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return
            }
            
            let id = OSSignpostID.makeExclusive(object)
            os_signpost(.event,
                        log: signpostLog,
                        name: name,
                        signpostID: id,
                        meesage())
#if DEBUG
        case .test(_):
            fallthrough
#endif
        case .kdebug:
            break
        }
#endif
    }

    @_transparent
    internal func traceEvent(object: AnyObject? = nil,
                             _ message: @autoclosure () -> StaticString,
                             _ args: @autoclosure () -> [CVarArg]) {
#if DANCE_UI_INHOUSE || DEBUG
        guard isEnabled else {
            return
        }
        switch style {
        case .os_log(let name):
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return
            }
            
            let id = OSSignpostID.makeExclusive(object)
            withVaList(args()) { argsPtr in
                os_signpost(.event, log: signpostLog, name: name, signpostID: id, message(), argsPtr)
            }
#if DEBUG
        case .test(_):
            fallthrough
#endif
        case .kdebug:
            break
        }
#endif
    }

    @_transparent
    @_spi(DanceUICompose)
    public func makeIntervalTraceID(object: AnyObject? = nil) -> OSSignpostID {
#if DANCE_UI_INHOUSE || DEBUG
        .makeExclusive(object)
#else
        .null
#endif
    }
    
    @_transparent
    @_spi(DanceUICompose)
    public func traceIntervalBegin(id: OSSignpostID,
                                     _ message: @autoclosure () -> StaticString,
                                     _ args: @autoclosure () -> [CVarArg]) {
#if DANCE_UI_INHOUSE || DEBUG
        guard isEnabled else {
            return
        }
        
        switch style {
        case .os_log(let name):
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return
            }
            
            let msg = message()
            let args2 = args()
            withVaList(args2) { argsPtr in
                os_signpost(.begin, log: signpostLog, name: name, signpostID: id, msg, argsPtr)
            }
            return
#if DEBUG
        case .test(let name):
            if let type = args().first as? String {
                SignpostManager.update(name, type: type)
            }
            return
#endif
        case .kdebug:
            return
        }
#endif
    }

    @_transparent
    @_spi(DanceUICompose)
    public func traceIntervalEnd(id: OSSignpostID,
                                   _ message: @autoclosure () -> StaticString,
                                   _ args: @autoclosure () -> [CVarArg]) {
#if DANCE_UI_INHOUSE || DEBUG
        guard isEnabled else {
            return
        }
        
        switch style {
        case .os_log(let name):
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return
            }
            
            let msg = message()
            let args2 = args()
            withVaList(args2) { argsPtr in
                os_signpost(.end, log: signpostLog, name: name, signpostID: id, msg, argsPtr)
            }
            return
#if DEBUG
        case .test(let name):
            if let type = args().first as? String {
                SignpostManager.update(name, type: type)
            }
            return
#endif
        case .kdebug:
            return
        }
#endif
    }

    // MARK: Utiliies
    
#if DANCE_UI_INHOUSE || DEBUG
    @_spi(DanceUICompose)
    public var isEnabled: Bool {
        // Use environment variable to control signpost level
        guard stability != .disabled && stability.rawValue <= EnvValue.signpostLevel.rawValue else {
            return false
        }
        switch style {
        case .os_log:
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return false
            }
            return signpostLog.signpostsEnabled
#if DEBUG
        case .test:
            return true
#endif
        case .kdebug:
            return false
        }
    }
#else
    @inline(__always)
    internal var isEnabled: Bool {
        return false
    }
#endif
    
#if DANCE_UI_INHOUSE || DEBUG
    @_spi(DanceUICompose)
    public var isPoiEnabled: Bool {
        // Use environment variable to control signpost level
        guard stability != .disabled && stability.rawValue <= EnvValue.signpostLevel.rawValue else {
            return false
        }
        switch style {
        case .os_log:
            guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else {
                return false
            }
            return signpostLog.signpostsEnabled
#if DEBUG
        case .test:
            return true
#endif
        case .kdebug:
            return false
        }
    }
#else
    @inline(__always)
    internal var isPoiEnabled: Bool {
        return false
    }
#endif
    
    @_spi(DanceUICompose)
    public static func makePermanentInhouse(name: @autoclosure () -> StaticString) -> Signpost {
#if DANCE_UI_INHOUSE || DEBUG
        .make(name: name(), .permanentInhouse)
#else
        return Signpost()
#endif
    }
    
    @_spi(DanceUICompose)
    public static func makePublished(name: @autoclosure () -> StaticString) -> Signpost {
#if DANCE_UI_INHOUSE || DEBUG
        .make(name: name(), .published)
#else
        return Signpost()
#endif
    }
    
#if DANCE_UI_INHOUSE || DEBUG
    
    @inline(__always)
    private static func make(name: @autoclosure () -> StaticString, _ stability: Stability) -> Signpost {
        return Signpost(style: .automaticStyle(name()), stability: stability)
    }
#endif
    
    // MARK: Supporting Types
    
#if DANCE_UI_INHOUSE || DEBUG
    
    @_spi(DanceUICompose)
    public enum Style {
        
        case kdebug(UInt8)
        
        case os_log(StaticString)
        
#if DEBUG
        case test(String)
#endif
        
        fileprivate static func automaticStyle(_ name: StaticString) -> Style {
            //#if DEBUG
            //
            //            return .test(name.stringValue)
            //
            //#endif
            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                return .os_log(name)
            } else {
                return .kdebug(0)
            }
        }
    }
    
    /// The order of the following cases is adjusted to work with the
    /// `maxLevel` design.
    ///
    /// Original order:
    /// disabled: 0
    /// verbose: 1
    /// debug: 2
    /// published: 3
    public enum Stability: UInt8, Equatable {
        
        /// Permanent signposts are toggled by feature flags and only exists in
        /// in-house version of DanceUI.
        case permanentInhouse
        
        case disabled
        
        case published
        
        case debug
        
        case verbose
        
    }
    
#endif
    
}

#if DANCE_UI_INHOUSE || DEBUG

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
@_spi(DanceUICompose)
public let signpostLog = OSLog(subsystem: "com.ByteDance.DanceUI", category: "DanceUI")

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
@_spi(DanceUICompose)
public let poiLog = OSLog(subsystem: "com.ByteDance.DanceUI", category: .pointsOfInterest)

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
extension OSSignpostID {
    /// Used in kdebug style
    @available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
    fileprivate static let continuation = OSSignpostID(0xea89ce2)
    
    @inline(__always)
    @_spi(DanceUICompose)
    public static func makeExclusive(_ object: AnyObject?) -> OSSignpostID {
        struct Static {
            private static var _seed: UInt64 = 0
            static var seed: UInt64 {
                defer {
                    _seed &+= 1
                }
                return _seed
            }
        }
        if let object = object {
            return OSSignpostID(UInt64(UInt(bitPattern: ObjectIdentifier(object))))
        } else {
            return OSSignpostID(Static.seed)
        }
    }
}



// swift-format-ignore: AlwaysUseLowerCamelCase
@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
@_spi(DanceUICompose)
public func os_signpost(_ type: OSSignpostType, dso: UnsafeRawPointer = #dsohandle, log: OSLog, name: StaticString, signpostID: OSSignpostID = .exclusive, _ format: StaticString, _ arguments: CVaListPointer) {
    let returnAddress = _swift_os_log_return_address()
    _swift_os_signpost_with_format(dso, returnAddress, log, type, name.utf8Start, signpostID.rawValue, format.utf8Start, arguments)
}

#endif

private var globalBodyAccessSeed: UInt {
    struct Static {
        static var seed: UInt = 0
    }
    defer {
        Static.seed &+= 1
    }
    return Static.seed
}

@inline(__always)
@available(iOS 13.0, *)
internal func traceRuleBody<ViewBody>(_ viewType: Any.Type, body: () -> ViewBody) -> ViewBody {
#if FEAT_MONITOR
    if let auditor = AnyRuleContext.current.attribute.auditor {
        return auditor.traceBodyAccess(viewType) {
            Signpost.bodyInvoke.traceInterval(
                "%{public}@.body [in %{public}@]",
                [_typeName(viewType, qualified: false),
                 Tracing.libraryName(defining: viewType)]
            ) {
                body()
            }
        }
    }
#endif
#if (DANCE_UI_INHOUSE || DEBUG) && FEAT_VIEW_INFO_TRACE
    let bodyAccessSeed = globalBodyAccessSeed
    let bodyAccessorAttribute = AnyRuleContext.current.attribute
    for eachDirtifyAction in bodyAccessorAttribute.dirtifyActions {
        if let eachDirtifyActionAttribute = eachDirtifyAction.attribute {
            Signpost.viewInfoTrace.traceEvent(
                "%{public}@.body [in %{public}@]; view-attribute = %{public}d; source-attribute = %{public}d; dirtify-action-kind = %{public}d; dirtify-action-seed = %{public}d; body-accessing-seed = %{public}d",
                [
                    _typeName(viewType, qualified: true),
                    Tracing.libraryName(defining: viewType),
                    bodyAccessorAttribute.rawValue,
                    eachDirtifyActionAttribute.rawValue,
                    eachDirtifyAction.kind.rawValue,
                    eachDirtifyAction.seed.rawValue,
                    bodyAccessSeed
                ])
        }
    }
    return Signpost.viewInfoTrace.traceInterval(
        "%{public}@.body [in %{public}@]; body-accessing-seed = %{public}d",
        [
            _typeName(viewType, qualified: true),
            Tracing.libraryName(defining: viewType),
            bodyAccessSeed,
        ]
    ) {
        Signpost.bodyInvoke.traceInterval(
            "%{public}@.body [in %{public}@]",
            [
                _typeName(viewType, qualified: true),
                Tracing.libraryName(defining: viewType)
            ]
        ) {
            body()
        }
    }
#else
    return Signpost.bodyInvoke.traceInterval(
        "%{public}@.body [in %{public}@]",
        [
            _typeName(viewType, qualified: true),
            Tracing.libraryName(defining: viewType),
        ]
    ) {
        body()
    }
#endif
}


@available(iOS 13.0, *)
enum Tracing {
    
#if DANCE_UI_INHOUSE || DEBUG
    internal static func libraryName(defining type: Any.Type) -> String {
        var info = Dl_info()
        
        guard let nominalDescriptor = DGTypeID(type).nominalDescriptor else {
            return "Unknown Module"
        }
        
        if let cachedName = moduleLookupCache[nominalDescriptor] {
            return cachedName
        }
        
        guard dladdr(nominalDescriptor, &info) != 0 else {
            return "Unknown Module"
        }
        
        let name = (String(cString: info.dli_fname) as NSString).lastPathComponent
        
        moduleLookupCache[nominalDescriptor] = name
        
        return name
    }
    
    @ThreadSpecific([:])
    private static var moduleLookupCache: [UnsafeRawPointer : String]
    
#else
    @inlinable
    internal static func libraryName(defining type: Any.Type) -> String {
        ""
    }
#endif
    
}

#if DEBUG

@_spi(DanceUICompose)
public struct SignpostManager {
    
    private static var bodyInvokeCache = [String:Int]()
    
    @_spi(DanceUICompose)
    public static func update(_ name: String, type: String) {
        
        if name == "BodyInvoke" {
            bodyInvokeCache[type] = (bodyInvokeCache[type] ?? 0) + 1
        }
    }
    
    internal static func clear(_ name: String) {
        if name == "BodyInvoke" {
            bodyInvokeCache = [:]
        }
    }
    
    
    internal static func bodyInvoke(_ type: String) -> Int {
        bodyInvokeCache[type] ?? 0
    }
    
    internal static func bodyInvoke(_ typeFilter: (String) -> Bool) -> [(String, Int)] {
        bodyInvokeCache.filter { key, value in
            typeFilter(key)
        }
    }
}

#endif

extension StaticString {
    var stringValue: String {
        self.withUTF8Buffer { buffer in
            String(decoding: buffer, as: UTF8.self)
        }
    }
}

#if DANCE_UI_INHOUSE || DEBUG

@available(iOS 13, *)
private struct SignpostLevelKey: EnvKey {
    
    fileprivate static var defaultValue: Signpost.Stability {
        .disabled
    }
    
    fileprivate static func makeValue(rawValue: String) -> Signpost.Stability {
        let rawInt = UInt8(rawValue) ?? 0
        return Signpost.Stability(rawValue: rawInt) ?? .disabled
    }
    
    internal static var raw: String {
        "DANCEUI_SIGNPOST_LEVEL"
    }
    
}


@available(iOS 13, *)
extension EnvValue where K == SignpostLevelKey {
    
    fileprivate static let singleton: Self = .init()
    
    @inline(__always)
    fileprivate static var signpostLevel: Signpost.Stability {
        singleton.value
    }
    
}

#endif
