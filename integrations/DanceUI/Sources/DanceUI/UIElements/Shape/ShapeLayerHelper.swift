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
import Foundation

@available(iOS 13.0, *)
internal struct ShapeLayerHelper: ResolvedPaintVisitor {
    
    internal var layer: CALayer
    
    internal var layerType: CALayer.Type
    
    internal var path: Path
    
    internal var origin: CGPoint
    
    internal var paint: AnyResolvedPaint
    
    internal var paintBounds: CGRect
    
    internal var style: FillStyle
    
    internal var contentsScale: CGFloat
    
    internal var hasShadow: Bool
    
    internal static func layerType(_ path: Path, _ paint: AnyResolvedPaint, hasShadow: Bool) -> CALayer.Type {
        let shapeType = ShapeType(path)
        var visitor = Visitor(shapeType: shapeType, hasShadow: hasShadow)
        paint.visit(&visitor)
        return visitor.layerType!
        
    }
    
    internal mutating func visitPaint<Paint: ResolvedPaint>(_ paint: Paint) {
        let shapeType = ShapeType(path)
        let paintType = PaintType(paint)
        let layerType = contentLayerType(shapeType,
                                         paintType: paintType,
                                         hasShadow: hasShadow)
        if self.layerType != layerType {
            self.layerType = layerType
        } else {
            self.layer.allowsEdgeAntialiasing = self.style.isAntialiased
            switch (shapeType, paintType) {
            case (.rectBorder(_, let radius, let style, let lineWidth), .color(let resolved)):
                layer.backgroundColor = nil
                layer.borderWidth = lineWidth
                layer.borderColor = resolved.cgColor
                layer.contents = nil
                layer.cornerRadius = radius
                let isContinuous = (style == .continuous) ? true : false
                layer.my_setContinuousCorners(isContinuous)
                if #available(iOS 13.0, *) {
                    layer.cornerCurve = style.cornerCurve
                } else {
                    // Fallback on earlier versions
                }
            case (.rect(_, let radius, let style), .color(let resolved)):
                layer.backgroundColor = resolved.cgColor
                layer.borderColor = nil
                layer.borderWidth = 0
                layer.contents = nil
                layer.cornerRadius = radius
                let isContinuous = (style == .continuous) ? true : false
                layer.my_setContinuousCorners(isContinuous)
                if #available(iOS 13.0, *) {
                    layer.cornerCurve = style.cornerCurve
                } else {
                    // Fallback on earlier versions
                }
            case (.rect(let rect, let radius, let style), .linearGradient(let resolved)):
                
                let gradientLayer = findGradientLayer()
                updateGradientLayer(gradientLayer: gradientLayer,
                                    gradient: resolved.gradient,
                                    gradientFunction: .axial(startPoint: resolved.startPoint, endPoint: resolved.endPoint),
                                    pathSize: rect.size,
                                    radius: radius,
                                    style: style)
                
            case (.rect(let rect, let radius, let style), .radialGradient(let resolved)):
                
                let gradientLayer = findGradientLayer()
                updateGradientLayer(gradientLayer: gradientLayer,
                                    gradient: resolved.gradient,
                                    gradientFunction: .radial(center: resolved.center, startRadius: resolved.startRadius, endRadius: resolved.endRadius),
                                    pathSize: rect.size,
                                    radius: radius,
                                    style: style)
                
            case (.rect(let rect, let radius, let style), .angularGradient(let resolved)):
                
                guard #available(iOS 12.0, *) else {
                    updatePaintShapeLayer(layer: self.layer)
                    return
                }
                
                let gradientLayer = findGradientLayer()
                let conicGradient = ConicGradient(paint: resolved, bounds: .init(x: 0, y: 0, width: 1, height: 1))
                updateGradientLayer(gradientLayer: gradientLayer,
                                    gradient: conicGradient.gradient,
                                    gradientFunction: .conic(center: resolved.center, angle: conicGradient.angle),
                                    pathSize: rect.size,
                                    radius: radius,
                                    style: style)
            
            case (.rect(let rect, let radius, let style), .ellipticalGradient(let resolved)):
                let gradientLayer = findGradientLayer()
                updateGradientLayer(gradientLayer: gradientLayer,
                                    gradient: resolved.gradient,
                                    gradientFunction: .elliptical(center: resolved.center,
                                                                  startRadiusFraction: resolved.startRadiusFraction,
                                                                  endRadiusFraction: resolved.endRadiusFraction),
                                    pathSize: rect.size,
                                    radius: radius,
                                    style: style)
                
            case (.empty, .color(let color)):
                
                guard let colorShapeLayer = layer as? ColorShapeLayer else {
                    _danceuiFatalError("Layer Type must be ColorShapeLayer")
                }
                
                updateContent(shapeLayer: colorShapeLayer,
                              color: color,
                              path: path,
                              origin: origin,
                              eoFill: style.isEOFilled)
                
            case (.empty, .linearGradient),
                (.empty, .radialGradient),
                (.empty, .angularGradient),
                (.empty, .ellipticalGradient),
                (.strokedPath, .linearGradient),
                (.strokedPath, .radialGradient),
                (.strokedPath, .angularGradient),
                (.strokedPath, .ellipticalGradient),
                (.rectBorder, .linearGradient),
                (.rectBorder, .radialGradient),
                (.rectBorder, .angularGradient),
                (.rectBorder, .ellipticalGradient),
                (.rect, .other),
                (.rectBorder, .other),
                (.strokedPath, .other),
                (.empty, .other):
                updatePaintShapeLayer(layer: layer)
                
            case (.strokedPath(let path, let startPoint, let endPoint, let style), .color(let color)):
                guard let colorShapeLayer = layer as? ColorShapeLayer else {
                    _danceuiFatalError("Layer Type must be ColorShapeLayer")
                }
                
                updateContent(shapeLayer: colorShapeLayer,
                              color: color,
                              strokedPath: path,
                              origin: origin,
                              start: startPoint,
                              end: endPoint,
                              style: style)
            case (.other, _):
                break
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension ShapeLayerHelper {
    
    fileprivate struct Visitor: ResolvedPaintVisitor {
        
        var shapeType: ShapeType
        
        var hasShadow: Bool
        
        var layerType: CALayer.Type?
        
        internal mutating func visitPaint<Paint: ResolvedPaint>(_ paint: Paint) {
            let paintType = PaintType(paint)
            let layerType = contentLayerType(shapeType, paintType: paintType, hasShadow: hasShadow)
            self.layerType = layerType
        }
    }
    
    @inline(__always)
    private func findGradientLayer() -> GradientLayer {
        
        var targetLayer: GradientLayer? = nil
        
        if hasShadow {
            guard let shadowGradientLayer = layer as? ShadowGradientLayer else {
                _danceuiFatalError("Layer Type must be ShadowGradientLayer")
            }
            
            targetLayer = shadowGradientLayer.gradientLayer
        } else {
            guard let gradientLayer = layer as? GradientLayer else {
                _danceuiFatalError("Layer Type must be GradientLayer")
            }
            
            targetLayer = gradientLayer
        }
        
        guard let gradientLayer = targetLayer else {
            _danceuiFatalError("GradientLayer is nil")
        }
        
        return gradientLayer
    }
    
    @inline(__always)
    private func updateGradientLayer(gradientLayer: GradientLayer,
                                     gradient: ResolvedGradient,
                                     gradientFunction: GradientLayer.Function,
                                     pathSize: CGSize,
                                     radius: CGFloat,
                                     style: RoundedCornerStyle) {
        gradientLayer.cornerRadius = radius
        let isContinuous = (style == .continuous) ? true : false
        gradientLayer.my_setContinuousCorners(isContinuous)
        gradientLayer.update(gradient: gradient, function: gradientFunction, size: pathSize, bounds: paintBounds)
    }
    
    @inline(__always)
    private func updatePaintShapeLayer(layer: CALayer) {
        guard let paintShapeLayer = layer as? PaintShapeLayer else {
            _danceuiFatalError("Layer Type must be PaintShapeLayer")
        }
        
        updateContent(shapeLayer: paintShapeLayer, path: self.path, origin:self.origin, paint: self.paint, paintBounds: self.paintBounds, style: self.style, contentScale: self.contentsScale)
    }
}

@available(iOS 13.0, *)
fileprivate func updateContent(shapeLayer: PaintShapeLayer,
                               path: Path,
                               origin: CGPoint,
                               paint: AnyResolvedPaint,
                               paintBounds: CGRect,
                               style: FillStyle,
                               contentScale: CGFloat) {
    shapeLayer.path = path
    shapeLayer.origin = origin
    shapeLayer.paint = paint
    shapeLayer.paintBounds = paintBounds
    shapeLayer.fillStyle = style
    shapeLayer.contentsScale = contentScale
    shapeLayer.setNeedsDisplay()
}

@available(iOS 13.0, *)
fileprivate func updateContent(shapeLayer: ColorShapeLayer,
                               color: Color.Resolved,
                               strokedPath: Path,
                               origin: CGPoint,
                               start: CGFloat,
                               end: CGFloat,
                               style: StrokeStyle) -> () {
    var layerPath = strokedPath
    
    if origin != .zero {
        let transform = CGAffineTransform(translationX: -origin.x, y: -origin.y)
        layerPath = strokedPath.applying(transform)
    }
    
    let cgPath = layerPath.cgPath
    
    shapeLayer.path = cgPath
    
    let strokeColor = color.cgColor
    
    shapeLayer.fillColor = nil
    
    shapeLayer.strokeColor = strokeColor
    
    shapeLayer.strokeStart = start
    
    shapeLayer.strokeEnd = end
    
    shapeLayer.lineWidth = style.lineWidth
    
    shapeLayer.miterLimit = style.miterLimit
    
    shapeLayer.lineCap = style.lineCap.caLineCap
    
    shapeLayer.lineJoin = style.lineJoin.caLineJoin
    
    shapeLayer.lineDashPhase = style.dashPhase
    
    shapeLayer.lineDashPattern = style.dash.map({ dashValue -> NSNumber in
        NSNumber(value: dashValue)
    })
}

@available(iOS 13.0, *)
fileprivate func updateContent(shapeLayer: ColorShapeLayer ,
                               color: Color.Resolved,
                               path: Path,
                               origin: CGPoint,
                               eoFill: Bool) -> () {
    var layerPath = path
    
    if origin.x != 0 || origin.y != 0 {
        let transform = CGAffineTransform(translationX: -origin.x, y: -origin.y)
        layerPath = path.applying(transform)
    }
    
    let cgPath = layerPath.cgPath
    
    shapeLayer.path = cgPath
    
    let fillColor = color.cgColor
    
    shapeLayer.fillColor = fillColor
    
    let fillRule: CAShapeLayerFillRule = eoFill ? .evenOdd : .nonZero
    
    shapeLayer.fillRule = fillRule
    
    shapeLayer.strokeColor = nil
}

@available(iOS 13.0, *)
fileprivate func contentLayerType(_ shapeType: ShapeType,
                                  paintType: PaintType,
                                  hasShadow: Bool) -> CALayer.Type {
    
    switch shapeType {
    case .rectBorder:
        switch paintType {
        case .color:
            return CALayer.self
        default:
            return PaintShapeLayer.self
        }
    case .strokedPath:
        guard case .color = paintType else {
            return PaintShapeLayer.self
        }
        
        return ColorShapeLayer.self
    case .rect(_, radius: _, style: _):
        switch paintType {
        case .color(_):
            return CALayer.self
        case .linearGradient(_):
            return hasShadow ? ShadowGradientLayer.self : GradientLayer.self
        case .radialGradient(_):
            return hasShadow ? ShadowGradientLayer.self : GradientLayer.self
        case .ellipticalGradient(_):
            return hasShadow ? ShadowGradientLayer.self : GradientLayer.self
        case .angularGradient(_):
            guard #available(iOS 12.0, *) else {
                return hasShadow ? ShadowGradientLayer.self : PaintShapeLayer.self
            }
            return hasShadow ? ShadowGradientLayer.self : GradientLayer.self
        case .other:
            return PaintShapeLayer.self
        }
    case .empty:
        switch paintType {
        case .color(_):
            return ColorShapeLayer.self
        case .linearGradient(_), .radialGradient(_), .ellipticalGradient(_), .angularGradient(_), .other:
            return PaintShapeLayer.self
        }
    case .other:
        return CALayer.self
    }
    
}

@available(iOS 13.0, *)
internal final class ShadowGradientLayer: CALayer {
    
    internal override init() {
        super.init()
        let gradientLayer = GradientLayer()
        sublayers = [gradientLayer]
    }
    
    internal var gradientLayer: GradientLayer {
        guard let subLayers = sublayers,
              subLayers.count > 0 else {
            _danceuiFatalError("ShadowGradientLayer subLayers empty.")
        }
        
        var targetLayer: GradientLayer? = nil
        
        subLayers.forEach { layer in
            if let gLayer = layer as? GradientLayer {
                targetLayer = gLayer
            }
        }
        
        guard let gradientLayer = targetLayer else {
            _danceuiFatalError("ShadowGradientLayer subLayers not contains GradientLayer.")
        }
        
        return gradientLayer
    }
    
    internal override func layoutSublayers() {
        gradientLayer.frame = bounds
    }
    
    internal required init?(coder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.0, *)
extension CGLineCap {
    
    internal var caLineCap: CAShapeLayerLineCap {
        switch self {
        case .butt:
            return .butt
        case .round:
            return .round
        case .square:
            return .square
        @unknown default:
            _danceuiFatalError()
        }
    }
}

@available(iOS 13.0, *)
extension CGLineJoin {
    
    internal var caLineJoin: CAShapeLayerLineJoin {
        switch self {
        case .miter:
            return .miter
        case .round:
            return .round
        case .bevel:
            return .bevel
        @unknown default:
            _danceuiFatalError()
        }
    }
}
