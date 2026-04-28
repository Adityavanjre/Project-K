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
internal final class EnvProvider: FeaturesProvider {
    
    internal var isFrozen: Bool {
        true
    }
    
    internal func value<K>(for key: K.Type) -> K.Value? where K : SettingsKey {
        EnvValue<Feature<K>>().value
    }
    
    private struct Feature<K: SettingsKey>: EnvKey {
        
        internal static func makeValue(rawValue: String) -> K.Value? {
            guard let convertibleType = K.Value.self as? LosslessStringConvertible.Type else {
                return nil
            }
            if convertibleType is Bool.Type {
                return (Bool(rawValue.lowercased()) ?? (Int(rawValue) != 0)) as? K.Value
            }
            return convertibleType.init(rawValue) as? K.Value
        }
        
        internal static var raw: String {
            K.key
        }
        
        internal static var defaultValue: K.Value? {
            nil
        }
    }
}

#endif
