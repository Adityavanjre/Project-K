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
internal import Resolver

/// Protocol defining keywords, restricted to enum usage
@_spi(DanceUIExtension)
@_spi(DanceUICompose)
public protocol LogKeyword {
    associatedtype Value = String
    var rawValue: Value { get }
    static var moduleName: String { get }
}

@_spi(DanceUIExtension)
@_spi(DanceUICompose)
@available(iOS 13.0, *)
public struct LogService {

    /// Log structure storage
    @available(iOS 13.0, *)
    internal struct LogInfo<K: LogKeyword> {
        internal let general: GeneralInfo
        internal let keyword: K
        internal let message: String
        internal let info: [String: Any]

        internal init(general: GeneralInfo, keyword: K, message: String, info: [String: Any]) {
            self.general = general
            self.keyword = keyword
            self.message = message
            self.info = info
        }

        internal var logMetadata: Logger.Metadata {
            info.mapValues { value in
                .string("\(value)")
            }
        }

        internal var logMessage: Logger.Message {
            "[\(keyword)] \(message)"
        }

        internal struct GeneralInfo {
            let file: String
            let function: String
            let line: UInt
        }
    }

    /// Log module definition
    @available(iOS 13.0, *)
    @_spi(DanceUICompose)
    public struct Module<K: LogKeyword> {

        public var rawValue: String

        internal var logger: Logger

        private let envValue: LogEnvValue = {
            EnvValue<Key>().value
        }()

        public init(_ factory: (String) -> LogHandler = LogService.logFactory) {
            self.rawValue = K.moduleName
            self.logger = Logger(label: K.moduleName, factory: factory)
        }

        internal func isEnable(_ level: Logger.Level) -> Bool {
#if DEBUG || DANCE_UI_INHOUSE
            switch (envValue, level) {
            case (.all, _), (.focus, .info), (.focus, .warning), (.focus, .error), (.focus, .critical):
                return true
            default:
                return false
            }
#else
            return true
#endif
        }

        internal func log(level: Logger.Level, _ logInfo: LogInfo<K>) {
            let general = logInfo.general
            logger.log(level: level, logInfo.logMessage, metadata: logInfo.logMetadata, file: general.file, function: general.function, line: general.line)
        }

        private struct Key: LogEnvKey {

            internal static var defaultValue: LogEnvValue {
                .none
            }

            internal static var raw: String {
                "DANCEUI_LOG_\(K.moduleName.uppercased())"
            }
        }
    }

    private static let structurePrintEnabled = EnvValue<LogStructurePrintKey>().value

    public static func logFactory(label: String) -> LogHandler {
#if DEBUG || DANCE_UI_INHOUSE
        if structurePrintEnabled {
            return OSLogHandler(label: label)
        }
        if let extensionLog = Resolver.services.optional(LogExtensionService.self) {
            return ExtendedLogHandler(label: label, extensionLog: extensionLog)
        }
        return OSLogHandler(label: label)
#else
        if let extensionLog = Resolver.services.optional(LogExtensionService.self) {
            return ExtendedLogHandler(label: label, extensionLog: extensionLog)
        }
        return SwiftLogNoOpLogHandler()
#endif
    }
}

@available(iOS 13.0, *)
internal struct LogStructurePrintKey: DefaultFalseBoolEnvKey {

    internal static let raw: String = "DANCEUI_LOG_STRUCTURE_PRINT"
}


