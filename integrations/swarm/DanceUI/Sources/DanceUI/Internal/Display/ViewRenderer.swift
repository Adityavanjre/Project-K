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

@available(iOS 13.0, *)
protocol ViewRendererBase {

    var exportedObject: AnyObject? { get }

    func render(
        rootView: UIView,
        from displayList: DisplayList,
        time: Time,
        version: DisplayList.Version,
        maxVersion: DisplayList.Version,
        contentsScale: CGFloat,
        auditor: PerformanceAuditor?
    ) -> (nextUpdate: Time, hasViewHierarchyModification: Bool, hasReclaimed: Bool)

    func renderAsync(to: DisplayList, time: Time, version: DisplayList.Version, maxVersion: DisplayList.Version) -> Time?

    func destroy(rootView: UIView) -> (hasViewHierarchyModification: Bool, hasReclaimed: Bool)

}

@available(iOS 13.0, *)
extension ViewRendererBase {
    internal var exportedObject: AnyObject? {
        nil
    }
}

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public final class ViewRenderer {

    internal var configuration: _RendererConfiguration

    internal weak var host: ViewRendererHost?

    internal var state: State

    internal var renderer: ViewRendererBase?

    internal var configChanged: Bool

#if FEAT_MONITOR
    @_spi(DanceUICompose)
    public struct KMPAuditingContext {

        internal let auditor: PerformanceAuditor

        internal let viewName: String

        internal let sceneName: String

        internal func enqueueCommit() {
            self.auditor.enqueueCommit(on: .kmpViewRendererLifetimtDidEnd, category: [
                PerformanceAuditor.CategoryKeys.kmpViewName : self.viewName,
                PerformanceAuditor.CategoryKeys.kmpSceneName : self.sceneName
            ])
        }

    }

    internal let kmpAuditingContext: KMPAuditingContext?
#else
    @_spi(DanceUICompose)
    public struct KMPAuditingContext {

    }
#endif

    internal var auditor: PerformanceAuditor? {
#if FEAT_MONITOR
        host?.viewGraph.auditor ?? kmpAuditingContext?.auditor
#else
        return nil
#endif
    }

    @_spi(DanceUICompose)
    public init(kmpAuditingContext: KMPAuditingContext? = nil) {
        configuration = .init(renderer: .default)
        host = nil
        state = .none
        renderer = nil
        configChanged = true
#if FEAT_MONITOR
        if DanceUIFeature.monitor.isEnable {
            self.kmpAuditingContext = kmpAuditingContext
        } else {
            self.kmpAuditingContext = nil
        }
#endif
    }

    deinit {
        host = nil
        renderer = nil
#if FEAT_MONITOR
        self.kmpAuditingContext?.enqueueCommit()
#endif
    }

    @_spi(DanceUICompose)
    public func render(rootView: UIView, from
                         displayList: DisplayList,
                         time: Time,
                         nextTime: Time,
                         version: DisplayList.Version,
                         maxVersion: DisplayList.Version,
                         contentsScale: CGFloat) -> Time {

#if FEAT_MONITOR
        self.kmpAuditingContext?.auditor.traceKmpFcpBeginIfNeeded()
        self.kmpAuditingContext?.auditor.traceKmpFmpBeginIfNeeded()
#endif

        let auditor = self.auditor
        var modifiedViewHierarchy = false
        var reclaimed = false

#if FEAT_MONITOR
        auditor?.traceViewRendererRenderBegin()
        defer {
            auditor?.traceViewRendererRenderEnd(modifiedViewHierarchy: modifiedViewHierarchy, reclaimed: reclaimed)
            self.kmpAuditingContext?.auditor.traceKmpFcpEndIfNeeded()
            self.kmpAuditingContext?.auditor.traceKmpFmpEndIfNeeded()
        }
#else
        let _ = modifiedViewHierarchy
        let _ = reclaimed
#endif

        let (renderer, modifiedViewHierarchy1, reclaimed1) = updateRenderer(rootView: rootView)
        var (nextUpdate, modifiedViewHierarchy2, reclaimed2) = renderer.render(
            rootView: rootView,
            from: displayList,
            time: time,
            version: version,
            maxVersion: maxVersion,
            contentsScale: contentsScale,
            auditor: auditor
        )
        nextUpdate = min(nextUpdate, nextTime)
        var frameInterval = time.distance(to: nextUpdate)
        frameInterval = max(frameInterval, configuration.minFrameInterval)
        modifiedViewHierarchy = modifiedViewHierarchy1 || modifiedViewHierarchy2
        reclaimed = reclaimed1 || reclaimed2
        return time.advanced(by: frameInterval)
    }

    internal func renderAsync(to: DisplayList, time: Time, version: DisplayList.Version, maxVersion: DisplayList.Version) -> Time? {
        return nil
    }

    internal func updateRenderer(rootView: UIView) -> (ViewRendererBase, hasViewHierarchyModification: Bool, hasReclaimed: Bool) {
        var hasViewHierarchyModification: Bool = false
        var hasReclaimed: Bool = false

        guard configChanged else {
            return (renderer!, hasViewHierarchyModification, hasReclaimed)
        }
        configChanged = false
        switch configuration.renderer {
        case .default:
            switch state {
            case .none: fallthrough
            case .rasterizing:
                if let renderer = self.renderer {
                    let (modifiedViewHierarchy, reclaimed) = renderer.destroy(rootView: rootView)
                    hasViewHierarchyModification = hasViewHierarchyModification || modifiedViewHierarchy
                    hasReclaimed = hasReclaimed || reclaimed
                }
                renderer = nil
                state = .none
            case .updating:
                break
            }
        case .rasterized:
            switch state {
            case .none: fallthrough
            case .updating:
                if let renderer = self.renderer {
                    let (modifiedViewHierarchy, reclaimed) = renderer.destroy(rootView: rootView)
                    hasViewHierarchyModification = hasViewHierarchyModification || modifiedViewHierarchy
                    hasReclaimed = hasReclaimed || reclaimed
                }
                renderer = nil
                state = .none
            case .rasterizing:
                break
            }
        }

        if let renderer = self.renderer {
            switch configuration.renderer {
            case .rasterized(let options):
                let rasterizer = renderer as! DisplayList.ViewRasterizer
                rasterizer.updateOptions(options)
            case .default:
                break
            }
        } else {
            switch configuration.renderer {
            case .rasterized(let options):
                _notImplemented()
            case .default:
                self.renderer = DisplayList.ViewUpdater(host: self.host)
            }
        }

        return (renderer!, hasViewHierarchyModification, hasReclaimed)
    }

}

@available(iOS 13.0, *)
extension ViewRenderer {

    enum State: Equatable {
        case none
        case updating
        case rasterizing
    }

}
