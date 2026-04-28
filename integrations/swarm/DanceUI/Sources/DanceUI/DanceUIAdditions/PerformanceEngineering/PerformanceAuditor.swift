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

// BDCOV_EXCL_EMPTY_FILE
// BDCOV_EXCL_START
import MyShims
internal import DanceUIGraph
import Foundation
import os.signpost

#if FEAT_MONITOR

/// PerformanceAuditor
///
/// This class traces the performance indicators of the framework.
///
/// The class is not named with XXXTracer because "trace" is sensitive
/// from the end user's perspective. This is what we learned from 2020
/// TikTok ban.
///
/// We may introduce a max-heap to trace the most significant
/// body-accessing duration view type. However, since the dom tree is not
/// ready, the view hierarchy is unable to get.
///
@available(iOS 13.0, *)
final internal class PerformanceAuditor: Auditor<PerformanceData> {
    
    internal struct CategoryKeys {
        
        internal static var literalRootViewName: String {
            "literal_root_view_name"
        }
        
        internal static var semanticRootViewName: String {
            "semantic_root_view_name"
        }
        
        internal static var kmpViewName: String {
            "kmp_view_name"
        }
        
        internal static var kmpSceneName: String {
            "kmp_scene_name"
        }
        
        internal static var version: String {
            "my_performance_indicators_version"
        }
        
    }
    
    internal override func commit(on timing: PerformanceIndicatorCommitTiming, category: [AnyHashable : Any]) {
        
        let name = "my_performance_indicators_all_in_one"
        
        var metrics = [String : NSNumber]()
        var extra = [AnyHashable : Any]()
        
        for eachMetadata in PerformanceData.metadata where !eachMetadata.commitTiming.isDisjoint(with: timing) {
            eachMetadata.assemble(from: self.data, intoMetrics: &metrics, extra: &extra)
        }
        
        for eachMetadata in PerformanceData.metadata where !eachMetadata.commitTiming.isDisjoint(with: timing) {
            eachMetadata.reset(self.data)
        }
        
        var mergedCategory = category
        
        mergedCategory[PerformanceAuditor.CategoryKeys.version] = PerformanceData.version
        
#if DEBUG
        if let mockupCommitHandler = DanceUIMonitor.mockupCommitHandler {
            mockupCommitHandler(name, metrics, mergedCategory)
        }
#endif
        
        DanceUIMonitor.trackService(serviceName: name, metric: metrics, category: mergedCategory, extra: extra)
        
    }
    
    /// Only one auditor running per thread at a specific moment. A
    /// thread-specific static property is OK.
    @ThreadSpecific(nil)
    fileprivate static var viewRendererRenderUpdateActionTraceSignpostID: OSSignpostID?
    
    /// Only one auditor running per thread at a specific moment. A
    /// thread-specific static property is OK.
    @ThreadSpecific(nil)
    fileprivate static var viewRendererRenderCacheHitTraceSignpostID: OSSignpostID?
    
    /// Only one auditor running per thread at a specific moment. A
    /// thread-specific static property is OK.
    @ThreadSpecific(nil)
    fileprivate static var viewRendererRenderCacheMissTraceSignpostID: OSSignpostID?
    
}

@available(iOS 13.0, *)
extension DGAttribute {
    
    internal var auditor: PerformanceAuditor? {
        if let auditor = graph.viewGraphOrNil?.auditor {
            return auditor
        }
        return nil
    }
    
}

// MARK: - PerformanceData

@available(iOS 13.0, *)
internal final class PerformanceData: PerformanceIndicatorCollection {
    
    internal static var version: String {
        return "0.0.1"
    }
    
    internal static let metadata: [PerformanceIndicatorMetadata<PerformanceData>] = [
        TypedPerformanceIndicatorMetadata(
            name: "root_view_lifetime_durations",
            recorder: \.rootViewLifetimeDurations,
            commitTiming: .rootViewLifetimeDidEnd
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "body_access_durations",
            recorder: \.bodyAccessDurations,
            commitTiming: .rootViewLifetimeDidEnd
        ),

        TypedPerformanceIndicatorMetadata(
            name: "kmp_fcp_duration",
            recorder: \.kmpFcpDuration,
            commitTiming: .kmpViewRendererLifetimtDidEnd
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "kmp_fmp_duration",
            recorder: \.kmpFmpDuration,
            commitTiming: .kmpViewRendererLifetimtDidEnd
        ),

        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_render_memory_usage_deltas",
            recorder: \.viewRendererRenderMemoryUsageDeltas,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_render_durations",
            recorder: \.viewRendererRenderDurations,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_hierarchy_modifying_render_count",
            recorder: \.viewRendererViewHierarchyModifyingRenderCount,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_reclaiming_render_count",
            recorder: \.viewRendererReclaimingRenderCount,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_renderer_update_action_durations_above_p95",
            recorder: \.viewRendererRenderUpdateActionDurationsAboveP95,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_hit_ratio",
            recorder: \.viewRendererViewCacheHitRatio,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_hit_result_durations",
            recorder: \.viewRendererViewCacheHitResultDurations,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_miss_result_durations",
            recorder: \.viewRendererViewCacheMissResultDurations,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_hit_update_view_durations",
            recorder: \.viewRendererViewCacheHitUpdateViewDurations,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_miss_make_view_durations",
            recorder: \.viewRendererViewCacheMissMakeViewDurations,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_miss_make_view_durations_above_p95",
            recorder: \.viewRendererViewCacheMissMakeViewDurationsAboveP95,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_hit_update_view_durations_above_p95",
            recorder: \.viewRendererViewCacheHitUpdateViewDurationsAboveP95,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
        TypedPerformanceIndicatorMetadata(
            name: "view_renderer_view_cache_reclaim_durations",
            recorder: \.viewRendererViewCacheReclaimDurations,
            commitTiming: [.kmpViewRendererLifetimtDidEnd, .rootViewLifetimeDidEnd]
        ),
        
    ]
    
    // View global health
    
    internal var rootViewLifetimeDurations = TimeIntervalRecorder().summed
    
    internal var bodyAccessDurations = TimeIntervalRecorder().summed
    
    // KMP

    internal var kmpFcpDuration = TimeIntervalRecorder(policy: .once)

    internal var kmpFmpDuration = TimeIntervalRecorder(policy: .extendsWithLastEnd)

    /// Used by ending the KMP FMP.
    fileprivate var viewRendererPerRenderUpdateActionCount: Int = 0

    /// Used by ending the KMP FMP.
    fileprivate var historicalMaxUpdateActionsCountPerRender: Int = 0
    
    // ViewRenderer render health
    
    internal var viewRendererRenderDurations = TimeIntervalRecorder().summed
    
    internal var viewRendererRenderMemoryUsageDeltas = MemoryUsageIntervalRecorder().summed
    
    internal var viewRendererViewHierarchyModifyingRenderCount = CountRecorder()
    
    internal var viewRendererReclaimingRenderCount = CountRecorder()
    
    // ViewCache global health
    
    internal var viewRendererViewCacheHitRatio = RatioRecorder()
    
    internal var viewRendererViewCacheHitResultDurations = TimeIntervalRecorder().summed
    
    internal var viewRendererViewCacheMissResultDurations = TimeIntervalRecorder().summed
    
    internal var viewRendererViewCacheHitUpdateViewDurations = TimeIntervalRecorder().summed
    
    internal var viewRendererViewCacheMissMakeViewDurations = TimeIntervalRecorder().summed
    
    internal var viewRendererViewCacheReclaimDurations = TimeIntervalRecorder().summed
    
    // ViewCache per-display-list-item health
    
    internal var viewRendererViewCacheHitUpdateViewDurationsAboveP95 = TimeIntervalRecorder().summed.aggregated(by: DisplayListItemValueCategory.self).aboveP95
    
    internal var viewRendererViewCacheMissMakeViewDurationsAboveP95 = TimeIntervalRecorder().summed.aggregated(by: DisplayListItemValueCategory.self).aboveP95
    
    internal var viewRendererRenderUpdateActionDurationsAboveP95 = TimeIntervalRecorder().summed.aggregated(by: DisplayListItemValueCategory.self).aboveP95
    
}

@available(iOS 13.0, *)
extension PerformanceAuditor { // where Data == PerformanceData
    
    @inlinable
    internal func traceRootViewComputationBegin() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.rootViewLifetimeDurations.begin(with: time)
        }
    }
    
    @inlinable
    internal func traceRootViewComputationEnd() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.rootViewLifetimeDurations.end(with: time)
        }
    }
    
    /// Body access maybe recursive: Calling `_UIHostingView.layoutSubviews`
    /// in `View.body`. We need to prevent using lock in the tracing
    /// method
    @discardableResult
    @inlinable
    internal func traceBodyAccess<R>(_ containerType: Any.Type, _ body: () -> R) -> R {
        let startTime = CACurrentMediaTime()
        defer {
            let endTime = CACurrentMediaTime()
            enqueueDataChanges { data in
                data.bodyAccessDurations.begin(with: startTime)
                data.bodyAccessDurations.end(with: endTime)
            }
        }
        let retVal = body()
        return retVal
    }

    @inlinable
    internal func traceKmpFcpBeginIfNeeded() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.kmpFcpDuration.begin(with: time)
        }
    }

    @inlinable
    internal func traceKmpFcpEndIfNeeded() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.kmpFcpDuration.end(with: time)
        }
    }

    @inlinable
    internal func traceKmpFmpBeginIfNeeded() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.kmpFmpDuration.begin(with: time)
        }
    }

    @inlinable
    internal func traceKmpFmpEndIfNeeded() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            if data.viewRendererPerRenderUpdateActionCount > data.historicalMaxUpdateActionsCountPerRender {
                data.kmpFmpDuration.end(with: time)
                data.historicalMaxUpdateActionsCountPerRender = data.viewRendererPerRenderUpdateActionCount
            }
            data.viewRendererPerRenderUpdateActionCount = 0
        }
    }
    
    @inlinable
    internal func traceViewRendererRenderBegin() {
        let time = CACurrentMediaTime()
        let usage = currentResidentMemory()
        enqueueDataChanges { data in
            data.viewRendererRenderMemoryUsageDeltas.begin(with: usage)
            data.viewRendererRenderDurations.begin(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererRenderEnd(modifiedViewHierarchy: Bool, reclaimed: Bool) {
        let time = CACurrentMediaTime()
        let usage = currentResidentMemory()
        enqueueDataChanges { data in
            data.viewRendererRenderMemoryUsageDeltas.end(with: usage)
            data.viewRendererRenderDurations.end(with: time)
            if modifiedViewHierarchy {
                data.viewRendererViewHierarchyModifyingRenderCount.hit()
            }
            if reclaimed {
                data.viewRendererReclaimingRenderCount.hit()
            }
        }
    }
    
    @inlinable
    internal func traceViewRendererUpdateActionBegin(item: borrowing DisplayList.Item) {
        let time = CACurrentMediaTime()
        let category = item.value.category
        let id = Signpost.viewRenderer.makeIntervalTraceID()
        Self.viewRendererRenderUpdateActionTraceSignpostID = id
        Signpost.viewRenderer.traceIntervalBegin(id: id, "view renderer update action: %@", [category.narrative])
        enqueueDataChanges { data in
            data.viewRendererRenderUpdateActionDurationsAboveP95[category].begin(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererUpdateActionEnd(item: borrowing DisplayList.Item) {
        let time = CACurrentMediaTime()
        let category = item.value.category
        if let id = Self.viewRendererRenderUpdateActionTraceSignpostID {
            Signpost.viewRenderer.traceIntervalEnd(id: id, "view renderer update action: %@", [category.narrative])
            Self.viewRendererRenderUpdateActionTraceSignpostID = nil
        }
        enqueueDataChanges { data in
            data.viewRendererRenderUpdateActionDurationsAboveP95[category].end(with: time)
            data.viewRendererPerRenderUpdateActionCount += 1
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheHitResultBegin() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewRendererViewCacheHitResultDurations.begin(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheHitResultEnd() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewRendererViewCacheHitRatio.increaseNumerator()
            data.viewRendererViewCacheHitRatio.increaseDenominator()
            data.viewRendererViewCacheHitResultDurations.end(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheMissResultBegin() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewRendererViewCacheMissResultDurations.begin(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheMissResultEnd() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewRendererViewCacheHitRatio.increaseDenominator()
            data.viewRendererViewCacheMissResultDurations.end(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheMissMakeViewBegin(item: borrowing DisplayList.Item) {
        let time = CACurrentMediaTime()
        let category = item.value.category
        let id = Signpost.viewRenderer.makeIntervalTraceID()
        Self.viewRendererRenderCacheMissTraceSignpostID = id
        Signpost.viewRenderer.traceIntervalBegin(id: id, "view renderer view cache miss and make view: %@", [category.narrative])
        enqueueDataChanges { data in
            data.viewRendererViewCacheMissMakeViewDurations.begin(with: time)
            data.viewRendererViewCacheMissMakeViewDurationsAboveP95[category].begin(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheMissMakeViewEnd(item: borrowing DisplayList.Item) {
        let time = CACurrentMediaTime()
        let category = item.value.category
        if let id = Self.viewRendererRenderCacheMissTraceSignpostID {
            Signpost.viewRenderer.traceIntervalEnd(id: id, "view renderer view cache miss and make view: %@", [category.narrative])
            Self.viewRendererRenderCacheMissTraceSignpostID = nil
        }
        enqueueDataChanges { data in
            data.viewRendererViewCacheMissMakeViewDurations.end(with: time)
            data.viewRendererViewCacheMissMakeViewDurationsAboveP95[category].end(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheHitUpdateViewBegin(item: borrowing DisplayList.Item, didChange: Bool) {
        let time = CACurrentMediaTime()
        let category = item.value.category
        let id = Signpost.viewRenderer.makeIntervalTraceID()
        Self.viewRendererRenderCacheHitTraceSignpostID = id
        Signpost.viewRenderer.traceIntervalBegin(id: id, "view renderer view cache hit and update view: %@; didChange: %@", [category.narrative, didChange ? "true" : "false"])
        enqueueDataChanges { data in
            data.viewRendererViewCacheHitUpdateViewDurations.begin(with: time)
            data.viewRendererViewCacheHitUpdateViewDurationsAboveP95[category].begin(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheHitUpdateViewEnd(item: borrowing DisplayList.Item, didChange: Bool) {
        let time = CACurrentMediaTime()
        let category = item.value.category
        if let id = Self.viewRendererRenderCacheHitTraceSignpostID {
            Signpost.viewRenderer.traceIntervalEnd(id: id, "view renderer view cache hit and update view: %@; didChange: %@", [category.narrative, didChange ? "true" : "false"])
            Self.viewRendererRenderCacheHitTraceSignpostID = nil
        }
        enqueueDataChanges { data in
            data.viewRendererViewCacheHitUpdateViewDurations.end(with: time)
            data.viewRendererViewCacheHitUpdateViewDurationsAboveP95[category].end(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheReclaimBegin() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewRendererViewCacheReclaimDurations.begin(with: time)
        }
    }
    
    @inlinable
    internal func traceViewRendererViewCacheReclaimEnd() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewRendererViewCacheReclaimDurations.end(with: time)
        }
    }
    
}

@available(iOS 13.0, *)
extension DisplayList.Item.Value {
    
    fileprivate var category: DisplayListItemValueCategory {
        switch self {
        case .content(let content):
            switch content.value {
            case .backdrop(_, _):
                return .contentOfBackdrop
            case .color(_):
                return .contentOfColor
            case .chameleonColor(_):
                return .contentOfChameleonColor
            case .image(_):
                return .contentOfImage
            case .animatedImage(_):
                return .contentOfAnimatedImage
            case .shape(_, _, _):
                return .contentOfShape
            case .shadow(_, _):
                return .contentOfShadow
            case .platformView(_):
                return .contentOfPlatformView
            case .platformLayer(_):
                return .contentOfPlatformLayer
            case .text(_, _):
                return .contentOfText
            case .flattened(_, _, _):
                return .contentOfFlattened
            case .drawing(_, _):
                return .contentOfDrawing
            case .view(_):
                return .contentOfView
            case .placeholder(_):
                return .contentOfPlaceholder
            }
        case .effect(let effect, _):
            switch effect {
            case .backdropGroup(_):
                return .effectOfBackdropGroup
            case .properties(_):
                return .effectOfProperties
            case .platformGroup(_):
                return .effectOfPlatformGroup
            case .opacity(_):
                return .effectOfOpacity
            case .blendMode(_):
                return .effectOfBlendMode
            case .clip(_, _):
                return .effectOfClip
            case .mask(_):
                return .effectOfMask
            case .affine(_):
                return .effectOfAffine
            case .projection(_):
                return .effectOfProjection
            case .filter(_):
                return .effectOfFilter
            case .animation(_):
                return .effectOfAnimation
            case .view(_):
                return .effectOfView
            case .accessibility(_):
                return .effectOfAX
            case .identity:
                return .effectOfIdentity
            case .geometryGroup:
                return .effectOfGeometryGroup
            case .compositingGroup:
                return .effectOfCompositingGroup
            case .archive:
                return .effectOfArchive
            case .renderNodeLayer:
                return .renderNodeLayer
            case .gestureRecognizers(_):
                return .effectOfGestureRecognizers
            }
        case .empty:
            return .empty
        }
    }
    
}

// MARK: - Data Abstractions

/// We may massively modify parts of the contents. A class type is
/// required.
///
@available(iOS 13.0, *)
@_spi(ForDanceUIExtensionOnly)
public protocol PerformanceIndicatorCollection: AnyObject {
    
    static var metadata: [PerformanceIndicatorMetadata<Self>] { get }
    
    static var version: String { get }
    
    init()
    
}

@available(iOS 13.0, *)
@_spi(ForDanceUIExtensionOnly)
public struct PerformanceIndicatorCommitTiming: OptionSet {
    
    public typealias RawValue = UInt
    
    // 1-based
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static var rootViewLifetimeDidEnd: PerformanceIndicatorCommitTiming {
        PerformanceIndicatorCommitTiming(rawValue: 0x1)
    }

    public static var kmpViewRendererLifetimtDidEnd: PerformanceIndicatorCommitTiming {
        PerformanceIndicatorCommitTiming(rawValue: 0x2)
    }
    
    public static var coreTestCaseFinished: PerformanceIndicatorCommitTiming {
        PerformanceIndicatorCommitTiming(rawValue: 0x4)
    }
}

@available(iOS 13.0, *)
internal protocol PerformanceIndicatorNumberic: AdditiveArithmetic {
    
    var asNSNumber: NSNumber { get }
    
    var asDouble: Double { get }
    
    static var min: Self { get }
    
    static var max: Self { get }
    
}

@available(iOS 13.0, *)
extension Double: PerformanceIndicatorNumberic {
    
    internal var asNSNumber: NSNumber {
        self as NSNumber
    }
    
    internal var asDouble: Double {
        self
    }
    
    internal static var min: Double {
        -.greatestFiniteMagnitude
    }
    
    internal static var max: Double {
        .greatestFiniteMagnitude
    }
    
}

@available(iOS 13.0, *)
extension Int: PerformanceIndicatorNumberic {
    
    internal var asNSNumber: NSNumber {
        self as NSNumber
    }
    
    internal var asDouble: Double {
        Double(self)
    }

}

@available(iOS 13.0, *)
extension Int64: PerformanceIndicatorNumberic {
    
    internal var asNSNumber: NSNumber {
        self as NSNumber
    }
    
    internal var asDouble: Double {
        Double(self)
    }
    
}

@available(iOS 13.0, *)
extension UInt8: PerformanceIndicatorNumberic {
    
    internal var asNSNumber: NSNumber {
        self as NSNumber
    }
    
    internal var asDouble: Double {
        Double(self)
    }

}

@available(iOS 13.0, *)
extension UInt64: PerformanceIndicatorNumberic {
    
    internal var asNSNumber: NSNumber {
        self as NSNumber
    }
    
    internal var asDouble: Double {
        Double(self)
    }

}

@available(iOS 13.0, *)
internal protocol PerformanceIndicatorDetailsReadable {
    
    var metrics: [String : NSNumber] { get }
    
    var extra: [AnyHashable : Any]? { get }
    
}

@available(iOS 13.0, *)
extension PerformanceIndicatorDetailsReadable {
    
}

/// Types recording perfomrance indicator. Most of them directly records
/// the performance data. Some of them may derive data from another.
///
@available(iOS 13.0, *)
internal protocol PerformanceIndicatorRecording: PerformanceIndicatorDetailsReadable {
    
    associatedtype ValueType
    
    /// The metadata checks this property before commiting a recorder. A
    /// recorder shall be ended before commit.
    ///
    /// However, the trace code may be incorrectly implemented, the
    /// commiting process shall have an opportunity to log this error.
    ///
    var isRecordingEnded: Bool { get }
    
    mutating func reset()
    
}

@available(iOS 13.0, *)
internal protocol IntervalPerformanceIndicatorRecording: PerformanceIndicatorRecording {
    
    var interval: ValueType { get }
    
    mutating func begin(with start: ValueType, reason: String?)
    
    mutating func end(with end: ValueType, reason: String?) -> Bool
    
}

/// The type-erased performance indicator metadata. Abstract class.
///
@available(iOS 13.0, *)
@_spi(ForDanceUIExtensionOnly)
public class PerformanceIndicatorMetadata<IndicatorCollection: PerformanceIndicatorCollection> {
    
    internal let name: String
    
    internal let commitTiming: PerformanceIndicatorCommitTiming
    
    internal init(name: String, commitTiming: PerformanceIndicatorCommitTiming) {
        self.name = name
        self.commitTiming = commitTiming
    }
    
    internal func assemble(from data: IndicatorCollection, intoMetrics targetMetrics: inout [String : NSNumber], extra targetExtra: inout [AnyHashable : Any]) {

    }

    internal func reset(_ data: IndicatorCollection) {

    }
    
}
 
@available(iOS 13.0, *)
internal class TypedPerformanceIndicatorMetadata<IndicatorCollection: PerformanceIndicatorCollection, Recorder: PerformanceIndicatorRecording>: PerformanceIndicatorMetadata<IndicatorCollection> {
    
    internal let recorder: ReferenceWritableKeyPath<IndicatorCollection, Recorder>
    
    internal let categoryBuilder: ((Recorder) -> [String: Any])?
    
    internal init(
        name: String,
        recorder: ReferenceWritableKeyPath<IndicatorCollection, Recorder>,
        commitTiming: PerformanceIndicatorCommitTiming,
        categoryBuilder: ((Recorder) -> [String: Any])? = nil
    ) {
        self.recorder = recorder
        self.categoryBuilder = categoryBuilder
        super.init(name: name, commitTiming: commitTiming)
    }
    
    internal override func assemble(from data: IndicatorCollection, intoMetrics targetMetrics: inout [String : NSNumber], extra targetExtra: inout [AnyHashable : Any]) {
        if !data[keyPath: recorder].isRecordingEnded {
            // Currently Slardar custom exception is not available in DanceUI.
            LogService.error(module: .performance, keyword: .commiting, "Assembling an un-ended recorder", info: [
                "indicator_name" : name,
            ])
        }
        
        let metrics = data[keyPath: recorder].metrics
        for (metricName, metricValue) in metrics {
            let indicatorName = "\(name)_\(metricName)"
            targetMetrics[indicatorName] = metricValue
        }
        
        if let extra = data[keyPath: recorder].extra {
            targetExtra[name] = extra
        }
    }
    
    internal override func reset(_ data: IndicatorCollection) {
        data[keyPath: recorder].reset()
    }
    
}

#if DEBUG
@available(iOS 13.0, *)
extension DanceUIMonitor {
    
    @AtomicBox
    internal static var mockupCommitHandler: ((_ serviceName: String, _ metric: [String: NSNumber], _ category: [AnyHashable: Any]) -> Void)? = nil
    
}
#endif

@available(iOS 13.0, *)
internal struct RatioRecorder: PerformanceIndicatorRecording, Comparable {
    
    internal static func < (lhs: RatioRecorder, rhs: RatioRecorder) -> Bool {
        lhs.ratio < rhs.ratio
    }
    
    internal static func == (lhs: RatioRecorder, rhs: RatioRecorder) -> Bool {
        lhs.ratio == rhs.ratio
    }
    
    internal typealias ValueType = Double
    
    internal var metrics: [String : NSNumber] {
        [
            // JSON cannot represents nan.
            "ratio" : ratio.isNaN ? 0 : ratio.asNSNumber,
            "numerator" : numerator.asNSNumber,
            "denominator" : denominator.asNSNumber,
        ]
    }
    
    internal var extra: [AnyHashable : Any]? {
        nil
    }

    internal private(set) var numerator: Int = 0
    
    internal private(set) var denominator: Int = 0
    
    /// numerator / denominator
    internal var ratio: Double {
        if denominator == 0 {
            if numerator > 0 {
                return .infinity
            } else if numerator < 0 {
                return -.infinity
            } else {
                return .nan
            }
        }
        return Double(numerator) / Double(denominator)
    }
    
    internal init() {
        
    }
    
    internal mutating func increaseDenominator() {
        denominator += 1
    }
    
    internal mutating func increaseNumerator() {
        numerator += 1
    }
    
    internal var isRecordingEnded: Bool {
        return true
    }
    
    internal mutating func reset() {
        numerator = 0
        denominator = 0
    }
    
}

@available(iOS 13.0, *)
internal struct SummationRecorder<Recorder: PerformanceIndicatorRecording>: PerformanceIndicatorRecording where Recorder.ValueType: PerformanceIndicatorNumberic & Comparable {
    
    internal typealias ValueType = Recorder.ValueType
    
    internal var metrics: [String : NSNumber] {
        [
            "sum" : sum.asNSNumber,
            "min" : min.asNSNumber,
            "max" : max.asNSNumber,
            "avg" : avg.asNSNumber,
            "stdev" : stdev.asNSNumber,
            "count" : counter.asNSNumber,
            "mean" : (mean.isNaN ? 0 : mean).asNSNumber,
        ]
    }
    
    internal var extra: [AnyHashable : Any]? {
        var extra: [AnyHashable : Any] = [
            "name" : name,
            "min_reason" : minReason ?? "placeholder",
            "max_reason" : maxReason ?? "placeholder",
        ]
        if reserveRawInExtra {
            extra["raw"] = raw
        }
        return extra
    }
    
    internal let name: String
    
    internal private(set) var recorder: Recorder
    
    internal private(set) var sum: ValueType = .zero
    
    internal private(set) var min: ValueType = .max
    
    internal private(set) var max: ValueType = .min
    
    internal private(set) var counter: Int = .zero
    
    internal private(set) var minReason: String?
    
    internal private(set) var maxReason: String?
    
    internal private(set) var mean: Double = .zero
    
    private let ignoreValueCount: Int
    
    private var remainingIgnoreCount: Int
    
    private let reserveRawInExtra: Bool
    
    private var raw: [Double] = []
    
    // for variance computation
    private var m2: Double = .zero
    
    internal var stdev: Double {
        guard mean != 0 else {
            return 0.0
        }
        return variance.squareRoot() / abs(mean)
    }
    
    internal var avg: Double {
        let result = sum.asDouble / Double(counter)
        guard !result.isNaN else {
            return 0
        }
        return result
    }
    
    private var variance: Double {
        guard counter > 1 else {
            return .zero
        }
        let result = m2 / Double(counter - 1)
        guard !result.isNaN else {
            return 0
        }
        return result
    }
    
    internal init(base baseRecorder: Recorder, name: String, skip: Int = 0, reserveRawInExtra: Bool = false) {
        self.recorder = baseRecorder
        self.name = name
        self.ignoreValueCount = skip
        self.remainingIgnoreCount = skip
        self.reserveRawInExtra = reserveRawInExtra
    }
    
    internal mutating func add(_ value: ValueType, forReason reason: String?) {
        let valueAsDouble = value.asDouble
        if reserveRawInExtra {
            raw.append(valueAsDouble)
        }
        
        guard remainingIgnoreCount == 0 else {
            remainingIgnoreCount -= 1
            return
        }
        
        counter += 1
        sum += value

        
        // Update min/max
        if value < min {
            min = value
            minReason = reason
        }
        if value > max {
            max = value
            maxReason = reason
        }

        // Welford’s algorithm
        let delta = valueAsDouble - mean
        mean += delta / Double(counter)
        let delta2 = valueAsDouble - mean
        m2 += delta * delta2
    }
    
    internal var isRecordingEnded: Bool {
        return true
    }
    
    internal mutating func reset() {
        recorder.reset()
        sum = .zero
        min = .max
        max = .min
        counter = .zero
        remainingIgnoreCount = ignoreValueCount
        raw.removeAll(keepingCapacity: true)
        minReason = nil
        maxReason = nil
        mean = .zero
        m2 = .zero
    }
    
    internal func aggregated<Category: AggregatorCategory>(by category: Category.Type) -> RecorderAggregation<Category, SummationRecorder<Recorder>> {
        RecorderAggregation<Category, SummationRecorder<Recorder>> { category in
            SummationRecorder(base: self.recorder, name: category.narrative)
        }
    }
    
}

@available(iOS 13.0, *)
extension SummationRecorder: Equatable where Recorder: Equatable {
    
    internal static func == (lhs: SummationRecorder, rhs: SummationRecorder) -> Bool {
        lhs.sum == rhs.sum
    }
    
}

@available(iOS 13.0, *)
extension SummationRecorder: Comparable where Recorder: Comparable {
    
    internal static func < (lhs: SummationRecorder, rhs: SummationRecorder) -> Bool {
        lhs.sum < rhs.sum
    }
    
}

@available(iOS 13.0, *)
extension SummationRecorder: IntervalPerformanceIndicatorRecording where Recorder: IntervalPerformanceIndicatorRecording {
    
    internal var interval: ValueType {
        sum
    }
    
    internal mutating func begin(with start: Recorder.ValueType, reason: String? = nil) {
        recorder.begin(with: start, reason: reason)
    }
    
    @discardableResult
    internal mutating func end(with end: Recorder.ValueType, reason: String? = nil) -> Bool {
        if recorder.end(with: end, reason: reason) {
            add(recorder.interval, forReason: reason)
            return true
        }
        return false
    }
    
}

@available(iOS 13.0, *)
extension SummationRecorder: ValuePerformanceIndicatorRecording where Recorder: ValuePerformanceIndicatorRecording {
    
    internal var value: ValueType {
        sum
    }
    
    internal mutating func setValue(_ value: Recorder.ValueType, reason: String? = nil) {
        recorder.setValue(value, reason: reason)
        add(recorder.value, forReason: reason)
    }
    
}

@available(iOS 13.0, *)
internal typealias TimeIntervalRecorder = IntervalRecorder<Double>

@available(iOS 13.0, *)
internal typealias MemoryUsageIntervalRecorder = IntervalRecorder<Int64>

@available(iOS 13.0, *)
internal struct IntervalRecorder<ValueType: PerformanceIndicatorNumberic>: IntervalPerformanceIndicatorRecording {
    
    internal enum Policy: Equatable {
        
        /// The recorder continuously records the interval.
        case continuous
        
        /// The recorder records the interval just once.
        case once
        
        /// The recorder extends the initial interval with last call of
        /// `end`.
        case extendsWithLastEnd
        
    }
    
    /// The states a recorder may transition in between. Different policy
    /// results in different transitionings.
    ///
    private enum State {
        
        case empty
        
        case started(start: ValueType)
        
        case ended(start: ValueType, end: ValueType)
        
        var isStarted: Bool {
            if case .started = self {
                return true
            }
            return false
        }
        
    }
    
    private var state: State = .empty
    
    internal var start: ValueType? {
        switch state {
        case .empty:
            return nil
        case .started(let start):
            return start
        case .ended(let start, _):
            return start
        }
    }
    
    internal private(set) var interval: ValueType = .zero
    
    internal private(set) var reason: String?
    
    internal let policy: Policy
    
    internal init() {
        self.init(policy: .continuous)
    }
    
    internal init(policy: Policy) {
        self.policy = policy
    }
    
    internal mutating func begin(with start: ValueType, reason: String? = nil) {
        switch (policy, state) {
        case (.continuous, .empty), (.continuous, .ended):
            self.state = .started(start: start)
            self.reason = reason
        case (.once, .empty):
            self.state = .started(start: start)
            self.reason = reason
        case (.extendsWithLastEnd, .empty):
            self.state = .started(start: start)
            self.reason = reason
        case (.extendsWithLastEnd, .ended):
            self.reason = reason
        default:
            return
        }
    }
    
    /// - Parameter reason: Could overwrite the `reason` given by begin.
    @discardableResult
    internal mutating func end(with end: ValueType, reason: String? = nil) -> Bool {
        let interval: ValueType
        
        switch (policy, state) {
        case (.continuous,  .started(let start)):
            interval = end - start
            self.state = .ended(start: start, end: end)
        case (.extendsWithLastEnd, .started(let start)):
            // Records the initial interval
            interval = end - start
            self.state = .ended(start: start, end: end)
        case (.extendsWithLastEnd, .ended(let start, _)):
            // Extensive mode
            interval = end - start
            self.state = .ended(start: start, end: end)
        case (.once, .started(let start)):
            interval = end - start
            self.state = .ended(start: start, end: end)
        default:
            return false
        }
        
        self.interval = interval
        self.reason = reason
        
        return true
    }
    
    internal var metrics: [String : NSNumber] {
        [
            "interval" : interval.asNSNumber,
        ]
    }
    
    internal var extra: [AnyHashable : Any]? {
        return [
            "interval" : interval.asNSNumber,
            "reason" : reason ?? "placeholder",
        ]
    }
    
    internal var isRecordingEnded: Bool {
        !state.isStarted
    }
    
    internal mutating func reset() {
        state = .empty
        interval = .zero
    }
    
}

@available(iOS 13.0, *)
extension IntervalRecorder: Equatable where ValueType: Equatable {
    
    internal static func == (lhs: IntervalRecorder, rhs: IntervalRecorder) -> Bool {
        lhs.interval == rhs.interval
    }
}

@available(iOS 13.0, *)
extension IntervalRecorder: Comparable where ValueType: Comparable {
    
    internal static func < (lhs: IntervalRecorder, rhs: IntervalRecorder) -> Bool {
        lhs.interval < rhs.interval
    }
    
}

@available(iOS 13.0, *)
extension IntervalRecorder where ValueType: Comparable {
    
    internal var summed: SummationRecorder<IntervalRecorder<ValueType>> {
        SummationRecorder(base: self, name: "interval")
    }
    
}

@available(iOS 13.0, *)
internal typealias CPUUsageRecorder = ValueRecorder<Double>

@available(iOS 13.0, *)
internal typealias MemoryUsageRecorder = ValueRecorder<UInt64>

@available(iOS 13.0, *)
internal typealias HitchTimeRatioRecorder = ValueRecorder<Double>

@available(iOS 13.0, *)
internal protocol ValuePerformanceIndicatorRecording: PerformanceIndicatorRecording {
    
    var value: ValueType { get }
    
    mutating func setValue(_ value: ValueType, reason: String?)
    
}

@available(iOS 13.0, *)
internal struct ValueRecorder<ValueType: PerformanceIndicatorNumberic>: ValuePerformanceIndicatorRecording {
    
    internal var metrics: [String : NSNumber] {
        [
            "value" : value.asNSNumber,
        ]
    }
    
    internal var extra: [AnyHashable : Any]? {
        nil
    }

    internal private(set) var value: ValueType = .zero

    internal private(set) var reason: String?
    
    internal init() {
        
    }
    
    internal var isRecordingEnded: Bool {
        true
    }
    
    internal mutating func setValue(_ value: ValueType, reason: String?) {
        self.value = value
        self.reason = reason
    }
    
    internal mutating func reset() {
        self.value = .zero
        self.reason = nil
    }
    
}

@available(iOS 13.0, *)
extension ValueRecorder: Equatable where ValueType: Equatable {
    
    internal static func == (lhs: ValueRecorder, rhs: ValueRecorder) -> Bool {
        lhs.value == rhs.value
    }
    
}

@available(iOS 13.0, *)
extension ValueRecorder: Comparable where ValueType: Comparable {
    
    internal static func < (lhs: ValueRecorder, rhs: ValueRecorder) -> Bool {
        lhs.value < rhs.value
    }
    
}

@available(iOS 13.0, *)
extension ValueRecorder where ValueType: Comparable {
    
    internal var summed: SummationRecorder<ValueRecorder<ValueType>> {
        SummationRecorder(base: self, name: "interval")
    }
    
    internal func summed(skip: Int, reserveRawInExtra: Bool = false) -> SummationRecorder<ValueRecorder<ValueType>> {
        SummationRecorder(base: self, name: "interval", skip: skip, reserveRawInExtra: reserveRawInExtra)
    }
}

@available(iOS 13.0, *)
internal struct CountRecorder: PerformanceIndicatorRecording, Comparable {
    
    internal typealias ValueType = Int
    
    internal static func < (lhs: CountRecorder, rhs: CountRecorder) -> Bool {
        lhs.count < rhs.count
    }
    
    internal var metrics: [String : NSNumber] {
        [
            "count" : count.asNSNumber,
        ]
    }
    
    internal var extra: [AnyHashable : Any]? {
        nil
    }

    internal private(set) var count: Int = 0
    
    internal init() {
        
    }
    
    internal var isRecordingEnded: Bool {
        true
    }
    
    internal mutating func hit() {
        self.count += 1
    }
    
    internal mutating func reset() {
        self.count = 0
    }
    
}

@available(iOS 13.0, *)
internal protocol AggregatorCategory: RawRepresentable, Hashable {
    
    var narrative: String { get }
    
}

@available(iOS 13.0, *)
internal struct RecorderAggregation<Category: AggregatorCategory, Recorder: PerformanceIndicatorRecording>: PerformanceIndicatorRecording, Sequence {
    
    internal typealias ValueType = Recorder.ValueType
    
    private var data: [Category: Recorder] = [:]
    
    internal let createRecorder: (Category) -> Recorder

    internal init(createRecorder: @escaping (Category) -> Recorder) {
        self.createRecorder = createRecorder
    }
    
    internal subscript(category: Category) -> Recorder {
        mutating get {
            if let index = data.index(forKey: category) {
                return data.values[index]
            }
            let recorder = createRecorder(category)
            data[category] = recorder
            return recorder
        }
        _modify {
            yield &data[category, default: createRecorder(category)]
        }
    }
    
    internal var metrics: [String : NSNumber] {
        [
            "count" : data.count.asNSNumber
        ]
    }
    
    internal var extra: [AnyHashable : Any]? {
        var extra = [AnyHashable : Any]()
        for (category, recorder) in data {
            var total: [AnyHashable : Any] = [:]
            for (k, v) in recorder.metrics {
                total[k] = v
            }
            if let extra = recorder.extra {
                for (k, v) in extra {
                    total[k] = v
                }
            }
            extra[category.narrative] = total
        }
        return extra
    }
    
    internal mutating func reset() {
        for each in data.indices {
            data.values[each].reset()
        }
    }
    
    internal var isRecordingEnded: Bool {
        return data.reduce(true) { partialResult, element in
            let (_, value) = element
            return partialResult && value.isRecordingEnded
        }
    }
    
    internal typealias Iterator = Dictionary<Category, Recorder>.Iterator
    
    internal func makeIterator() -> Iterator {
        data.makeIterator()
    }
    
}

@available(iOS 13.0, *)
extension RecorderAggregation where Recorder: Comparable {
    
    /// Returns a `TransformableRecorderAggregation` that outputs the
    /// categories whose record is above P-95.
    ///
    internal var aboveP95: TransformableRecorderAggregation<Category, Recorder> {
        return TransformableRecorderAggregation(base: self, name: "p95", transform: { aggregator in
            let contents = aggregator.map { (category, recorder) in
                AggregatedRecorder(category: category, recorder: recorder)
            }
            // Using Top-K to calculate the records "above" the P95
            // samples means to calculate to 0.05 Top-K records.
            let topK = TopK<AggregatedRecorder>(capacity: Int((Double(contents.count) * 0.05).rounded()), contentsOf: contents)
            return topK.values
        })
    }
    
}

/// The internal cache is not thread safe. This type is supposed to be
/// used in the performance auditor's internal queue only.
///
@available(iOS 13.0, *)
internal struct TransformableRecorderAggregation<Category: AggregatorCategory, Recorder: PerformanceIndicatorRecording>: PerformanceIndicatorRecording {
    
    internal typealias ValueType = Recorder.ValueType
    
    private class Cache {
        
        fileprivate var records: [AggregatedRecorder<Category, Recorder>]?
        
    }
    
    internal var aggregator: RecorderAggregation<Category, Recorder>
    
    internal let name: String
    
    internal let transform: (RecorderAggregation<Category, Recorder>) -> [AggregatedRecorder<Category, Recorder>]
    
    private let cache: Cache
    
    internal init(base baseAggregator: RecorderAggregation<Category, Recorder>, name: String, transform: @escaping (RecorderAggregation<Category, Recorder>) -> [AggregatedRecorder<Category, Recorder>]) {
        self.aggregator = baseAggregator
        self.name = name
        self.transform = transform
        self.cache = Cache()
    }
    
    internal mutating func reset() {
        aggregator.reset()
        cache.records = nil
    }
    
    internal var isRecordingEnded: Bool {
        aggregator.isRecordingEnded
    }
    
    internal subscript(category: Category) -> Recorder {
        mutating get {
            return aggregator[category]
        }
        _modify {
            defer {
                resetCacheIfNeeded()
            }
            yield &aggregator[category]
        }
    }
    
    internal var metrics: [String : NSNumber] {
        let records = self.cachedTransformedRecordsIfNeeded()
        return [
            "count" : records.count.asNSNumber
        ]
    }
    
    internal var extra: [AnyHashable : Any]? {
        let records = self.cachedTransformedRecordsIfNeeded()
        return Dictionary(records.map({
            ($0.category.narrative, $0.extra)
        }), uniquingKeysWith: {$1})
    }
    
    private func resetCacheIfNeeded() {
        if cache.records != nil {
            cache.records = nil
        }
    }
    
    private func cachedTransformedRecordsIfNeeded() -> [AggregatedRecorder<Category, Recorder>] {
        if let records = cache.records {
            return records
        } else {
            let records = transform(aggregator)
            cache.records = records
            return records
        }
    }
    
}

@available(iOS 13.0, *)
internal struct AggregatedRecorder<Category: AggregatorCategory, Recorder: PerformanceIndicatorRecording>: PerformanceIndicatorDetailsReadable {
    
    internal var metrics: [String : NSNumber] {
        recorder.metrics
    }
    
    internal var extra: [AnyHashable : Any]? {
        recorder.extra
    }
    
    internal let category: Category
    
    internal let recorder: Recorder
    
}

@available(iOS 13.0, *)
extension AggregatedRecorder: Equatable where Recorder: Equatable {
    
    internal static func == (lhs: AggregatedRecorder, rhs: AggregatedRecorder) -> Bool {
        return lhs.recorder == rhs.recorder
    }
    
}

@available(iOS 13.0, *)
extension AggregatedRecorder: Comparable where Recorder: Comparable {
    
    internal static func < (lhs: AggregatedRecorder, rhs: AggregatedRecorder) -> Bool {
        return lhs.recorder < rhs.recorder
    }
    
}

// MARK: Log

@available(iOS 13.0, *)
internal enum PerformanceLogKeyword: String, LogKeyword {
    
    case measuring
    
    case commiting
    
    internal static var moduleName: String { "Performance" }
}

@available(iOS 13.0, *)
extension LogService.Module where K == PerformanceLogKeyword {
    
    internal static let performance: Self = .init()
    
}

#if DEBUG

@available(iOS 13.0, *)
extension PerformanceData {
    
    internal func testableIncreaseViewRendererPerRenderUpdateActionCount() {
        viewRendererPerRenderUpdateActionCount += 1
    }
    
}

#endif // DEBUG

#else // FEAT_MONITOR

@available(iOS 13.0, *)
internal class PerformanceAuditor {
    
}

#endif // FEAT_MONITOR
