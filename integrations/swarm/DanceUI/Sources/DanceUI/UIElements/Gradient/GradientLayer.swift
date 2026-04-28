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
internal final class GradientLayer: CAGradientLayer {
    
    private lazy var rgbColorSpace = {
        CGColorSpaceCreateDeviceRGB()
    }()
    
    internal func update(gradient: ResolvedGradient, 
                         function: GradientLayer.Function, 
                         size: CGSize,
                         bounds: CGRect) {
        
        let geometry = GradientGeometry(size: size, function: function, bounds: bounds)
        self.type = geometry.type
        self.startPoint = geometry.startPoint
        self.endPoint = geometry.endPoint
        let (locations, colors, interpolations) = Self.clippedValues(gradient: gradient, function: function)
        self.locations = locations
        
        if #available(iOS 16, *) {
            self.set_myShims_premultiplied(true)
            self.colors = colors
            self.set_myShims_interpolations(interpolations)
            if gradient.usePerceptualBlending == true {
                let colorSpace = gradient.colorSpace.cgColorSpace
                self.set_myShims_colorSpace(colorSpace)
            }
        } else {
            self.colors = resolveTransparent(colors: colors)
        }
    }
    
    private struct RGBA {
        internal var r: CGFloat
        internal var g: CGFloat
        internal var b: CGFloat
        internal var a: CGFloat
        
        internal var isTransparent: Bool {
            a == 0
        }
        
        internal var isOpaque: Bool {
            a > 0
        }

        internal init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
            self.r = r
            self.g = g
            self.b = b
            self.a = a
        }

        internal init?(_ color: CGColor) {
            guard let c = color.components, c.count >= 4 else { return nil }
            self.init(r: c[0], g: c[1], b: c[2], a: c[3])
        }

        internal func interpolated(to end: RGBA, t: CGFloat, preserveAlpha alpha: CGFloat) -> RGBA {
            RGBA(
                r: r * (1 - t) + end.r * t,
                g: g * (1 - t) + end.g * t,
                b: b * (1 - t) + end.b * t,
                a: alpha // 保持原透明度
            )
        }

        internal func makeCGColor(in space: CGColorSpace) -> CGColor {
            CGColor(colorSpace: space, components: [r, g, b, a]) ?? CGColor(gray: 0, alpha: 0)
        }

        
    }

    
    func resolveTransparent(colors: [CGColor]) -> [CGColor] {
        guard !colors.isEmpty else {
            return []
        }

        var resolved = colors
        let colorSpace = rgbColorSpace
        
        let resolvedColors = resolved.compactMap(RGBA.init)
        guard resolvedColors.count == colors.count else {
            return colors
        }

        if let firstOpaque = resolvedColors.first(where: { $0.isOpaque }) {
            for (index, color) in resolvedColors.enumerated() {
                if color.isTransparent {
                    resolved[index] = RGBA(r: firstOpaque.r, g: firstOpaque.g, b: firstOpaque.b, a: color.a)
                        .makeCGColor(in: colorSpace)
                } else {
                    break
                }
            }
        }

        var currentIndex = 0
        while currentIndex < resolvedColors.count {
            let startColor = resolvedColors[currentIndex]
            var endIndex = currentIndex &+ 1
            var sawTransparent = false
            
            while endIndex < resolvedColors.count {
                let endColor = resolvedColors[endIndex]

                if endColor.isTransparent {
                    sawTransparent = true
                } else if sawTransparent {
                    // 找到透明段后的第一个不透明色
                    break
                } else {
                    currentIndex = endIndex // 跳过连续不透明段
                }

                endIndex &+= 1
            }
            
            if sawTransparent, endIndex < resolvedColors.count, startColor.isOpaque {
                let end = resolvedColors[endIndex]
                if end.isOpaque {
                    let count = endIndex &- currentIndex
                    for index in 1..<count {
                        let midColor = resolvedColors[currentIndex + index]
                        let t = CGFloat(index) / CGFloat(count)
                        let interpolated = startColor.interpolated(to: end, t: t, preserveAlpha: midColor.a)
                        resolved[currentIndex + index] = interpolated.makeCGColor(in: colorSpace)
                    }
                }
            }
            currentIndex = endIndex
        }

        if let lastOpaque = resolvedColors.last(where: { $0.isOpaque }) {
            for index in stride(from: resolvedColors.count - 1, through: 0, by: -1) {
                let color = resolvedColors[index]
                if color.isTransparent {
                    resolved[index] = RGBA(r: lastOpaque.r, g: lastOpaque.g, b: lastOpaque.b, a: color.a)
                        .makeCGColor(in: colorSpace)
                } else {
                    break
                }
            }

        }

        return resolved
    }


    
    internal enum Function {
        
        case axial(startPoint: UnitPoint, endPoint: UnitPoint)

        case radial(center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat)

        case elliptical(center: UnitPoint, startRadiusFraction: CGFloat, endRadiusFraction: CGFloat)
        
        case conic(center: UnitPoint, angle: Angle)

    }
    
    private struct GradientGeometry: Equatable {
        
        fileprivate var type: CAGradientLayerType
        
        fileprivate var startPoint: CGPoint
        
        fileprivate var endPoint: CGPoint
        
        fileprivate init(size: CGSize,
                         function: Function,
                         bounds: CGRect) {
            switch function {
            case .axial(let startPoint, let endPoint):
                self.type = .axial
                
                let maxLengthOfSide = max(size.width, size.height)
                
                var maxLengthOfSideVector: CGPoint = .init(x: maxLengthOfSide, y: maxLengthOfSide)
                
                var startPointVector: CGPoint = .init(x: (startPoint.x * bounds.width + bounds.origin.x) / maxLengthOfSide,
                                        y: (startPoint.y * bounds.height + bounds.origin.y) / maxLengthOfSide)
                
                var endPointVector: CGPoint = .init(x: (endPoint.x * bounds.width + bounds.origin.x) / maxLengthOfSide,
                                        y: (endPoint.y * bounds.height + bounds.origin.y) / maxLengthOfSide)
                
                var endPointResultVector: CGPoint = endPointVector.subPoint(startPointVector)
                
                endPointResultVector = .init(x: endPointResultVector.y, y: endPointResultVector.x)
                
                var tempVector: CGPoint = startPointVector.subPoint(endPointResultVector)
                
                endPointResultVector = startPointVector.addPoint(endPointResultVector)
                
                endPointResultVector = .init(x: endPointResultVector.x, y: tempVector.y)
                
                tempVector = .init(x: size.width, y: size.height)
                
                maxLengthOfSideVector = maxLengthOfSideVector.dividedBy(tempVector)
                
                tempVector = maxLengthOfSideVector.multiplyBy(startPointVector)
                
                let startPointValue = tempVector
                
                startPointVector = maxLengthOfSideVector.multiplyBy(endPointVector)
                
                maxLengthOfSideVector = maxLengthOfSideVector.multiplyBy(endPointResultVector)
                
                maxLengthOfSideVector = maxLengthOfSideVector.subPoint(tempVector)
                
                endPointVector = maxLengthOfSideVector.multiplyBy(maxLengthOfSideVector)
                
                endPointResultVector = startPointVector.subPoint(tempVector)
                
                endPointResultVector = endPointResultVector.multiplyBy(maxLengthOfSideVector)
                
                tempVector = .init(x: endPointResultVector.y, y: endPointVector.y)
                
                endPointVector = .init(x: endPointResultVector.x, y: endPointVector.x)
                
                endPointVector = tempVector.addPoint(endPointVector)
                
                endPointResultVector = .init(x: endPointVector.y, y: endPointVector.y)
                
                endPointVector = endPointVector.dividedBy(endPointResultVector)
                
                endPointResultVector = maxLengthOfSideVector.multiplyBy(endPointVector)
                
                endPointResultVector = startPointVector.subPoint(endPointResultVector)
                
                maxLengthOfSideVector = endPointVector.multiply(by: maxLengthOfSideVector.y)
                
                startPointVector = .init(x: startPointVector.y, y: startPointVector.y)
                
                maxLengthOfSideVector = startPointVector.subPoint(maxLengthOfSideVector)
                
                let endPointValue: CGPoint = .init(x: endPointResultVector.x, y: maxLengthOfSideVector.x)
                
                self.startPoint = startPointValue
                
                self.endPoint = endPointValue
            case .radial(let center, let startRadius ,let endRadius):
                self.type = .radial
                
                let maxRadius = max(startRadius, endRadius)
                
                let centerVector: CGPoint = .init(x: center.x, y: center.y)
                
                let boundsSizeVector: CGPoint = .init(x: bounds.width, y: bounds.height)
                
                var tempVector = boundsSizeVector.multiplyBy(centerVector)
                
                let boundsOriginVector: CGPoint = .init(x: bounds.origin.x, y: bounds.origin.y)
                
                tempVector = tempVector.addPoint(boundsOriginVector)
                
                let sizeVector: CGPoint = .init(x: size.width, y: size.height)
                
                tempVector = tempVector.dividedBy(sizeVector)
                
                let startPointValue = tempVector
                
                tempVector = .init(x: maxRadius, y: maxRadius)
                
                tempVector = tempVector.dividedBy(boundsSizeVector)
                
                var endPointValue = centerVector.subPoint(tempVector)
                
                endPointValue = endPointValue.multiplyBy(boundsSizeVector)
                
                endPointValue = endPointValue.addPoint(boundsOriginVector)
                
                endPointValue = endPointValue.dividedBy(sizeVector)
                
                self.startPoint = startPointValue
                
                self.endPoint = endPointValue
            case .elliptical(let center, let startRadiusFraction, let endRadiusFraction):
                self.type = .radial
                
                let maxRadiusFraction = max(startRadiusFraction, endRadiusFraction)
                
                let centerVector: CGPoint = .init(x: center.x, y: center.y)
                
                let boundsSizeVector: CGPoint = .init(x: bounds.width, y: bounds.height)
                
                let boundsOriginVector: CGPoint = .init(x: bounds.origin.x, y: bounds.origin.y)
                
                let sizeVector: CGPoint = .init(x: size.width, y: size.height)
                
                var tempVector = boundsSizeVector.multiplyBy(centerVector)
                
                tempVector = tempVector.addPoint(boundsOriginVector)
                
                tempVector = tempVector.dividedBy(sizeVector)
                
                let startPointValue = tempVector
                
                tempVector = .init(x: maxRadiusFraction, y: maxRadiusFraction)
                
                var endPointValue = centerVector.subPoint(tempVector)
                
                endPointValue = endPointValue.multiplyBy(boundsSizeVector)
                
                endPointValue = endPointValue.addPoint(boundsOriginVector)
                
                endPointValue = endPointValue.dividedBy(sizeVector)
                
                self.startPoint = startPointValue
                
                self.endPoint = endPointValue
            case .conic(let center, let angle):
                self.type = .conic
                
                let centerVector: CGPoint = .init(x: center.x, y: center.y)
                
                let boundsSizeVector: CGPoint = .init(x: bounds.width, y: bounds.height)
                
                let boundsOriginVector: CGPoint = .init(x: bounds.origin.x, y: bounds.origin.y)
                
                var tempVector = boundsSizeVector.multiplyBy(centerVector)
                
                tempVector = tempVector.addPoint(boundsOriginVector)
                
                let sizeVector: CGPoint = .init(x: size.width, y: size.height)
                
                tempVector = tempVector.dividedBy(sizeVector)
                
                let startPointValue = tempVector
                
                let sincos = __sincos_stret(angle.radians)
                
                let cossinVector: CGPoint = .init(x: sincos.__cosval, y: sincos.__sinval)
                
                let endPointValue = cossinVector.addPoint(tempVector)
                
                self.startPoint = startPointValue
                
                self.endPoint = endPointValue
            }
        }
    }
    
    internal static func clippedValues(gradient: ResolvedGradient, 
                                       function: GradientLayer.Function) -> (locations: [NSNumber], colors: [CGColor], interpolations: [NSNumber]?) {
        guard !gradient.stops.isEmpty else {
            return ([], [], nil)
        }
        
        var resultColors: [CGColor] = []
        var resultLocation: [NSNumber] = []
        var interpolations: [NSNumber]?
        
        if gradient.usePerceptualBlending == false {
            for stop in gradient.stops {
                resultColors.append(stop.color.cgColor)
                resultLocation.append(.init(floatLiteral: stop.location))
            }
            return (resultLocation, resultColors, nil)
        }

        @inline(__always)
        func appendColorAndLocation(lastColorInfo: (color: Color.Resolved, location: CGFloat)?,
                                    currentColor: Color.Resolved,
                                    location: CGFloat) {
            if let lastColorInfo {
                let interpolationColor = interpolationColor(firstColor: (color: lastColorInfo.color, location: lastColorInfo.location),
                                                            secondColor: (currentColor, location))
                resultColors.append(interpolationColor.color.cgColor)
                resultLocation.append(.init(floatLiteral: interpolationColor.location))
                
                resultColors.append(currentColor.cgColor)
                resultLocation.append(.init(floatLiteral: location))
            } else {
                resultColors.append(currentColor.cgColor)
                resultLocation.append(.init(floatLiteral: location))
            }
        }

        @inline(__always)
        func adjustedColorForLocationGTOne(colorStop: ResolvedGradient.Stop,
                                           currentLocation: CGFloat,
                                           previousColor: (color: Color.Resolved, location: CGFloat)) -> Color.Resolved {
            let previousLocation = previousColor.location
            let previousColorOpacity = previousColor.color.opacity
            let currentColorOpacity = colorStop.color.opacity
            let (currentColorPowVector, currentColorPowComponent) = colorStop.color.interpolationValues
            let (previousColorPowVector, previousColorPowComponent) = previousColor.color.interpolationValues
            let colorComponentVector: CGPoint = .init(x: previousColorPowComponent, y: currentColorPowComponent)
            
            let locationBase = (1 - previousLocation) / (currentLocation - previousLocation)
            let previousColorOpacityVector: CGPoint = .init(x: previousColorOpacity, y: previousColorOpacity)
            let tempVector2 = previousColorPowVector.multiplyBy(previousColorOpacityVector)
            let opacityVector: CGPoint = .init(x: previousColorOpacity, y: currentColorOpacity)
            let tempVector3 = colorComponentVector.multiplyBy(opacityVector)
            let currentColorOpacityVector: CGPoint = .init(x: currentColorOpacity, y: currentColorOpacity)
            let tempVector11 = currentColorPowVector.multiplyBy(currentColorOpacityVector)
            let locationMixedPreviousOpacity = (1 - locationBase) * CGFloat(previousColorOpacity)
            var powVectorBase: CGPoint = .init(x: 1 - locationBase, y: 1 - locationBase)
            var tempVector0: CGPoint = .init(x: 1 - locationBase, y: locationBase)
            tempVector0 = tempVector0.multiplyBy(tempVector3)

            var opacityValue = locationBase * CGFloat(currentColorOpacity)
            opacityValue = opacityValue + locationMixedPreviousOpacity

            powVectorBase = powVectorBase.multiplyBy(tempVector2)
            var tempVector1: CGPoint = .init(x: locationBase, y: locationBase)
            let tempVector0Sum = tempVector0.x + tempVector0.y
            tempVector1 = tempVector1.multiplyBy(tempVector11)
            tempVector1 = tempVector1.addPoint(powVectorBase)

            let opacityAsDivisor = opacityValue == 0 ? 1 : opacityValue
            let base = 1 / opacityAsDivisor
            powVectorBase = .init(x: base, y: base)
            let powValueBase = base * tempVector0Sum
            powVectorBase = powVectorBase.multiplyBy(tempVector1)
            
            let powValue = pow(powValueBase, 3)
            let powVector: CGPoint = .init(x: pow(powVectorBase.x, 3), y: pow(powVectorBase.y, 3))
            let mixedColor = mixedColor(powVector: powVector, powValue: Float(powValue), opacity: Float(opacityValue))
            return mixedColor
        }

        @inline(__always)
        func adjustedColorForContinuousNegativeLocation(colorStop: ResolvedGradient.Stop,
                                                        nextColorStop: ResolvedGradient.Stop,
                                                        nextLocation: CGFloat) -> Color.Resolved {
            let currentColorOpacity = colorStop.color.opacity
            let nextColorOpacity = nextColorStop.color.opacity
            let (currentColorPowVector, currentColorPowComponent) = colorStop.color.interpolationValues
            let (nextColorPowVector, nextColorPowComponent) = nextColorStop.color.interpolationValues
            var currentColorVector = currentColorPowVector
            let nextColorVector = nextColorPowVector
            let colorComponentVector: CGPoint = .init(x: currentColorPowComponent, y: nextColorPowComponent)
            var currenrLocationABSValue = -colorStop.location
            let locationDiff = nextLocation - colorStop.location
            currenrLocationABSValue = currenrLocationABSValue / locationDiff
            
            let tempVector1 = currentColorVector.multiply(by: CGFloat(currentColorOpacity))
            let opacityVector: CGPoint = .init(x: currentColorOpacity, y: nextColorOpacity)
            let tempVector3 = colorComponentVector.multiplyBy(opacityVector)
            currentColorVector = nextColorVector.multiply(by: CGFloat(nextColorOpacity))

            var currentOpacityMixedLocation = CGFloat(currentColorOpacity) * (1 - currenrLocationABSValue)
            var tempVector6: CGPoint = .init(x: 1 - currenrLocationABSValue, y: 1 - currenrLocationABSValue)
            var tempVector5: CGPoint = .init(x: 1 - currenrLocationABSValue, y: currenrLocationABSValue)
            tempVector5 = tempVector5.multiplyBy(tempVector3)
            let opacityResult = CGFloat(nextColorOpacity) * currenrLocationABSValue + currentOpacityMixedLocation
            
            tempVector6 = tempVector6.multiplyBy(tempVector1)
            var tempVector0: CGPoint = .init(x: currenrLocationABSValue, y: currenrLocationABSValue)
            let tempVector5Sum = tempVector5.x + tempVector5.y
            tempVector0 = currentColorVector.multiplyBy(tempVector0)
            tempVector0 = tempVector0.addPoint(tempVector6)

            let opacityAsDivisor = opacityResult == 0 ? 1 : opacityResult
            let base = 1 / opacityAsDivisor
            var powVectorBase: CGPoint = .init(x: base, y: base)
            currentOpacityMixedLocation = tempVector5Sum * base
            powVectorBase = powVectorBase.multiplyBy(tempVector0)
            
            let powValue = pow(currentOpacityMixedLocation, 3)
            let powVector: CGPoint = .init(x: pow(powVectorBase.x, 3), y: pow(powVectorBase.y, 3))
            let mixedColor = mixedColor(powVector: powVector, powValue: Float(powValue), opacity: Float(opacityResult))
            return mixedColor
        }
        
        let colorsCount = gradient.stops.count
        var lastColorInfo: (color: Color.Resolved, location: CGFloat)? = nil
        switch function {
        case .axial,
             .conic:
            gradient.stops.enumerated().forEach { value in
                let colorStop = value.element
                let index = value.offset
                let location = colorStop.location
                if location >= 0 {
                    if location > 1,
                       let previousColor = lastColorInfo,
                       previousColor.location <= 1 {
                        let currentAdjustedLocation = min(1, location)
                        let mixedColor = adjustedColorForLocationGTOne(colorStop: colorStop,
                                                                       currentLocation: colorStop.location,
                                                                       previousColor: previousColor)
                        appendColorAndLocation(lastColorInfo: previousColor,
                                               currentColor: mixedColor,
                                               location: currentAdjustedLocation)
                        lastColorInfo = (mixedColor, location)
                    } else { // location = [0, 1]
                        let adjustedLocation = min(1, location)
                        let lastColor = lastColorInfo.map { ($0.color, min(1, $0.location)) }
                        appendColorAndLocation(lastColorInfo: lastColor,
                                               currentColor: colorStop.color,
                                               location: adjustedLocation)
                        lastColorInfo = (colorStop.color, location)
                    }
                } else { // location < 0
                    if index + 1 < colorsCount {
                        let nextColorStop = gradient.stops[index + 1]
                        let nextLocation = nextColorStop.location
                        let currentAdjustedLocation = max(0, location)
                        if nextLocation < 0 { // location < 0 & nextLocation < 0
                            let nextAdjustedLocation = max(0, nextLocation)
                            if index == 0 {
                                resultColors.append(colorStop.color.cgColor)
                                resultLocation.append(.init(floatLiteral: currentAdjustedLocation))
                            }
                            lastColorInfo = (colorStop.color, currentAdjustedLocation)
                            appendColorAndLocation(lastColorInfo: lastColorInfo,
                                                   currentColor: nextColorStop.color, location: nextAdjustedLocation)
                        } else { // location < 0 & nextLocation >= 0
                            let mixedColor = adjustedColorForContinuousNegativeLocation(colorStop: colorStop,
                                                                                        nextColorStop: nextColorStop,
                                                                                        nextLocation: nextLocation)
                            resultColors.append(mixedColor.cgColor)
                            resultLocation.append(.init(floatLiteral: currentAdjustedLocation))
                            
                            lastColorInfo = (mixedColor, currentAdjustedLocation)
                        }
                    } else {
                        let currentAdjustedLocation = max(0, location)
                        appendColorAndLocation(lastColorInfo: lastColorInfo,
                                               currentColor: colorStop.color, location: currentAdjustedLocation)
                        lastColorInfo = (colorStop.color, currentAdjustedLocation)
                    }
                }
            }
        case .radial(_, let startRadius, let endRadius),
             .elliptical(_, let startRadius, let endRadius): // TO DO: Check endRadius == 0
            let radiusVector: CGPoint
            if startRadius == 0 {
                radiusVector = .init(x: 0, y: 1)
            } else if startRadius < endRadius {
                radiusVector = .init(x: startRadius / endRadius, y: (endRadius - startRadius) / endRadius)
            } else {
                radiusVector = .init(x: 1, y: (endRadius / startRadius) - 1)
            }
            
            let thresholdValueOfLocation = min(min(1, radiusVector.x), radiusVector.x + radiusVector.y)
            let colorStops: [ResolvedGradient.Stop]
            if radiusVector.y > 0 {
                colorStops = gradient.stops
            } else {
                colorStops = gradient.stops.reversed()
            }
            
            colorStops.enumerated().forEach { value in
                let colorStop = value.element
                let index = value.offset
                let adjustedLocation = colorStop.location * radiusVector.y + radiusVector.x
                if adjustedLocation >= thresholdValueOfLocation {
                    if adjustedLocation > 1,
                       let previousColor = lastColorInfo,
                       previousColor.location <= 1 { // adjustedLocation > 1 & previousLocation <= 1
                        let mixedColor = adjustedColorForLocationGTOne(colorStop: colorStop,
                                                                       currentLocation: adjustedLocation,
                                                                       previousColor: previousColor)
                        appendColorAndLocation(lastColorInfo: previousColor,
                                               currentColor: mixedColor,
                                               location: min(1, adjustedLocation))
                        lastColorInfo = (mixedColor, adjustedLocation)
                    } else { // location = [0, 1]
                        let currentLocation = min(1, adjustedLocation)
                        let lastColor = lastColorInfo.map { ($0.color, min(1, $0.location)) }
                        appendColorAndLocation(lastColorInfo: lastColor,
                                               currentColor: colorStop.color,
                                               location: currentLocation)
                        lastColorInfo = (colorStop.color, adjustedLocation)
                    }
                } else {
                    if index + 1 < colorsCount {
                        let nextColorStop = gradient.stops[index + 1]
                        let nextLocation = nextColorStop.location
                        let adjustedNextLocation = nextColorStop.location * radiusVector.y + radiusVector.x
                        if adjustedNextLocation < thresholdValueOfLocation { // adjustedLocation < thresholdValueOfLocation & adjustedNextLocation < thresholdValueOfLocation
                            let adjustedLocation = thresholdValueOfLocation
                            if index == 0 {
                                resultColors.append(colorStop.color.cgColor)
                                resultLocation.append(.init(floatLiteral: adjustedLocation))
                            }
                            lastColorInfo = (colorStop.color, adjustedLocation)
                            appendColorAndLocation(lastColorInfo: lastColorInfo,
                                                   currentColor: nextColorStop.color, location: adjustedLocation)
                        } else { // adjustedLocation < thresholdValueOfLocation & adjustedNextLocation >= thresholdValueOfLocation
                            let mixedColor = adjustedColorForContinuousNegativeLocation(colorStop: colorStop,
                                                                                        nextColorStop: nextColorStop,
                                                                                        nextLocation: nextLocation)
                            let adjustedLocation = thresholdValueOfLocation
                            resultColors.append(mixedColor.cgColor)
                            resultLocation.append(.init(floatLiteral: adjustedLocation))
                            
                            lastColorInfo = (mixedColor, adjustedLocation)
                        }
                    }
                }
            }
        }
        
        return (resultLocation, resultColors, interpolations)
    }
}

@available(iOS 13.0, *)
private func interpolationColor(firstColor: (color: Color.Resolved,  location: CGFloat),
                                secondColor: (color: Color.Resolved, location: CGFloat)) -> (color: Color.Resolved, location: CGFloat) {
    let newLocation = (firstColor.location + secondColor.location) / 2
    let firstColorVector = firstColor.color.interpolationColorVetcor
    let secondColorVector = secondColor.color.interpolationColorVetcor
    
    let redComponent = (firstColorVector.redValue + secondColorVector.redValue) * 0.5
    let greenComponent = (firstColorVector.greenValue + secondColorVector.greenValue) * 0.5
    let blueComponent = (firstColorVector.blueValue + secondColorVector.blueValue) * 0.5
    let opacityComponent = (firstColorVector.opacityValue + secondColorVector.opacityValue) * 0.5
    
    let color = mixedColor(redComponent: redComponent,
                           greenComponent: greenComponent,
                           blueComponent: blueComponent,
                           opacityComponent: opacityComponent)
    return (color, newLocation)
}

@available(iOS 13.0, *)
private func mixedColor(powVector: CGPoint, powValue: Float, opacity: Float) -> Color.Resolved {
    var componentPowVector = powVector
    var blueValue = powValue
    
    var tempVector: CGPoint = componentPowVector.multiplyBy(.init(x: Float(bitPattern: 0x4053_b18c), y: Float(bitPattern: 0x3fa2_5c2d)))
    tempVector = tempVector.reverse()
    
    var redAndGreenVector = componentPowVector.multiplyBy(.init(x: Float(bitPattern: 0x4027_0644), y: Float(bitPattern: 0x4082_74ab)))
    redAndGreenVector = redAndGreenVector.subPoint(tempVector)
    
    tempVector = .init(x: blueValue, y: blueValue)
    tempVector = tempVector.multiplyBy(.init(x: Float(bitPattern: 0x3eae_c16a), y: Float(bitPattern: 0x3e6c_8362)))
    
    redAndGreenVector = .init(x: redAndGreenVector.x - tempVector.x, y: redAndGreenVector.y + tempVector.y)
    
    componentPowVector = componentPowVector.multiplyBy(.init(x: Float(bitPattern: 0x3f34_133e), y: Float(bitPattern: 0xbb89_7f53)))
    
    tempVector = .init(x: componentPowVector.y, y: componentPowVector.y)
    tempVector = tempVector.subPoint(componentPowVector)
    
    blueValue = blueValue * Float(bitPattern: 0x3fda_931e)
    blueValue = Float(tempVector.x) + blueValue
    
    let red = redAndGreenVector.y
    let green = redAndGreenVector.x
    let blue = blueValue
    let mixedColor = Color.Resolved(linearRed: Float(red), linearGreen: Float(green), linearBlue: Float(blue), opacity: opacity)
    return mixedColor
}

@available(iOS 13.0, *)
private func mixedColor(redComponent: Float,
                        greenComponent: Float,
                        blueComponent: Float,
                        opacityComponent: Float) -> Color.Resolved {
    let opacityAsDivisor = opacityComponent == 0 ? 1 : opacityComponent
    var base = 1 / opacityAsDivisor
    let opacityVector: CGPoint = .init(x: 1 / opacityAsDivisor, y: 1 / opacityAsDivisor)
    base = base * blueComponent
    var componentVector: CGPoint = .init(x: greenComponent, y: redComponent)
    componentVector = componentVector.multiplyBy(opacityVector)

    let componentPowVector: CGPoint = .init(x: pow(componentVector.x, 3), y: pow(componentVector.y, 3))
    let powValue = powf(base, 3)
    return mixedColor(powVector: componentPowVector, powValue: powValue, opacity: opacityComponent)
}

@available(iOS 13.0, *)
extension Color.Resolved {
    
    fileprivate var interpolationValues: (powVector: CGPoint, powComponent: Float) {
        var redVector: CGPoint = .init(x: linearRed, y: linearRed)
        redVector = redVector.multiplyBy(.init(x: Float(bitPattern: 0x3e58_fd3b), y: Float(bitPattern: 0x3ed3_0eb1)))
        
        var greenVector: CGPoint = .init(x: linearGreen, y: linearGreen)
        greenVector = greenVector.multiplyBy(.init(x: Float(bitPattern: 0x3f2e_4253), y: Float(bitPattern: 0x3f09_4d17)))
        
        var blueVector: CGPoint = .init(x: linearBlue, y: linearBlue)
        blueVector = blueVector.multiplyBy(.init(x: Float(bitPattern: 0x3dd_bf2f0), y: Float(bitPattern: 0x3d52_b909)))
        
        var tempVector = greenVector.addPoint(redVector)
        tempVector = tempVector.addPoint(blueVector)
        
        let firstPowValue = powf(Float(tempVector.x), Float(bitPattern: 0x3eaa_aaab))
        let secondPowValue = powf(Float(tempVector.y), Float(bitPattern: 0x3eaa_aaab))
        let powVector: CGPoint = .init(x: firstPowValue, y: secondPowValue)
        
        let redComponent = linearRed * Float(bitPattern: 0x3db4_d7ec)
        let greenComponent = linearGreen * Float(bitPattern: 0x3e90_3d74)
        let blueComponent = linearBlue * Float(bitPattern: 0x3f21_4649)
        
        let tempComponent = redComponent + greenComponent + blueComponent
        let powComponent = powf(tempComponent, Float(bitPattern: 0x3eaa_aaab))
        return (powVector, powComponent)
    }
    
    fileprivate var interpolationColorVetcor: (redValue: Float, greenValue: Float, blueValue: Float, opacityValue: Float) {
        let (powVector, powComponent) = interpolationValues
        let redValue = Float(powVector.y) * opacity
        let greenValue = Float(powVector.x) * opacity
        let blueValue = powComponent * opacity
        return (redValue, greenValue, blueValue, opacity)
    }
}

@available(iOS 13.0, *)
extension CGPoint {
    internal init(x: Float, y: Float) {
        self.init(x: CGFloat(x), y: CGFloat(y))
    }
}
