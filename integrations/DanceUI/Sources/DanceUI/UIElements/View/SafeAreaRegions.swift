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

/// A set of symbolic safe area regions.
@frozen
@available(iOS 13.0, *)
public struct SafeAreaRegions: OptionSet {
    
    /// All safe area regions.
    public static let all: SafeAreaRegions = .init(rawValue: .max)

    /// The safe area defined by the device and containers within the user interface, including elements such as top and bottom bars.
    public static let container: SafeAreaRegions = .init(rawValue: 0x1)
    
    /// The safe area matching the current extent of any software keyboard displayed over the view content.
    public static let keyboard: SafeAreaRegions = .init(rawValue: 0x2)
    
    internal static let e_0x8: SafeAreaRegions = .init(rawValue: 0x8)

    /// The corresponding value of the raw type.
    public let rawValue: UInt
    
    /// Creates a new option set from the given raw value.
    @inlinable
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
}
