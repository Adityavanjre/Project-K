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
internal import DanceUIGraph

@_silgen_name("__MyAddSubview")
@available(iOS 13.0, *)
internal func __MyAddSubview(_ subview: UIView, _ container: UIView, _ index: UInt) -> Bool

@available(iOS 13.0, *)
extension DisplayList {
    
    internal final class ViewUpdater: ViewRendererBase {
        
        internal weak var host: ViewRendererHost?
        
        internal var viewCache: ViewCache
        
        internal var seed: DisplayList.Seed
        
        internal var asyncSeed: DisplayList.Seed
        
        internal var nextUpdate: Time
        
        internal var lastContentsScale: CGFloat
        
        internal var lastList: DisplayList
        
        internal var lastTime: Time
        
        internal var isValid: Bool
        
        internal var wasValid: Bool
        
        internal init(host: ViewRendererHost?) {
            self.host = host
            viewCache = .init()
            seed = .init(value: 0)
            asyncSeed = .init(value: 0)
            nextUpdate = .zero
            lastContentsScale = 0
            lastList = .empty
            lastTime = .zero
            isValid = true
            wasValid = true
        }
        
        fileprivate func update(container: inout Container,
                                from displayList: DisplayList,
                                parentState: UnsafePointer<Model.State>,
                                auditor: PerformanceAuditor?) -> Bool {
            var modifiedViewHierarchy = false
            for var item in displayList.items {
                viewCache.index.serial &+= 1
                var oldIndex = DisplayList.Index(identity: DisplayList.Identity(value: 0), serial: 0)
                if item.identity.value != 0 {
                    oldIndex = viewCache.index
                    viewCache.index.identity = item.identity
                    viewCache.index.serial = 0
                }
                let time = viewCache.prepare(item: &item, parentState: parentState)
                container.time = min(time, container.time)
                modifiedViewHierarchy.reducing(updateInheritedView(container: &container, from: item, parentState: parentState, auditor: auditor))
                if item.identity.value != 0 {
                    viewCache.index = oldIndex
                }
            }
            return modifiedViewHierarchy
        }
        
        fileprivate func updateAsync(oldList: DisplayList,
                                     oldParentState: UnsafePointer<Model.State>,
                                     newList: DisplayList,
                                     newParentState: UnsafePointer<Model.State>) -> Time? {
            nil
        }
        
        fileprivate func updateInheritedView(container: inout Container,
                                             from item: DisplayList.Item,
                                             parentState: UnsafePointer<Model.State>,
                                             auditor: PerformanceAuditor?) -> Bool {
            var modifiedViewHierarchy = false
            var item = item
            var localState = parentState.pointee
            let requirements = Model.merge(item: &item, into: &localState)
            
            guard requirements.contains(.isVisible) || item.features.contains(.isRequired) else {
                viewCache.index.skipIfNeeded(item: item)
                return modifiedViewHierarchy
            }
            
            if requirements.contains(.needsImplicitView) {
                var result = viewCache.update(item: item, state: parentState, tag: .inheritedView, in: container.id, auditor: auditor) { item, state in
                    Platform.makeInheritedView(item: item, state: state)
                } updateView: { viewInfo, item, state in
                    Platform.updateState(&viewInfo, item: item, size: item.frame.size, state: state)
                }
                isValid = result.isValid
                if result.isValid || !wasValid {
                    var subContainer = Container(view: result.view, id: result.id, time: .distantFuture, index: 0)
                    if requirements.contains(.needsItemView) {
                        modifiedViewHierarchy.reducing(updateItemView(container: &subContainer, from: item, localState: &localState, auditor: auditor))
                    } else {
                        if case .effect(_, let contentList) = item.value {
                            modifiedViewHierarchy.reducing(update(container: &subContainer, from: contentList, parentState: &localState, auditor: auditor))
                        }
                    }
                    modifiedViewHierarchy.reducing(subContainer.removeRemaining(viewCache: &viewCache))
                    if subContainer.time < .distantFuture {
                        viewCache.setNextUpdate(subContainer.time, in: &result)
                    }
                } else {
                    viewCache.index.skipIfNeeded(item: item)
                }
                modifiedViewHierarchy.reducing(__MyAddSubview(result.view, container.view, container.index))
                container.time = min(container.time, result.nextUpdate)
                container.index += 1
            } else if requirements.contains(.needsItemView) {
                modifiedViewHierarchy.reducing(updateItemView(container: &container, from: item, localState: &localState, auditor: auditor))
            } else if DanceUIFeature.gestureContainer.isEnable && requirements.contains(.needsGhostContainer) {
                var result = viewCache.update(item: item, state: &localState, tag: .ghostContainerView, in: container.id, auditor: auditor) { item, state in
                    let info = Platform.makeGhostContainerView(item: item, state: state)
                    state.pointee.prepareGestureRecognizers(for: info.view)
                    info.view.gestureRecognizers = state.pointee.gestureRecognizers
                    return info
                } updateView: { viewInfo, item, state in
                    Platform.updateStateForGhostContainer(&viewInfo, item: item, size: item.frame.size, state: state)
                }
                localState.resetGesture()
                for index in 0..<localState.clipModels.count {
                    localState.clipModels[index].gestureContrainerTransform = localState.clipModels[index].gestureContrainerTransform.concatenating(localState.transformValue)
                }
                localState.transformValue = .identity
                localState.transformVersion = .zero
                isValid = result.isValid
                if result.isValid || !wasValid {
                    var subContainer = Container(view: result.view, id: result.id, time: .distantFuture, index: 0)
                    if requirements.contains(.needsItemView) {
                        modifiedViewHierarchy.reducing(updateItemView(container: &subContainer, from: item, localState: &localState, auditor: auditor))
                    } else {
                        if case let .effect(_, contentList) = item.value {
                            modifiedViewHierarchy.reducing(update(container: &subContainer, from: contentList, parentState: &localState, auditor: auditor))
                        }
                    }
                    modifiedViewHierarchy.reducing(subContainer.removeRemaining(viewCache: &viewCache))
                    if subContainer.time < .distantFuture {
                        viewCache.setNextUpdate(subContainer.time, in: &result)
                    }
                } else {
                    viewCache.index.skipIfNeeded(item: item)
                }
                modifiedViewHierarchy.reducing(__MyAddSubview(result.view, container.view, container.index))
                container.time = min(container.time, result.nextUpdate)
                container.index += 1
            } else if requirements.contains(.needsRenderNodeLayer) {
                if case .effect(.renderNodeLayer(let updateContent), let displaylist) = item.value {
                    var result = viewCache.update(item: item, state: &localState, tag: .renderNodeLayer, in: container.id, auditor: auditor) { item, state in
                        Platform.makeRenderNodeLayerView(item: item, state: state)
                    } updateView: { viewInfo, item, state in
                        Platform.updateStateForRenderNodeLayer(&viewInfo, item: item, size: item.frame.size, state: state)
                    }
                    isValid = result.isValid
                    if (result.isValid || !wasValid) && updateContent {
                        Signpost.viewRenderer.traceInterval("ViewUpdater:real-update-renoder-node-layer-children") {
                            var subContainer = Container(view: result.view, id: result.id, time: .distantFuture, index: 0)
                            var localState = parentState.pointee
                            localState.reset()
                            if requirements.contains(.needsItemView) {
                                modifiedViewHierarchy.reducing(updateItemView(container: &subContainer, from: item, localState: &localState, auditor: auditor))
                            } else {
                                if case let .effect(_, contentList) = item.value {
                                    modifiedViewHierarchy.reducing(update(container: &subContainer, from: contentList, parentState: &localState, auditor: auditor))
                                }
                            }
                            modifiedViewHierarchy.reducing(subContainer.removeRemaining(viewCache: &viewCache))
                            if subContainer.time < .distantFuture {
                                viewCache.setNextUpdate(subContainer.time, in: &result)
                            }
                        }
                    } else {
                        viewCache.index.skipIfNeeded(item: item)
                    }
                    modifiedViewHierarchy.reducing(__MyAddSubview(result.view, container.view, container.index))
                    container.time = min(container.time, result.nextUpdate)
                    container.index += 1
                }
            } else {
                if case .effect(_, let displaylist) = item.value {
                    modifiedViewHierarchy.reducing(update(container: &container, from: displaylist, parentState: &localState, auditor: auditor))
                }
            }
            
            return modifiedViewHierarchy
        }
        
        fileprivate func updateInheritedViewAsync(oldItem: DisplayList.Item,
                                                  oldParentState: UnsafePointer<Model.State>,
                                                  newItem: DisplayList.Item,
                                                  newParentState: UnsafePointer<Model.State>) -> Time? {
            nil
        }
        
        fileprivate func updateItemView(container: inout Container,
                                        from item: DisplayList.Item,
                                        localState: inout Model.State,
                                        auditor: PerformanceAuditor?) -> Bool {
            var modifiedViewHierarchy = false
            var updateResult: ViewCache.Result = viewCache.update(item: item, state: &localState, tag: .itemView, in: container.id, auditor: auditor, makeView: { (item, state) -> ViewInfo in
                Platform.makeItemView(item: item, state: state, auditor: auditor)
            }) { (viewInfo, item, state) in
                Platform.updateItemView(&viewInfo, item: item, state: state, auditor: auditor)
            }
            
            self.isValid = updateResult.isValid
            if case .effect(let effect, let displaylist) = item.value {
                if updateResult.didChange || !wasValid {
                    localState.reset()
                    var container = Container(view: updateResult.container, id: updateResult.id, time: .distantFuture, index: 0)
                    modifiedViewHierarchy.reducing(update(container: &container, from: displaylist, parentState: &localState, auditor: auditor))
                    modifiedViewHierarchy.reducing(container.removeRemaining(viewCache: &viewCache))
                    var nextTime = container.time
                    switch effect {
                    case .mask(let maskDisplayList):
                        if let maskView = updateResult.view.mask {
                            var maskContainer = Container(view: maskView, id: updateResult.id, time: .distantFuture, index: 0)
                            modifiedViewHierarchy.reducing(update(container: &maskContainer, from: maskDisplayList, parentState: &localState, auditor: auditor))
                            modifiedViewHierarchy.reducing(maskContainer.removeRemaining(viewCache: &viewCache))
                            nextTime = min(nextTime, maskContainer.time)
                        }
                    default:
                        break
                    }
                    viewCache.setNextUpdate(nextTime, in: &updateResult)
                } else {
                    self.viewCache.index.skipIfNeeded(item: item)
                }
            }
            
            modifiedViewHierarchy.reducing(__MyAddSubview(updateResult.view, container.view, container.index))
            container.index += 1
            container.time = min(container.time, updateResult.nextUpdate)
            
            return modifiedViewHierarchy
        }
        
        fileprivate func updateItemViewAsync(oldItem: DisplayList.Item,
                                             oldState: inout Model.State,
                                             newItem: DisplayList.Item,
                                             newState: inout Model.State) -> Time? {
            nil
        }
        
        internal func renderAsync(to: DisplayList, time: Time, version: DisplayList.Version, maxVersion: DisplayList.Version) -> Time? {
            nil
        }
        
        internal func render(rootView: UIView,
                             from displayList: DisplayList,
                             time: Time,
                             version: DisplayList.Version,
                             maxVersion: DisplayList.Version,
                             contentsScale: CGFloat,
                             auditor: PerformanceAuditor?) -> (nextUpdate: Time, hasViewHierarchyModification: Bool, hasReclaimed: Bool) {
            Signpost.viewRenderer.traceInterval("ViewUpdater:render") {
                Signpost.viewRenderer.tracePoi("ViewUpdate:render", []) {
                    var hasViewHierarchyModification: Bool = false
                    var hasReclaimed: Bool = false
                    
                    if lastContentsScale != contentsScale {
                        lastContentsScale = contentsScale
                        seed = .zero
                    }
                    let seedByVersion = Seed(version: version)
                    guard !isValid || seed != seedByVersion || time > nextUpdate else {
                        return (nextUpdate, hasViewHierarchyModification, hasReclaimed)
                    }
                    
                    return Signpost.viewRenderer.traceInterval("ViewUpdater:real-renderer") {
                        if lastTime == .zero {
                            rootView.layer.allowsGroupOpacity = false
                            rootView.layer.my_setAllowsGroupBlending(false)
                        }
                        
                        seed = seedByVersion
                        asyncSeed = seedByVersion
                        wasValid = isValid
                        isValid = true
                        lastList = displayList
                        lastTime = time
                        
                        if EnvValue.isDisplayPrintEnabled {
                            Swift.print("View \(Unmanaged.passUnretained(rootView).toOpaque()) at \(time)")
                            Swift.print(displayList)
                        }
                        
                        viewCache.clearAsyncValues()
                        
                        let needsLayoutOnGeometryChange = rootView.layer.my_needsLayoutOnGeometryChange
                        rootView.layer.my_needsLayoutOnGeometryChange = false
                        
                        var state = Model.State(Model.State.Info(viewUpdater: self, time: time, maxVersion: maxVersion, contentsScale: contentsScale))
                        viewCache.index = .zero
                        
                        var container: Container = Container(view: rootView,
                                                             id: ViewInfo.ID(value: 0),
                                                             time: .distantFuture,
                                                             index: 0)
                        hasViewHierarchyModification.reducing(update(container: &container, from: displayList, parentState:&state, auditor: auditor))
                        hasViewHierarchyModification.reducing(container.removeRemaining(viewCache: &viewCache))
                        
#if FEAT_MONITOR
                        auditor?.traceViewRendererViewCacheReclaimBegin()
#endif
                        
                        hasReclaimed.reducing(viewCache.reclaim(time: time))
                        
#if FEAT_MONITOR
                        auditor?.traceViewRendererViewCacheReclaimEnd()
#endif
                        
                        if let host = host {
                            host.didRender()
                        }
                        rootView.layer.my_needsLayoutOnGeometryChange = needsLayoutOnGeometryChange
                        nextUpdate = isValid ? container.time: time
                        return (nextUpdate, hasViewHierarchyModification, hasReclaimed)
                    }
                }
            }
        }
        
        internal func destroy(rootView: UIView) -> (hasViewHierarchyModification: Bool, hasReclaimed: Bool) {
            let hasViewHierarchyModification = Container(view: rootView, id: ViewInfo.ID(value: 0), time: .distantFuture, index: 0).removeRemaining(viewCache: &viewCache)
            let hasReclaimed = viewCache.reclaim(time: .distantFuture)
            return (hasViewHierarchyModification, hasReclaimed)
        }
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater {
    
    fileprivate struct Container {
        
        internal var view: UIView
        
        internal var id: ViewInfo.ID
        
        internal var time: Time
        
        internal var index: UInt
        
        internal func removeRemaining(viewCache: inout ViewCache) -> Bool {
            let subviews = view.subviews as NSArray
            guard subviews.count > index else {
                return false
            }
            
            var hasViewHierarchyModification = false
            
            for idx in (Int(index) ..< subviews.count).reversed() {
                unowned let currentSubview = subviews[idx] as! UIView
                let reverseMapKey = OpaquePointer(Unmanaged<UIView>.passUnretained(currentSubview).toOpaque())
                guard let mapKey = viewCache.reverseMap[reverseMapKey] else {
                    continue
                }
                var viewInfo = viewCache.map[mapKey]!
                if !viewInfo.isRemoved {
                    viewInfo.isRemoved = true
                    viewCache.map[mapKey] = viewInfo
                    if (currentSubview as? _RenderNodeLayerView) == nil {
                        viewCache.removed.insert(mapKey)
                    }
                }
                currentSubview.removeFromSuperview()
                hasViewHierarchyModification.reducing(viewCache.reclaim(time: time))
            }
            
            return hasViewHierarchyModification
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater {
    
    internal enum Model {
        
        fileprivate static func merge(item: inout DisplayList.Item,
                                      into state: inout State) -> MergedViewRequirements {
            if state.alpha != 1 {
                var shouldHandleEffectForBlendMode = false
                switch state.blendMode {
                case .blendMode(let blendMode):
                    if blendMode != .normal {
                        shouldHandleEffectForBlendMode = true
                    }
                case .caFilter:
                    shouldHandleEffectForBlendMode = true
                }
                
                if shouldHandleEffectForBlendMode {
                    if case .effect(let effect, let contentList) = item.value,
                       case .filter(let filter) = effect,
                       case .vibrantColorMatrix(let colorMartix) = filter {
                        item.rewriteVibrancyFilterAsBackdrop(matrix: colorMartix, list: contentList)
                    }
                }
            }
            var requirements = MergedViewRequirements()
            
            if item.discardContainingClips(state: &state) {
                requirements.insert(.isVisible)
            }
            
            if !state.clipModels.isEmpty {
                if item.canMergeWithClipMask(state: &state) {
                    if let fixedRoundedRect: FixedRoundedRect = state.clipRect(),
                       !item.canMergeWithClipRect(rect: fixedRoundedRect, state: &state) {
                        requirements.insert(.needsImplicitView)
                    }
                } else {
                    requirements.insert(.needsImplicitView)
                }
            }
            
            if !requirements.contains(.needsImplicitView) &&
                !state.transformValue.isTranslation &&
                !item.canMergeWithTransform() {
                requirements.insert(.needsImplicitView)
            }
            
            if !requirements.contains(.needsImplicitView) &&
                (state.hasShadow || !state.filters.isEmpty) && !item.canInheritShadowOrFilters {
                requirements.insert(.needsImplicitView)
            }
            
            if item.isRenderNodeLayer {
                requirements.insert(.needsRenderNodeLayer)
            }
            if DanceUIFeature.gestureContainer.isEnable && item.isGestureRecognizers {
                requirements.insert(.needsGhostContainer)
            }
            
            if requirements.contains(.needsImplicitView) {
                state.reset()
            } else if state.properties.contains(.isHitTestingDisabled) {
                if item.value.needsImplicitView {
                    requirements.insert(.needsImplicitView)
                    state.reset()
                }
            }
            
            state.transformValue = state.transformValue.translatedBy(x: item.frame.origin.x,
                                                                     y: item.frame.origin.y)
            state.transformVersion.max(rhs: item.version)
            
            item.value.finishMerge(&requirements, item: item, state: &state)
            return requirements
        }
    }
}

extension DisplayList.Item {
    var isRenderNodeLayer: Bool {
        switch value {
        case .effect(.renderNodeLayer, _):
            return true
        default:
            return false
        }
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater.Model {
    
    internal struct State {
        
        internal struct Info {
            
            internal var viewUpdater: DisplayList.ViewUpdater
            
            internal var time: Time
            
            internal var maxVersion: DisplayList.Version
            
            internal var contentsScale: CGFloat
        }
        
        internal var info: Info
        
        internal var alpha: CGFloat
        
        internal var blendMode: GraphicsBlendMode
        internal var transformValue: CGAffineTransform
        
        internal var clipModels: [Clip]
        
        internal var filters: [GraphicsFilter]
        
        internal var shadowStyle: MutableBox<ResolvedShadowStyle>?
        
        internal var properties: DisplayList.Properties
        
        internal var gestureRecognizers: [UIGestureRecognizer]
        
        internal var someTagForViewCache: UInt32
        
        internal var e70: UInt32
        
        internal var opacityVersion: DisplayList.Version
        
        internal var blendVersion: DisplayList.Version
        
        internal var transformVersion: DisplayList.Version
        
        internal var clipsVersion: DisplayList.Version
        
        internal var filtersVersion: DisplayList.Version
        
        internal var shadowVersion: DisplayList.Version
        
        internal var propertiesVersion: DisplayList.Version
        
        internal var gestureRecognizersVersion: DisplayList.Version
        
        internal init(_ info: Info) {
            self.info = info
            self.alpha = 1.0
            self.blendMode = .normal
            self.transformValue = .identity
            self.clipModels = []
            self.filters = []
            self.shadowStyle = nil
            self.properties = .empty
            self.gestureRecognizers = []
            self.e70 = 0
            self.someTagForViewCache = 0
            self.opacityVersion = .zero
            self.blendVersion = .zero
            self.transformVersion = .zero
            self.clipsVersion = .zero
            self.filtersVersion = .zero
            self.shadowVersion = .zero
            self.propertiesVersion = .zero
            self.gestureRecognizersVersion = .zero
        }
        
        @inline(__always)
        internal var hasShadow: Bool {
            shadowStyle != nil
        }
        
        internal func clipRect() -> FixedRoundedRect? {
            guard clipModels.count == 1 else {
                return nil
            }
            guard clipModels[0].transform == nil else {
                return nil
            }
            var roundedCornerStyle: RoundedCornerStyle = .circular
            var clipRect: CGRect = .zero
            var cornerSize: CGSize = .zero
            let clip: Clip = clipModels.first!
            
            switch clip.path.storage {
            case .rect(let rect):
                clipRect = rect
            case .ellipse(let rect):
                guard rect.size.width == rect.size.height else {
                    return nil
                }
                clipRect = rect
                cornerSize = CGSize(width: rect.width * 0.5, height: rect.width * 0.5)
                roundedCornerStyle = .circular
            case .roundedRect(let roundedRect):
                roundedCornerStyle = roundedRect.style
                clipRect = roundedRect.rect
                cornerSize = roundedRect.cornerSize
                roundedCornerStyle = roundedRect.style
            default:
                return nil
            }
            
            guard self.transformValue.isRectilinear else {
                return nil
            }
            
            let invertedTransform = transformValue.inverted()
            
            clipRect = clipRect.applying(invertedTransform)
            if DanceUIFeature.gestureContainer.isEnable {
                clipRect = clipRect.applying(clip.gestureContrainerTransform.inverted())
            }
            if cornerSize.isFinite {
                cornerSize = cornerSize.applying(invertedTransform)
                    .updateSign(cornerSize)
            }
            return FixedRoundedRect(rect: clipRect, cornerSize: cornerSize, style: roundedCornerStyle)
        }
        
        internal mutating func reset() {
            alpha = 1.0
            blendMode = .normal
            transformValue = .identity
            clipModels = []
            filters = []
            shadowStyle = nil
            properties = .empty
            opacityVersion = .zero
            blendVersion = .zero
            transformVersion = .zero
            clipsVersion = .zero
            filtersVersion = .zero
            shadowVersion = .zero
            propertiesVersion = .zero
        }
        
        internal mutating func resetGesture() {
            gestureRecognizers = []
            gestureRecognizersVersion = .zero
        }
        
        @inline(__always)
        internal var ViewCacheSeedValue: UInt32 {
            let high16 = someTagForViewCache >> 0x10
            let low16 = someTagForViewCache & (1 << 0x10 - 1)
            return (low16 << 0x10) | high16
        }
        
        fileprivate mutating func addClip(_ path: Path, style: FillStyle) {
            guard (transformValue.b == 0 && transformValue.c == 0) ||
                    (transformValue.a == 0 && transformValue.d == 0) else {
                let clipModel: Clip = .init(path: path, transform: transformValue, style: style)
                self.clipModels.append(clipModel)
                return
            }
            
            let transform: CGAffineTransform? = nil
            var clipPath: Path = path
            switch path.storage {
            case .rect(let rect):
                let newRect = rect.applying(transformValue)
                if newRect.isNull {
                    clipPath.storage = .empty
                } else {
                    clipPath.storage = .rect(newRect)
                }
            case .ellipse(let rect):
                let transformedRect = rect.applying(self.transformValue)
                if rect.isNull {
                    clipPath.storage = .empty
                } else {
                    if rect.isInfinite {
                        clipPath.storage = .rect(transformedRect)
                    } else {
                        clipPath.storage = .ellipse(transformedRect)
                    }
                }
            case .roundedRect(let roundedRect):
                var rect: CGRect = roundedRect.rect
                rect = rect.applying(transformValue)
                
                var cornerSize: CGSize = roundedRect.cornerSize
                if cornerSize.isFinite {
                    cornerSize = cornerSize.applying(transformValue)
                }
                clipPath.storage = .roundedRect(FixedRoundedRect(rect: rect, cornerSize: cornerSize, style: roundedRect.style))
            case .path:
                let clipModel = Clip(path: path, transform: self.transformValue, style: style)
                self.clipModels.append(clipModel)
                return
            default:
                self.clipModels.append(Clip(path: path, transform: transformValue, style: style))
                return
            }
            
            let models: [Clip] = clipModels
            var shouldAppendClipModel = true
            for (index, clip) in models.enumerated() {
                guard clip.transform == nil else {
                    continue
                }
                var newPath: Path = clip.path
                if newPath.intersect(clipPath) {
                    clipModels[index].path = newPath
                    shouldAppendClipModel = false
                    break
                }
            }
            
            if shouldAppendClipModel {
                let clipModel = Clip(path: clipPath, transform: transform, style: style)
                self.clipModels.append(clipModel)
            }
        }
        
        fileprivate mutating func adjust(for transform: CGAffineTransform) {
            guard hasShadow || !filters.isEmpty else {
                return
            }
            let size = CGSize(width: 1.0, height: 1.0).applying(transform)
            guard abs(size.width - 1.0) > 0.001 else {
                return
            }
            let multiplier = 1.0 / size.width
            if var shadowStyle = self.shadowStyle?.value {
                shadowStyle.radius *= multiplier
                shadowStyle.offset.width *= multiplier
                shadowStyle.offset.height *= multiplier
                self.shadowStyle?.value = shadowStyle
            }
            
            for (index, filter) in filters.enumerated() {
                guard case .blur(let style) = filter else {
                    continue
                }
                var newStyle = style
                newStyle.radius *= multiplier
                filters[index] = .blur(newStyle)
            }
        }
        
        internal func prepareGestureRecognizers(for targetView: UIView) {
            for eachGestureRecognizer in gestureRecognizers {
                if let originalTargetView = eachGestureRecognizer.view, originalTargetView !== targetView {
                    originalTargetView.removeGestureRecognizer(eachGestureRecognizer)
                }
            }
        }
        
    }
    
    internal struct MergedViewRequirements: OptionSet {
        
        internal let rawValue: UInt8
        
        internal static let needsItemView: MergedViewRequirements = .init(rawValue: 0x1)
        
        internal static let needsImplicitView: MergedViewRequirements = .init(rawValue: 0x2)
        
        internal static let isVisible: MergedViewRequirements = .init(rawValue: 0x4)
        
        internal static let needsGhostContainer: MergedViewRequirements = .init(rawValue: 0x8)
        
        internal static let needsRenderNodeLayer: MergedViewRequirements = .init(rawValue: 0x10)
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater.Model {
    
    internal struct Clip: Equatable {
        
        internal var path: Path
        
        internal var transform: CGAffineTransform?
        
        internal var style: FillStyle
        
        internal var gestureContrainerTransform: CGAffineTransform
        
        internal var isEmpty: Bool {
            path.isEmpty
        }
        
        internal init(path: Path, transform: CGAffineTransform? = nil, style: FillStyle) {
            self.path = path
            self.transform = transform
            self.style = style
            self.gestureContrainerTransform = .identity
        }
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater {
    
    internal struct ViewInfo: CustomStringConvertible {
        
        var description: String {
            return "<\(Self.self); view = \(view); layer = \(layer); container = \(container); state = \(state); id = \(id); parentID = \(parentID); seeds = \(seeds); isRemoved = \(isRemoved); isInvalid = \(isInvalid); nextUpdate = \(nextUpdate)>"
        }
        
        final private class Storage {
            
            internal var view: UIView
            
            internal var layer: CALayer
            
            internal var container: UIView
            
            internal var state: Platform.State
            
            internal var id: ID
            
            internal var parentID: ID
            
            internal var seeds: Seeds
            
            internal var isRemoved: Bool
            
            internal var isInvalid: Bool
            
            internal var nextUpdate: Time
            
            @inline(__always)
            internal init(view: UIView, layer: CALayer, container: UIView, state: DisplayList.ViewUpdater.Platform.State, id: DisplayList.ViewUpdater.ViewInfo.ID, parentID: DisplayList.ViewUpdater.ViewInfo.ID, seeds: DisplayList.ViewUpdater.ViewInfo.Seeds, isRemoved: Bool, isInvalid: Bool, nextUpdate: Time) {
                self.view = view
                self.layer = layer
                self.container = container
                self.state = state
                self.id = id
                self.parentID = parentID
                self.seeds = seeds
                self.isRemoved = isRemoved
                self.isInvalid = isInvalid
                self.nextUpdate = nextUpdate
            }
            
            @inline(__always)
            internal init(_ storage: Storage) {
                self.view = storage.view
                self.layer = storage.layer
                self.container = storage.container
                self.state = storage.state
                self.id = storage.id
                self.parentID = storage.parentID
                self.seeds = storage.seeds
                self.isRemoved = storage.isRemoved
                self.isInvalid = storage.isInvalid
                self.nextUpdate = storage.nextUpdate
            }
            
            @inline(__always)
            internal init(view: UIView, container: UIView, state: Platform.State) {
                self.view = view
                layer = view.layer
                self.container = container
                self.state = state
                id = .make()
                parentID = .init(value: .max)
                seeds = Seeds()
                isRemoved = false
                isInvalid = false
                nextUpdate = .distantFuture
            }
        }
        
        private var storage: Storage
        
        private mutating func makeStorageUniqueIfNeeded() {
            guard !isKnownUniquelyReferenced(&storage) else {
                return
            }
            self.storage = Storage(storage)
        }
        
        @inline(__always)
        internal var view: UIView {
            _read {
                yield storage.view
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.view
            }
        }
        
        @inline(__always)
        internal var layer: CALayer {
            _read {
                yield storage.layer
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.layer
            }
        }
        
        @inline(__always)
        internal var container: UIView {
            _read {
                yield storage.container
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.container
            }
        }
        
        @inline(__always)
        internal var state: Platform.State {
            _read {
                yield storage.state
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.state
            }
        }
        
        @inline(__always)
        internal var id: ID {
            _read {
                yield storage.id
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.id
            }
        }
        
        @inline(__always)
        internal var parentID: ID {
            _read {
                yield storage.parentID
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.parentID
            }
        }
        
        @inline(__always)
        internal var seeds: Seeds {
            _read {
                yield storage.seeds
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.seeds
            }
        }
        
        @inline(__always)
        internal var isRemoved: Bool {
            _read {
                yield storage.isRemoved
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.isRemoved
            }
        }
        
        @inline(__always)
        internal var isInvalid: Bool {
            _read {
                yield storage.isInvalid
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.isInvalid
            }
        }
        
        @inline(__always)
        internal var nextUpdate: Time {
            _read {
                yield storage.nextUpdate
            }
            _modify {
                makeStorageUniqueIfNeeded()
                yield &storage.nextUpdate
            }
        }
        
        internal struct ID: Equatable {
            
            internal var value: Int
            
            @inline(__always)
            internal static func make() -> ID {
                .init(value: Int(DGMakeUniqueID().rawValue))
            }
        }
        
        internal struct Seeds {
            
            internal var item: DisplayList.Seed
            
            internal var content: DisplayList.Seed
            
            internal var opacity: DisplayList.Seed
            
            internal var blend: DisplayList.Seed
            
            internal var transform: DisplayList.Seed
            
            internal var clips: DisplayList.Seed
            
            internal var filters: DisplayList.Seed
            
            internal var shadow: DisplayList.Seed
            
            internal var properties: DisplayList.Seed
            
            internal var gestureRecognizers: DisplayList.Seed
            
            internal init(item: DisplayList.Seed = .zero,
                          content: DisplayList.Seed = .zero,
                          opacity: DisplayList.Seed = .zero,
                          blend: DisplayList.Seed = .zero,
                          transform: DisplayList.Seed = .zero,
                          clips: DisplayList.Seed = .zero,
                          filters: DisplayList.Seed = .zero,
                          shadow: DisplayList.Seed = .zero,
                          properties: DisplayList.Seed = .zero,
                          gestureRecognizers: DisplayList.Seed = .zero) {
                self.item = item
                self.content = content
                self.opacity = opacity
                self.blend = blend
                self.transform = transform
                self.clips = clips
                self.filters = filters
                self.shadow = shadow
                self.properties = properties
                self.gestureRecognizers = gestureRecognizers
            }
            
            internal mutating func invalidate() {
                self.item = self.item.invalidate()
                self.content = self.content.invalidate()
                self.opacity = self.opacity.invalidate()
                self.blend = self.blend.invalidate()
                self.transform = self.transform.invalidate()
                self.clips = self.clips.invalidate()
                self.filters = self.filters.invalidate()
                self.shadow = self.shadow.invalidate()
                self.properties = self.properties.invalidate()
                self.gestureRecognizers = self.gestureRecognizers.invalidate()
            }
            
        }
        
        internal init(view: UIView, container: UIView, state: Platform.State) {
            self.storage = Storage(view: view, container: container, state: state)
        }
        
        internal mutating func reset() {
            layer = view.layer
            seeds = Seeds()
            state.reset()
            nextUpdate = .distantFuture
        }
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.Item {
    
    fileprivate func canMergeWithClipRect(rect: FixedRoundedRect, state: inout DisplayList.ViewUpdater.Model.State) -> Bool {
        switch value {
        case .content(let content):
            return content.canMergeWithClipRect(rect: rect, state: &state, frame: frame)
        case .effect(let effect, let displayList):
            return effect.canMergeWithClipRect(rect: rect, state: &state, displayList: displayList)
        case .empty:
            return true
        }
    }
    
    fileprivate func discardContainingClips(state: inout DisplayList.ViewUpdater.Model.State) -> Bool {
        guard state.clipModels.count > 0 else {
            return true
        }
        guard !state.clipModels[0].isEmpty else {
            return false
        }
        guard case .content(let content) = self.value,
              state.transformValue.isRectilinear else {
            return true
        }
        let invertedTransform = state.transformValue.inverted()
        
        var offset: CGFloat? = nil
        var index = 0
        while index < state.clipModels.count {
            let clip = state.clipModels[index]
            guard clip.transform == nil else {
                index += 1
                continue
            }
            var newRect: CGRect
            var cornerSize: CGSize
            switch clip.path.storage {
            case .rect(let rect):
                newRect = rect
                cornerSize = .zero
            case .ellipse(let rect):
                guard rect.size.width == rect.size.height else {
                    index += 1
                    continue
                }
                newRect = rect
                cornerSize = CGSize(width: rect.width * 0.5, height: rect.height * 0.5)
            case .roundedRect(let rect):
                newRect = rect.rect
                cornerSize = rect.cornerSize
            default:
                index += 1
                continue
            }
            var transformedRect = newRect.applying(invertedTransform)
            if DanceUIFeature.gestureContainer.isEnable {
                transformedRect = transformedRect.applying(clip.gestureContrainerTransform.inverted())
            }
            
            newRect = transformedRect
            if !cornerSize.isInfinite {
                if DanceUIFeature.gestureContainer.isEnable {
                    cornerSize = cornerSize.applying(invertedTransform)
                } else {
                    cornerSize = cornerSize.applying(invertedTransform)
                }
            }
            let sectionRect: CGRect!
            switch content.value {
            case .backdrop, .color, .chameleonColor,
                    .image, .animatedImage, .text, .flattened, .drawing:
                sectionRect = self.frame
            case .shape(let path, _, _):
                sectionRect = path.boundingRect.offsetBy(dx: self.frame.origin.x, dy: self.frame.origin.y)
            case .shadow, .platformView, .platformLayer, .view, .placeholder:
                return true
            }
            newRect = newRect.intersection(sectionRect)
            guard !newRect.isEmpty else {
                return false
            }
            if offset == nil {
                var result = 0.0
                if let style = state.shadowStyle?.value {
                    result = (style.radius * 0.5) + 0.0 + max(style.offset.width, style.offset.height)
                }
                for filter in state.filters {
                    guard case .blur(let style) = filter, !style.isOpaque else {
                        continue
                    }
                    result += style.radius * 2.8
                }
                offset = result
            }
            let offset = offset!
            if offset != 0.0 {
                transformedRect = transformedRect.insetBy(dx: offset, dy: offset)
                guard !transformedRect.isEmpty else {
                    index += 1
                    continue
                }
                cornerSize.width = max(cornerSize.width - offset, 0)
                cornerSize.height = max(cornerSize.height - offset, 0)
            }
            
            let rect = transformedRect.insetBy(dx: -0.001, dy: -0.001)
            guard rect.contains(frame) else {
                index += 1
                continue
            }
            
            if cornerSize.width > 0 || cornerSize.height > 0 {
                let size = CGSize(width: abs(transformedRect.size.width) * 0.5, height: abs(transformedRect.size.height) * 0.5)
                cornerSize.width = min(cornerSize.width, size.width)
                cornerSize.height = min(cornerSize.height, size.height)
                let rect = transformedRect.insetBy(dx: cornerSize.width * 0.292893, dy: cornerSize.height * 0.292893)
                guard rect.contains(frame) else {
                    index += 1
                    continue
                }
            }
            guard index < state.clipModels.count else {
                continue
            }
            state.clipModels.remove(at: index)
        }
        return true
    }
    
    fileprivate var canInheritShadowOrFilters: Bool {
        switch value {
        case .content(let content):
            switch content.value {
            case .shadow, .platformView, .platformLayer:
                return false
            default:
                return true
            }
        case .effect(let effect, _):
            switch effect {
            case .blendMode, .platformGroup, .clip, .mask:
                return false
            case .affine(let transform):
                if transform.b != 0 || transform.c != 0, transform.a != 0 || transform.d != 0 {
                    return false
                }
                
                if transform.a != transform.d {
                    return false
                }
                return transform.b == transform.c
            case .filter(let filter):
                if case .shadow = filter {
                    return false
                } else {
                    return true
                }
            case .animation, .view:
                _danceuiFatalError()
            default:
                return true
            }
        case .empty:
            return true
        }
    }
    
    fileprivate var isGestureRecognizers: Bool {
        switch value {
        case .effect(.gestureRecognizers, _):
            return true
        default:
            return false
        }
    }
    
    fileprivate func canMergeWithClipMask(state: UnsafePointer<DisplayList.ViewUpdater.Model.State>) -> Bool {
        switch value {
        case .content(let content):
            return content.canMergeWithClipMask(state: state)
        case .effect(let effect, _):
            return effect.canMergeWithClipMask(state: state)
        case .empty:
            return true
        }
    }
    
    fileprivate func canMergeWithGestureRecognizer(state: UnsafePointer<DisplayList.ViewUpdater.Model.State>) -> Bool {
        switch value {
        case .content(let content):
            return content.canMergeWithGestureRecognizer(state: state)
        case .effect(let effect, _):
            return effect.canMergeWithGestureRecognizer(state: state)
        case .empty:
            return true
        }
    }
    
    fileprivate func canMergeWithTransform() -> Bool {
        
        guard case .effect(let effect, _) = value else {
            return true
        }
        
        guard case .clip(let path, _) = effect else {
            return true
        }
        
        switch path.storage {
        case .rect, .roundedRect:
            return false
        case .ellipse(let rect):
            return rect.width != rect.height
        default:
            return true
        }
    }
    
    fileprivate mutating func rewriteVibrancyFilterAsBackdrop(matrix: _ColorMatrix, list: DisplayList) {
        let backdropItem = DisplayList.Item(frame: CGRect(origin: .zero, size: self.frame.size),
                                            version: self.version,
                                            value: .content(DisplayList.Content(value: .backdrop(1, Color.Resolved()),
                                                                                seed: .zero)),
                                            identity: .zero)
        
        let backdropDisplayList = DisplayList(item: backdropItem)
        
        let filterItem = DisplayList.Item(frame: CGRect(origin: .zero, size: self.frame.size),
                                          version: self.version,
                                          value: .effect(.filter(.colorMatrix(matrix)), backdropDisplayList),
                                          identity: .zero)
        let filterDisplayList = DisplayList(item: filterItem)
        
        self.value = .effect(.mask(list), filterDisplayList)
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.Item.Value {
    
    @inline(__always)
    fileprivate var needsImplicitView: Bool {
        
        switch self {
        case .content(let content):
            return content.needsImplicitView
        case .effect(let effect, _):
            return effect.needsImplicitView
        case .empty:
            return false
        }
    }
    
    @inline(__always)
    fileprivate func finishMerge(_ requirements: inout DisplayList.ViewUpdater.Model.MergedViewRequirements,
                                 item: DisplayList.Item,
                                 state: inout DisplayList.ViewUpdater.Model.State) {
        switch self {
        case .content(let content):
            content.finishMerge(&requirements, item: item, state: &state)
        case .effect(let effect, _):
            effect.finishMerge(&requirements, item: item, state: &state)
        case .empty:
            requirements.remove(.needsImplicitView)
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Content {
    
    @inline(__always)
    fileprivate func canMergeWithClipRect(rect: FixedRoundedRect,
                                          state: inout DisplayList.ViewUpdater.Model.State,
                                          frame: CGRect) -> Bool {
        switch value {
        case .backdrop, .color, .chameleonColor, .shadow, .text, .flattened, .drawing:
            let insetRect = frame.insetBy(dx: -0.001, dy: -0.001)
            return insetRect.contains(rect.rect)
        case .image, .animatedImage:
            let xDiff = frame.origin.x - rect.rect.origin.x
            let yDiff = frame.origin.y - rect.rect.origin.y
            let widthDiff = frame.width - rect.rect.width
            let heightDiff = frame.height - rect.rect.height
            if abs(xDiff) > 0.001 || abs(yDiff) > 0.001 || abs(widthDiff) > 0.001 || abs(heightDiff) > 0.001 {
                return false
            }
            
            return true
        case .shape(let path, _, _):
            if case .rect(let pathRect) = path.storage {
                return pathRect.contains(rect.rect)
            }
            
            return false
        case .platformView, .platformLayer:
            return false
        case .view, .placeholder:
            _danceuiFatalError()
        }
    }
    
    @inline(__always)
    fileprivate func canMergeWithClipMask(state: UnsafePointer<DisplayList.ViewUpdater.Model.State>) -> Bool {
        switch value {
        case .backdrop, .color, .chameleonColor, .image, .animatedImage, .shape, .shadow, .view, .placeholder:
            return true
        case .text, .platformView, .platformLayer:
            return false
        case .flattened(_, _, let options), .drawing(_, let options):
            return options.isEnableRenderBox
        }
    }
    
    @inline(__always)
    fileprivate func canMergeWithGestureRecognizer(state: UnsafePointer<DisplayList.ViewUpdater.Model.State>) -> Bool {
        switch value {
        case .backdrop, .color, .chameleonColor, .image, .animatedImage, .shape, .shadow, .view, .placeholder, .text:
            return true
        case .platformView, .platformLayer:
            return false
        case .flattened(_, _, let options), .drawing(_, let options):
            _notImplemented()
        }
    }
    
    @inline(__always)
    fileprivate var needsImplicitView: Bool {
        switch value {
        case .platformView:
            return true
        default:
            return false
        }
    }
    
    @inline(__always)
    fileprivate func finishMerge(_ requirements: inout DisplayList.ViewUpdater.Model.MergedViewRequirements,
                                 item: DisplayList.Item,
                                 state: inout DisplayList.ViewUpdater.Model.State) {
        requirements.insert(.needsItemView)
    }
}

@available(iOS 13.0, *)
extension DisplayList.Effect {
    
    @inline(__always)
    fileprivate func canMergeWithClipRect(rect: FixedRoundedRect,
                                          state: inout DisplayList.ViewUpdater.Model.State,
                                          displayList: DisplayList) -> Bool {
        switch self {
        case .filter(let filter):
            if case .shadow = filter {
                return false
            } else {
                return true
            }
        case .animation:
            _danceuiFatalError()
        default:
            return true
        }
    }
    
    @inline(__always)
    fileprivate func canMergeWithClipMask(state: UnsafePointer<DisplayList.ViewUpdater.Model.State>) -> Bool {
        switch self {
        case .backdropGroup, .properties, .opacity, .blendMode, .clip, .filter, .accessibility, .identity, .geometryGroup, .compositingGroup, .archive, .renderNodeLayer, .gestureRecognizers:
            return true
        case .platformGroup, .mask, .projection:
            return false
        case .affine(let transform):
            return transform.isIdentity
        case .animation, .view:
            _danceuiFatalError()
        }
    }
    
    @inline(__always)
    fileprivate func canMergeWithGestureRecognizer(state: UnsafePointer<DisplayList.ViewUpdater.Model.State>) -> Bool {
        switch self {
        case .backdropGroup, .properties, .opacity, .blendMode, .clip, .filter, .accessibility, .identity, .geometryGroup, .compositingGroup, .archive, .renderNodeLayer, .gestureRecognizers, .mask, .affine, .projection:
            return true
        case .platformGroup:
            return false
        case .animation, .view:
            _danceuiFatalError()
        }
    }
    
    @inline(__always)
    fileprivate var needsImplicitView: Bool {
        switch self {
        case .platformGroup:
            return true
        default:
            return false
        }
    }
    
    @inline(__always)
    fileprivate func finishMerge(_ requirements: inout DisplayList.ViewUpdater.Model.MergedViewRequirements,
                                 item: DisplayList.Item,
                                 state: inout DisplayList.ViewUpdater.Model.State) {
        switch self {
        case .backdropGroup(let value):
            if value {
                state.e70 = (state.someTagForViewCache * 0x21)^item.identity.value
            } else {
                state.e70 = 0
            }
        case .properties(let properties):
            state.properties = state.properties.union(properties)
            state.propertiesVersion.max(rhs: item.version)
        case .platformGroup, .mask, .compositingGroup, .geometryGroup, .archive:
            requirements.insert(.needsItemView)
        case .opacity(let opacity):
            state.alpha *= CGFloat(opacity)
            state.opacityVersion.max(rhs: item.version)
        case .blendMode(let mode):
            state.blendMode = mode
            state.blendVersion.max(rhs: item.version)
        case .clip(let path, let style):
            state.addClip(path, style: style)
            state.clipsVersion.max(rhs: item.version)
        case .affine(let transform):
            state.transformValue = transform.concatenating(state.transformValue)
            state.transformVersion.max(rhs: item.version)
            state.adjust(for: state.transformValue)
        case .projection(let transform):
            if !transform.isIdentity {
                requirements.insert(.needsItemView)
            }
        case .filter(let filter):
            if case .shadow(let shadowStyle) = filter {
                state.shadowStyle = MutableBox<ResolvedShadowStyle>(shadowStyle)
                state.shadowVersion.max(rhs: item.version)
            } else {
                guard !filter.isIdentity else {
                    return
                }
                state.filters.append(filter)
                state.filtersVersion.max(rhs: item.version)
            }
        case .gestureRecognizers(let gestureRecognizers):
            if DanceUIFeature.gestureContainer.isEnable {
                state.gestureRecognizers.append(contentsOf: gestureRecognizers)
                state.gestureRecognizersVersion.max(rhs: item.version)
            }
        case .animation, .view:
            _danceuiFatalError()
        case .accessibility, .identity, .renderNodeLayer:
            break
        }
    }
}

@available(iOS 13.0, *)
extension CGSize {
    
    internal var isFinite: Bool {
        width.isFinite && height.isFinite
    }
    
    internal func updateSign(_ size: CGSize) -> CGSize {
        let newWidth = size.width < 0 ? -abs(width) : abs(width)
        let newHeight = size.height < 0 ? -abs(height) : abs(height)
        return CGSize(width: newWidth, height: newHeight)
    }
}

@available(iOS 13.0, *)
extension Bool {
    
    @_transparent
    fileprivate mutating func reducing(operator op: (Bool, Bool) -> Bool = { $0 || $1 }, _ boolean: @autoclosure () -> Bool) {
        let value = boolean()
        self = op(value, self)
    }
    
}
