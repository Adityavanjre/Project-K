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
public import Resolver

@available(iOS 13.0, *)
public let AsyncImageIdentifier = "AsyncImage"
@available(iOS 13.0, *)
public let TrackerServiceIdentifier = "TrackerService"
@available(iOS 13.0, *)
private let internalServicesIdentifier = "InternalServices"
@available(iOS 13.0, *)
private let exposureServiceIdentifier = "ExposureService"
@available(iOS 13.0, *)
private let settingsServicesIdentifier = "SettingsService"
@available(iOS 13.0, *)
private let logServicesIdentifier = "LogExtensionService"
@available(iOS 13.0, *)
extension Resolver: ResolverRegistering {
    
    public static var extensionEnable = true
    
    public static func registerAllServices() {
        guard extensionEnable else {
            return
        }
        ExtensionFunction.start(key: AsyncImageIdentifier)
        ExtensionFunction.start(key: TrackerServiceIdentifier)
        ExtensionFunction.start(key: internalServicesIdentifier)
        ExtensionFunction.start(key: exposureServiceIdentifier)
        ExtensionFunction.start(key: settingsServicesIdentifier)
        ExtensionFunction.start(key: logServicesIdentifier)
    }
}

@available(iOS 13.0, *)
extension Resolver {
    public static var services: Resolver = servicesResolver()
    
    internal static func resetServices() {
        Resolver.reset()
        self.services = servicesResolver()
    }
}

@available(iOS 13.0, *)
fileprivate func servicesResolver() -> Resolver {
    let resolver = Resolver()
    Resolver.main.add(child: resolver)
    return resolver
}

@available(iOS 13.0, *)
public protocol ServiceRegister {
    
    static func register()
}
