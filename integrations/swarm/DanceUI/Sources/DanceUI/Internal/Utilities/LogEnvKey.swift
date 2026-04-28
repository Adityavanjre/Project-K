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

// MARK: - BoolEnvKey

/// Convenient encapsulation for environment variable keys by log.
@available(iOS 13.0, *)
internal protocol LogEnvKey: EnvKey where Value == LogEnvValue {

}

@available(iOS 13.0, *)
extension LogEnvKey {

    @inlinable
    internal static func makeValue(rawValue: String) -> LogEnvValue {
        LogEnvValue(rawValue: Int(rawValue) ?? 0) ?? .none
    }
}

@available(iOS 13.0, *)
internal enum LogEnvValue: Int {
    case none = 0
    case focus      // LogLevel >= .info, i.e. [.info, .warning, .error, .critical]
    case all
}
