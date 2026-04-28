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
import MyShims

@_silgen_name("__MyMakeFilter")
@available(iOS 13.0, *)
internal func __MyMakeFilter(_ name: NSString, _ options: NSDictionary) -> Any
@available(iOS 13.0, *)
extension DisplayList.ViewUpdater {
    
    internal enum Platform {
        
        @inlinable
        internal static func makeView(_ kind: ViewKind) -> UIView {
            let view: UIView
            switch kind {
            case .inherited, .compositing, .geometry, .projection, .platformGroup:
                view = _InheritedView()
            case .mask:
                view = _InheritedView()
                view.mask = _UIGraphicsView()
                let maskView = view.mask!
                maskView.autoresizesSubviews = false
                let maskLayer = maskView.layer
                maskLayer.anchorPoint = .zero
                maskLayer.allowsGroupOpacity = false
                maskLayer.my_setAllowsGroupBlending(false)
            default:
                view = _UIGraphicsView()
            }
            initView(view, kind: kind)
            return view
        }
        
        @inlinable
        internal static func initView(_ view: UIView,
                                      kind: ViewKind) {
            if kind != .platformView && kind != .platformGroup {
                view.autoresizesSubviews = false
                switch kind {
                case .color, .image, .shape, .shadow,
                        .backdrop, .chameleonColor, .drawing:
                    view.my_setFocusInteractionEnabled(false)
                default:
                    break
                }
                
            }
            view.layer.anchorPoint = .zero
            
            switch kind {
            case .color, .image, .shape:
                view.layer.allowsEdgeAntialiasing = true
                break
            case .inherited, .geometry, .projection, .mask,
                    .platformGroup, .platformLayer:
                view.layer.allowsGroupOpacity = false
                view.layer.my_setAllowsGroupBlending(false)
            default:
                break
            }
        }
        
        internal static func setCompositingFilter(_ filter: Any?,
                                                  of view: UIView) {
            view.layer.compositingFilter = filter
        }
        
        internal static func setFilters(_ filters: [GraphicsFilter],
                                        of view: UIView) {
            let layer = view.layer
            layer.filters = filters.map { filter in
                let properties = filter.caFilterProperties
                return __MyMakeFilter(properties.0, properties.1)
            }
        }
        
        internal static func setShadowStyle(_ style: ResolvedShadowStyle,
                                            of view: UIView) {
            let layer = view.layer
            layer.shadowOpacity = 1.0
            layer.shadowColor = style.color.cgColor
            layer.shadowOffset = style.offset
            layer.shadowRadius = style.radius
        }
        
        internal static func updateGeometry(of viewInfo: inout ViewInfo,
                                            position: CGPoint,
                                            positionChanged: Bool,
                                            origin: CGPoint,
                                            originChanged: Bool,
                                            size: CGSize,
                                            sizeChanged: Bool) {
            if viewInfo.state.kind == .platformGroup || viewInfo.state.kind == .platformView {
                if positionChanged {
                    if !sizeChanged || viewInfo.state.transformChanged,
                       !position.isInvalid {
                        viewInfo.view.center = position
                    } else {
                        if !position.isInvalid,
                           !size.isInvalid {
                            viewInfo.view.frame = CGRect(origin: position, size: size)
                            return
                        }
                    }
                }
                
                if sizeChanged,
                   !size.isInvalid {
                    viewInfo.view.bounds.size = size
                }
            } else {
                if positionChanged,
                   !position.isInvalid {
                    viewInfo.view.layer.position = position
                }
                
                if originChanged || sizeChanged,
                   !origin.isInvalid,
                   !size.isInvalid {
                    viewInfo.view.layer.bounds = CGRect(origin: origin, size: size)
                }
            }
        }
        
        fileprivate static func updateGeometry(viewInfo: inout ViewInfo,
                                               item: DisplayList.Item,
                                               size: CGSize,
                                               state: UnsafePointer<Model.State>,
                                               clipRectChanged: Bool) -> Bool {
            let stateModel = state.pointee
            let viewInfoTransform = viewInfo.seeds.transform
            var sizeEqual: Bool = viewInfo.state.size == size
            var changedTransformValue = true
            var positionChanged = false
            var sizeChanged: Bool = false
            var newSize = size
            var origin: CGPoint = .zero
            var originChanged: Bool = false
            var position: CGPoint = .zero
            var needCheckOriginChanged = false
            
            if stateModel.transformVersion == .zero {
                if viewInfoTransform != .zero  {
                    viewInfo.seeds.transform = .zero
                } else {
                    changedTransformValue = false
                }
            } else {
                let newStateTransform = DisplayList.Seed(version: stateModel.transformVersion)
                if newStateTransform != viewInfoTransform {
                    viewInfo.seeds.transform = newStateTransform
                } else {
                    changedTransformValue = false
                }
            }
            
            guard !sizeEqual || clipRectChanged || changedTransformValue else {
                return false
            }
            
            if viewInfo.state.isContainsClip {
                let fixedRoundedRect = state.pointee.clipRect()!
                let originValue = fixedRoundedRect.rect.origin
                let positionValue = CGPoint(x: stateModel.transformValue.tx + fixedRoundedRect.rect.origin.x,
                                            y: stateModel.transformValue.ty + fixedRoundedRect.rect.origin.y)
                let sizeValue = fixedRoundedRect.rect.size 
                position = positionValue
                newSize = sizeValue
                origin = originValue
                
                if changedTransformValue {
                    
                    sizeEqual = (!sizeEqual) || clipRectChanged
                    
                    needCheckOriginChanged = true
                    if viewInfo.state.position != positionValue {
                        viewInfo.state.position = positionValue
                        positionChanged = true
                    }
                    
                    if sizeEqual && viewInfo.state.size != sizeValue {
                        viewInfo.state.size = sizeValue
                        sizeChanged = true
                    }
                } else {
                    
                    if clipRectChanged {
                        needCheckOriginChanged = true
                        if viewInfo.state.position != positionValue {
                            viewInfo.state.position = positionValue
                            positionChanged = true
                        }
                        
                        if viewInfo.state.size != sizeValue {
                            viewInfo.state.size = sizeValue
                            sizeChanged = true
                        }
                    } else {
                        if !sizeEqual {
                            if viewInfo.state.size != sizeValue {
                                viewInfo.state.size = sizeValue
                                sizeChanged = true
                            }
                        }
                    }
                }
                
            } else if viewInfo.state.isOriginChanged {
                let positionValue = CGPoint(x: stateModel.transformValue.tx, y: stateModel.transformValue.ty)
                position = positionValue
                switch (changedTransformValue, sizeEqual){
                case (true, true):
                    viewInfo.state.isOriginChanged = false
                case (true, false):
                    if viewInfo.state.size != newSize {
                        viewInfo.state.size = newSize
                        sizeChanged = true
                        needCheckOriginChanged = true
                    } else {
                        viewInfo.state.isOriginChanged = false
                    }
                default:
                    sizeEqual = !sizeEqual
                    if viewInfo.state.position != positionValue {
                        viewInfo.state.position = positionValue
                        positionChanged = true
                    }
                    
                    if sizeEqual && viewInfo.state.size != newSize {
                        viewInfo.state.size = newSize
                        sizeChanged = true
                    }
                    needCheckOriginChanged = true
                }
            } else {
                position = CGPoint(x: stateModel.transformValue.tx, y: stateModel.transformValue.ty)
                
                if changedTransformValue && viewInfo.state.position != position {
                    viewInfo.state.position = position
                    positionChanged = true
                }
                
                if !sizeEqual && viewInfo.state.size != newSize {
                    viewInfo.state.size = newSize
                    sizeChanged = true
                }
            }
            
            if needCheckOriginChanged {
                if viewInfo.state.isOriginChanged {
                    originChanged = true
                    if origin == .zero {
                        viewInfo.state.isOriginChanged = false
                    }
                } else {
                    if origin != .zero {
                        originChanged = true
                        viewInfo.state.isOriginChanged = true
                    }
                }
            }
            
            if viewInfo.state.projectionTransformChanged {
                if originChanged || sizeChanged {
                    viewInfo.view.bounds.size = newSize
                }
            } else {
                
                if changedTransformValue {
                    
                    let shouldApplyTransform = !stateModel.transformValue.isTranslation
                    
                    if shouldApplyTransform || viewInfo.state.transformChanged {
                        
                        let t = CGAffineTransform(a: stateModel.transformValue.a,
                                                  b: stateModel.transformValue.b,
                                                  c: stateModel.transformValue.c,
                                                  d: stateModel.transformValue.d,
                                                  tx: 0, ty: 0)
                        viewInfo.view.transform = t
                        viewInfo.state.transformChanged = shouldApplyTransform
                    }
                }
                updateGeometry(of: &viewInfo,
                               position: position,
                               positionChanged: positionChanged,
                               origin: origin,
                               originChanged: originChanged,
                               size: newSize,
                               sizeChanged: sizeChanged)
            }
            
            if originChanged || sizeChanged {
                
                if viewInfo.state.kind == .mask {
                    updateMaskGeometry(of: &viewInfo,
                                       origin: origin,
                                       originChanged: originChanged,
                                       size: newSize,
                                       sizeChanged: sizeChanged)
                }
                
                return true
            }
            
            return false
        }
        
        internal static func updateMaskGeometry(of viewInfo: inout ViewInfo,
                                                origin: CGPoint,
                                                originChanged: Bool,
                                                size: CGSize,
                                                sizeChanged: Bool) {
            let maskView = viewInfo.view.mask!
            maskView.center = origin
            maskView.bounds = CGRect(origin: origin, size: size)
        }
        
        internal static func makeDrawingView(options: RasterizationOptions) -> UIView {
            guard options.isEnableRenderBox else {
                return CGDrawingView(options: options)
            }
            return UIView()
        }
        
        internal static func updateDrawingView(_ view: inout UIView,
                                               options: RasterizationOptions,
                                               contentsScale: CGFloat) -> PlatformDrawable {
            let drawableView = view as! PlatformDrawable
            let drawableOptions = drawableView.options
            assert(options == drawableOptions)
            view.layer.contentsScale = contentsScale
            return drawableView
        }
        
        @inlinable
        internal static func makeItemView(item: DisplayList.Item,
                                          state: UnsafePointer<DisplayList.ViewUpdater.Model.State>,
                                          auditor: PerformanceAuditor?) -> DisplayList.ViewUpdater.ViewInfo {
            var viewInfo = _makeItemView(item: item, state: state)
            updateItemView(&viewInfo, item: item, state: state, auditor: auditor)
            return viewInfo
        }
        
        internal static func makeInheritedView(item: DisplayList.Item,
                                               state: UnsafePointer<Model.State>) -> ViewInfo {
            let view = _InheritedView()
            view.autoresizesSubviews = false
            view.layer.anchorPoint = .zero
            view.layer.allowsGroupOpacity = false
            view.layer.my_setAllowsGroupBlending(false)
            var viewInfo = ViewInfo(view: view, container: view, state: State(position: .zero, size: .zero, kind: .inherited, flags: .init()))
            updateState(&viewInfo, item: item, size: item.frame.size, state: state)
            return viewInfo
        }
        
        internal static func makeRenderNodeLayerView(item: DisplayList.Item,
                                                     state: UnsafePointer<Model.State>) -> ViewInfo {
            let view = _RenderNodeLayerView()
            view.autoresizesSubviews = false
            view.layer.anchorPoint = .zero
            view.layer.allowsGroupOpacity = false
            view.layer.my_setAllowsGroupBlending(false)
            var viewInfo = ViewInfo(view: view, container: view, state: State(position: .zero, size: .zero, kind: .inherited, flags: .init()))
            updateStateForRenderNodeLayer(&viewInfo, item: item, size: item.frame.size, state: state)
            return viewInfo
        }
        
        internal static func makeGhostContainerView(item: DisplayList.Item,
                                                    state: UnsafePointer<Model.State>) -> ViewInfo {
            let view = _InheritedView()
            view.autoresizesSubviews = false
            view.layer.anchorPoint = .zero
            view.layer.allowsGroupOpacity = false
            view.layer.my_setAllowsGroupBlending(false)
            var viewInfo = ViewInfo(view: view, container: view, state: State(position: .zero, size: .zero, kind: .inherited, flags: .init()))
            updateStateForGhostContainer(&viewInfo, item: item, size: item.frame.size, state: state)
            return viewInfo
        }
        
        internal static func updateItemView(_ viewInfo: inout ViewInfo,
                                            item: DisplayList.Item,
                                            state: UnsafePointer<Model.State>,
                                            auditor: PerformanceAuditor?) {
            var newState = state.pointee
            var shouldContinue = false
            switch item.value {
            case .content(let content):
                shouldContinue = content.updateItemView(&viewInfo, item: item, state: &newState, auditor: auditor)
            case .effect(let effect, let contentList):
                shouldContinue = effect.updateItemView(&viewInfo, item: item, state: &newState, contentList: contentList, auditor: auditor)
            case .empty:
                _danceuiFatalError("DisplayList.Item value is empty")
            }
            guard shouldContinue else {
                return
            }
            
            if viewInfo.state.isShapeChanged {
                _updateStateForShapeChanged(&viewInfo, item: item, state: &newState)
            } else {
                if viewInfo.state.kind == .drawing &&
                    viewInfo.state.size != item.frame.size {
                    let drawable = viewInfo.view as! PlatformDrawable
                    viewInfo.isInvalid = drawable.update(content: nil)
                }
                updateState(&viewInfo, item: item, size: item.frame.size, state: &newState)
            }
        }
        
        private static func _updateStateForShapeChanged(_ viewInfo: inout ViewInfo,
                                                        item: DisplayList.Item,
                                                        state: UnsafePointer<Model.State>) {
            var newState = state.pointee
            switch item.value {
            case .content(let content):
                switch content.value {
                case .backdrop, .color, .chameleonColor, .shadow, .platformView, .platformLayer, .text, .flattened, .drawing, .view:
                    _danceuiFatalError()
                case .image(let image), .animatedImage(let image):
                    let size = item.frame.size
                    var sourceSize = size
                    if image.orientation.isRotated {
                        sourceSize = CGSize(width: size.height, height: size.width)
                    }
                    let transform = CGAffineTransform(orientation: image.orientation, in: size)
                    newState.transformValue = transform.concatenating(newState.transformValue)
                    updateState(&viewInfo, item: item, size: sourceSize, state: &newState)
                case .shape(let path, _, _):
                    
                    let boundingRect = path.boundingRect
                    var boundingOrigin: CGPoint = boundingRect.origin
                    var boundingSize: CGSize = boundingRect.size
                    
                    if type(of: viewInfo.layer) == PaintShapeLayer.self {
                        let roundRect = newState.round(rect: boundingRect)
                        boundingOrigin = roundRect.origin
                        boundingSize = roundRect.size
                    } else {
                        if boundingRect.isNull {
                            boundingOrigin = .zero
                            boundingSize = .zero
                        }
                    }
                    
                    let transform = newState.transformValue.translatedBy(x: boundingOrigin.x, y: boundingOrigin.y)
                    newState.transformValue = transform
                    newState.transformVersion.max(rhs: item.version)
                    
                    updateState(&viewInfo,
                                item: item,
                                size: boundingSize,
                                state: &newState)
                case .placeholder:
                    break
                }
            default:
                _danceuiFatalError()
            }
        }
        
        internal static func updateState(_ viewInfo: inout ViewInfo,
                                         item: DisplayList.Item,
                                         size: CGSize,
                                         state: UnsafePointer<Model.State>) {
            let opacitySeed = DisplayList.Seed(version: state.pointee.opacityVersion)
            if viewInfo.seeds.opacity != opacitySeed {
                viewInfo.view.alpha = state.pointee.alpha
                viewInfo.seeds.opacity = opacitySeed
            }
            
            let blendSeed = DisplayList.Seed(version: state.pointee.blendVersion)
            if viewInfo.seeds.blend != blendSeed {
                viewInfo.seeds.blend = blendSeed
                setCompositingFilter(state.pointee.blendMode.caCompositingFilter, of: viewInfo.view)
            }
            
            let filtersSeed = DisplayList.Seed(version: state.pointee.filtersVersion)
            if viewInfo.seeds.filters != filtersSeed {
                setFilters(state.pointee.filters, of: viewInfo.view)
                viewInfo.seeds.filters = filtersSeed
            }
            
            let clipsSeed = DisplayList.Seed(version: state.pointee.clipsVersion)
            var clipRectChanged = false
            if viewInfo.seeds.clips != clipsSeed ||
                viewInfo.seeds.transform != DisplayList.Seed(version: state.pointee.transformVersion) {
                let containsClip = viewInfo.state.isContainsClip
                updateClipShapes(&viewInfo, state: state)
                viewInfo.seeds.clips = clipsSeed
                clipRectChanged = viewInfo.state.isContainsClip || containsClip
            }
            
            let updateGeometryResult = updateGeometry(viewInfo: &viewInfo, item: item, size: size, state: state, clipRectChanged: clipRectChanged)
            
            let shadowSeed = DisplayList.Seed(version: state.pointee.shadowVersion)
            if updateGeometryResult ||
                viewInfo.seeds.shadow != shadowSeed ||
                viewInfo.seeds.item != DisplayList.Seed(version: item.version) {
                updateShadow(&viewInfo, state: state, item: item)
                viewInfo.seeds.shadow = shadowSeed
            }
            
            let propertiesSeed = DisplayList.Seed(version: state.pointee.propertiesVersion)
            if viewInfo.seeds.properties != propertiesSeed {
                viewInfo.view.isUserInteractionEnabled = !state.pointee.properties.contains(.isHitTestingDisabled)
                viewInfo.seeds.properties = propertiesSeed
            }
            
            if DanceUIFeature.gestureContainer.isEnable {
                let gestureRecognizersSeed = DisplayList.Seed(version: state.pointee.gestureRecognizersVersion)
                if viewInfo.seeds.gestureRecognizers != gestureRecognizersSeed {
                    if viewInfo.view.gestureRecognizers?.isEmpty != false {
                        state.pointee.prepareGestureRecognizers(for: viewInfo.view)
                        viewInfo.view.gestureRecognizers = state.pointee.gestureRecognizers
                        viewInfo.seeds.gestureRecognizers = gestureRecognizersSeed
                    }
                }
            }
        }
        
        internal static func updateStateForGhostContainer(_ viewInfo: inout ViewInfo,
                                                          item: DisplayList.Item,
                                                          size: CGSize,
                                                          state: UnsafePointer<Model.State>) {
            let updateGeometryResult = updateGeometry(viewInfo: &viewInfo, item: item, size: size, state: state, clipRectChanged: false)
            
            let gestureRecognizersSeed = DisplayList.Seed(version: state.pointee.gestureRecognizersVersion)
            if viewInfo.seeds.gestureRecognizers != gestureRecognizersSeed {
                if viewInfo.view.gestureRecognizers?.isEmpty != false {
                    state.pointee.prepareGestureRecognizers(for: viewInfo.view)
                    viewInfo.view.gestureRecognizers = state.pointee.gestureRecognizers
                    viewInfo.seeds.gestureRecognizers = gestureRecognizersSeed
                }
            }
        }
        
        internal static func updateStateForRenderNodeLayer(_ viewInfo: inout ViewInfo,
                                                           item: DisplayList.Item,
                                                           size: CGSize,
                                                           state: UnsafePointer<Model.State>) {
            let opacitySeed = DisplayList.Seed(version: state.pointee.opacityVersion)
            if viewInfo.seeds.opacity != opacitySeed {
                viewInfo.view.alpha = state.pointee.alpha
                viewInfo.seeds.opacity = opacitySeed
            }
            
            let blendSeed = DisplayList.Seed(version: state.pointee.blendVersion)
            if viewInfo.seeds.blend != blendSeed {
                viewInfo.seeds.blend = blendSeed
                setCompositingFilter(state.pointee.blendMode.caCompositingFilter, of: viewInfo.view)
            }
            
            let filtersSeed = DisplayList.Seed(version: state.pointee.filtersVersion)
            if viewInfo.seeds.filters != filtersSeed {
                setFilters(state.pointee.filters, of: viewInfo.view)
                viewInfo.seeds.filters = filtersSeed
            }
            
            let clipsSeed = DisplayList.Seed(version: state.pointee.clipsVersion)
            var clipRectChanged = false
            if viewInfo.seeds.clips != clipsSeed ||
                viewInfo.seeds.transform != DisplayList.Seed(version: state.pointee.transformVersion) {
                let containsClip = viewInfo.state.isContainsClip
                updateClipShapes(&viewInfo, state: state)
                viewInfo.seeds.clips = clipsSeed
                if !containsClip {
                    clipRectChanged = viewInfo.state.isContainsClip
                }
            }
            
            let updateGeometryResult = updateGeometry(viewInfo: &viewInfo, item: item, size: size, state: state, clipRectChanged: clipRectChanged)
            
            let shadowSeed = DisplayList.Seed(version: state.pointee.shadowVersion)
            if updateGeometryResult ||
                viewInfo.seeds.shadow != shadowSeed ||
                viewInfo.seeds.item != DisplayList.Seed(version: item.version) {
                updateShadow(&viewInfo, state: state, item: item)
                viewInfo.seeds.shadow = shadowSeed
            }
            
            let propertiesSeed = DisplayList.Seed(version: state.pointee.propertiesVersion)
            if viewInfo.seeds.properties != propertiesSeed {
                viewInfo.view.isUserInteractionEnabled = !state.pointee.properties.contains(.isHitTestingDisabled)
                viewInfo.seeds.properties = propertiesSeed
            }
        }
        
        fileprivate static func _makeItemView(item: DisplayList.Item,
                                              state: UnsafePointer<Model.State>) -> ViewInfo {
            switch item.value {
            case .content(let content):
                return content._makeItemView(item: item,
                                             state: state,
                                             platform: self)
            case .effect(let effect, let contentList):
                return effect._makeItemView(item: item,
                                            state: state,
                                            contentList: contentList,
                                            platform: self)
            case .empty:
                _danceuiFatalError("DisplayList.Item value is empty")
            }
        }
        
        fileprivate static func updateShapeView(_ viewInfo: inout ViewInfo,
                                                state: inout Model.State,
                                                size: inout CGSize,
                                                path: Path,
                                                paint: AnyResolvedPaint,
                                                style: FillStyle,
                                                contentsChanged: Bool) {
            
            let boundingRect = path.boundingRect
            let layerType = type(of: viewInfo.layer)
            var origin: CGPoint = .zero
            var newSize: CGSize = .zero
            if layerType == PaintShapeLayer.self {
                let roundRect = state.round(rect: boundingRect)
                origin = roundRect.origin
                newSize = roundRect.size
            } else {
                if !boundingRect.isNull {
                    origin = boundingRect.origin
                    newSize = boundingRect.size
                }
            }
            
            if contentsChanged {
                let newOrigin = CGPoint(x: -origin.x, y: -origin.y)
                var layerHelper = ShapeLayerHelper(layer: viewInfo.layer,
                                                   layerType: layerType,
                                                   path: path,
                                                   origin: origin,
                                                   paint: paint,
                                                   paintBounds: CGRect(x: newOrigin.x,
                                                                       y: newOrigin.y,
                                                                       width: size.width,
                                                                       height: size.height),
                                                   style: style,
                                                   contentsScale: state.info.contentsScale,
                                                   hasShadow: state.hasShadow)
                paint.visit(&layerHelper)
                
                if layerHelper.layerType != layerType {
                    let shapeView = _UIShapeHitTestingView.my_view(with: layerHelper.layerType.init())
                    initView(shapeView, kind: .shape)
                    let state = Platform.State(kind: .shape)
                    viewInfo = ViewInfo(view: shapeView,
                                        container: shapeView,
                                        state: state)
                    layerHelper.layer = viewInfo.layer
                    paint.visit(&layerHelper)
                }
                
                if let shapeView = viewInfo.view as? _UIShapeHitTestingView {
                    var newPath = path
                    if origin.x != 0 || origin.y != 0 {
                        let transform = CGAffineTransform.init(translationX: newOrigin.x, y: newOrigin.y)
                        newPath = path.applying(transform)
                    }
                    shapeView.path = newPath
                }
                viewInfo.state.isShapeChanged = true
            }
            
            state.transformValue = state.transformValue.translatedBy(x: origin.x, y: origin.y)
            size = newSize
        }
        
        fileprivate static func updateClipShapes(_ viewInfo: inout ViewInfo,
                                                 state: UnsafePointer<Model.State>) {
            if let roundedRect: FixedRoundedRect = state.pointee.clipRect() {
                var cornerRadius: CGFloat = CGFloat.minimum(roundedRect.rect.size.width, roundedRect.rect.size.height)
                cornerRadius *= 0.5
                cornerRadius = .minimum(cornerRadius, roundedRect.cornerSize.width)
                let layer = viewInfo.view.layer
                layer.masksToBounds = true
                layer.cornerRadius = cornerRadius
                
                if #available(iOS 13.0, *) {
                    switch roundedRect.style {
                    case .circular:
                        layer.cornerCurve = .circular
                    case .continuous:
                        layer.cornerCurve = .continuous
                    }
                } else {
                }
                
                viewInfo.state.isContainsClip = true
                if viewInfo.state.isContainsMask {
                    layer.mask = nil
                    viewInfo.state.isContainsMask = false
                }
            } else {
                if viewInfo.state.isContainsClip {
                    viewInfo.state.isContainsClip = false
                    let layer = viewInfo.view.layer
                    layer.masksToBounds = false
                    layer.bounds.origin = .zero
                    layer.cornerRadius = 0
                    if #available(iOS 13.0, *) {
                        layer.cornerCurve = .circular
                    } else {
                    }
                }
                
                if !state.pointee.clipModels.isEmpty {
                    let layer = viewInfo.view.layer
                    
                    if layer.mask as? MaskLayer == nil {
                        let maskLayer = MaskLayer()
                        layer.mask = maskLayer
                        viewInfo.state.isContainsMask = true
                    }
                    
                    let invertedTransform = state.pointee.transformValue.inverted()
                    _danceuiPrecondition(layer.mask != nil)
                    let maskLayer: MaskLayer = layer.mask as! MaskLayer
                    if maskLayer.clips != state.pointee.clipModels ||
                        maskLayer.clipTransform != invertedTransform {
                        maskLayer.setClips(state.pointee.clipModels, transform: invertedTransform)
                    }
                } else {
                    if viewInfo.state.isContainsMask {
                        viewInfo.view.layer.mask = nil
                        viewInfo.state.isContainsMask = false
                    }
                }
            }
        }
        
        @inline(__always)
        fileprivate static func updateShadow(with shadowBox: MutableBox<ResolvedShadowStyle>, viewInfo: ViewInfo) {
            let shadowStyle = shadowBox.value
            Platform.setShadowStyle(shadowStyle, of: viewInfo.view)
        }
        
        fileprivate static func updateShadow(_ viewInfo: inout ViewInfo,
                                             state: UnsafePointer<Model.State>,
                                             item: DisplayList.Item) {
            if let shadowBox = state.pointee.shadowStyle {
                guard viewInfo.state.kind != .inherited else {
                    updateShadow(with: shadowBox, viewInfo: viewInfo)
                    return
                }
                
                switch item.value {
                case .content(let content):
                    if case .shape(let path, let paint, _) = content.value {
                        let layer = viewInfo.view.layer
                        var boundingRect = path.boundingRect
                        if (layer as? PaintShapeLayer) != nil {
                            boundingRect = state.pointee.round(rect: boundingRect)
                        }
                        
                        let shadowStyle = shadowBox.value
                        var layerHelper = ShapeLayerShadowHelper(layer: layer,
                                                                 path: path,
                                                                 offset: boundingRect.origin,
                                                                 shadow: shadowStyle,
                                                                 updateShape: false)
                        paint.visit(&layerHelper)
                        
                    } else if case .color(let color) = content.value {
                        let layer = viewInfo.view.layer
                        var shadowStyle = shadowBox.value
                        layer.shadowPath = nil
                        shadowStyle.color.opacity = shadowStyle.color.opacity * color.opacity
                        layer.updateShadowStyle(style: shadowStyle)
                    } else {
                        updateShadow(with: shadowBox, viewInfo: viewInfo)
                    }
                default:
                    updateShadow(with: shadowBox, viewInfo: viewInfo)
                }
                
            } else {
                let newShadowSeed = DisplayList.Seed(version: state.pointee.shadowVersion)
                let shadowSeedChanged = (state.pointee.shadowVersion != .zero) && (newShadowSeed != viewInfo.seeds.shadow)
                let isNotPlatformKind = viewInfo.state.kind != .platformView &&
                viewInfo.state.kind != .platformGroup &&
                viewInfo.state.kind != .platformLayer
                if (viewInfo.seeds.shadow != .zero || shadowSeedChanged) && isNotPlatformKind {
                    viewInfo.layer.shadowOpacity = 0
                }
            }
        }
        
        internal static func forEachChild(of viewInfo: ViewInfo, do body: (UIView) -> ()) {
            switch viewInfo.state.kind {
            case .platformLayer, .inherited, .compositing, .geometry, .projection, .mask, .platformGroup:
                break
            default:
                return
            }
            
            viewInfo.container.subviews.forEach {
                body($0)
                $0.removeFromSuperview()
            }
            
            guard viewInfo.state.kind == .mask else {
                return
            }
            
            viewInfo.view.mask!.subviews.forEach {
                body($0)
                $0.removeFromSuperview()
            }
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater.Platform {
    
    internal struct State {
        
        internal var position: CGPoint
        
        internal var size: CGSize
        
        internal let kind: ViewKind
        
        private var flags: ViewFlags
        
        @inline(__always)
        internal mutating func reset() {
            position = .invalidValue
            size = .invalidValue
            flags = .empty
        }
        
        @inline(__always)
        internal var isOriginChanged: Bool {
            get {
                flags.contains(.originChanged)
            }
            set {
                if newValue {
                    flags.insert(.originChanged)
                } else {
                    flags.remove(.originChanged)
                }
            }
        }
        
        @inline(__always)
        internal var transformChanged: Bool {
            get {
                flags.contains(.transformChanged)
            }
            set {
                if newValue {
                    flags.insert(.transformChanged)
                } else {
                    flags.remove(.transformChanged)
                }
            }
        }
        
        @inline(__always)
        internal var projectionTransformChanged: Bool {
            get {
                flags.contains(.projectionTransformChanged)
            }
            set {
                if newValue {
                    flags.insert(.projectionTransformChanged)
                } else {
                    flags.remove(.projectionTransformChanged)
                }
            }
        }
        
        @inline(__always)
        internal var isContainsClip: Bool {
            get {
                flags.contains(.containsClip)
            }
            set {
                if newValue {
                    flags.insert(.containsClip)
                } else {
                    flags.remove(.containsClip)
                }
            }
        }
        
        @inline(__always)
        internal var isContainsMask: Bool {
            get {
                flags.contains(.containsMask)
            }
            set {
                if newValue {
                    flags.insert(.containsMask)
                } else {
                    flags.remove(.containsMask)
                }
            }
        }
        
        @inline(__always)
        internal var isShapeChanged: Bool {
            get {
                flags.contains(.shapeChanged)
            }
            set {
                if newValue {
                    flags.insert(.shapeChanged)
                } else {
                    flags.remove(.shapeChanged)
                }
            }
        }
        
        @inline(__always)
        internal init(position: CGPoint = .invalidValue,
                      size: CGSize = .invalidValue,
                      kind: ViewKind,
                      flags: ViewFlags = ViewFlags()) {
            self.position = position
            self.size = size
            self.kind = kind
            self.flags = flags
        }
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater.Platform {
    
    internal struct ViewFlags: OptionSet {
        
        internal typealias RawValue = UInt8
        
        internal let rawValue: RawValue
        
        internal static let empty: ViewFlags = ViewFlags(rawValue: 0x0)
        
        internal static let originChanged: ViewFlags = ViewFlags(rawValue: 0x1 << 0)
        
        internal static let transformChanged: ViewFlags = ViewFlags(rawValue: 0x1 << 1)
        
        internal static let projectionTransformChanged: ViewFlags = ViewFlags(rawValue: 0x1 << 2)
        
        internal static let containsClip: ViewFlags = ViewFlags(rawValue: 0x1 << 3)
        
        internal static let containsMask: ViewFlags = ViewFlags(rawValue: 0x1 << 4)
        
        internal static let shapeChanged: ViewFlags = ViewFlags(rawValue: 0x1 << 5)
    }
    
    internal enum ViewKind: Equatable, Hashable {
        
        case inherited
        
        case color
        
        case image
        
        case animtedImage
        
        case shape
        
        case shadow
        
        case backdrop
        
        case chameleonColor
        
        case platformView
        
        case drawing
        
        case compositing
        
        case geometry
        
        case projection
        
        case mask
        
        case platformGroup
        
        case platformLayer
        
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.Content {
    
    @inline(__always)
    internal func _makeItemView(item: DisplayList.Item,
                                state: UnsafePointer<DisplayList.ViewUpdater.Model.State>,
                                platform: DisplayList.ViewUpdater.Platform.Type) -> DisplayList.ViewUpdater.ViewInfo {
        switch self.value {
        case .text:
            let options = RasterizationOptions(maxDrawableCount: 3)
            let view = DisplayList.ViewUpdater.Platform.makeDrawingView(options: options)
            view.contentMode = .topLeft
            DisplayList.ViewUpdater.Platform.initView(view, kind: .drawing)
            return DisplayList.ViewUpdater.ViewInfo(view: view, container: view, state: DisplayList.ViewUpdater.Platform.State(kind: .drawing))
        case .color:
            let view = platform.makeView(.color)
            return DisplayList.ViewUpdater.ViewInfo(view: view,
                                                    container: view,
                                                    state:DisplayList.ViewUpdater.Platform.State(kind: .color))
        case .image(let image):
            let imageView = _UIGraphicsView.my_view(with: ImageLayer())
            DisplayList.ViewUpdater.Platform.initView(imageView, kind: .image)
            return DisplayList.ViewUpdater.ViewInfo(view: imageView, container: imageView, state: DisplayList.ViewUpdater.Platform.State(kind: .image))
        case .animatedImage(let image):
            let imageView = ImageLayerContainer.createImageView(image)
            DisplayList.ViewUpdater.Platform.initView(imageView, kind: .animtedImage)
            return DisplayList.ViewUpdater.ViewInfo(view: imageView, container: imageView, state: DisplayList.ViewUpdater.Platform.State(kind: .animtedImage))
        case .shape(let path, let paint, _):
            let hasShadow = state.pointee.hasShadow
            let layerType = ShapeLayerHelper.layerType(path, paint, hasShadow: hasShadow)
            let shapeView = _UIShapeHitTestingView.my_view(with: layerType.init())
            platform.initView(shapeView, kind: .shape)
            return DisplayList.ViewUpdater.ViewInfo(view: shapeView,
                                                      container: shapeView,
                                                      state: DisplayList.ViewUpdater.Platform.State(kind: .shape))
        case .shadow:
            let view = platform.makeView(.shadow)
            return DisplayList.ViewUpdater.ViewInfo(view: view,
                                                      container: view,
                                                      state:DisplayList.ViewUpdater.Platform.State(kind: .shadow))
        case .platformView(let factory):
            let view = factory.makePlatformView()
            DisplayList.ViewUpdater.Platform.initView(view, kind: .platformView)
            return DisplayList.ViewUpdater.ViewInfo(view: view,
                                                      container: view,
                                                      state: DisplayList.ViewUpdater.Platform.State(kind: .platformView))
        default:
            return .init(view: UIView(), container: UIView(), state: .init(kind: .inherited))
        }
    }
    
    @inline(__always)
    internal func updateItemView(_ viewInfo: inout DisplayList.ViewUpdater.ViewInfo,
                                 item: DisplayList.Item,
                                 state: UnsafePointer<DisplayList.ViewUpdater.Model.State>,
                                 auditor: PerformanceAuditor?) -> Bool {
        guard viewInfo.seeds.content != self.seed else {
            return true
        }
        var newState = state.pointee
        viewInfo.isInvalid = false
        var item = item
        switch value {
        case .text(let resolvedStyledText, let textSize):
            if viewInfo.state.kind != .drawing {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: &newState)
            }
            let oldView = viewInfo.view
            let drawable = DisplayList.ViewUpdater.Platform.updateDrawingView(&viewInfo.view, options: RasterizationOptions(maxDrawableCount: 3), contentsScale: newState.info.contentsScale)
            
            let content: PlatformDrawableContent = .platformCallback { size in
                resolvedStyledText.draw(in: CGRect(origin: .zero, size: size), with: textSize)
            }
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
#endif
            viewInfo.isInvalid = !drawable.update(content: content)
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionEnd(item: item)
#endif
            if oldView != viewInfo.view {
                viewInfo.reset()
            }
            let nextTime = resolvedStyledText.nextUpdate(after: state.pointee.info.time)
            viewInfo.nextUpdate = min(viewInfo.nextUpdate, nextTime)
            
        case .color(let resolvedColor):
            if viewInfo.state.kind != .color {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: &newState)
            }
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
#endif
            
            let cgColor = resolvedColor.cgColor
            viewInfo.view.layer.backgroundColor = cgColor
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionEnd(item: item)
#endif
        case .image(let resolvedImage):
            if viewInfo.state.kind != .image {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: &newState)
            }
            var size = item.frame.size
            let imageLayer = viewInfo.view.layer as! ImageLayer
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
#endif
            
            imageLayer.update(resolvedImage: resolvedImage, size: size)
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionEnd(item: item)
#endif
            
            let affineTransform = CGAffineTransform(orientation: resolvedImage.orientation,
                                                    in: size)
            if resolvedImage.orientation.isRotated {
                swap(&size.width, &size.height)
            }
            
            item.frame.size = size
            newState.transformValue = affineTransform.concatenating(newState.transformValue)
            if !viewInfo.state.isShapeChanged {
                viewInfo.state.isShapeChanged = true
            }
        case .animatedImage(let resolvedImage):
            if viewInfo.state.kind != .animtedImage {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: &newState)
            }
            var size = item.frame.size
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
#endif
            ImageLayerContainer.update(viewInfo.view, image: resolvedImage, size: size)
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionEnd(item: item)
#endif
            
            let affineTransform = CGAffineTransform(orientation: resolvedImage.orientation,
                                                    in: size)
            if resolvedImage.orientation.isRotated {
                swap(&size.width, &size.height)
            }
            
            item.frame.size = size
            newState.transformValue = affineTransform.concatenating(newState.transformValue)
            if !viewInfo.state.isShapeChanged {
                viewInfo.state.isShapeChanged = true
            }
        case .shape(let path, let paint, let style):
            if viewInfo.state.kind != .shape {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: &newState)
            }
            
            viewInfo.state.isShapeChanged = true
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
#endif
            
            DisplayList.ViewUpdater.Platform.updateShapeView(&viewInfo,
                                                               state: &newState,
                                                               size: &item.frame.size,
                                                               path: path,
                                                               paint: paint,
                                                               style: style,
                                                               contentsChanged: true)
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionEnd(item: item)
#endif
            
        case .platformView(let factory):
            if viewInfo.state.kind != .platformView {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: state)
            }
            var view = viewInfo.view
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
#endif
            
            factory.updatePlatformView(&view)
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionEnd(item: item)
#endif
            
            guard view != viewInfo.view else {
                break
            }
            viewInfo.view = view
            DisplayList.ViewUpdater.Platform.initView(viewInfo.view, kind: .platformView)
            viewInfo.reset()
        default:
            break
        }
        if viewInfo.state.isShapeChanged {
            newState.transformVersion.max(rhs: item.version)
        }
        if !viewInfo.isInvalid && viewInfo.nextUpdate == .distantFuture {
            viewInfo.seeds.content = seed
        }
        DisplayList.ViewUpdater.Platform.updateState(&viewInfo, item: item, size: item.frame.size, state: &newState)
        return false
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.Effect {
    
    @inline(__always)
    internal func _makeItemView(item: DisplayList.Item,
                                state: UnsafePointer<DisplayList.ViewUpdater.Model.State>,
                                contentList: DisplayList,
                                platform: DisplayList.ViewUpdater.Platform.Type) -> DisplayList.ViewUpdater.ViewInfo {
        switch self {
        case .backdropGroup, .properties, .opacity,
                .blendMode, .clip, .affine, .filter,
                .animation, .view, .accessibility,
                .identity, .archive, .renderNodeLayer, . gestureRecognizers:
            _danceuiFatalError()
        case .platformGroup(let factory):
            let view = factory.makePlatformGroup()
            view.layer.anchorPoint = .zero
            let container = factory.platformGroupContainer(view)
            return .init(view: view, container: container, state: DisplayList.ViewUpdater.Platform.State(kind: .platformGroup))
        case .mask:
            let view = DisplayList.ViewUpdater.Platform.makeView(.mask)
            return .init(view: view, container: view, state: DisplayList.ViewUpdater.Platform.State(kind: .mask))
        case .projection:
            let view = DisplayList.ViewUpdater.Platform.makeView(.projection)
            DisplayList.ViewUpdater.Platform.initView(view, kind: .projection)
            var viewInfo = DisplayList.ViewUpdater.ViewInfo(view: view,
                                                            container: view,
                                                            state: DisplayList.ViewUpdater.Platform.State(kind: .projection))
            viewInfo.state.projectionTransformChanged = true
            return viewInfo
        case .geometryGroup:
            let view = DisplayList.ViewUpdater.Platform.makeView(.geometry)
            DisplayList.ViewUpdater.Platform.initView(view, kind: .geometry)
            return .init(view: view, container: view, state: DisplayList.ViewUpdater.Platform.State(kind: .geometry))
        case .compositingGroup:
            let view = DisplayList.ViewUpdater.Platform.makeView(.compositing)
            DisplayList.ViewUpdater.Platform.initView(view, kind: .compositing)
            return .init(view: view, container: view, state: DisplayList.ViewUpdater.Platform.State(kind: .compositing))
        }
        
    }
    
    @inline(__always)
    internal func updateItemView(_ viewInfo: inout DisplayList.ViewUpdater.ViewInfo,
                                 item: DisplayList.Item,
                                 state: UnsafePointer<DisplayList.ViewUpdater.Model.State>,
                                 contentList: DisplayList,
                                 auditor: PerformanceAuditor?) -> Bool {
        guard viewInfo.seeds.content != .init(version: item.version) else {
            return true
        }
        switch self {
        case .backdropGroup, .properties, .opacity,
                .blendMode, .clip, .affine, .filter,
                .animation, .view, .accessibility,
                .identity, .archive, .renderNodeLayer, . gestureRecognizers:
            _danceuiFatalError()
        case .platformGroup(let factory):
            if viewInfo.state.kind != .platformGroup {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: state)
            }
            
            factory.updatePlatformGroup(&viewInfo.view)
            viewInfo.container = factory.platformGroupContainer(viewInfo.view)
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
            defer {
                auditor?.traceViewRendererUpdateActionEnd(item: item)
            }
#endif
            
            DisplayList.ViewUpdater.Platform.updateState(&viewInfo, item: item, size: item.frame.size, state: state)
            
        case .mask:
            if viewInfo.state.kind != .mask {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: state)
            }
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
            defer {
                auditor?.traceViewRendererUpdateActionEnd(item: item)
            }
#endif
            
            DisplayList.ViewUpdater.Platform.updateState(&viewInfo, item: item, size: item.frame.size, state: state)
        case .projection(let transform):
            if viewInfo.state.kind != .projection {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: state)
            }
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
            defer {
                auditor?.traceViewRendererUpdateActionEnd(item: item)
            }
#endif
            
            var transformVersion = state.pointee.transformVersion
            transformVersion.max(rhs: item.version)
            if viewInfo.seeds.transform != .init(version: transformVersion) {
                let projectionTransform = ProjectionTransform(state.pointee.transformValue)
                let newProjectionTransform = transform.concatenating(projectionTransform)
                viewInfo.view.layer.transform = newProjectionTransform.transform3DValue
            }
            DisplayList.ViewUpdater.Platform.updateState(&viewInfo, item: item, size: item.frame.size, state: state)
        case .geometryGroup:
            if viewInfo.state.kind != .geometry {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: state)
            }
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
            defer {
                auditor?.traceViewRendererUpdateActionEnd(item: item)
            }
#endif
            
            DisplayList.ViewUpdater.Platform.updateState(&viewInfo, item: item, size: item.frame.size, state: state)
        case .compositingGroup:
            if viewInfo.state.kind != .compositing {
                viewInfo = DisplayList.ViewUpdater.Platform._makeItemView(item: item, state: state)
            }
            
#if FEAT_MONITOR
            auditor?.traceViewRendererUpdateActionBegin(item: item)
            defer {
                auditor?.traceViewRendererUpdateActionEnd(item: item)
            }
#endif
            
            DisplayList.ViewUpdater.Platform.updateState(&viewInfo, item: item, size: item.frame.size, state: state)
        }
        return false
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater.Model.State {
    
    fileprivate func round(rect: CGRect) -> CGRect {
        let base = 1 / info.contentsScale
        var roundRect: CGRect = rect.isNull ? .zero : rect
        roundRect.roundCoordinatesToNearestOrUp(toMultipleOf: base)
        return roundRect
    }
}
