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

import CoreGraphics
@_spi(DanceUICompose) import DanceUI
import Foundation
import UIKit

@_transparent
internal func withIdentityContainer(_ container: ComposeDisplayListIdentityContainer, canvas: ComposeCanvasImpl, body: (ComposeCanvasImpl) -> Void) {
    let id = Signpost.compose.tracePoiBegin("Canvas:withIdentityContainer", [])
    let oldContainer = canvas.context.identityContainer
    canvas.context.identityContainer = container
    defer { canvas.context.identityContainer = oldContainer }
    body(canvas)
    Signpost.compose.tracePoiEnd(id: id, "Canvas:withIdentityContainer", [])
}

@available(iOS 13, *)
internal final class ComposeCanvasImpl: NSObject {

    public struct CanvasState {
        let effectsCount: Int
        let displayList: DisplayList
        let position: CGPoint
    }

    @inline(__always)
    internal override convenience init() {
        let id = Signpost.compose.tracePoiBegin("Canvas:init", [])
        self.init(context: .init())
        Signpost.compose.tracePoiEnd(id: id, "Canvas:init", [])
    }

    @inline(__always)
    private init(context: ComposeCanvasContext) {
        let id = Signpost.compose.tracePoiBegin("Canvas:initWithContext", [])
        self.context = context
        Signpost.compose.tracePoiEnd(id: id, "Canvas:initWithContext", [])
    }
    
    internal convenience init(_ container: ComposeDisplayListIdentityContainer) {
        let id = Signpost.compose.tracePoiBegin("Canvas:initWithContainer", [])
        let context = ComposeCanvasContext()
        context.identityContainer = container
        self.init(context: context)
        Signpost.compose.tracePoiEnd(id: id, "Canvas:initWithContainer", [])
    }

    @inline(__always)
    var stack: Stack<CanvasState> = .init(capacity: 16)

    fileprivate let context: ComposeCanvasContext
    internal var currentPosition: CGPoint = .zero
    internal var currentSize: CGSize = .zero
    
    internal func reset() {
        stack.reset()
        context.reset()
        currentSize = .zero
        currentPosition = .zero
    }
    
    @inline(__always)
    private func offset(for rect: CGRect) -> CGRect {
        rect.offsetBy(dx: currentPosition.x, dy: currentPosition.y)
    }

    @inline(__always)
    internal var currentResult: DisplayList {
        get { context.result }
        _modify { yield &context.result }
    }
    
    override var description: String {
        var lines: [String] = []
        
        for (index, state) in stack.enumerated() {
            lines.append("- state[\(index)] (effectsCount: \(state.effectsCount), displayList: \(state.displayList.minimalDebugDescription))")
        }
        
        let currentPointer = String(format: "0x%lx", unsafeBitCast(context, to: UInt.self))
        lines.append("- context (\(currentPointer))")
        lines.append("  - result: {\(context.result.minimalDebugDescription)}")
        lines.append("- currentPosition (\(currentPosition))")
        lines.append("- currentSize (\(currentSize))")
        return lines.joined(separator: "\n")
    }
}

@available(iOS 13, *)
extension ComposeCanvasImpl {

    @inline(__always)
    internal func append(_ displayList: DisplayList) {
        Signpost.compose.tracePoi("Canvas:append", []) {
            currentResult.append(contentOf: displayList)
        }
    }
}

@available(iOS 13, *)
extension ComposeCanvasImpl: ComposeCanvas {
    
    internal func saveEffect(_ effect: DisplayList.Effect) {
        context.effects.append(.init(effect: effect,
                                     bounds: CGRect(origin: .zero, size: currentSize),
                                     identity: context.identity))
    }

    internal func save() {
        Signpost.compose.tracePoi("Canvas:save", []) {
            composePrint(.canvas, message: "Canvas save effectsCount: \(context.effects.count)")
            let state = CanvasState(effectsCount: context.effects.count, displayList: context.result, position: currentPosition)
            stack.push(state)
            context.result = .empty
        }
    }

    internal func restore() {
        Signpost.compose.tracePoi("Canvas:restore", []) {
            composePrint(.canvas, message: "Canvas willRestore")
            guard let state = stack.pop() else {
                _danceuiRuntimeIssue(type: .info, "Unbalanced restore call")
                return
            }
            
            var restoredDisplayList = context.result
            let effectsCount = context.effects.count
            let previousEffectsCount = state.effectsCount

            if effectsCount > previousEffectsCount {
                var list = restoredDisplayList
                for index in (previousEffectsCount..<effectsCount).reversed() {
                    if let effectStorage = context.effects[index] {
                        let version = DisplayList.Version.make()
                        var item = DisplayList.Item(
                            frame: CGRect(origin: .zero, size: currentSize),
                            version: version,
                            value: .effect(effectStorage.effect, list),
                            identity: effectStorage.identity
                        )
                        item.canonicalize()
                        list = DisplayList(item: item)
                    }
                }
                restoredDisplayList = list
                context.effects.removeLast(effectsCount - previousEffectsCount)
            }

            var parentDisplayList = state.displayList
            parentDisplayList.append(contentOf: restoredDisplayList)
            context.result = parentDisplayList
            currentPosition = state.position

            composePrint(.canvas, message: "Canvas didRestore. New effects count: \(context.effects.count)")
        }
    }

    internal func saveLayer(withBounds bounds: CGRect, paint: any ComposePaint) {
        preconditionFailure("Unimplemented")
    }

    internal func translate(dx: CGFloat, dy: CGFloat) {
        currentPosition.x += dx.px2pt
        currentPosition.y += dy.px2pt
        composePrint(.canvas, message: "Canvas translate by dx: \(dx) dy: \(dy) -> \(currentPosition)")
    }
    
    internal func resizeLayer(size: CGSize) {
        currentSize = size.px2pt
        composePrint(.canvas, message: "Canvas resize to \(currentSize)")
    }

    internal func scale(sx: CGFloat, sy: CGFloat) {
        Signpost.compose.tracePoi("Canvas.scale", []) {
            let transform = CGAffineTransform(
                translationX: -currentPosition.x,
                y: -currentPosition.y
            )
            .concatenating(.init(scaleX: sx, y: sy))
            .concatenating(.init(translationX: currentPosition.x, y: currentPosition.y))

            saveEffect(.affine(transform))
        }
    }

    internal func rotate(degrees: CGFloat) {
        Signpost.compose.tracePoi("Canvas.rotate", []) {
            let transform = CGAffineTransform(
                translationX: -currentPosition.x,
                y: -currentPosition.y
            )
            .concatenating(.init(rotation: Angle(degrees: degrees)))
            .concatenating(.init(translationX: currentPosition.x, y: currentPosition.y))
            
            saveEffect(.affine(transform))
        }
    }

    internal func concat(matrix: CATransform3D) {
        saveEffect(.projection(.init(matrix.px2pt)))
    }

    internal func setOpacity(_ opacity: CGFloat) {
        saveEffect(.opacity(Float(opacity)))
    }
    
    internal func clipRect(with rect: CGRect, clipOp: ComposeClipOp) {
        saveClipEffect(path: Path(rect.px2pt), clipOp: clipOp)
    }

    internal func clipRect(withLeft left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat, clipOp: ComposeClipOp) {
        let rect = EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right).rect
        saveClipEffect(path: Path(rect.px2pt), clipOp: clipOp)
    }

    internal func clipRoundRect(with rect: CGRect, radiusX: CGFloat, radiusY: CGFloat, clipOp: ComposeClipOp) {
        saveClipEffect(
            path: Path(roundedRect: rect.px2pt, cornerSize: .init(width: radiusX.px2pt, height: radiusY.px2pt)),
            clipOp: clipOp
        )
    }

    internal func clipPath(with path: CGPath, clipOp: ComposeClipOp) {
        saveClipEffect(path: Path(path.px2pt), clipOp: clipOp)
    }

    private func saveClipEffect(path: Path, clipOp: ComposeClipOp) {
        if clipOp == .difference {
            saveEffect(.clip(makeDifferenceClipPath(excluding: path), .init()))
        } else {
            saveEffect(.clip(path, .init()))
        }
        saveEffect(.compositingGroup)
    }

    private func makeDifferenceClipPath(excluding innerPath: Path) -> Path {
        var compound = Path()
        compound.addRect(CGRect(x: -1e5, y: -1e5, width: 2e5, height: 2e5))
        let r = innerPath.boundingRect
            .offsetBy(dx: currentPosition.x, dy: currentPosition.y)
        compound.move(to: CGPoint(x: r.minX, y: r.minY))
        compound.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        compound.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        compound.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        compound.closeSubpath()
        return compound
    }
    
    private func drawShape<S: Shape>(_ shape: S, rect: CGRect, paint: any ComposePaint) {
        drawShape(
            shape,
            rect: rect,
            paint: paint,
            paintStyle: paint.style
        )
    }
    
    private func drawShape<S: Shape>(
        _ shape: S,
        rect: CGRect,
        paint: any ComposePaint,
        paintStyle: ComposePaintingStyle
    ) {
        Signpost.compose.tracePoi("Canvas:drawShape", []) {
            guard paint.supportForRender else {
                composePrint(.canvas, message: "canvas draw shape with unsupported paint")
                return
            }
            
            let rect = rect.px2pt
            let version = DisplayList.Version.make()
                    
            let content = paint.makeShapeContent(shape: shape,
                                                 paintStyle: paintStyle,
                                                 edge: rect.edge,
                                                 in: context.environment,
                                                 seed: .init(version: version))
            
            var item = DisplayList.Item(
                frame: offset(for: rect),
                version: version,
                value: .content(content),
                identity: context.identity
            )
            item.canonicalize()
            
            let displayList = paint.update(DisplayList(item: item), frame: offset(for: rect), seed: .init(version: version))
            append(displayList)
        }
    }

    internal func drawLine(withP1 p1: CGPoint, p2: CGPoint, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawLine", []) {
            let path = Path { p in
                p.addLines([p1.px2pt, p2.px2pt])
            }
            let rect = CGRect(origin: .zero, size: currentSize.pt2px)
            drawShape(path, rect: rect, paint: paint, paintStyle: .stroke)
        }
    }

    internal func drawRect(with rect: CGRect, paint: any ComposePaint) {
        drawShape(Rectangle(), rect: rect, paint: paint)
    }

    internal func drawRect(withLeft left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawRectWithPaint", []) {
            let rect = EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right).rect
            drawShape(Rectangle(), rect: rect, paint: paint)
        }
    }

    internal func drawRoundRect(withLeft left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat, radiusX: CGFloat, radiusY: CGFloat, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawRectWithRadius", []) {
            let rect = EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right).rect
            drawShape(RoundedRectangle(cornerSize: CGSize(width: radiusX.px2pt, height: radiusY.px2pt)), rect: rect, paint: paint)
        }
    }

    internal func drawOval(with rect: CGRect, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawOvalWithRect", []) {
            drawShape(Ellipse(), rect: rect, paint: paint)
        }
    }

    internal func drawOval(withLeft left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawOvalWithEdges", []) {
            let rect = EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right).rect
            drawShape(Ellipse(), rect: rect, paint: paint)
        }
    }

    internal func drawCircle(withCenter center: CGPoint, radius: CGFloat, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawCircle", []) {
            drawShape(Circle(),
                      rect: CGRect(x: center.x - radius,
                                   y: center.y - radius,
                                   width: radius * 2,
                                   height: radius * 2),
                      paint: paint)
        }
    }

    internal func drawArc(with rect: CGRect, startAngle: CGFloat, sweepAngle: CGFloat, useCenter: Bool, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawArcWithRect", []) {
            let arc = ArcShape(startAngle: startAngle / 180.0 * .pi, sweepAngle: sweepAngle / 180.0 * .pi, useCenter: useCenter)
            drawShape(arc, rect: rect, paint: paint)
        }
    }

    internal func drawArc(withLeft left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat, startAngle: CGFloat, sweepAngle: CGFloat, useCenter: Bool, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawCircleWithEdges", []) {
            let arc = ArcShape(startAngle: startAngle / 180.0 * .pi, sweepAngle: sweepAngle / 180.0 * .pi, useCenter: useCenter)
            let rect = EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right).rect
            drawShape(arc, rect: rect, paint: paint)
        }
    }

    internal func drawPath(with path: CGPath, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawPath", []) {
            let shape = Path(path.px2pt)
            drawShape(shape, rect: CGRect(origin: .zero, size: shape.boundingRect.size), paint: paint)
        }
    }

    internal func drawImage(with image: any ComposeImageBitmap, topLeftOffset: CGPoint, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawImage", []) {
            let imageSize = CGSize(width: image.width, height: image.height)
            drawImageRect(with: image, srcOffset: .zero, srcSize: imageSize, dstOffset: topLeftOffset, dstSize: imageSize, paint: paint)
        }
    }
    
    internal func drawImageRect(with image: any ComposeImageBitmap, srcOffset: CGPoint, srcSize: CGSize, dstOffset: CGPoint, dstSize: CGSize, paint: any ComposePaint) {
        Signpost.compose.tracePoi("Canvas:drawImageRect", []) {
            
            guard paint.supportForRender else {
                composePrint(.canvas, message: "canvas draw image with unsupported paint")
                return
            }
            
            let version = DisplayList.Version.make()
            let rect = CGRect(origin: dstOffset, size: dstSize).px2pt
            
            let imageContent: DisplayList.Item.Value? = switch image.type {
            case .uiImage:
                unsafeDowncast(image, to: ComposeImage.self)
                    .content(paint, in: context.environment, seed: .init(version: version))
            case .vector:
                unsafeDowncast(image, to: ComposeVectorImage.self)
                    .content()
            @unknown default:
                nil
            }
            
            guard let imageContent else {
                _danceuiRuntimeIssue(type: .info, "Canvas draw a empty Image")
                return
            }
            
            var item = DisplayList.Item(
                frame: offset(for: rect),
                version: version,
                value: imageContent,
                identity: context.identity
            )
            item.canonicalize()
            
            let displayList = paint.update(DisplayList(item: item), frame: offset(for: rect), seed: .init(version: version), isBitmap: image.type == .uiImage)
            
            append(displayList)
        }
    }
    
    internal func drawPlatformView(_ view: UIView, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, identity: UInt) {
        
        let version = DisplayList.Version.make()
        let rect = CGRect(x:x, y: y, width: width, height: height).px2pt
        
        let factory = ComposePlatformViewFactory(platformView: view)
        
        let uikitContent = DisplayList.Item.Value.content(.init(value: .platformView(factory), seed: .init(version: version)))
        
        var item = DisplayList.Item(
            frame: offset(for: rect),
            version: version,
            value: uikitContent,
            identity: .init(value: UInt32(identity))
        )
        item.canonicalize()
        
        append(DisplayList(item: item))
    }
}


@available(iOS 13.0, *)
extension ComposeCanvasImpl {

    public func scale(sx: CGFloat) {
        scale(sx: sx, sy: sx)
    }

    public func scale(sx: CGFloat, sy: CGFloat, pivotX: CGFloat, pivotY: CGFloat) {
        guard !(sx == 1.0 && sy == 1.0) else { return }
        translate(dx: pivotX, dy: pivotY)
        scale(sx: sx, sy: sy)
        translate(dx: -pivotX, dy: -pivotY)
    }

    public func rotate(degrees: CGFloat, pivotX: CGFloat, pivotY: CGFloat) {
        guard degrees != 0 else { return }
        translate(dx: pivotX, dy: pivotY)
        rotate(degrees: degrees)
        translate(dx: -pivotX, dy: -pivotY)
    }

    public func rotate(radians: CGFloat, pivotX: CGFloat, pivotY: CGFloat) {
        rotate(degrees: Angle(radians: radians).degrees, pivotX: pivotX, pivotY: pivotY)
    }
}

@available(iOS 13.0, *)
internal struct ArcShape: Shape {
    
    internal var startAngle: CGFloat
    internal var sweepAngle: CGFloat
    internal var useCenter: Bool

    internal func path(in rect: CGRect) -> Path {
        Signpost.compose.tracePoi("ArcShape:path", []) {
            var path = Path()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radiusX = rect.width / 2
            let radiusY = rect.height / 2
            let endAngle = startAngle + sweepAngle
            
            path.addEllipticalArc(
                center: center,
                radiusX: radiusX,
                radiusY: radiusY,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            
            if useCenter {
                path.addLine(to: center)
                path.closeSubpath()
            }
            
            return path
        }
    }
}


@available(iOS 13.0, *)
extension Path {
    internal mutating func addEllipticalArc(
        center: CGPoint,
        radiusX: CGFloat,
        radiusY: CGFloat,
        startAngle: CGFloat,
        endAngle: CGFloat,
        clockwise: Bool
    ) {
        Signpost.compose.tracePoi("Path:addEllipticalArc", []) {
            let transform = CGAffineTransform(scaleX: radiusX, y: radiusY)
                .translatedBy(x: center.x / radiusX, y: center.y / radiusY)

            self.addArc(
                center: .zero,
                radius: 1,
                startAngle: Angle(radians: startAngle),
                endAngle: Angle(radians: endAngle),
                clockwise: clockwise,
                transform: transform
            )
        }
    }
}


@available(iOS 13.0, *)
extension ComposeCanvasImpl {

    internal func drawParagraph(_ paragraph: ComposeParagraphImpl, width: CGFloat, color: UIColor, shadow: NSShadow?) {
        Signpost.compose.tracePoi("Canvas:drawParagraph", []) {
            let resolved = paragraph.resolvedStyledText
            resolved.update(color: color, shadow: shadow)
            // Fix the Box fullWidth + align center issue
            resolved._composeAlignFix = true
            let version = DisplayList.Version.make()
            let content = DisplayList.Content(
                value: .text(resolved, paragraph.metrics.size),
                seed: .init(version: version)
            )
            var frame = offset(for: paragraph.bounds)
            frame.size.width = width
            var item = DisplayList.Item(
                frame: frame,
                version: version,
                value: .content(content),
                identity: context.identity
            )
            item.canonicalize()
            append(.init(item: item))
        }
    }
}


private struct ComposePlatformViewFactory: PlatformViewFactory {
    
    let platformView: UIView
    
    fileprivate func makePlatformView() -> UIView {
        platformView
    }
    
    fileprivate func updatePlatformView(_ view: inout UIView) {
        view = platformView
    }
    
    fileprivate func renderPlatformView(in graphicsContext: DanceUI.GraphicsContext, size: CGSize, renderer: DanceUI.DisplayList.GraphicsRenderer) {
        
    }
    
#if DEBUG || DANCE_UI_INHOUSE
    
    fileprivate var viewType: Any.Type = UIView.self
    
    fileprivate func encoding() -> (id: String, data: Codable)? {
        nil
    }
    
#endif
}
