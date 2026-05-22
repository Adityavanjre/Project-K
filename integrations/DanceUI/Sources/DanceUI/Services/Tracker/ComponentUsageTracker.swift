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
internal import Resolver

@_spi(DanceUI)
public final class ComponentUsageTracker {
    /// Component name
    private let componentName: String
    private let params: [String: String]?
    private let tag: String?
    
    /// Record if already reported, prevent duplicate reports
    private var hasReported: Bool = false
    private let samplingRate: Double
    private let traceEnable: Bool
    
    public init(componentName: String, tag: String? = nil, params: [String: String]? = nil) {
        self.componentName = componentName
        self.tag = tag
        self.params = params
        
        guard DanceUIFeature.componentUsageTraceEnable.isEnable,
              let settingService = Resolver.services.optional(SettingsService.self) else {
            self.samplingRate = 0
            self.traceEnable = false
            return
        }
        
        let samplingRate = settingService.value(key: ComponentUsageTraceSampleRateKey.self)[componentName]
        self.traceEnable = samplingRate != nil
        self.samplingRate = samplingRate ?? 0
    }
    
    /// When exposure timing is reached, trigger tracking report via this method
    public func launch(params: [String: String]? = nil) {
        // Check if should report
        guard traceEnable,
              !hasReported else {
            return
        }
        
        // Ensure execution on main thread
        if Thread.isMainThread {
            performLaunch(params: params)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performLaunch(params: params)
            }
        }
    }
    
    /// Private method for execute report logic
    private func performLaunch(params: [String: String]? = nil) {
        // Check if should report
        guard shouldReport() else {
            return
        }
        
        // Execute report logic
        var reportParams = [String: String]()
        if let params = self.params {
            reportParams.merge(params) { $1 }
        }
        
        if let params {
            reportParams.merge(params) { $1 }
        }
        
        reportParams["tag"] = tag
        reportParams["component"] = componentName
        
        if let topVC = Responder.topViewController() {
            reportParams["scene"] = _typeName(type(of: topVC))
        }
        
        let trackService: TrackerService? = Resolver.services.optional()
        trackService?.track("danceui_component_usage", params: reportParams)
        // 标记已上报
        hasReported = true
    }
    
    /// Check if should report (prevent duplicate reports + sampling rate check)
    private func shouldReport() -> Bool {
        // Duplicate report prevention check
        guard traceEnable,
              !hasReported else {
            return false
        }
        
        // Sampling rate check
        let randomValue = Double.random(in: 0.0...1.0)
        return randomValue <= samplingRate
    }
}


/// Startup tracking sampling rate
///
/// - owner: @chenjiesheng
/// - module: Foundation
@available(iOS 13.0, *)
private struct ComponentUsageTraceSampleRateKey: SettingsKey {
    
    internal static let key: String = "DanceUI_ComponentUsageTraceSampleRate"
    
    internal static var defaultValue: [String: Double] {
        ["DanceUI": 0.00001]
    }
}
