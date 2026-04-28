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

#if FEAT_MONITOR && FEAT_COMPOSE_BENCHMARK

internal import DanceUIGraph
import Foundation

// MARK: - CoreTestBenchmarkAuditor

@available(iOS 13.0, *)
@_spi(ForDanceUIExtensionOnly)
final public class CoreTestBenchmarkAuditor: Auditor<CoreTestBenchmarkData> {
    typealias Data = CoreTestBenchmarkData
    
    @_spi(ForDanceUIExtensionOnly)
    override public init() {}
    
    private var storedResults: [BenchmarkResult] = []
    
    @_spi(ForDanceUIExtensionOnly)
    public struct CategoryKeys {
        
        public static var performanceCaseTestName: String {
            "performance_case_test_name"
        }
        
        public static var version: String {
            "core_test_benchmark_version"
        }
    }
    
    internal override func commit(on timing: PerformanceIndicatorCommitTiming, category: [AnyHashable : Any]) {        
        var metrics = [String : NSNumber]()
        var extra = [AnyHashable : Any]()
        
        
        for eachMetadata in CoreTestBenchmarkData.metadata where !eachMetadata.commitTiming.isDisjoint(with: timing) {
            eachMetadata.assemble(from: self.data, intoMetrics: &metrics, extra: &extra)
        }
        
        for eachMetadata in CoreTestBenchmarkData.metadata where !eachMetadata.commitTiming.isDisjoint(with: timing) {
            eachMetadata.reset(self.data)
        }
        
        var mergedCategory = category
        mergedCategory[CoreTestBenchmarkAuditor.CategoryKeys.version] = Data.version

        // Convert metrics to AnyHashable dictionary for processor
        var metricsDict = [AnyHashable: Any]()
        for (key, value) in metrics {
            metricsDict[key] = value
        }
        for (key, value) in mergedCategory {
            metricsDict[key] = value
        }
        
        for eachMetadata in CoreTestBenchmarkData.metadata where !eachMetadata.commitTiming.isDisjoint(with: timing) {
            let name = eachMetadata.name
            guard let dict = extra[name] as? [AnyHashable: Any] else {
                continue
            }
            for (key, value) in dict {
                metricsDict["\(name)_\(key)"] = value
            }
        }
        let benchmarkResult = BenchmarkResultProcessor.benchmarkResult(from: metricsDict)
        storedResults.append(benchmarkResult)
    }
    
    @_spi(ForDanceUIExtensionOnly)
    public func outputStoredResults(config: BenchmarkConfig) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            underlyingQueue.async { [self] in
                guard !storedResults.isEmpty else {
                    print("No benchmark results to output")
                    continuation.resume()
                    return
                }
                
                let benchmarkResults = BenchmarkResultProcessor.benchmarkResults(from: storedResults)
                BenchmarkResultProcessor.writeBenchmarkResultsToFile(benchmarkResults, customPath: config.outputPath)
                
                print("Benchmark results output completed")
                print("Total results: \(benchmarkResults.results.count)")
                
                storedResults.removeAll()
                continuation.resume()
            }
        }
    }
    
    @_spi(ForDanceUIExtensionOnly)
    public var storedResultsCount: Int {
        return storedResults.count
    }
}

// MARK: - HostBenchmarkData

@available(iOS 13.0, *)
@_spi(ForDanceUIExtensionOnly)
public final class CoreTestBenchmarkData: PerformanceIndicatorCollection {
    
    public init() {}
    
    public static var version: String {
        return "0.0.2"
    }
    
    public static let metadata: [PerformanceIndicatorMetadata<CoreTestBenchmarkData>] = [
        TypedPerformanceIndicatorMetadata(
            name: "cpuUsage",
            recorder: \.cpuUsageRecorder,
            commitTiming: [.coreTestCaseFinished]
        ),
        TypedPerformanceIndicatorMetadata(
            name: "appMemoryUsage",
            recorder: \.appMemoryUsageRecorder,
            commitTiming: [.coreTestCaseFinished]
        ),
        TypedPerformanceIndicatorMetadata(
            name: "hitchTimeRatio",
            recorder: \.hitchTimeRatioRecorder,
            commitTiming: [.coreTestCaseFinished]
        ),
        TypedPerformanceIndicatorMetadata(
            name: "viewControllerFirstFrameRenderDuration",
            recorder: \.viewControllerFirstFrameRenderDurationsRecorder,
            commitTiming: [.coreTestCaseFinished]
        ),
    ]
    
    internal var cpuUsageRecorder = CPUUsageRecorder().summed(skip: 3, reserveRawInExtra: true)
    
    internal var appMemoryUsageRecorder = MemoryUsageRecorder().summed
    
    internal var hitchTimeRatioRecorder = HitchTimeRatioRecorder().summed
    
    internal var viewControllerFirstFrameRenderDurationsRecorder = TimeIntervalRecorder().summed
}

@available(iOS 13.0, *)
extension Auditor where Data == CoreTestBenchmarkData {
    public func emitCPUUsage(_ usage: Double, reason: String? = nil) {
        enqueueDataChanges { data in
            data.cpuUsageRecorder.setValue(usage, reason: reason)
        }
    }

    public func emitAppMemoryUsage(_ usage: UInt64, reason: String? = nil) {
        enqueueDataChanges { data in
            data.appMemoryUsageRecorder.setValue(usage, reason: reason)
        }
    }
    
    public func emitHitchTimeRatio(_ ratio: Double, reason: String? = nil) {
        enqueueDataChanges { data in
            data.hitchTimeRatioRecorder.setValue(ratio, reason: reason)
        }
    }

    public func traceViewControllerFirstFrameRenderBegin() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewControllerFirstFrameRenderDurationsRecorder.begin(with: time)
        }
    }
    
    public func traceViewControllerFirstFrameRenderEnd() {
        let time = CACurrentMediaTime()
        enqueueDataChanges { data in
            data.viewControllerFirstFrameRenderDurationsRecorder.end(with: time)
        }
    }
}

#endif
