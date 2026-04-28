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
internal protocol HostAppInfoProvider {
    
    var appID: String? { get }
    
    var channel: String? { get }
    
    /// Currently not available.
    var deviceID: String? { get }
}

@available(iOS 13.0, *)
public struct HostAppInfo: HostAppInfoProvider, ServiceRegister {
    
    @_silgen_name("DanceUIExtension.InternalServices.StandardHostAppInfo")
    public static func register() {
        Resolver.services.register {
            HostAppInfo() as HostAppInfoProvider
        }.scope(.application)
    }
    
    internal let appID: String?
    
    internal let channel: String?
    
    internal let deviceID: String?
    
    internal init() {
        let infoDictionary = Bundle.main.infoDictionary
        self.appID = infoDictionary?["SSAppID"] as? String
        self.channel = infoDictionary?["CHANNEL_NAME"] as? String
        self.deviceID = ""
    }
}
#endif
