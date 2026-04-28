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

@available(iOS 13.0, *)
public typealias BenchmarkResult = BenchmarkResultV0

@available(iOS 13.0, *)
public typealias BenchmarkResults = BenchmarkResultsV0

@available(iOS 13.0, *)
public struct BenchmarkResultV0: Codable {
    public struct MetricData: Codable {
        public let min: Double
        public let max: Double
        public let avg: Double
        public let mean: Double
        public let stdev: Double
        public let count: Int
        public let raw: [Double]?
        
        public init(min: Double, max: Double, avg: Double, mean: Double, stdev: Double, count: Int, raw: [Double]?) {
            self.min = min
            self.max = max
            self.avg = avg
            self.mean = mean
            self.stdev = stdev
            self.count = count
            self.raw = raw
        }
    }
    
    public let version: String
    public let timestamp: Date
    public let testName: String?
    
    // Performance metrics
    public let cpuUsage: MetricData?
    public let appMemoryUsage: MetricData?
    public let hitchTimeRatio: MetricData?
    public let viewControllerFirstFrameRenderDuration: MetricData?
    
    public init(
        version: String = "0.0.3",
        timestamp: Date = Date(),
        testName: String? = nil,
        cpuUsage: MetricData? = nil,
        appMemoryUsage: MetricData? = nil,
        hitchTimeRatio: MetricData? = nil,
        viewControllerFirstFrameRenderDuration: MetricData? = nil
    ) {
        self.version = version
        self.timestamp = timestamp
        self.testName = testName
        self.cpuUsage = cpuUsage
        self.appMemoryUsage = appMemoryUsage
        self.hitchTimeRatio = hitchTimeRatio
        self.viewControllerFirstFrameRenderDuration = viewControllerFirstFrameRenderDuration
    }
}

@available(iOS 13.0, *)
extension BenchmarkResult {
    
    /// Convert BenchmarkResult to JSON Data
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
    
    /// Create BenchmarkResult from JSON Data
    public static func fromJSONData(_ data: Data) throws -> BenchmarkResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BenchmarkResult.self, from: data)
    }
    
    /// Convert BenchmarkResult to JSON String
    public func toJSONString() throws -> String {
        let data = try toJSONData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "BenchmarkResult", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"])
        }
        return string
    }
}

@available(iOS 13.0, *)
public struct BenchmarkResultsV0: Codable {
    public let version: String
    public let timestamp: Date
    public let results: [BenchmarkResult]
    
    public init(
        version: String = "0.0.3",
        timestamp: Date = Date(),
        results: [BenchmarkResult]
    ) {
        self.version = version
        self.timestamp = timestamp
        self.results = results
    }
}


@available(iOS 13.0, *)
extension BenchmarkResults {
    
    /// Convert BenchmarkResults to JSON Data
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
    
    /// Create BenchmarkResults from JSON Data
    public static func fromJSONData(_ data: Data) throws -> BenchmarkResults {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BenchmarkResults.self, from: data)
    }
    
    /// Convert BenchmarkResults to JSON String
    public func toJSONString() throws -> String {
        let data = try toJSONData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "BenchmarkResults", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"])
        }
        return string
    }
}


#endif
