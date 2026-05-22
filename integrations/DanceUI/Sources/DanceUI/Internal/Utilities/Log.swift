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

@available(iOS 13.0, *)
public enum RuntimeIssueType: UInt8 {
    
    /// Informations like performance hint.
    case info
    
    /// Events that would not cause disasters.
    case warning
    
    /// Events that would cause disasters like crash.
    case error
    
#if DEBUG || DANCE_UI_INHOUSE
    @inline(__always)
    fileprivate var shouldTreatAsException: Bool {
        switch self {
        case .error:
            return EnvValue.treatsRuntimeErrorAsException
        case .warning:
            return EnvValue.treatsRuntimeWarningAsException
        default:
            return false
        }
    }
    
    @inline(__always)
    fileprivate var treatAsExceptionEnvironmentVariableName: String? {
        switch self {
        case .error:
            return TreatsRuntimeErrorAsException.raw
        case .warning:
            return TreatsRuntimeWarningAsException.raw
        default:
            return nil
        }
    }
#endif
    
}

/// Call this wrapper directly inside each public api.
/// Save pc before check and reset pc after check
@usableFromInline
@available(iOS 13.0, *)
internal func runtimeIssue(type: RuntimeIssueType, _ warningFormat: StaticString, _ arguments: CVarArg...) {
#if DEBUG || DANCE_UI_INHOUSE
    if type.shouldTreatAsException {
        var message = String(format: warningFormat.stringValue, arguments: arguments)
        if let environmentVariableName = type.treatAsExceptionEnvironmentVariableName {
            message += " Set environment variable \(environmentVariableName) to 0, FLASE, False or false to silent this issue."
        }
        _danceuiPreconditionFailure(message)
    } else {
        // @_transparent inlines the function call and causes Xcode's stack trace for the
        // runtime issue to show only the callee for the stack frames above the call to
        // raise (e.g. withVaList, the closures in the body of raise, etc.)
        _setThreadLogCallerAddress(__DanceUIGraphGetCallerAddress(["DanceUI", "DanceUIExtention"]))
        RuntimeIssueLogger.default.raise(warningFormat, arguments)
    }
#endif
}

@_spi(DanceUIExtension)
@_spi(DanceUICompose)
@available(iOS 13.0, *)
public func _danceuiRuntimeIssue(type: RuntimeIssueType, _ warningFormat: StaticString, _ arguments: CVarArg...) {
    runtimeIssue(type: type, warningFormat, arguments)
}

#if DEBUG || DANCE_UI_INHOUSE

internal import os.log
internal import _SwiftOSOverlayShims
import MyShims

@available(iOS 13.0, *)
private let systemFrameworkHandle: UnsafeRawPointer? = {
    for i in 0..<_dyld_image_count() {
        guard let name = _dyld_get_image_name(i).flatMap(String.init(utf8String:)), name.hasSuffix("/Foundation") else {
            continue
        }
        return UnsafeRawPointer(_dyld_get_image_header(i))
    }
    return nil
}()

#if DEBUG
public var testableEliminatesDuplicateRuntimeIssue: Bool = false
#endif

@available(iOS 13.0, *)
private final class RuntimeIssueLogger {
    
    /// Returns the shared default runtime issue logger with a generic category.
    fileprivate static let `default` = RuntimeIssueLogger()
    
    private var issuedAddressList: Set<UnsafeRawPointer> = []
    
    private var errorString = ""
    
    private let log: OSLog = OSLog(subsystem: "com.apple.runtime-issues", category: "DanceUI")
    
    /// Log a runtime issue to the console.
    ///
    /// When executed while attached to Xcode's debugger, this will have the additional effect
    /// of highlighting the issue and providing heads-up information regarding the issue.
    @inline(__always)
    fileprivate func raise(_ warningFormat: StaticString, _ arguments: CVarArg...) {
        // @_transparent inlines the function call and causes Xcode's stack trace for the
        // runtime issue to show only the callee for the stack frames above the call to
        // raise (e.g. withVaList, the closures in the body of raise, etc.)
        warningFormat.withUTF8Buffer {
            self.errorString = String(format: String(decoding: $0, as: UTF8.self), arguments)
        }
        withVaList(arguments) {
            raise(warningFormat, vaList: $0)
        }
    }
    
    private func shouldRaise(for address: UnsafeRawPointer) -> Bool {
#if DEBUG
        // Test cases run in debug mode.
        // This prevents runtime issues from random ghosting in some test
        // cases.
        if testableEliminatesDuplicateRuntimeIssue {
            return !issuedAddressList.contains(address)
        }
        return true
#elseif DANCE_UI_INHOUSE
        return !issuedAddressList.contains(address)
#else
        return false
#endif
    }
    
    /// Log a runtime issue to the console.
    ///
    /// When executed while attached to Xcode's debugger, this will have the additional effect
    /// of highlighting the issue and providing heads-up information regarding the issue.
    fileprivate func raise(_ warningFormat: StaticString, vaList: CVaListPointer) {
        
        guard let handle = systemFrameworkHandle,
              let ra = _threadLogCallerAddress(),
              shouldRaise(for: ra) else {
            return
        }
        
        warningFormat.withUTF8Buffer { buffer in
            guard let base = buffer.baseAddress else {
                return
            }
            
            base.withMemoryRebound(to: CChar.self, capacity: buffer.count) { cString in
                // Xcode reveals generic runtime issues which match the following criteria:
                //
                // 1. the dso is a system framework
                // 2. the subsystem is "com.apple.runtime-issues"
                // 3. the level is a fault
                //
                // Hijacking the handle for a system framework doesn't appear to have any negative side-effects.
                // Given that this is for interfacing with Xcode to bring to attention a category of failures
                // which are specifically to be fixed during the development/debugging cycle, this is _probably_ ok.
                logger.error(Logger.Message(stringLiteral: errorString))
                _swift_os_log(handle, ra, log, .fault, cString, vaList)
                issuedAddressList.insert(ra)
            }
        }
    }
}

@_silgen_name("_DanceUISetThreadLogAddress")
@inline(__always)
@available(iOS 13.0, *)
internal func _setThreadLogCallerAddress(_: UnsafeRawPointer?)

@_silgen_name("_DanceUIThreadLogAddress")
@inline(__always)
@available(iOS 13.0, *)
internal func _threadLogCallerAddress() -> UnsafeRawPointer?

@available(iOS 13.0, *)
struct TreatsRuntimeErrorAsException: DefaultTrueBoolEnvKey {
    
    static var raw: String {
        "DANCEUI_RUNTIME_ERROR_AS_EXCEPTION"
    }
    
}

@available(iOS 13.0, *)
extension EnvValue where K == TreatsRuntimeErrorAsException {
    
    private static let store: Self = .init()
    
    internal static var treatsRuntimeErrorAsException: Bool {
        store.value
    }
    
}

@available(iOS 13.0, *)
public func testableSetMockupTreatsRuntimeErrorAsException(_ flag: Bool) {
#if DEBUG
    EnvMock.shared.setValue(flag, for: TreatsRuntimeErrorAsException.self)
#endif
}

@available(iOS 13.0, *)
public func testableEnableMockupForTreatsRuntimeErrorAsException() {
#if DEBUG
    EnvMock.shared.enableMock(TreatsRuntimeErrorAsException.self)
#endif
}

@available(iOS 13.0, *)
public func testableDisableMockupForTreatsRuntimeErrorAsException() {
#if DEBUG
    EnvMock.shared.disableMock(TreatsRuntimeErrorAsException.self)
#endif
}

@available(iOS 13.0, *)
struct TreatsRuntimeWarningAsException: DefaultFalseBoolEnvKey {
    
    static var raw: String {
        "DANCEUI_RUNTIME_WARNING_AS_EXCEPTION"
    }
    
}

@available(iOS 13.0, *)
extension EnvValue where K == TreatsRuntimeWarningAsException {
    
    private static let store: Self = .init()
    
    internal static var treatsRuntimeWarningAsException: Bool {
        store.value
    }
    
}

#endif // DEBUG || DANCE_UI_INHOUSE
