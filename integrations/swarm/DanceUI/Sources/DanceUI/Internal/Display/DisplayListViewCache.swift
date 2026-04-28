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
import QuartzCore

@available(iOS 13.0, *)

extension DisplayList.ViewUpdater {
    
    internal struct ViewCache {
        
        internal var map: [Key: ViewInfo]
        
        internal var reverseMap: [OpaquePointer: Key]
        
        internal var removed: Set<Key>
        
        fileprivate var animators: [Key: AnimatorInfo]
        
        internal var index: DisplayList.Index
        
        internal init() {
            map = [:]
            reverseMap = [:]
            removed = []
            animators = [:]
            index = .zero
        }
        
        internal mutating func prepare(item: inout DisplayList.Item, parentState: UnsafePointer<Model.State>) -> Time {
            guard case let .effect(effect, displayList) = item.value,
                  case let .animation(animation) = effect else {
                return .distantFuture
            }
            
            let other: UInt32 = if DanceUIFeature.gestureContainer.isEnable {
                (self.index.serial << 2) ^ parentState.pointee.ViewCacheSeedValue
            } else {
                (self.index.serial * 2) ^ parentState.pointee.ViewCacheSeedValue
            }
            let key = Key(id: self.index.identity.value, other: other)
            let time = parentState.pointee.info.time
            
            var animatorInfo = animators[key] ?? AnimatorInfo(state: .idle, deadline: .zero)
            if case .idle = animatorInfo.state {
                animatorInfo.state = .active(animation.makeAnimator())
            }
            
            var animationFinished = true
            switch animatorInfo.state {
            case .active(let animator):
                animatorInfo.state = .idle 
                let (effect, result) = animator.evaluate(animation, at: time, size: item.frame.size)
                animationFinished = result
                item.value = .effect(effect, displayList)
                item.version = parentState.pointee.info.maxVersion
                if animationFinished {
                    animatorInfo.state = .finished((effect, item.version))
                } else {
                    animatorInfo.state = .active(animator)
                }
            case .finished(let (effect, version)):
                item.value = .effect(effect, displayList)
                item.version = version
            case .idle:
                _danceuiFatalError()
            }
            
            animatorInfo.deadline = time
            animators[key] = animatorInfo
            return animationFinished ? .distantFuture : time
        }
        
        internal mutating func setNextUpdate(_ time: Time, in result: inout Result) {
            guard result.nextUpdate < time else {
                return
            }
            result.nextUpdate = time
            map[result.cacheMapKey]!.nextUpdate = time
        }
        
        internal mutating func reclaim(time: Time) -> Bool {
            var reclaimCount: UInt = 0
            for key in removed {
                guard let viewInfo: ViewInfo = map[key],
                      viewInfo.isRemoved else {
                    continue
                }
                map.removeValue(forKey: key)
                let opaquePointerKey = OpaquePointer(Unmanaged<UIView>.passUnretained(viewInfo.view).toOpaque())
                reverseMap.removeValue(forKey: opaquePointerKey)
                removeViewInfo(viewInfo)
                reclaimCount &+= 1
            }
            self.removed = []
            self.animators = self.animators.filter {
                $0.value.deadline >= time
            }
            return reclaimCount != 0
        }
        
        @inline(__always)
        internal mutating func removeViewInfo(_ viewInfo: ViewInfo) {
            Platform.forEachChild(of: viewInfo) { uiView in
                let opaquePointerKey = OpaquePointer(Unmanaged<UIView>.passUnretained(uiView).toOpaque())
                if let removedKey = reverseMap.removeValue(forKey: opaquePointerKey),
                   let removedViewInfo = map.removeValue(forKey: removedKey) {
                    removeViewInfo(removedViewInfo)
                }
            }
        }
        
        internal mutating func clearAsyncValues() {
#warning("_notImpl")
        }
        
        internal mutating func update(item: DisplayList.Item,
                                      state: UnsafePointer<Model.State>,
                                      tag: Tag,
                                      in viewInfoId: ViewInfo.ID,
                                      auditor: PerformanceAuditor?,
                                      makeView: (DisplayList.Item, UnsafePointer<Model.State>) -> ViewInfo,
                                      updateView: (inout ViewInfo, DisplayList.Item, UnsafePointer<Model.State>) -> Void) -> Result {
            let other: UInt32 = if DanceUIFeature.gestureContainer.isEnable {
                (tag.rawValue + self.index.serial << 2) ^ state.pointee.ViewCacheSeedValue
            } else {
                (tag.rawValue + self.index.serial * 2) ^ state.pointee.ViewCacheSeedValue
            }
            let key = Key(id: self.index.identity.value, other: other)
            guard let viewInfoIndex = map.index(forKey: key) else {
#if FEAT_MONITOR
                auditor?.traceViewRendererViewCacheMissResultBegin()
                defer {
                    auditor?.traceViewRendererViewCacheMissResultEnd()
                }
                
                auditor?.traceViewRendererViewCacheMissMakeViewBegin(item: item)
#endif
                var newViewInfo = makeView(item, state)
#if FEAT_MONITOR
                auditor?.traceViewRendererViewCacheMissMakeViewEnd(item: item)
#endif
                
                newViewInfo.parentID = viewInfoId
                newViewInfo.seeds.item = DisplayList.Seed(version: item.version)
                map[key] = newViewInfo
                let opaquePointerKey = OpaquePointer(Unmanaged<UIView>.passUnretained(newViewInfo.view).toOpaque())
                reverseMap[opaquePointerKey] = key
                if state.pointee.ViewCacheSeedValue == 0 && item.identity.value != 0 {
                    newViewInfo.layer.danceUI_displayListID = Int(item.identity.value)
                }
                return Result(viewInfo: newViewInfo, cacheMapKey: key, didChange: true)
            }
            
#if FEAT_MONITOR
            auditor?.traceViewRendererViewCacheHitResultBegin()
            defer {
                auditor?.traceViewRendererViewCacheHitResultEnd()
            }
#endif
            
            if map.values[viewInfoIndex].isRemoved {
                map.values[viewInfoIndex].isRemoved = false
                removed.remove(key)
            }
            
            let newSeedsItem = DisplayList.Seed(version: item.version)
            var didChange = (map.values[viewInfoIndex].seeds.item != newSeedsItem || map.values[viewInfoIndex].nextUpdate <= state.pointee.info.time)
            map.values[viewInfoIndex].nextUpdate = .distantFuture
            if map.values[viewInfoIndex].parentID != viewInfoId {
                map.values[viewInfoIndex].parentID = viewInfoId
                map.values[viewInfoIndex].seeds.invalidate()
            }
            let oldView = map.values[viewInfoIndex].view
            
#if FEAT_MONITOR
            auditor?.traceViewRendererViewCacheHitUpdateViewBegin(item: item, didChange: didChange)
#endif
            updateView(&map.values[viewInfoIndex], item, state)
            
#if FEAT_MONITOR
            auditor?.traceViewRendererViewCacheHitUpdateViewEnd(item: item, didChange: didChange)
#endif
            
            if !map.values[viewInfoIndex].isInvalid {
                map.values[viewInfoIndex].seeds.item = newSeedsItem
            }
            if map.values[viewInfoIndex].view != oldView {
                reverseMap.removeValue(forKey: oldView.viewCacheReverseMapKey)
                oldView.removeFromSuperview()
                reverseMap[map.values[viewInfoIndex].view.viewCacheReverseMapKey] = key
                
                didChange = true
                if state.pointee.ViewCacheSeedValue == 0 && item.identity != .zero {
                    map.values[viewInfoIndex].layer.danceUI_displayListID = Int(item.identity.value)
                }
            }
            
            return Result(viewInfo: map.values[viewInfoIndex], cacheMapKey: key, didChange: didChange)
        }
        
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.ViewUpdater.ViewCache {
    
    internal enum Tag: UInt32 {
        
        case itemView = 0
        
        case inheritedView = 1
        
        case renderNodeLayer = 3
        
        case ghostContainerView = 2
        
    }
    
    internal struct Result {
        
        @inline(__always)
        internal init(viewInfo: DisplayList.ViewUpdater.ViewInfo, cacheMapKey: Key, didChange: Bool) {
            self.init(viewInfo.view,
                      container: viewInfo.container,
                      id: viewInfo.id,
                      cacheMapKey: cacheMapKey,
                      didChange: didChange,
                      isValid: !viewInfo.isInvalid,
                      nextUpdate: viewInfo.nextUpdate)
        }
        
        private init(_ view: UIView,
                     container: UIView,
                     id: DisplayList.ViewUpdater.ViewInfo.ID,
                     cacheMapKey: Key,
                     didChange: Bool,
                     isValid: Bool,
                     nextUpdate: Time) {
            self.view = view
            self.container = container
            self.id = id
            self.cacheMapKey = cacheMapKey
            self.didChange = didChange
            self.isValid = isValid
            self.nextUpdate = nextUpdate
        }
        
        internal var view: UIView
        
        internal var container: UIView
        
        internal var id: DisplayList.ViewUpdater.ViewInfo.ID
        
        internal var cacheMapKey: Key
        
        internal var didChange: Bool
        
        internal var isValid: Bool
        
        internal var nextUpdate: Time
        
    }
    
    internal struct Key: Hashable {
        
        internal var id: UInt32
        
        internal var other: UInt32
        
    }
    
    fileprivate struct AnimatorInfo {
        
        internal enum State {
            
            case active(_DisplayList_AnyEffectAnimator)
            
            case finished((DisplayList.Effect, DisplayList.Version))
            
            case idle
            
        }
        
        var state: State
        
        var deadline: Time
    }
}

@available(iOS 13.0, *)
extension UIView {
    
    @inline(__always)
    fileprivate var viewCacheReverseMapKey: OpaquePointer {
        OpaquePointer(Unmanaged<UIView>.passUnretained(self).toOpaque())
    }
}
