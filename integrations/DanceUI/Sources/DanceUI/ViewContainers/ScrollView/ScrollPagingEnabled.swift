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
extension View {
    
    public func scrollPagingEnabled(_ enabled: Bool?) -> some View {
        environment(\.scrollPagingEnabled, enabled)
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    internal var scrollPagingEnabled: Bool? {
        get {
            self[IsPagingEnabledKey.self]
        }
        set {
            self[IsPagingEnabledKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct IsPagingEnabledKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool?
    
    fileprivate static var defaultValue: Value { nil }
    
}
