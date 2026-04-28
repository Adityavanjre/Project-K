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
internal struct AccessibilityDataSeriesConfiguration {

    internal var name: Text

    internal var type: AccessibilityDataSeriesConfiguration.DataSeriesType

    internal var supportsSonification: Bool

    internal var sonificationDuration: Double?

    internal var includesTrendlineInSonification: Bool

    internal var supportsSummarization: Bool
    
    internal var xAxisConfiguration: AxisConfiguration?

    internal var yAxisConfiguration: AxisConfiguration?
    
    internal struct ValueDescription {

        internal var description: Text

        internal var effectiveValueRange: Range<Double>

    }
    
    internal enum DataSeriesType {

        case scatter

        case line

        case bar

    }
    
    internal struct AxisConfiguration {

        internal var title: ResolvedStyledText?

        internal var unitLabel: ResolvedStyledText?

        internal var categoryLabels: [ResolvedStyledText]

        internal var minimumValue: Double?

        internal var maximumValue: Double?

        internal var gridlinePositions: [Double]

        internal var values: [Double]

        internal var valueDescriptions: [CodableAccessibilityDataSeriesConfiguration.ValueDescription]

    }

}

@available(iOS 13.0, *)
internal struct CodableAccessibilityDataSeriesConfiguration {

    internal var name: ResolvedStyledText

    internal var type: AccessibilityDataSeriesConfiguration.DataSeriesType

    internal var supportsSonification: Bool

    internal var sonificationDuration: Double?

    internal var includesTrendlineInSonification: Bool

    internal var supportsSummarization: Bool

    internal var xAxisConfiguration: AxisConfiguration?

    internal var yAxisConfiguration: AxisConfiguration?
    
    internal struct AxisConfiguration {

        internal var title: ResolvedStyledText?

        internal var unitLabel: ResolvedStyledText?

        internal var categoryLabels: [ResolvedStyledText]

        internal var minimumValue: Double?

        internal var maximumValue: Double?

        internal var gridlinePositions: [Double]

        internal var values: [Double]

        internal var valueDescriptions: [ValueDescription]

    }
    
    internal struct ValueDescription {

        internal var description: ResolvedStyledText

        internal var effectiveValueRange: Range<Double>

    }

}
