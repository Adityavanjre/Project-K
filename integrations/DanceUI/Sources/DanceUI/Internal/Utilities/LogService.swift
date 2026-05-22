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
extension LogService {
    @_spi(DanceUICompose)
    public static func log<K: LogKeyword>(level: Logger.Level,
                                            module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> String,
                                            info: [String: Any] = [:],
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        guard module.isEnable(level) else {
            return
        }
        let general = LogInfo<K>.GeneralInfo(file: file, function: function, line: line)
        let logInfo = LogInfo(general: general, keyword: keyword, message: message(), info: info)
        module.log(level: level, logInfo)
    }
    
    internal static func log<K: LogKeyword>(level: Logger.Level,
                                            module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            info: @autoclosure () -> [String: Any] = [:],
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .debug, module: module, keyword: keyword, message().stringValue, info: info(), file: file, function: function, line: line)
    }
    
    @inline(__always)
    @_disfavoredOverload
    @_spi(DanceUIExtension)
    public static func debug<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            info: @autoclosure () -> [String: Any] = [:],
                                            file: String = #file, function: String = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        log(level: .debug, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
#endif
    }
    
    @inline(__always)
    @_spi(DanceUIExtension)
    public static func debug<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            @DictionaryBuilder<String, Any> info: () -> [String: Any] = { [:] },
                                            file: String = #file, function: String = #function, line: UInt = #line) {
#if DEBUG || DANCE_UI_INHOUSE
        log(level: .debug, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
#endif
    }
    
    @inline(__always)
    @_disfavoredOverload
    @_spi(DanceUIExtension)
    public static func info<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            info: @autoclosure () -> [String: Any] = [:],
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .info, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
    }
    
    @inline(__always)
    @_spi(DanceUIExtension)
    public static func info<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            @DictionaryBuilder<String, Any> info: () -> [String: Any] = { [:] },
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .info, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
    }
    
    @inline(__always)
    @_disfavoredOverload
    @_spi(DanceUIExtension)
    public static func warning<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            info: @autoclosure () -> [String: Any] = [:],
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .warning, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
    }
    
    @inline(__always)
    @_spi(DanceUIExtension)
    public static func warning<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            @DictionaryBuilder<String, Any> info: () -> [String: Any] = { [:] },
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .warning, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
    }
    
    @inline(__always)
    @_disfavoredOverload
    @_spi(DanceUIExtension)
    public static func error<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            info: @autoclosure () -> [String: Any] = [:],
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .error, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
    }
    
    @inline(__always)
    @_spi(DanceUIExtension)
    public static func error<K: LogKeyword>(module: Module<K>,
                                            keyword: K,
                                            _ message: @autoclosure () -> StaticString,
                                            @DictionaryBuilder<String, Any> info: () -> [String: Any] = { [:] },
                                            file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .error, module: module, keyword: keyword, message(), info: info(), file: file, function: function, line: line)
    }
}
