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
internal struct ConicGradient {
    
    internal var gradient: ResolvedGradient
    
    internal var center: CGPoint
    
    internal var angle: Angle
    
    internal init(paint: AngularGradient._Paint, bounds: CGRect) {
        
        var gradientValue = paint.gradient
        
        let colorCount = gradientValue.stops.count
        
        let boundsWidth = bounds.size.width
        
        let boundsHeight = bounds.size.height
        
        let boundsX = bounds.origin.x
        
        let boundsY = bounds.origin.y
        
        let minRadius = min(paint.startAngle.radians, paint.endAngle.radians)
        
        let maxRadius = max(paint.startAngle.radians, paint.endAngle.radians)
        
        let diffRadius = maxRadius - minRadius
        
        if diffRadius > 2 * Double.pi { // startRadius 与 endRadius 的差值大于 2π
            let fullTurnRadius = -2 * Double.pi
            let targetRadius = maxRadius + fullTurnRadius
            let diffRadiusDividedByFullTurn = diffRadius / fullTurnRadius + 1
            let oneRadius = 1.0
            var shouldAdjustLocations: Bool = false
            
            if paint.startAngle <= paint.endAngle {
                if abs(diffRadiusDividedByFullTurn) > 0.000001 {
                    shouldAdjustLocations = true
                }
            } else {
                shouldAdjustLocations = true
            }
            
            self.angle = .init(radians: targetRadius)
            
            if shouldAdjustLocations {
                if colorCount > 0 {
                    let locationFactor = oneRadius - diffRadiusDividedByFullTurn
                    var newColorStops: [ResolvedGradient.Stop] = []
                    
                    gradientValue.stops.forEach { element in
                        var elementCopy = element
                        let baseLocation = paint.startAngle > paint.endAngle ? (1 - element.location) : element.location
                        let newLocation = baseLocation * locationFactor + diffRadiusDividedByFullTurn
                        elementCopy.location = newLocation
                        newColorStops.append(elementCopy)
                    }
                    
                    gradientValue.stops = newColorStops
                }
            }
        } else { // startRadius 与 endRadius 的差值少于等于 2π
            let fullTurnSubDiffRadius = (2 * Double.pi - diffRadius) / 2
            let targetRadius = minRadius - fullTurnSubDiffRadius
            let lowValue = fullTurnSubDiffRadius / (2 * Double.pi)
            let highValue = (diffRadius + fullTurnSubDiffRadius) / (2 * Double.pi)
            var shouldAdjustLocations: Bool = false
            
            if paint.startAngle <= paint.endAngle {
                if abs(lowValue) > 0.000001 || abs(highValue - 1.0) > 0.000001 {
                    shouldAdjustLocations = true
                }
            } else {
                shouldAdjustLocations = true
            }
            
            self.angle = .init(radians: targetRadius)
            
            if shouldAdjustLocations {
                if colorCount > 0 {
                    let locationFactor = highValue - lowValue
                    var newColorStops: [ResolvedGradient.Stop] = []
                    
                    gradientValue.stops.forEach { element in
                        var elementCopy = element
                        let baseLocation = paint.startAngle > paint.endAngle ? (1 - element.location) : element.location
                        let newLocation = baseLocation * locationFactor + lowValue
                        elementCopy.location = newLocation
                        newColorStops.append(elementCopy)
                    }
                    
                    gradientValue.stops = newColorStops
                }
            }
        }
        
        self.gradient = gradientValue
        
        let centerX = paint.center.x * boundsWidth + boundsX
        
        let centerY = paint.center.y * boundsHeight + boundsY
        
        self.center = .init(x: centerX, y: centerY)
    }
}
