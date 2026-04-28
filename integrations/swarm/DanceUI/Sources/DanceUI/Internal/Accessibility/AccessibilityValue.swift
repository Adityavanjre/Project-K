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
internal struct AccessibilityValue: Equatable {
    
    private var value: ValueType?

    internal var description: Text?
    
    internal init (description: Text) {
        self.value = nil
        self.description = description
    }
    
    private init (value: ValueType?, description: Text?) {
        self.value = value
        self.description = description
    }
    
    internal init(_ value: AccessibilityAdjustableNumericValue?) {
        self.value = value.map { .adjustableNumeric($0) }
        self.description = nil
    }
    
    internal init(_ value: Double?, description: Text?) {
        self.value = value.map {
            .percentage(Percentage(value: max(min($0, 1.0), 0.0), minValue: 0.0, maxValue: 1.0))
        }
        self.description = description
    }
    
    internal static func combine(_ lhs: AccessibilityValue, with rhs: AccessibilityValue) -> AccessibilityValue {
        assert(lhs.value == nil && rhs.value == nil)
        return AccessibilityValue(value: nil, description: lhs.description ?? rhs.description)
    }
    
    internal var numberValue: NSNumber? {
        switch value {
        case .none:
            return nil
        case .int(let int):
            return int as NSNumber
        case .toggleState(let state):
            switch state {
            case .on:
                return 1
            case .off:
                return 0
            case .mixed:
                return nil
            }
        case .percentage(let percentage):
            return percentage.value as NSNumber
        case .adjustableNumeric(let accessibilityAdjustableNumericValue):
            return accessibilityAdjustableNumericValue.value as NSNumber
        case .disclosure:
            return nil
        }
    }
    
    internal var platformMaxValue: NSNumber? {
        switch value {
        case .none, .int, .toggleState, .disclosure:
            return nil
        case .percentage(let percentage):
            return percentage.maxValue as NSNumber
        case .adjustableNumeric(let accessibilityAdjustableNumericValue):
            guard let maxValue = accessibilityAdjustableNumericValue.maxValue else {
                return nil
            }
            return maxValue as NSNumber
        }
    }
    
    internal var platformMinValue: NSNumber? {
        switch value {
        case .none, .int, .toggleState, .disclosure:
            return nil
        case .percentage(let percentage):
            return percentage.minValue as NSNumber
        case .adjustableNumeric(let accessibilityAdjustableNumericValue):
            guard let minValue = accessibilityAdjustableNumericValue.minValue else {
                return nil
            }
            return minValue as NSNumber
        }
    }
    
    internal var platformValue: String? {
        guard let value = value else {
            return nil
        }
        switch value {
        case .int(let value):
            return NumberFormatter.localizedString(from: value as NSNumber, number: .none)
        case .toggleState(let toggleState):
            return toggleState == .on ? "1" : "0"
        case .percentage(let percentage):
            return NumberFormatter.localizedString(from: percentage.value as NSNumber, number: .percent)
        case .adjustableNumeric(let accessibilityAdjustableNumericValue):
            return NumberFormatter.localizedString(from: accessibilityAdjustableNumericValue.value as NSNumber, number: .decimal)
        case .disclosure:
            return nil
        }
    }
    
    private enum ValueType: Equatable {

        case int(Int)

        case toggleState(ToggleState)

        case percentage(Percentage)

        case adjustableNumeric(AccessibilityAdjustableNumericValue)

        case disclosure(DisclosureState)

    }
    
    internal struct Percentage: Equatable {
        
        internal var value: Double

        internal let minValue: Double

        internal let maxValue: Double

    }

    internal enum DisclosureState: Hashable {

        case undisclosed

        case disclosed

    }
    
}
