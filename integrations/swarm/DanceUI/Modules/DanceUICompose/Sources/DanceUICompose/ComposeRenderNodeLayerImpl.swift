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

@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
internal final class ComposeGraphicsLayerScopeImpl: NSObject, ComposeGraphicsLayerScope {
    
    internal var alpha: CGFloat = 1.0
    
    internal var alphaChanged: Bool = false

    internal var tranformChanged: Bool = false
    
    internal var clipChanged: Bool = false
}

@available(iOS 13.0, *)
internal final class ComposeRenderNodeLayerImpl: NSObject, ComposeRenderNodeLayer {
    
    internal var isItemRoot: Bool
    
    internal var position: CGPoint = .zero
    
    internal var size: CGSize = .zero
    
    internal var alpha: LayerProperty<CGFloat> = .init(value: 1)
    
    private var isDirty = true
    
    internal lazy var canvasRecoder = ComposeCanvasImpl()
    
    internal var transfrom: ProjectionTransform = ProjectionTransform()
    
    private let contentIdentifierContainer: ComposeDisplayListIdentityContainer = .init()
    
    private let alphaIdentifier = ComposeDisplayListIdentityContainer()
    private let transform3DIdentifier = DisplayList.Identity.make()
    private let layerIdentifier = DisplayList.Identity.make()
    
    private var lastDisplayList = DisplayList.empty
    
    private var layerVersion = DisplayList.Version.make()
    private var layerChanged = true
    
    private var transformVersion = DisplayList.Version.make()
    private var transformChanged = true
    
    private var positionChanged = true
    
    private var clipVersion: DisplayList.Version = .make()
    
    internal init(isItemRoot: Bool = false) {
        let id = Signpost.compose.tracePoiBegin("RenderNodeLayer:init", [])
        self.isItemRoot = isItemRoot
        Signpost.compose.tracePoiEnd(id: id, "RenderNodeLayer:init", [])
    }
    
    internal func destroy() {
        Signpost.compose.tracePoi("RenderNodeLayer:destory", []) {
            isDirty = true
            canvasRecoder.reset()
        }
    }
    
    internal func reuse(draw drawBlock: @escaping (ComposeCanvas) -> Void, invalidateParentLayer: @escaping () -> Void) {
        composePrint(.renderNodeLayer, message: "\(#function) try to resue for \(self)")
    }
    
    internal func resize(_ size: CGSize) {
        Signpost.compose.tracePoi("RenderNodeLayer:move", []) {
            guard size != self.size else {
                return
            }
            self.size = size
            invalidate()
        }
    }
    
    internal func move(x: CGFloat, y: CGFloat) -> Bool {
        Signpost.compose.tracePoi("RenderNodeLayer:resize", []) {
            let position = CGPoint(x: x, y: y)
            guard position != self.position else {
                return false
            }
            self.position = position
            positionChanged = true
            return true
        }
    }
    
    internal struct LayerProperty<Value> {

        internal var value: Value
        
        internal var changed: Bool
        
        internal init(value: Value,
                      changed: Bool = false) {
            self.value = value
            self.changed = changed
        }
        
    }
    
    internal func updateProperties(_ scope: any ComposeGraphicsLayerScope) {
        Signpost.compose.tracePoi("RenderNodeLayer:updateProperties", []) {
            alpha = .init(value: scope.alpha, changed: scope.alphaChanged)
            transformChanged = scope.tranformChanged
            if scope.clipChanged {
                clipVersion = .make()
            }
            invalidate()
        }
    }
    
    internal func updateDrawTransform(pivotX: CGFloat,
                                      pivotY: CGFloat,
                                      rotationZ: CGFloat,
                                      rotationY: CGFloat,
                                      rotationX: CGFloat,
                                      scaleX: CGFloat,
                                      scaleY: CGFloat,
                                      translationX: CGFloat,
                                      translationY: CGFloat,
                                      cameraDistance: CGFloat) {
        var transform = CATransform3DIdentity
        let px = pivotX.px2pt
        let py = pivotY.px2pt
        let tx = translationX.px2pt
        let ty = translationY.px2pt

        transform = CATransform3DTranslate(transform, -px, -py, 0)


        var geometryTransform = CATransform3DIdentity
        
        let rz = CATransform3DMakeRotation(rotationZ * .pi / 180, 0, 0, 1)
        let ry = CATransform3DMakeRotation(rotationY * .pi / 180, 0, 1, 0)
        let rx = CATransform3DMakeRotation(rotationX * .pi / 180, 1, 0, 0)
        let s = CATransform3DMakeScale(scaleX, scaleY, 1)
        
        geometryTransform = CATransform3DConcat(geometryTransform, rz)
        geometryTransform = CATransform3DConcat(geometryTransform, ry)
        geometryTransform = CATransform3DConcat(geometryTransform, rx)
        geometryTransform = CATransform3DConcat(geometryTransform, s)
        
        transform = CATransform3DConcat(transform, geometryTransform)
        
        if rotationX != 0 || rotationY != 0 {
            let depth = cameraDistance.px2pt * 72.0
            var perspectiveMatrix = CATransform3DIdentity
            perspectiveMatrix.m34 = -1.0 / depth
            transform = CATransform3DConcat(transform, perspectiveMatrix)
        }

        var translateT = CATransform3DIdentity
        translateT = CATransform3DTranslate(translateT, px + tx, py + ty, 0)
        
        transform = CATransform3DConcat(transform, translateT)

        self.transfrom = ProjectionTransform(transform)
    }
    

    internal func invalidate() {
        Signpost.compose.tracePoi("RenderNodeLayer: invalidate", []) {
            composePrint(.renderNodeLayer, message: "\(#function) begin for \(self)")
            isDirty = true
            canvasRecoder.reset()
        }
    }
    
    internal func draw(_ canvas: ComposeCanvas, performDraw drawBlock: @escaping (ComposeCanvas) -> Void) {
        Signpost.compose.tracePoi("RenderNodeLayer:draw", []) {
            guard let nativeCanvas = canvas as? ComposeCanvasImpl else {
                return
            }
            composePrint(.renderNodeLayer, message: "\(#function) begin for \(self)")
            let shouldUpdateContent: Bool = Signpost.compose.tracePoi("RenderNodeLayer:phaseDSL", []) {
                if !isDirty {
                    composePrint(.renderNodeLayer, message: "\(#function) use cache \(canvasRecoder.currentResult.minimalDebugDescription) for \(self)")
                    return false
                } else {
                    canvasRecoder.resizeLayer(size: size)
                    contentIdentifierContainer.resetIndex()
                    withIdentityContainer(contentIdentifierContainer, canvas: canvasRecoder) {
                        drawBlock($0)
                    }
                    isDirty = false
                    composePrint(.renderNodeLayer, message: "\(#function) make cache \(canvasRecoder.currentResult.minimalDebugDescription) for \(self)")
                    return true
                }
            }
            
            Signpost.compose.tracePoi("RenderNodeLayer:makeDisplayList", []) {
                nativeCanvas.translate(dx: position.x, dy: position.y)
                
                var list = canvasRecoder.currentResult
                let itemSize = size.px2pt
                
                let contentUpdate = shouldUpdateContent && lastDisplayList != list
                                
                guard contentUpdate || layerChanged || transformChanged || positionChanged else {
                    nativeCanvas.append(lastDisplayList)
                    nativeCanvas.translate(dx: -position.x, dy: -position.y)
                    return
                }

                if contentUpdate || transformChanged {
                    transformVersion = .make()
                    layerVersion = .make()
                }
                
                if !transfrom.isIdentity {
                    let item = DisplayList.Item(
                        frame: CGRect(origin: .zero,
                                        size: itemSize),
                        version: transformVersion,
                        value: .effect(.projection(transfrom), list),
                        identity: transform3DIdentifier
                    )
                    list = DisplayList(item: item)
                }
                
                if isItemRoot {
                    let item = DisplayList.Item(
                        frame: CGRect(origin: nativeCanvas.currentPosition,
                                      size: itemSize),
                        version: layerVersion,
                        value: .effect(.renderNodeLayer(shouldUpdateContent), list),
                        identity: layerIdentifier
                    )
                    layerChanged = shouldUpdateContent
                    list = DisplayList(item: item)
                } else {
                    if nativeCanvas.currentPosition != .zero {
                        var item = DisplayList.Item(
                            frame: CGRect(origin: nativeCanvas.currentPosition,
                                          size: itemSize),
                            version: .make(),
                            value: .effect(.identity, list),
                            identity: .make()
                        )
                        item.canonicalize()
                        list = DisplayList(item: item)
                    }
                }

                nativeCanvas.append(list)
                
                nativeCanvas.translate(dx: -position.x, dy: -position.y)
                lastDisplayList = list
                transformChanged = false
                positionChanged = false
            }
            composePrint(.renderNodeLayer, message: "\(#function) end for \(self). DisplayList: \(nativeCanvas.currentResult.minimalDebugDescription)")
        }
    }
    
//    internal func drawShaow(canvas: Compose.Canvas) {
//        _notImplemented()
//    }
//    
//    internal func drawRenderEffect() {
//        
//    }
}

@available(iOS 13.0, *)
extension ComposeRenderNodeLayerMatrix {
    var transform: CATransform3D {
        .init(m11: m11, m12: m12, m13: m13, m14: m14,
              m21: m21, m22: m22, m23: m23, m24: m24,
              m31: m31, m32: m32, m33: m33, m34: m34,
              m41: m41, m42: m42, m43: m43, m44: m44)
    }
}
