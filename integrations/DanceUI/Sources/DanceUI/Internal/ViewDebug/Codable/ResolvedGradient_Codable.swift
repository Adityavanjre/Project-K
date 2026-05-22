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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
extension ResolvedGradient: Codable {
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stops = try container.decode([Stop].self, forKey: .stops)
        self.colorSpace = try container.decode(ColorSpace.self, forKey: .colorSpace)
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.stops, forKey: .stops)
        try container.encode(self.colorSpace, forKey: .colorSpace)
    }
    
    fileprivate enum CodingKeys: Hashable, CodingKey {
        case stops
        case colorSpace
    }
}

@available(iOS 13.0, *)
extension ResolvedGradient.Stop: Codable {
    
    fileprivate enum CodingKeys: Hashable, CodingKey {
        
        case color
        
        case location
    }
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = try container.decode(Color.Resolved.self, forKey: .color)
        self.location = try container.decode(CGFloat.self, forKey: .location)
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.color, forKey: .color)
        try container.encode(self.location, forKey: .location)
    }
}

#endif
