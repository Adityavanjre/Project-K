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

import OSLog

@available(iOS 13.0, *)
internal struct OSLogHandler: LogHandler {
    
    internal let log: OSLog
    internal let label:String
    
    internal init(label: String) {
        self.log = .init(subsystem: "DanceUI", category: label)
        self.label = label
    }

    @inlinable
    internal func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        os_log("%{public}s \n%{public}s \n%{public}s", log: log, type: level.type, message.description, metadata?.prettifyMessage ?? "", source(file: file, function: function, line: line))
    }
    
    private func source(file: String, function: String, line: UInt) -> String {
        let fileName = file.split(separator: "/").last ?? ""
        return ".../\(fileName)[\(function)]:\(line)"
    }
    
    @inlinable
    internal subscript(metadataKey _: String) -> Logger.Metadata.Value? {
        get {
            return nil
        }
        set {}
    }

    @inlinable
    internal var metadata: Logger.Metadata {
        get {
            return [:]
        }
        set {}
    }

    @inlinable
    internal var logLevel: Logger.Level {
        get {
#if DANCE_UI_INHOUSE
            return .debug
#elseif DEBUG
            return .trace
#else
            return .error
#endif
        }
        set {}
    }
    
    internal static func standardLog(label: String) -> OSLogHandler {
        return OSLogHandler(label: label)
    }
}

@available(iOS 13.0, *)
extension Logger.Metadata {
    
    internal var prettifyMessage: String {
        !isEmpty ? self.lazy.map { "\($0) = \($1)" }.sorted().joined(separator: " \n") : ""
    }
}

@available(iOS 13.0, *)
extension Logger.Level {
    internal var type: OSLogType {
        switch self {
        case .trace:
            return .default
        case .info:
            return .info
        case .debug, .notice:
            return .debug
        case .error, .warning:
            return .error
        case .critical:
            return .fault
        }
    }
}
