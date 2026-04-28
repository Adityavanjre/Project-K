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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct EnvironmentReadingChild<ViewType: EnvironmentalView>: StatefulRule {
    
    internal typealias Value = ViewType.EnvironmentBody
    

    @Attribute
    internal var view: ViewType
    
    @Attribute
    internal var env: EnvironmentValues
    
    internal let tracker: PropertyList.Tracker = .init()
    
    internal mutating func updateValue() {
        let view = $view.changedValue()
        let (environment, isEnvironmentChanged) = $env.changedValue()
        guard view.changed || (isEnvironmentChanged && environment.hasDifferentUsedValues(with: tracker)) || !hasValue else {
            return
        }
        let trackedEnvironment = environment.withTracker(tracker)
        
        value = view.value.body(environment: trackedEnvironment)
    }
}
