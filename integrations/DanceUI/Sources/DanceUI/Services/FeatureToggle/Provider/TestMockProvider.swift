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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
internal final class TestMockProvider: FeaturesProvider {
    
    internal let isFrozen: Bool = false
            
    internal func value<K>(for key: K.Type) -> K.Value? where K : SettingsKey {
        FeatureMock.mockValue(for: key)
    }
}

@available(iOS 13.0, *)
internal final class FeatureMock {
        
    private var mockValues: [String: Any] = [:]
    
    private var lock = Lock()
    
    private func mock<K: SettingsKey>(_ key: K.Type, value: K.Value) {
        lock.withLockVoid {
            mockValues[K.key] = value
        }
    }
    
    private func mockValue<K: SettingsKey>(for key: K.Type) -> K.Value? {
        lock.withLock {
            mockValues[K.key] as? K.Value
        }
    }
    
    private func reset<K: SettingsKey>(for key: K.Type) {
        lock.withLockVoid {
            mockValues[K.key] = nil
        }
    }
    
    private func resetAll() {
        lock.withLockVoid {
            mockValues = [:]
        }
    }
}

@available(iOS 13.0, *)
extension FeatureMock {
    
    internal static let shared = FeatureMock()

    @inline(__always)
    internal static func mock<K: SettingsKey>(_ key: K.Type, value: K.Value) {
        shared.mock(key, value: value)
    }
    
    @inline(__always)
    internal static func mockValue<K: SettingsKey>(for key: K.Type) -> K.Value? {
        shared.mockValue(for: key)
    }
    
    @inline(__always)
    internal static func reset<K: SettingsKey>(for key: K.Type) {
        shared.reset(for: key)
    }
    
    @inline(__always)
    internal static func resetAll() {
        shared.resetAll()
    }
}

#endif
