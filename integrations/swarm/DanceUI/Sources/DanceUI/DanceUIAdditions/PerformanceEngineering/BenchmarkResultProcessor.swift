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

import Foundation
import Darwin

@available(iOS 13.0, *)
public class BenchmarkResultProcessor {
    /// Constants for options dictionary keys
    public struct OptionsKeys {
        public static let benchmarkOutputPath = "benchmark_output_path"
    }
    
    public static func benchmarkResult(from dict: [AnyHashable: Any]) -> BenchmarkResult {
        let testName = dict["test_name"] as? String ?? dict[CoreTestBenchmarkAuditor.CategoryKeys.performanceCaseTestName] as? String
        
        return BenchmarkResult(
            testName: testName,
            cpuUsage: extractMetricData(from: dict, prefix: "cpuUsage"),
            appMemoryUsage: extractMetricData(from: dict, prefix: "appMemoryUsage"),
            hitchTimeRatio: extractMetricData(from: dict, prefix: "hitchTimeRatio"),
            viewControllerFirstFrameRenderDuration: extractMetricData(from: dict, prefix: "viewControllerFirstFrameRenderDuration")
        )
    }
    
    public static func benchmarkResults(from results: [BenchmarkResult]) -> BenchmarkResults {
        return BenchmarkResults(results: results)
    }
    
    /// Write BenchmarkResults to file with customizable output path
    /// - Parameter results: The BenchmarkResults to write
    /// - Parameter customPath: Optional custom file path. If nil, uses environment variable or default path
    public static func writeBenchmarkResultsToFile(_ results: BenchmarkResults, customPath: String? = nil) {
        do {
            let filePath = customPath ?? getOutputFilePath()
            let jsonString = try results.toJSONString()
            
            // Create directory if it doesn't exist
            let directoryURL = URL(fileURLWithPath: filePath).deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
                print("Removed existing file at: \(filePath)")
            }
            
            // Write to file
            try jsonString.write(toFile: filePath, atomically: true, encoding: .utf8)
            
            print("BenchmarkResults written to: \(filePath)")
        } catch {
            print("Failed to write BenchmarkResults to file: \(error)")
        }
    }
    
    /// Get output file path based on environment variable or default timestamp-based path
    /// - Parameter suffix: Optional suffix to append to filename
    /// - Returns: File path string
    private static func getOutputFilePath(suffix: String = "") -> String {
        // Default path with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestampString = formatter.string(from: Date())
        
        // Use different base directories for simulator vs real device to fix save permissino issue
        #if targetEnvironment(simulator)
        let baseDirectory = "/tmp/com.bytedance.DanceUICompose/Benchmarks"
        #else
        let baseDirectory = NSTemporaryDirectory() + "com.bytedance.DanceUICompose/Benchmarks"
        #endif
        let fileName = timestampString + suffix + ".json"
        return baseDirectory + "/" + fileName
    }
    
    private static func extractMetricData(from dict: [AnyHashable: Any], prefix: String) -> BenchmarkResult.MetricData? {
        let minKey = "\(prefix)_min"
        let maxKey = "\(prefix)_max"
        let avgKey = "\(prefix)_avg"
        let meanKey = "\(prefix)_mean"
        let stdevKey = "\(prefix)_stdev"
        let countKey = "\(prefix)_count"
        let rawKey = "\(prefix)_raw"
        
        guard let min = extractDouble(from: dict, key: minKey),
              let max = extractDouble(from: dict, key: maxKey),
              let avg = extractDouble(from: dict, key: avgKey),
              let mean = extractDouble(from: dict, key: meanKey),
              let stdev = extractDouble(from: dict, key: stdevKey),
              let count = extractInt(from: dict, key: countKey)
        else {
            return nil
        }
        let raw = extractDoubleArray(from: dict, key: rawKey)
        
        // Handle infinity values for min/max
        let normalizedMin = min == Double.greatestFiniteMagnitude ? 0 : min
        let normalizedMax = max == -Double.greatestFiniteMagnitude ? 0 : max
        
        // Convert memory values from bytes to MiB
        let isMemory = isMemoryMetric(prefix: prefix)
        
        return BenchmarkResult.MetricData(
            min: isMemory ? bytesToMiB(normalizedMin) : normalizedMin,
            max: isMemory ? bytesToMiB(normalizedMax) : normalizedMax,
            avg: isMemory ? bytesToMiB(avg) : avg,
            mean: isMemory ? bytesToMiB(mean) : mean,
            stdev: isMemory ? bytesToMiB(stdev) : stdev,
            count: count,
            raw: raw
        )
    }
    
    private static func isMemoryMetric(prefix: String) -> Bool {
        return prefix.contains("Memory") || prefix.contains("memory")
    }
    
    private static func bytesToMiB(_ bytes: Double) -> Double {
        return bytes / (1024 * 1024)
    }

    private static func extractDouble(from dict: [AnyHashable: Any], key: String) -> Double? {
        if let nsNumber = dict[key] as? NSNumber {
            return nsNumber.doubleValue
        }
        return dict[key] as? Double
    }
    
    private static func extractInt(from dict: [AnyHashable: Any], key: String) -> Int? {
        if let nsNumber = dict[key] as? NSNumber {
            return nsNumber.intValue
        }
        return dict[key] as? Int
    }
    
    private static func extractDoubleArray(from dict: [AnyHashable: Any], key: String) -> [Double]? {
        if let nsNumber = dict[key] as? NSArray {
            return nsNumber as? [Double]
        }
        return dict[key] as? [Double]
    }
}

#endif
