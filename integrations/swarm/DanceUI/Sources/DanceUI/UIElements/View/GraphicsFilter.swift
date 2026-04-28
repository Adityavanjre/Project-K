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
@_spi(DanceUICompose)
public enum GraphicsFilter: RendererEffect {

    case blur(BlurStyle)
    
    case shadow(ResolvedShadowStyle)

    case projection(ProjectionTransform)

    case colorMatrix(_ColorMatrix)
    
    case colorMultiply(Color.Resolved)

    case hueRotation(Angle)

    case saturation(Double)

    case brightness(Double)

    case contrast(Double)

    case grayscale(Double)

    case colorMonochrome(ColorMonochrome)

    case vibrantColorMatrix(_ColorMatrix)

    case luminanceCurve(LuminanceCurve)
    
    case luminanceToAlpha

    case colorInvert
    
    internal var isIdentity: Bool {
        switch self {
        case .blur(let style):
            return style.radius <= 0
        case .colorMatrix(let matrix):
            return matrix.isIdentity
        case .colorMultiply(let color):
            return color.red == 1 &&
                color.green == 1 &&
                color.blue == 1 &&
                color.alpha == 1
        case .hueRotation(let angle):
            return angle.radians == 0
        case .saturation(let value), .contrast(let value):
            return value == 1
        case .brightness(let value), .grayscale(let value):
            return value == 0
        case .colorMonochrome(let value):
            return value.amount == 0
        case .luminanceCurve(let curve):
            return curve.amount == 0
        case .shadow, .projection, .luminanceToAlpha, .colorInvert, .vibrantColorMatrix:
            return false
        }
    }
    
    internal var caFilterProperties: (String , [String: AnyObject]) {
        switch self {
        case .blur(let style):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputRadiusPropertyKey] = style.radius as AnyObject
            properties[GraphicsFilter.inputDitherPropertyKey] = style.dither as AnyObject
            properties[GraphicsFilter.luminanceCurveMapPropertyKey] = style.isOpaque as AnyObject
            return (GraphicsFilter.blurEffectName, properties)
        case .shadow, .projection:
            _danceuiFatalError()
        case .colorMatrix(let matrix):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.vibrantColorMatrixPropertyKey] = matrix.floatArray as AnyObject
            return (GraphicsFilter.colorMatrixEffectName, properties)
        case .colorMultiply(let color):
            let cgColor = color.cgColor
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputColorPropertyKey] = cgColor
            return (GraphicsFilter.multiplyColorEffectName, properties)
        case .hueRotation(let angle):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputAnglePropertyKey] = angle.radians as AnyObject
            return (GraphicsFilter.colorHueRotateEffectName, properties)
        case .saturation(let value):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputAmountPropertyKey] = value as AnyObject
            return (GraphicsFilter.colorSaturateEffectName, properties)
        case .brightness(let value):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputAmountPropertyKey] = value as AnyObject
            return (GraphicsFilter.colorBrightnessEffectName, properties)
        case .contrast(let value):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputAmountPropertyKey] = value as AnyObject
            return (GraphicsFilter.colorContrastEffectName, properties)
        case .grayscale(let value):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputAmountPropertyKey] = value as AnyObject
            return (GraphicsFilter.colorMonochromeEffectName, properties)
        case .colorMonochrome(let colorMonochrome):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.inputColorPropertyKey] = colorMonochrome.color.cgColor
            properties[GraphicsFilter.inputAmountPropertyKey] = colorMonochrome.amount as AnyObject
            properties[GraphicsFilter.inputBiasPropertyKey] = colorMonochrome.bias as AnyObject
            return (GraphicsFilter.colorMonochromeEffectName, properties)
        case .vibrantColorMatrix(let matrix):
            var properties: [String: AnyObject] = [:]
            properties[GraphicsFilter.vibrantColorMatrixPropertyKey] = matrix.floatArray as AnyObject
            return (GraphicsFilter.vibrantColorMatrixEffectName, properties)
        case .luminanceCurve(let luminanceCurve):
            var properties: [String: AnyObject] = [:]
            let curveArray = NSArray(arrayLiteral: luminanceCurve.curve.0,
                                                   luminanceCurve.curve.1,
                                                   luminanceCurve.curve.2,
                                                   luminanceCurve.curve.3)
            properties[GraphicsFilter.inputValuePropertyKey] = curveArray
            properties[GraphicsFilter.inputAmountPropertyKey] = luminanceCurve.amount as AnyObject
            return (GraphicsFilter.luminanceCurveEffectName, properties)
        case .luminanceToAlpha:
            return (GraphicsFilter.luminanceToAlphaEffectName, [:])
        case .colorInvert:
            return (GraphicsFilter.colorInvertEffectName, [:])
        }
    }

    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .filter(self)
    }
    
    /*
     CAFilter Effect Name
     */
    internal static let blurEffectName = "gaussianBlur"
    
    internal static let colorMatrixEffectName = "colorMatrix"
    
    internal static let multiplyColorEffectName = "multiplyColor"
    
    internal static let colorHueRotateEffectName = "colorHueRotate"
    
    internal static let colorSaturateEffectName = "colorSaturate"
    
    internal static let colorBrightnessEffectName = "colorBrightness"
    
    internal static let colorContrastEffectName = "colorContrast"
    
    internal static let colorMonochromeEffectName = "colorMonochrome"
    
    internal static let vibrantColorMatrixEffectName = "vibrantColorMatrix"
    
    internal static let luminanceCurveEffectName = "luminanceCurveMap"
    
    internal static let luminanceToAlphaEffectName = "luminanceToAlpha"
    
    internal static let colorInvertEffectName = "colorInvert"
    
    /*
     CAFilter Property Key
     */
    internal static let inputRadiusPropertyKey = "inputRadius"
    
    internal static let inputDitherPropertyKey = "inputDither"
    
    internal static let luminanceCurveMapPropertyKey = "luminanceCurveMap"
    
    internal static let vibrantColorMatrixPropertyKey = "inputColorMatrix"
    
    internal static let inputColorPropertyKey = "inputColor"
    
    internal static let inputAnglePropertyKey = "inputAngle"
    
    internal static let inputAmountPropertyKey = "inputAmount"
    
    internal static let inputBiasPropertyKey = "inputBias"
    
    internal static let inputValuePropertyKey = "inputValue"
    
    @_spi(DanceUICompose)
    public struct ColorMonochrome: Equatable {
        
        internal var color: Color.Resolved
        
        internal var amount: Float
        
        internal var bias: Float
    }
    
    @_spi(DanceUICompose)
    public struct LuminanceCurve {
        
        internal var curve: (Float, Float, Float, Float)
        
        internal var amount: Float
    }
}
