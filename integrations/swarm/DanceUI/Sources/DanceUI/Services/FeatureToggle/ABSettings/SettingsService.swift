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

internal import Resolver

// MARK: SettingsService

@available(iOS 13.0, *)
public protocol SettingsService {
        
    func value<Value: SettingsValue>(key: String, defaultValue: Value) -> Value
}

@available(iOS 13.0, *)
public protocol SettingsKey {
    
    associatedtype Value: SettingsValue
    
    static var key: String { get }
    
    static var defaultValue: Value { get }
}

// MARK: Impl

@available(iOS 13.0, *)
extension SettingsService {
    public static func settingDidChange() {
        NotificationCenter.default.post(name: ABSettingsService.didChangeNotification, object: nil)
    }
    
    public func value<K: SettingsKey>(key: K.Type) -> K.Value {
        value(key: K.key, defaultValue: K.defaultValue)
    }
}

@available(iOS 13.0, *)
internal enum ABSettingsService {
    
#if DANCE_UI_INHOUSE || DEBUG
    internal static var impl: SettingsService? {
        return Resolver.services.optional(SettingsService.self)
    }
#else
    internal static let impl = Resolver.services.optional(SettingsService.self)
#endif

    internal static let didChangeNotification: NSNotification.Name = .init(rawValue: "DanceUIABSettingsDidChanged")
}
