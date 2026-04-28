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
internal protocol EnvironmentConfigurableFormatter {
    
    func configure(in environment: EnvironmentValues) -> ()
}

@available(iOS 13.0, *)
extension DateFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.locale = environment.locale
        self.timeZone = environment.timeZone
        self.calendar = environment.calendar
    }
}

@available(iOS 13.0, *)
extension ISO8601DateFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.timeZone = environment.timeZone
    }
}

@available(iOS 13.0, *)
extension DateComponentsFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.calendar = environment.calendar
    }
}

@available(iOS 13.0, *)
extension DateIntervalFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.locale = environment.locale
        self.timeZone = environment.timeZone
        self.calendar = environment.calendar
    }
}

@available(iOS 13.0, *)
extension NumberFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.locale = environment.locale
    }
}

@available(iOS 13.0, *)
extension MassFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.numberFormatter.locale = environment.locale
    }
}

@available(iOS 13.0, *)
extension MeasurementFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.locale = environment.locale
        self.numberFormatter.locale = environment.locale
    }
}

@available(iOS 13.0, *)
extension LengthFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.numberFormatter.locale = environment.locale
    }
}

@available(iOS 13.0, *)
extension EnergyFormatter: EnvironmentConfigurableFormatter {
    
    internal func configure(in environment: EnvironmentValues) {
        self.numberFormatter.locale = environment.locale
    }
}
