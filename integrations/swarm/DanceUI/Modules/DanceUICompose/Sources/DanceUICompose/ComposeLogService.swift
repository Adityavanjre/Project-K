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

@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
@_transparent
internal func composePrint(_ keyword: ComposeLogKeyword, message: @autoclosure () -> String) {
#if DEBUG
    ComposeLogServiceImpl.sharedInstance.log(with: .debug, keyword: keyword, message: message(), info: [:])
#endif
}

@available(iOS 13.0, *)
internal final class ComposeLogServiceImpl: NSObject, ComposeLogService {
    
    public static let sharedInstance = ComposeLogServiceImpl()
    
    internal func log(with priority: ComposeLogPriority, keyword: ComposeLogKeyword, message: String, info: [String : Any]) {
        LogService.log(level: priority.logLevel,
                       module: .compose,
                       keyword: .init(keyword: keyword),
                       message,
                       info: info)
    }
}

@available(iOS 13.0, *)
extension ComposeLogPriority {
    fileprivate var logLevel: Logger.Level {
        switch self {
        case .trace:
                .trace
        case .debug:
                .debug
        case .info:
                .info
        case .notice:
                .notice
        case .warning:
                .warning
        case .error:
                .error
        case .critical:
                .critical
        @unknown default:
                .debug
        }
    }
}

@available(iOS 13.0, *)
internal struct ComposeModuleLogKeyword: LogKeyword {
    
    var rawValue: String
    
    init(keyword: ComposeLogKeyword) {
        self.rawValue = keyword.rawValue as String
    }
    
    internal static var moduleName: String { "Compose" }
}

@available(iOS 13.0, *)
extension LogService.Module where K == ComposeModuleLogKeyword {
    internal static let compose: Self = .init()
}
