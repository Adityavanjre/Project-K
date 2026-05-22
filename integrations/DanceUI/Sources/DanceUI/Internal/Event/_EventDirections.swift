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

@available(iOS 13.0, *)
public struct _EventDirections: OptionSet, Equatable {
    
    public typealias ArrayLiteralElement = _EventDirections
    
    public typealias Element = _EventDirections
    
    public typealias RawValue = Int8
    
    public let rawValue: Int8
    
    public static let left: _EventDirections = .init(rawValue: 1 << 0)

    public static let right: _EventDirections = .init(rawValue: 1 << 1)

    public static let up: _EventDirections = .init(rawValue: 1 << 2)

    public static let down: _EventDirections = .init(rawValue: 1 << 3)

    public static let horizontal: _EventDirections = [.left, .right]

    public static let vertical: _EventDirections = [.up, .down]

    public static let all: _EventDirections = [.horizontal, .vertical]

    internal static let empty: _EventDirections = _EventDirections(rawValue: 0)
    
    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }
    
}
