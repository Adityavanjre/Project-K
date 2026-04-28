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

import MyShims
@available(iOS 13.0, *)
internal struct RenderBoxWarpper {

    internal let cgContext: CGContext

    internal var environments: EnvironmentValues

    internal var shading: GraphicsContext.ResolvedShading

    internal init(cgContext: CGContext,
                  environments: EnvironmentValues) {
        self.cgContext = cgContext
        self.environments = environments
        self.shading = .color(Color.Resolved())
    }

    internal var transform: CGAffineTransform {

        set {
            MyCGContextSetCTM(cgContext, newValue)
        }

        get {
            cgContext.ctm
        }
    }

    internal var blendMode: GraphicsContext.BlendMode {
        set {
            if let cgBlendMode = CGBlendMode(rawValue: newValue.rawValue) {
                cgContext.setBlendMode(cgBlendMode)
            }
        }

        get {
            GraphicsContext.BlendMode(rawValue: cgContext.blendMode.rawValue)
        }
    }

    internal var clipBoundingRect: CGRect {
        cgContext.boundingBoxOfClipPath
    }

    internal mutating func scaleBy(x: CGFloat, y: CGFloat) {
        guard x != 0 || y != 0 else {
            return
        }
        cgContext.scaleBy(x: x, y: y)
    }

    internal mutating func translateBy(x: CGFloat, y: CGFloat) {
        guard x != 0 || y != 0 else {
            return
        }
        cgContext.translateBy(x: x, y: y)
    }

    internal mutating func rotate(by angle: Angle) {
        guard angle.radians > 0 else {
            return
        }

        cgContext.rotate(by: angle.radians)
    }

    internal mutating func concatenate(_ matrix: CGAffineTransform) {
        guard matrix != .identity else {
            return
        }

        cgContext.concatenate(matrix)
    }

    internal mutating func clip(to path: Path,
                                style: FillStyle,
                                options: GraphicsContext.ClipOptions) {
        let cgPath = path.cgPath
        cgContext.beginPath()
        cgContext.addPath(cgPath)

        if !style.isAntialiased {
            cgContext.setShouldAntialias(false)
        }

        cgContext.clip(using: style.isEOFilled ? .evenOdd : .winding)

        if style.isAntialiased {
            cgContext.setShouldAntialias(true)
        }
    }

    internal mutating func addFilter(_ filter: GraphicsContext.Filter,
                                     options: GraphicsContext.FilterOptions) {
        switch filter.storage {
        case .shadow((let color, let radius, let offset, _, _)):
            let cgColor = color.resolvedCGColor(in: environments)
            cgContext.setShadow(offset: offset, blur: radius * 2, color: cgColor)
            MyCGContextSetBaseCTM(cgContext, cgContext.ctm)
        default:
            break
        }
    }

    internal mutating func addFilter(_ filter :GraphicsFilter, in rect :CGRect) {
        switch filter {
        case .shadow(let resolvedShadowStyle):
            let cgColor = resolvedShadowStyle.color.resolve(in: environments).cgColor
            cgContext.setShadow(offset: resolvedShadowStyle.offset, blur: resolvedShadowStyle.radius * 2, color: cgColor)
            MyCGContextSetBaseCTM(cgContext, cgContext.ctm)
        default:
            break
        }
    }

    internal func withCGContext(content: (CGContext) throws -> Void) rethrows {
        cgContext.saveGState()
        try content(cgContext)
        cgContext.restoreGState()
    }

    internal func withPlatformContext(content: () -> ()) -> () {
        UIGraphicsPushContext(cgContext)
        defer {
            UIGraphicsPopContext()
        }
        content()
    }

    internal mutating func fill(_ path: Path,
                       with resolvedShading: GraphicsContext.ResolvedShading,
                       style: FillStyle = FillStyle()) {

        self.shading = resolvedShading
        let storage = path.storage

        switch storage {
        case .rect(let rect):
            fill(rect, style: style)

        case .ellipse(let rect):
            fillEllipse(rect, style: style)

        case .roundedRect(let fixedRoundedRect):
            fill(fixedRoundedRect, style: style)

        case .stroked(let strokePath):
            stroke(strokePath.path, strokeStyle: strokePath.style, fillStyle: style)

        case .path,
             .trimmed:
            cgContext.beginPath()
            cgContext.addPath(path.cgPath)
            fillPath(style: style)

        case .empty:
            break
        }
    }
}

@available(iOS 13.0, *)
extension RenderBoxWarpper {

    fileprivate func stroke(_ path: Path,
                            strokeStyle: StrokeStyle,
                            fillStyle: FillStyle) {
        switch path.storage {

        case .rect(let rect):
            stroke(rect, strokeStyle: strokeStyle, fillStyle: fillStyle)

        case .ellipse(let rect):
            strokeEllipse(in: rect, strokeStyle: strokeStyle, fillStyle: fillStyle)

        case .roundedRect(let fixedRounedRect):
            stroke(fixedRounedRect, strokeStyle: strokeStyle, fillStyle: fillStyle)

        case .path, .trimmed, .stroked:
            cgContext.beginPath()
            cgContext.addPath(path.cgPath)
            strokePath(strokeStyle: strokeStyle, fillStyle: fillStyle)

        case .empty:
            break
        }
    }

    fileprivate func stroke(_ rect: CGRect,
                            strokeStyle: StrokeStyle,
                            fillStyle: FillStyle) {
        if case .color(let resolvedColor) = shading {
            withStrokeStyle(strokeStyle: strokeStyle, fillStyle: fillStyle) {
                let cgColor = resolvedColor.cgColor
                cgContext.setStrokeColor(cgColor)
                cgContext.stroke(rect)
            }
        } else {
            let rectPath = CGPath(rect: rect, transform: nil)
            cgContext.beginPath()
            cgContext.addPath(rectPath)
            strokePath(strokeStyle: strokeStyle, fillStyle: fillStyle)
        }
    }

    fileprivate func strokeEllipse(in rect: CGRect,
                                   strokeStyle: StrokeStyle,
                                   fillStyle: FillStyle) {
        let ellipsePath = CGPath(ellipseIn: rect, transform: nil)
        cgContext.beginPath()
        cgContext.addPath(ellipsePath)
        strokePath(strokeStyle: strokeStyle, fillStyle: fillStyle)
    }

    fileprivate func stroke(_ fixedRoundedRect: FixedRoundedRect,
                            strokeStyle: StrokeStyle,
                            fillStyle: FillStyle) {
        guard fixedRoundedRect.cornerSize != .zero else {
            stroke(fixedRoundedRect.rect, strokeStyle: strokeStyle, fillStyle: fillStyle)
            return
        }

        cgContext.setPath(fixedRoundedRect: fixedRoundedRect)
        strokePath(strokeStyle: strokeStyle, fillStyle: fillStyle)
    }

    fileprivate func strokePath(strokeStyle: StrokeStyle,
                                fillStyle: FillStyle) {
        withStrokeStyle(strokeStyle: strokeStyle, fillStyle: fillStyle) {
            if case .color(let resolvedColor) = shading {
                let cgColor = resolvedColor.cgColor
                cgContext.setStrokeColor(cgColor)
                cgContext.strokePath()
            } else {
                cgContext.replacePathWithStrokedPath()
                cgContext.clip(using: .winding)
                shading.draw(in: self.cgContext)
            }
        }
    }

    fileprivate func withStrokeStyle(strokeStyle: StrokeStyle,
                                     fillStyle: FillStyle,
                                     body: () -> Void) {
        cgContext.saveGState()
        cgContext.setShouldAntialias(fillStyle.isAntialiased)
        cgContext.setLineWidth(strokeStyle.lineWidth)
        cgContext.setLineJoin(strokeStyle.lineJoin)
        cgContext.setLineCap(strokeStyle.lineCap)
        cgContext.setMiterLimit(strokeStyle.miterLimit)
        if !strokeStyle.dash.isEmpty {
            cgContext.setLineDash(phase: strokeStyle.dashPhase, lengths: strokeStyle.dash)
        }
        body()
        cgContext.restoreGState()
    }
}

@available(iOS 13.0, *)
extension RenderBoxWarpper {

    fileprivate func fill(_ rect: CGRect, style: FillStyle) {

        if case .color(let solidColor) = self.shading {
            withFillStyle(style) {
                let fillColor = solidColor.cgColor
                cgContext.setFillColor(fillColor)
                cgContext.fill(rect)
            }
        } else {
            let path: CGPath = .init(rect: rect, transform: nil)
            cgContext.beginPath()
            cgContext.addPath(path)
            fillPath(style: style)
        }
    }

    fileprivate func fill(_ rect: FixedRoundedRect, style: FillStyle) {

        guard rect.cornerSize != .zero else {
            fill(rect.rect, style: style)
            return
        }

        cgContext.setPath(fixedRoundedRect: rect)
        fillPath(style: style)
    }

    fileprivate func fillEllipse(_ rect: CGRect, style: FillStyle) {
        let path = CGPath.init(ellipseIn: rect, transform: nil)
        cgContext.beginPath()
        cgContext.addPath(path)
        fillPath(style: style)
    }

    fileprivate func fillPath(style: FillStyle) {
        withFillStyle(style) {
            if case .color(let solidColor) = self.shading {
                let fillColor = solidColor.cgColor
                cgContext.setFillColor(fillColor)
                cgContext.drawPath(using: .eoFill)
            } else {
                cgContext.saveGState()
                let fillRule: CGPathFillRule = style.isEOFilled ? .evenOdd : .winding
                cgContext.clip(using: fillRule)
                self.shading.draw(in: self.cgContext)
                cgContext.restoreGState()
            }
        }
    }

    fileprivate func withFillStyle(_ style: FillStyle, body: () -> Void) {
        let isAntialiased = style.isAntialiased
        if !isAntialiased {
            cgContext.setShouldAntialias(false)
        }
        defer {
            if !isAntialiased {
                cgContext.setShouldAntialias(true)
            }
        }
        body()
    }

}

@available(iOS 13.0, *)
extension GraphicsContext.ResolvedShading {

    fileprivate func draw(in context: CGContext) {
        switch self {

        case .color(let resolvedColor):
            let cgColor = resolvedColor.cgColor
            context.setFillColor(cgColor)
            context.fill(.infinite)

        case .gradient((let resolvedGradient, let gradientType, _)):
            drawGradient(with: gradientType,
                         resolvedGradient: resolvedGradient,
                         context: context)
        }
    }

    @inline(__always)
    fileprivate func drawGradient(with type: GraphicsContext.GradientGeometry,
                                  resolvedGradient: ResolvedGradient,
                                  context: CGContext) {
        switch type {

        case .axial((let startPoint, let endPoint)):
            let cgGradient = resolvedGradient.cgGradient
            guard let cgGradientValue = cgGradient else {
                _danceuiFatalError("CGGradient is nil.")
            }
            context.drawLinearGradient(cgGradientValue,
                                       start: startPoint,
                                       end: endPoint,
                                       options: .drawsBothStartAndEndLocation)

        case .radial((let center, let startRadius, let endRadius)):
            let cgGradient = resolvedGradient.cgGradient
            guard let cgGradientValue = cgGradient else {
                _danceuiFatalError("CGGradient is nil.")
            }
            context.drawRadialGradient(cgGradientValue,
                                       startCenter: center,
                                       startRadius: startRadius,
                                       endCenter: center,
                                       endRadius: endRadius,
                                       options: .drawsBothStartAndEndLocation)

        case .conic((let center, let angle)):
            let cgGradient = resolvedGradient.cgGradient
            guard let cgGradientValue = cgGradient else {
                _danceuiFatalError("CGGradient is nil.")
            }
            MyCGContextDrawConicGradient(context,
                                              cgGradientValue,
                                              center,
                                              angle.radians)

        case .elliptical((let rect, let startRadiusFraction, let endRadiusFraction)):
            let cgGradient = resolvedGradient.cgGradient
            guard let cgGradientValue = cgGradient else {
                _danceuiFatalError("CGGradient is nil.")
            }

            context.concatenate(CGAffineTransform(a: rect.width, b: 0, c: 0, d: rect.height, tx: rect.origin.x, ty: rect.origin.y))
            context.drawRadialGradient(cgGradientValue,
                                       startCenter: .zero,
                                       startRadius: startRadiusFraction,
                                       endCenter: .zero,
                                       endRadius: endRadiusFraction,
                                       options: .drawsBothStartAndEndLocation)
        }
    }
}

@available(iOS 13.0, *)
extension CGContext {

    fileprivate func setPath(fixedRoundedRect: FixedRoundedRect) {
        beginPath()
        addPath(fixedRoundedRect.cgPath)
    }
}

@available(iOS 13.0, *)
extension CGGradientDrawingOptions {

    internal static var drawsBothStartAndEndLocation: CGGradientDrawingOptions {
        CGGradientDrawingOptions(rawValue: 0x3)
    }
}
