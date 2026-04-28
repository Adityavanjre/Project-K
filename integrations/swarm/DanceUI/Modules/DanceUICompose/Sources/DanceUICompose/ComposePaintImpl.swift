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
@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
internal final class DashPathEffect: NSObject, ComposePathEffect {
    
    internal let intervals: [CGFloat]
    internal let phase: CGFloat
    
    internal init(intervals: [CGFloat], phase: CGFloat) {
        self.intervals = intervals
        self.phase = phase
    }
}

@available(iOS 13.0, *)
internal final class ComposePaintImpl: NSObject, ComposePaint {
    
    internal var alpha: CGFloat = 1.0
    
    internal var isAntiAlias: Bool = true
    
    internal var _color: UIColor = .black

    internal var color: UIColor {
        get {
            guard blendMode == .clear else { return _color }
            return _color.withAlphaComponent(1.0)
        }
        set {
            _color = newValue
        }
    }
    
    internal var blendMode: CGBlendMode = .overlay
    
    internal var style: ComposePaintingStyle = .fill
    
    internal var strokeWidth: CGFloat = 0.0
    
    internal var strokeCap: ComposeStrokeCap = .butt
    
    internal var strokeJoin: ComposeStrokeJoin = .miter
    
    internal var strokeMiterLimit: CGFloat = 4.0
    
    internal var filterQuality: ComposeFilterQuality = .low
    
    internal var shader: (any ComposeShader)? = nil
    
    internal var colorFilter: (any ComposeColorFilter)? = nil
    
    internal var pathEffect: (any ComposePathEffect)? = nil
}

@available(iOS 13.0, *)
extension ComposePaint {
    
    internal func makeShapeContent<S: Shape>(
        shape: S,
        paintStyle: ComposePaintingStyle,
        edge: EdgeInsets,
        in environment: EnvironmentValues,
        seed: DisplayList.Seed
    ) -> DisplayList.Content {
        Signpost.compose.tracePoi("Paint:makeShapeContent", []) {
            if S.self == Rectangle.self, shader == nil, style == .fill, blendMode != .clear {
                let colorResolved = Color.Resolved(color) ?? color.resolve(in: environment)
                return .init(value: .color(colorResolved), seed: seed)
            }
            
            var contentShape = AnyShape(shape)
            if paintStyle == .stroke {
                var stroke = StrokeStyle(lineWidth: strokeWidth.px2pt, lineCap: strokeCap.lineCap, lineJoin: strokeJoin.lineJoin, miterLimit: strokeMiterLimit.px2pt)
                if let dashPathEffect = pathEffect as? DashPathEffect {
                    stroke.dashPhase = dashPathEffect.phase
                    stroke.dash = dashPathEffect.intervals
                }
                contentShape = AnyShape(shape.stroke(style: stroke))
            }
            
            let path = contentShape.path(in: CGRect(origin: .zero,
                                                    size: CGSize(width: edge.trailing - edge.leading,
                                                                 height: edge.bottom - edge.top)
                                                   ))
            
            let content: DisplayList.Content.Value = if let colorFilter, colorFilter.type == .tintColor {
                .shape(path, _AnyResolvedPaint(unsafeDowncast(colorFilter, to: ComposeBlendModeColorFilter.self).color.resolve(in: environment)), fillStyle)
            } else if let gradient = shader?.gradient {
                .shape(path, gradient.makePaint(edge: edge, in: environment), fillStyle)
            } else {
                .shape(path, _AnyResolvedPaint(color.resolve(in: environment)), fillStyle)
            }
            return .init(value: content, seed: seed)
        }
    }
    
    internal var fillStyle: FillStyle {
        .init(antialiased: isAntiAlias)
    }
    
    @inline(__always)
    internal var opacityEffect: DisplayList.Effect? {
        alpha != 1.0 ? .opacity(Float(alpha)) : nil
    }
    
    @inline(__always)
    internal var blendModeEffect: DisplayList.Effect? {
        if blendMode == .clear {
            .blendMode(.blendMode(.destinationOut))
        } else {
            blendMode != .overlay ? .blendMode(.init(blendMode: .init(blendMode))) : nil
        }
    }
    
    @inline(__always)
    internal var supportForRender: Bool {
        return !unsupportedBlendMode.contains(blendMode)
    }
    
    @inline(__always)
    private func updateColorFilter(displayList: DisplayList, frame: CGRect, seed: DisplayList.Seed, isBitmap: Bool) -> DisplayList {
        guard let colorFilter else {
            return displayList
        }
        
        switch colorFilter.type {
        case .tintColor:
            let tintColor = unsafeDowncast(colorFilter, to: ComposeBlendModeColorFilter.self)
            let version = DisplayList.Version.make()
            var item = DisplayList.Item(
                frame: frame,
                version: version,
                value: .content(.init(value: .color(tintColor.color.resolve(in: EnvironmentValues())), seed: seed)),
                identity: .make()
            )
            item.canonicalize()
            
            let effectVersion = DisplayList.Version.make()
            let effet = GraphicsBlendMode.blendMode(.init(rawValue: tintColor.blendMode.rawValue))
            
            item = DisplayList.Item(
                frame: .zero,
                version: effectVersion,
                value: .effect(.blendMode(effet), DisplayList(item: item)),
                identity: .make()
            )
            item.canonicalize()
            
            if isBitmap && tintColor.blendMode != .sourceIn {
                var newDL = displayList
                newDL.items.append(item)
                return newDL.updateEffectIfNeeded(.compositingGroup)
            } else {
                let maskDisplayList = DisplayList(item: item)
                return maskDisplayList.updateEffectIfNeeded(.mask(displayList))
            }
        case .colorMatrix:
            let colorMatrix = unsafeDowncast(colorFilter, to: ComposeColorMatrixColorFilter.self)
            return displayList.updateEffectIfNeeded(colorMatrix.effect)
        case .lighting:
            let lighting = unsafeDowncast(colorFilter, to: ComposeLightingColorFilter.self)
            return displayList.updateEffectIfNeeded(lighting.effect)
        @unknown default:
            return displayList
        }
    }
    
    @inline(__always)
    internal func update(_ display: DisplayList, frame: CGRect, seed: DisplayList.Seed, isBitmap: Bool = false) -> DisplayList {
        updateColorFilter(displayList: display, frame: frame, seed: seed, isBitmap: isBitmap)
            .updateEffectIfNeeded(opacityEffect)
            .updateEffectIfNeeded(blendModeEffect)
    }
}

private let unsupportedBlendMode: [CGBlendMode] = [
    .copy,
    .sourceIn,
    .sourceOut,
    .destinationIn,
    .destinationAtop,
    .xor
]

@available(iOS 13.0, *)
extension DisplayList {
    
    @inline(__always)
    internal func updateEffectIfNeeded(_ effect: Effect?) -> DisplayList {
        Signpost.compose.tracePoi("DisplayList:updateEffectIfNeeded", []) {
            guard let effect else {
                return self
            }
            var item = DisplayList.Item(frame: .zero,
                                        version: .make(),
                                        value: .effect(effect, self),
                                        identity: .make())
            item.canonicalize()
            return DisplayList(item: item)
        }
    }
}

extension ComposeStrokeCap {
    
    internal var lineCap: CGLineCap {
        switch self {
        case .butt:
                .butt
        case .round:
                .round
        case .square:
                .square
        @unknown default:
                .butt
        }
    }
}

extension ComposeStrokeJoin {
    
    internal var lineJoin: CGLineJoin {
        switch self {
        case .miter:
                .miter
        case .round:
                .round
        case .bevel:
                .bevel
        @unknown default:
                .miter
        }
    }
}

@available(iOS 13.0, *)
extension ComposeFilterQuality {
    
    internal var interpolation: Image.Interpolation {
        switch self {
        case .none:
                .none
        case .low:
                .low
        case .medium:
                .medium
        case .high:
                .high
        @unknown default:
                .none
        }
    }
}


@available(iOS 13.0, *)
extension EdgeInsets {
    internal var rect: CGRect {
        CGRect(x: leading, y: top, width: trailing - leading, height: bottom - top)
    }
}


@available(iOS 13.0, *)
extension CGRect {
    internal var edge: EdgeInsets {
        EdgeInsets(top: minY, leading: minX, bottom: maxY, trailing: maxX)
    }
    
    internal init(p1: CGPoint, p2: CGPoint) {
        let x = min(p1.x, p2.x)
        let y = min(p1.y, p2.y)
        
        let width = max(p1.x, p2.x) - x
        let height = max(p1.y, p2.y) - y

        self.init(x: x, y: y, width: width, height: height)
    }
}
