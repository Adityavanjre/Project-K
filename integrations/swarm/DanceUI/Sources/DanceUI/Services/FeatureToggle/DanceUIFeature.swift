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

@available(iOS 13.0, *)
@objcMembers
public class DanceUIFeatureObjc: NSObject {
    public static func enabledUIHookFreeViewInitHook() -> Bool {
        DanceUIFeature.enabledUIHookFreeViewInitHook.isEnable
    }
}

@_spi(ExternalFeatures)
public var isDanceUIObservationEnabled: Bool {
    DanceUIFeature.observation.isEnable
}

@available(iOS 13.0, *)
internal struct DanceUIFeature<K: SettingsKey>: Feature where K.Value == Bool {
    
    internal static var isEnable: Bool {
        FeaturesManager[K.self]
    }
}


@available(iOS 13.0, *)
internal struct FeaturesManager {
    
    fileprivate let providers: [AnyFeaturesProviderBox]
    
    fileprivate subscript<K: SettingsKey>(key: K.Type) -> K.Value {
        for provider in providers {
            if let value = provider.value(for: key) {
                return value
            }
        }
        return key.defaultValue
    }
}

@available(iOS 13.0, *)
extension FeaturesManager {
#if DEBUG || DANCE_UI_INHOUSE
    private static let shared = FeatureBuilder()
        .append(TestMockProvider())
        .append(EnvProvider())
        .append(SettingsProvider())
        .build()
    #else
    private static let shared = FeatureBuilder().append(SettingsProvider()).build()

    #endif
    
    @inline(__always)
    internal static subscript<K: SettingsKey>(key: K.Type) -> K.Value {
        shared[key]
    }
}

@available(iOS 13.0, *)
private final class FeatureBuilder {
    
    private var providers = [AnyFeaturesProviderBox]()

    fileprivate func append<P: FeaturesProvider>(_ provider: P) -> FeatureBuilder {
        providers.append(AnyFeaturesProviderBox(provider))
        return self
    }

    fileprivate func build() -> FeaturesManager {
        return FeaturesManager(providers: providers)
    }
}

@available(iOS 13.0, *)
private final class AnyFeaturesProviderBox {
    
    private let provider: FeaturesProvider
    
    private var cache: [String: Any] = [:]
    
    private let lock = Lock(.init(PTHREAD_MUTEX_RECURSIVE))
    
    fileprivate init<F: FeaturesProvider>(_ provider: F) {
        self.provider = provider
    }
    
    fileprivate func value<K: SettingsKey>(for key: K.Type) -> K.Value? {
        guard provider.isFrozen else {
            return provider.value(for: key)
        }
        
        return lock.withLock {
            if let value = cache[K.key] as? K.Value {
                return value
            }
            let providerValue: K.Value? = provider.value(for: key)
            providerValue.map { value in
                cache[K.key] = value
            }
            
            return providerValue
        }
    }
    
}
