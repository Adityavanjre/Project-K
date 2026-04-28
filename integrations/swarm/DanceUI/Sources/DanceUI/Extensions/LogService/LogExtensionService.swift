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
@_spi(DanceUIExtension)
public protocol LogExtensionService {
    
    func log(level: LogExtension.Level, module: String, message: String, file: String, function: String, line: UInt)
}

@available(iOS 13.0, *)
@_spi(DanceUIExtension)
public enum LogExtension {
    
    public enum Level {
        
        case debug

        case info

        case warning

        case error
    }
}

@available(iOS 13.0, *)
extension Logger.Level {
    internal var extendLevel: LogExtension.Level {
        switch self {
        case .trace, .debug:
            return .debug
        case .info, .notice:
            return .info
        case .warning:
            return .warning
        case .error, .critical:
            return .error
        }
    }
}

@available(iOS 13.0, *)
internal struct ExtendedLogHandler: LogHandler {
    
    internal let label: String
    
    internal let extensionLog: LogExtensionService?
    
    internal func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let output = "\(message)\n\(metadata?.prettifyMessage ?? "")"
        extensionLog?.log(level: level.extendLevel, module: label, message: output, file: file, function: function, line: line)
    }
    
    internal subscript(metadataKey _: String) -> Logger.Metadata.Value? {
        get { nil }
        set { }
    }
    
    internal var metadata: Logger.Metadata = [:]
    
    internal var logLevel: Logger.Level = .debug
}
