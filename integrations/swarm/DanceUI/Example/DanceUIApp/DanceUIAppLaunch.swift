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

import DanceUI
import Resolver
import MyShims

@available(iOS 13.0, *)
extension AppDelegate {

    internal func setup() {
        my_pre_main()
    }

    private func setupServices() {
        Resolver.services.register {
            DanceUITrackService() as DanceUI.TrackerService
        }.scope(.shared)
        Resolver.services.register {
            DanceUISettingsService() as DanceUI.SettingsService
        }.scope(.shared)
    }
}

public struct DanceUITrackService: TrackerService {
    public func track(_ event: String, params: [AnyHashable : Any]?) {
        print("[Track] event:\(event), params: \(String(describing: params))")
    }
}

public struct DanceUISettingsService: DanceUI.SettingsService {

    public init() { }

    public func value<Value>(key: String, defaultValue: Value) -> Value where Value : DanceUI.SettingsValue {
        return defaultValue
    }
}
