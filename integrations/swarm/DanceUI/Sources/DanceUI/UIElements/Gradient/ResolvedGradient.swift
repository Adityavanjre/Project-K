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

import CoreFoundation
import CoreGraphics
import MyShims

@available(iOS 13.0, *)
internal struct ResolvedGradient: Equatable {
    
    internal var stops: [Stop]
    
    internal var colorSpace: ColorSpace
    
    internal var usePerceptualBlending = true
    
    internal struct Stop: Equatable {
        
        internal var color: Color.Resolved
        
        internal var location: CGFloat
    }
    
    internal var constantColor: Color.Resolved? {
        
        guard stops.count > 0 else {
            return .init()
        }
        
        let firstColor = stops.first?.color
        
        if stops.count == 1 {
            return firstColor
        }
        
        let otherColor = stops.first { colorStop in
            colorStop.color != firstColor
        }
        
        if otherColor != nil {
            return nil
        }
        
        return firstColor
    }
    
    internal var cgGradient: CGGradient? {
        
        let colorSpace = Color.Resolved.colorSpace
        
        guard self.stops.count > 0 else {
            return .init(colorsSpace: colorSpace, colors: [] as CFArray, locations: [])
        }
        
        var colors: [CGColor] = []
        
        var locations: [CGFloat] = []
        
        self.stops.forEach { colorStop in
            let cgColor = colorStop.color.cgColor
            colors.append(cgColor)
            locations.append(colorStop.location)
        }
        
        return .init(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
    }
    
    internal init(stops: [Stop], colorSpace: ColorSpace, usePerceptualBlending: Bool = true) {
        self.stops = stops
        self.colorSpace = colorSpace
        self.usePerceptualBlending = usePerceptualBlending
    }
    
    internal enum ColorSpace: Hashable, Codable {
        
        case device

        case linear

        case perceptual
        
        internal var cgColorSpace: CGColorSpace {
            switch self {
            case .device:
                MyColorSpaceSRGBExtended().takeUnretainedValue() // BDCOV_EXCL_LINE
            case .linear:
                MyColorSpaceSRGBExtendedLinear().takeUnretainedValue() // BDCOV_EXCL_LINE
            case .perceptual:
                MyColorSpaceGetPerceptual().takeUnretainedValue()
            }
        }
    }
}
