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
internal struct ShapeLayerShadowHelper: ResolvedPaintVisitor {
    
    internal var layer: CALayer
    
    internal var path: Path
    
    internal var offset: CGPoint
    
    internal var shadow: ResolvedShadowStyle
    
    internal var updateShape: Bool
    
    internal func visitPaint<Paint>(_ paint: Paint) where Paint : ResolvedPaint {
        let shapeType = ShapeType(path)
        let paintType = PaintType(paint)
        
        switch (shapeType, paintType) {
        case (.empty, .color),
             (.rectBorder, .color),
             (.strokedPath,.color),
             (.other, .color):
            
            var shadowPath = path
            
            if offset.x != 0 || offset.y != 0 {
                let transform = CGAffineTransform.init(translationX: -offset.x, y: -offset.y)
                shadowPath = path.applying(transform)
            }
            
            layer.shadowPath = shadowPath.cgPath
            layer.updateShadowStyle(style: shadow)
            if updateShape {
                layer.cornerRadius = 0
            }
            
        case (.rect(_, let radius, let style), .color(let color)):
            var shadowStyle = shadow
            shadowStyle.color.opacity = shadowStyle.color.opacity * color.opacity
            layer.my_setShadowPathIsBounds(true)
            layer.shadowPath = nil
            layer.updateShadowStyle(style: shadowStyle)
            if updateShape {
                layer.cornerRadius = radius
                let isContinuous = (style == .continuous) ? true : false
                layer.my_setContinuousCorners(isContinuous)
            }
        
        case (.rect(_, let radius, let style), .linearGradient(let resolved)):
            
            updateGradientLayerShadow(with: radius, style: style, resolved: resolved)
            
        case (.rect(_, let radius, let style), .radialGradient(let resolved)):
            
            updateGradientLayerShadow(with: radius, style: style, resolved: resolved)
            
        case (.rect(_, let radius, let style), .angularGradient(let resolved)):
            
            updateGradientLayerShadow(with: radius, style: style, resolved: resolved)
            
        case (.rect(_, let radius, let style), .ellipticalGradient(let resolved)):
            
            updateGradientLayerShadow(with: radius, style: style, resolved: resolved)
            
        case (.rect(_, let radius, let style), .other):
            layer.my_setShadowPathIsBounds(false)
            layer.shadowPath = nil
            layer.updateShadowStyle(style: shadow)
            if updateShape {
                layer.cornerRadius = radius
                let isContinuous = (style == .continuous) ? true : false
                layer.my_setContinuousCorners(isContinuous)
            }
            
        case (.rectBorder, .linearGradient),
            (.rectBorder, .radialGradient),
            (.rectBorder, .angularGradient),
            (.rectBorder, .ellipticalGradient),
            (.strokedPath, .linearGradient),
            (.strokedPath, .radialGradient),
            (.strokedPath, .angularGradient),
            (.strokedPath, .ellipticalGradient),
            (.empty, .linearGradient),
            (.empty, .radialGradient),
            (.empty, .angularGradient),
            (.empty, .ellipticalGradient),
            (.rectBorder, .other),
            (.strokedPath, .other),
            (.empty, .other):
            
            updateCommonLayerShadow()
            
        case (.other, _):
            layer.shadowOpacity = 0
        }
    }
    
    @inline(__always)
    private func updateCommonLayerShadow() {
        layer.my_setShadowPathIsBounds(false)
        layer.shadowPath = nil
        layer.updateShadowStyle(style: shadow)
        if updateShape {
            layer.cornerRadius = 0
        }
    }
    
    @inline(__always)
    private func updateGradientLayerShadow<ResolvedType: ResolvedPaint>(with radius: CGFloat,
                                                                        style: RoundedCornerStyle,
                                                                        resolved: ResolvedType) {
        guard let shadowGradientLayer = layer as? ShadowGradientLayer else {
            _danceuiFatalError("Layer Type must be ShadowGradientLayer")
        }
        
        shadowGradientLayer.my_setShadowPathIsBounds(resolved.isOpaque)
        let gradientLayer = shadowGradientLayer.gradientLayer
        shadowGradientLayer.cornerRadius = gradientLayer.cornerRadius
        let isContinuousCorners = gradientLayer.my_continuousCorners()
        shadowGradientLayer.my_setContinuousCorners(isContinuousCorners)
        shadowGradientLayer.updateShadowStyle(style: shadow)
        if updateShape {
            shadowGradientLayer.cornerRadius = radius
            let isContinuous = (style == .continuous) ? true : false
            shadowGradientLayer.my_setContinuousCorners(isContinuous)
        }
    }
}
