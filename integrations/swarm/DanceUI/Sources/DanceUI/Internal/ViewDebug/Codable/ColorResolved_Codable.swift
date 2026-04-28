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
extension Color.Resolved: Codable {
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let red = try container.decode(Float.self)
        let green = try container.decode(Float.self)
        let blue = try container.decode(Float.self)
        let alpha = try container.decode(Float.self)
        let (linearRed, linearGreen, linearBlue) = (sRGBToLinear(red), sRGBToLinear(green), sRGBToLinear(blue))
        self.init(linearRed: linearRed, linearGreen: linearGreen, linearBlue: linearBlue, opacity: alpha)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(red)
        try container.encode(green)
        try container.encode(blue)
        try container.encode(alpha)
    }
}

@available(iOS 13.0, *)
extension GraphicsFilter.ColorMonochrome: Codable {
    
    private enum CodingKeys: CodingKey, Hashable  {
        
        case color
        
        case amount
        
        case bias
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(amount, forKey: .amount)
        try container.encode(bias, forKey: .bias)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = try container.decode(Color.Resolved.self, forKey: .color)
        self.amount = try container.decode(Float.self, forKey: .amount)
        self.bias = try container.decode(Float.self, forKey: .bias)
    }
}

@available(iOS 13.0, *)
extension ResolvedShadowStyle: Codable {
    
    fileprivate enum CodingKeys: Hashable, CodingKey {
        case color
        
        case radius
        
        case offset
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(radius, forKey: .radius)
        try container.encode(offset, forKey: .offset)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = try container.decode(Color.Resolved.self, forKey: .color)
        self.radius = try container.decode(CGFloat.self, forKey: .radius)
        self.offset = try container.decode(CGSize.self, forKey: .offset)
    }
}

#endif
