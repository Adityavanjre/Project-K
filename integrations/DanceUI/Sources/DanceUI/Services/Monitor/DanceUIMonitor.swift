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

#if FEAT_MONITOR
import Foundation
internal import Resolver

@available(iOS 13.0, *)
internal protocol DanceUIMonitorConsumer {
    
    static func trackService(serviceName: String,
                             metric: [String: NSNumber],
                             category: [AnyHashable: Any],
                             extra: [AnyHashable: Any]?)
}

@available(iOS 13.0, *)
internal class DanceUIMonitor {
    
    private static var shared = DanceUIMonitor()
    
    private var lockPtr: UnsafeMutablePointer<os_unfair_lock_s>
    
    // only for test
    internal static func resetForTest() {
        self.shared = DanceUIMonitor()
    }
    
    private init() {
        self.lockPtr = .allocate(capacity: 1)
        self.lockPtr.initialize(to: os_unfair_lock_s())
        
        guard let settingsProvider = Resolver.services.optional(DanceUISettingsProvider.self) else {
            logger.warning("missing DanceUISettingsProvider")
            return
        }
        
        // DanceUI integrated as SDK, entry unified under sdk_key_danceui_sdk host config
        // Sampling rate config, key is monitor_samples
        // let danceuiConfigs = settingsProvider.dictionaryForKey("sdk_key_danceui_sdk")
        // guard let samplesData = danceuiConfigs["monitor_samples"],
        //       let samplesData = try? JSONSerialization.data(withJSONObject: samplesData, options: .prettyPrinted),
        //       let events = try? JSONDecoder().decode([HeimdallrDownSampleData].self, from: samplesData) else {
        //     logger.warning("Decode DanceUI Config failed. Configs: \(danceuiConfigs)")
        //     return
        // }
    }
    
    deinit {
        self.lockPtr.deallocate()
    }
    
    private var consumers: [DanceUIMonitorConsumer.Type] = [MonitorHeimdallrConsumer.self]
    
    internal func addConsumer(_ consumer: any DanceUIMonitorConsumer.Type) {
        os_unfair_lock_lock(lockPtr)
        defer {
            os_unfair_lock_unlock(lockPtr)
        }
        guard !self.consumers.contains(where: { $0 == consumer }) else {
            return
        }
        self.consumers.append(consumer)
    }
    
    internal static func addConsumer(_ consumer: any DanceUIMonitorConsumer.Type) {
        shared.addConsumer(consumer)
    }
    
    internal func trackService(serviceName: String,
                               metric: [String: NSNumber],
                               category: [AnyHashable: Any],
                               extra: [AnyHashable: Any]?) {
        os_unfair_lock_lock(lockPtr)
        defer {
            os_unfair_lock_unlock(lockPtr)
        }

        for consumer in consumers {
            consumer.trackService(serviceName: serviceName, metric: metric, category: category, extra: extra)
        }
    }
    
    internal static func trackService(serviceName: String,
                                      metric: [String: NSNumber],
                                      category: [AnyHashable: Any],
                                      extra: [AnyHashable: Any]?) {
        shared.trackService(serviceName: serviceName, metric: metric, category: category, extra: extra)
    }
    
}
#endif
