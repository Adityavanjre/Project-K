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
public struct BenchmarkConfig: Codable {
    public let outputPath: String?
    public let defaultRepeatCount: Int
    public let repeatCountConfig: [String: Int]
    
    private enum CodingKeys: String, CodingKey {
        case outputPath = "output_path"
        case defaultRepeatCount = "default_repeat_count"
        case repeatCountConfig = "repeat_count_config"
    }
    
    public init(outputPath: String? = nil, defaultRepeatCount: Int = 10, repeatCountConfig: [String: Int] = [:]) {
        self.outputPath = outputPath
        self.defaultRepeatCount = defaultRepeatCount
        self.repeatCountConfig = repeatCountConfig
    }
    
    /// Get repeat count for a specific test name
    /// - Parameter testName: The name of the test
    /// - Returns: The repeat count for this test, or defaultRepeatCount if not specified
    public func repeatCount(module: String? = nil, caseName: String) -> Int {
        let result = if let module {
            repeatCountConfig["\(module).\(caseName)"] ?? repeatCountConfig[caseName]
        } else {
            repeatCountConfig[caseName]
        }
        return result ?? defaultRepeatCount
    }
    
    /// Shared instance loaded from environment or defaults
    public static let compose: BenchmarkConfig = {
        return loadFromEnvironmentOrDefault("DANCEUI_BENCHMARK_COMPOSE_CONFIG")
    }()
    
    private static func loadFromEnvironmentOrDefault(_ key: String) -> BenchmarkConfig {
        // Check for environment variable
        guard let configPath = ProcessInfo.processInfo.environment[key] else {
            print("BenchmarkConfig: No config path found in environment, using defaults")
            return BenchmarkConfig()
        }
        
        // Try to load from file
        do {
            let url = URL(fileURLWithPath: configPath)
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(BenchmarkConfig.self, from: data)
            print("BenchmarkConfig: Loaded config from \(configPath)")
            return config
        } catch {
            print("BenchmarkConfig: Failed to load config from \(configPath): \(error)")
            print("BenchmarkConfig: Falling back to defaults")
            return BenchmarkConfig()
        }
    }
    
    #if DEBUG
    /// Save the current config to a file
    /// - Parameter path: The file path to save to
    /// - Throws: Encoding or file writing errors
    public func save(to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        
        let url = URL(fileURLWithPath: path)
        
        // Create directory if it doesn't exist
        let directoryURL = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        
        try data.write(to: url)
        print("ComposeBenchmarkConfig: Saved config to \(path)")
    }
    
    /// Create a sample config file for reference
    /// - Parameter path: The file path to save the sample to
    /// - Throws: Encoding or file writing errors
    public static func createSampleConfig(at path: String) throws {
        let sampleConfig = BenchmarkConfig(
            outputPath: "/tmp/benchmark.json",
            defaultRepeatCount: 50,
            repeatCountConfig: [
                "ExamplePerformanceTestCase": 100,
                "AnimatedPage": 30,
                "ImageLoadPage": 20,
                "LongListImageResortPage": 10,
                "LongListTextPage": 25,
                "LongTextPage0": 40,
                "LongTextPage1": 40,
                "SlideTestView": 60
            ]
        )
        try sampleConfig.save(to: path)
    }
    #endif
}

#endif
