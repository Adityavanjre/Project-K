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

@frozen
@available(iOS 13.0, *)
public struct _ColorMatrix: Equatable, Codable {
    
   
    public var m11: Float = 1, m12: Float = 0, m13: Float = 0, m14: Float = 0, m15: Float = 0
    
    
    public var m21: Float = 0, m22: Float = 1, m23: Float = 0, m24: Float = 0, m25: Float = 0
    
    
    public var m31: Float = 0, m32: Float = 0, m33: Float = 1, m34: Float = 0, m35: Float = 0
    
   
    public var m41: Float = 0, m42: Float = 0, m43: Float = 0, m44: Float = 1, m45: Float = 0
    
    @inlinable
    public init() {
        
    }
    
    internal static let identity: _ColorMatrix = _ColorMatrix()
    
    @inline(__always)
    internal static let luminanceToAlpha: _ColorMatrix = _ColorMatrix(m11: 0.0, m12: 0.0, m13: 0.0, m14: 0.0, m15: 0.0,
                                                                      m21: 0.0, m22: 0.0, m23: 0.0, m24: 0.0, m25: 0.0,
                                                                      m31: 0.0, m32: 0.0, m33: 0.0, m34: 0.0, m35: 0.0,
                                                                      m41: 0.2126, m42: 0.7152, m43: 0.0722, m44: 0.0, m45: 0.0)
    
    @inline(__always)
    internal static let colorInvert: _ColorMatrix = _ColorMatrix(m11: -1.0, m12: 0.0, m13: 0.0, m14: 0.0, m15: 1.0,
                                                                 m21: 0.0, m22: -1.0, m23: 0.0, m24: 0.0, m25: 1.0,
                                                                 m31: 0.0, m32: 0.0, m33: -1.0, m34: 0.0, m35: 1.0,
                                                                 m41: 0.0, m42: 0.0, m43: 0.0, m44: 1.0, m45: 0.0)
    
    @_spi(DanceUICompose)
    public init(m11: Float = 1, m12: Float = 0, m13: Float = 0, m14: Float = 0, m15: Float = 0,
                  m21: Float = 0, m22: Float = 1, m23: Float = 0, m24: Float = 0, m25: Float = 0,
                  m31: Float = 0, m32: Float = 0, m33: Float = 1, m34: Float = 0, m35: Float = 0,
                  m41: Float = 0, m42: Float = 0, m43: Float = 0, m44: Float = 1, m45: Float = 0) {
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        self.m14 = m14
        self.m15 = m15
        
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
        self.m24 = m24
        self.m25 = m25
        
        self.m31 = m31
        self.m32 = m32
        self.m33 = m33
        self.m34 = m34
        self.m35 = m35
        
        self.m41 = m41
        self.m42 = m42
        self.m43 = m43
        self.m44 = m44
        self.m45 = m45
    }
    
    @inline(__always)
    internal init(colorMartix: _ColorMatrix) {
        m11 = colorMartix.m11
        m12 = colorMartix.m12
        m13 = colorMartix.m13
        m14 = colorMartix.m14
        m15 = colorMartix.m15
        
        m21 = colorMartix.m21
        m22 = colorMartix.m22
        m23 = colorMartix.m23
        m24 = colorMartix.m24
        m25 = colorMartix.m25
        
        m31 = colorMartix.m31
        m32 = colorMartix.m32
        m33 = colorMartix.m33
        m34 = colorMartix.m34
        m35 = colorMartix.m35
        
        m41 = colorMartix.m41
        m42 = colorMartix.m42
        m43 = colorMartix.m43
        m44 = colorMartix.m44
        m45 = colorMartix.m45
    }
    
    @inline(__always)
    internal init(color: Color.Resolved) {
        self.init(m11: color.red,
                  m22: color.green,
                  m33: color.blue,
                  m44: color.opacity)
    }
    
    @inline(__always)
    internal init(saturation: Double) {
        
        let amount = Float(max(saturation, 0))
        
        self.init(m11: amount * 0.7873 + 0.2126,
                  m12: (1 - amount) * 0.7152,
                  m13: (1 - amount) * 0.0722,
                  
                  m21: (1 - amount) * 0.2126,
                  m22: 0.7152 + amount * 0.2848,
                  m23: (1 - amount) * 0.0722,
                  
                  m31: (1 - amount) * 0.2126,
                  m32: (1 - amount) * 0.7152,
                  m33: amount * 0.9278 + 0.0722)
    }
    
    @inline(__always)
    internal init(brightness: Double) {
        
        let amount = Float(max(brightness, 0))
        
        self.init(m15: amount,
                  m25: amount,
                  m35: amount)
    }
    
    @inline(__always)
    internal init(contrast: Double) {
        
        let amount = Float(max(contrast, 0))
        
        self.init(m11: amount,
                  m15: (1 - amount) * 0.5,
                  
                  m22: amount,
                  m25: (1 - amount) * 0.5,
                  
                  m33: amount,
                  m35: (1 - amount) * 0.5)
    }
    
    @inline(__always)
    internal init(grayscale: Double) {
        let amount = Float(max(grayscale, 0))
        self.init(colorMonochrome: Color.Resolved(linearRed: 1,
                                                  linearGreen: 1,
                                                  linearBlue: 1,
                                                  opacity: 1),
                  amount: amount,
                  bias: 0)
    }
    
    public init(color: Color, in environment: EnvironmentValues) {
        let resolvedColor = color.resolvePaint(in: environment)
        self.init(color: resolvedColor)
    }
    
    internal init(hueRotation: Angle) {
        let sincos = __sincos_stret(hueRotation.radians)
        let sinValue = Float(sincos.__sinval)
        let cosValue = Float(sincos.__cosval)
        
        let m11 = (cosValue * 0.7873 + 0.2126) - (sinValue * 0.2126)
        let m12 = (1 - cosValue) * 0.7152 - sinValue * 0.7152
        let m13 = sinValue * 0.9278 + (1 - cosValue) * 0.0722
        
        let m21 = sinValue * 0.143 + (1 - cosValue) * 0.2126
        let m22 = sinValue * 0.14 + cosValue * 0.2848 + 0.7152
        let m23 = sinValue * -0.283 + (1 - cosValue) * 0.0722
        
        let m31 = (1 - cosValue) * 0.2126 - sinValue * 0.7873
        let m32 = sinValue * 0.7152 + (1 - cosValue) * 0.7152
        let m33 = sinValue * 0.0722 + cosValue * 0.9278 + 0.0722
        
        self.init(m11: m11, m12: m12, m13: m13,
                  m21: m21, m22: m22, m23: m23,
                  m31: m31, m32: m32, m33: m33)
    }
    
    internal init(colorMonochrome: Color.Resolved,
                  amount: Float,
                  bias: Float) {
        let red = colorMonochrome.red
        let green = colorMonochrome.green
        let blue = colorMonochrome.blue
        let opacity = colorMonochrome.opacity
        
        let m11 = red * 0.2126 * amount + (1 - amount)
        let m12 = red * amount * 0.7152
        let m13 = red * amount * 0.0722
        let m15 = red * amount * bias
        
        let m21 = green * 0.2126 * amount
        let m22 = green * 0.7152 * amount + (1 - amount)
        let m23 = green * amount * 0.0722
        let m25 = green * amount * bias
        
        let m31 = blue * amount * 0.2126
        let m32 = blue * amount * 0.7152
        let m33 = blue * amount * 0.0722 + (1 - amount)
        let m35 = blue * bias * amount
        
        let m44 = opacity * amount + (1 - amount)
        
        self.init(m11: m11, m12: m12, m13: m13, m14: 0, m15: m15,
                  m21: m21, m22: m22, m23: m23, m24: 0, m25: m25,
                  m31: m31, m32: m32, m33: m33, m34: 0, m35: m35,
                  m41: 0, m42: 0, m43: 0, m44: m44, m45: 0)
    }
    
    internal init?(graphicsFilter: GraphicsFilter) {
        switch graphicsFilter {
            
        case .blur, .shadow, .projection, .vibrantColorMatrix, .luminanceCurve:
            return nil
            
        case .colorMatrix(let colorMartix):
            self.init(colorMartix: colorMartix)
            
        case .colorMultiply(let color):
            self.init(color: color)
            
        case .hueRotation(let angle):
            self.init(hueRotation: angle)
            
        case .saturation(let saturation):
            self.init(saturation: saturation)
            
        case .brightness(let brightness):
            self.init(brightness: brightness)
            
        case .contrast(let contrast):
            self.init(contrast: contrast)
            
        case .grayscale(let grayscale):
            self.init(grayscale: grayscale)
            
        case .colorMonochrome(let colorMonochrome):
            self.init(colorMonochrome: colorMonochrome.color,
                      amount: colorMonochrome.amount,
                      bias: colorMonochrome.bias)
            
        case .luminanceToAlpha:
            self = .luminanceToAlpha
            
        case .colorInvert:
            self = .colorInvert
        }
    }
    
    public static func *(a: _ColorMatrix, b: _ColorMatrix) -> _ColorMatrix {
        
        let m11 = a.m14 * b.m41 + a.m13 * b.m31 + a.m12 * b.m21 + a.m11 * b.m11
        
        let m12 = a.m14 * b.m42 + a.m13 * b.m32 + a.m12 * b.m22 + a.m11 * b.m12
        
        let m13 = a.m14 * b.m43 + a.m13 * b.m33 + a.m12 * b.m23 + a.m11 * b.m13
        
        let m14 = a.m14 * b.m44 + a.m13 * b.m34 + a.m12 * b.m24 + a.m11 * b.m14
        
        let m15 = a.m14 * b.m45 + a.m13 * b.m35 + a.m12 * b.m25 + a.m11 * b.m15 + a.m15
        
        let m21 = a.m24 * b.m41 + a.m23 * b.m31 + a.m22 * b.m21 + a.m21 * b.m11
        
        let m22 = a.m24 * b.m42 + a.m23 * b.m32 + a.m22 * b.m22 + a.m21 * b.m12
        
        let m23 = a.m24 * b.m43 + a.m23 * b.m33 + a.m22 * b.m23 + a.m21 * b.m13
        
        let m24 = a.m23 * b.m34 + a.m24 * b.m44 + a.m22 * b.m24 + a.m21 * b.m14
        
        let m25 = a.m23 * b.m35 + a.m24 * b.m45 + a.m22 * b.m25 + a.m21 * b.m15 + a.m25
        
        let m31 = a.m33 * b.m31 + a.m34 * b.m41 + a.m32 * b.m21 + a.m31 * b.m11
        
        let m32 = a.m33 * b.m32 + a.m34 * b.m42 + a.m32 * b.m22 + a.m31 * b.m12
        
        let m33 = a.m33 * b.m33 + a.m34 * b.m43 + a.m32 * b.m23 + a.m31 * b.m13
        
        let m34 = a.m33 * b.m34 + a.m34 * b.m44 + a.m32 * b.m24 + a.m31 * b.m14
        
        let m35 = a.m34 * b.m45 + a.m33 * b.m35 + a.m32 * b.m25 + a.m31 * b.m15 + a.m35
        
        let m41 = a.m43 * b.m31 + a.m44 * b.m41 + a.m42 * b.m21 + a.m41 * b.m11
        
        let m42 = a.m43 * b.m32 + a.m44 * b.m42 + a.m42 * b.m22 + a.m41 * b.m12
        
        let m43 = a.m43 * b.m33 + a.m44 * b.m43 + a.m42 * b.m23 + a.m41 * b.m13
        
        let m44 = a.m43 * b.m34 + a.m44 * b.m44 + a.m42 * b.m24 + a.m41 * b.m14
        
        let m45 = a.m44 * b.m45 + a.m43 * b.m35 + a.m42 * b.m25 + a.m41 * b.m15 + a.m45
        
        let colorMatrix = _ColorMatrix(m11: m11, m12: m12, m13: m13, m14: m14, m15: m15,
                                       m21: m21, m22: m22, m23: m23, m24: m24, m25: m25,
                                       m31: m31, m32: m32, m33: m33, m34: m34, m35: m35,
                                       m41: m41, m42: m42, m43: m43, m44: m44, m45: m45)
        
        return colorMatrix
    }
    
    internal var isIdentity: Bool {
        self == .identity
    }
    
    internal var floatArray: [Float] {
        [m11, m12, m13, m14, m15,
         m21, m22, m23, m24, m25,
         m31, m32, m33, m34, m35,
         m41, m42, m43, m44, m45]
    }
}


/// A matrix to use in an RGBA color transformation.
///
/// The matrix has five columns, each with a red, green, blue, and alpha
/// component. You can use the matrix for tasks like creating a color
/// transformation ``GraphicsContext/Filter`` for a ``GraphicsContext`` using
/// the ``GraphicsContext/Filter/colorMatrix(_:)`` method.
@frozen
@available(iOS 13.0, *)
public struct ColorMatrix: Equatable {
    
    public var r1: Float = 1, r2: Float = 0, r3: Float = 0, r4: Float = 0, r5: Float = 0
    
    public var g1: Float = 0, g2: Float = 1, g3: Float = 0, g4: Float = 0, g5: Float = 0
    
    public var b1: Float = 0, b2: Float = 0, b3: Float = 1, b4: Float = 0, b5: Float = 0
    
    public var a1: Float = 0, a2: Float = 0, a3: Float = 0, a4: Float = 1, a5: Float = 0
    
    @inlinable
    public init() {
    }
    
    @inline(__always)
    internal func getInternalColorMatrix() -> _ColorMatrix {
        var colorMatrix = _ColorMatrix()
        
        colorMatrix.m11 = r1
        colorMatrix.m12 = r2
        colorMatrix.m13 = r3
        colorMatrix.m14 = r4
        colorMatrix.m15 = r5
        
        colorMatrix.m21 = g1
        colorMatrix.m22 = g2
        colorMatrix.m23 = g3
        colorMatrix.m24 = g4
        colorMatrix.m25 = g5
        
        colorMatrix.m31 = b1
        colorMatrix.m32 = b2
        colorMatrix.m33 = b3
        colorMatrix.m34 = b4
        colorMatrix.m35 = b5
        
        colorMatrix.m41 = a1
        colorMatrix.m42 = a2
        colorMatrix.m43 = a3
        colorMatrix.m44 = a4
        colorMatrix.m45 = a5
        
        return colorMatrix
    }
}
