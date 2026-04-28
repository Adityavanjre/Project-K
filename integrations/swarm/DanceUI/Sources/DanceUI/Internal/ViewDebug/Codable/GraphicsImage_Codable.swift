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

internal struct CodableCGImage: CodableProxy, Encodable {

    internal var base : CGImage
    
    internal func encode(to encoder: Encoder) throws {
    }

    private enum Error: Hashable, Swift.Error {
        
        case imageData
        
        case invalidImageType
    }
}

@available(iOS 13.0, *)
extension GraphicsImage: Encodable {
    
    private enum CodingKeys: CodingKey, Hashable {
        case data
        
        case color
        
        case contents
        
        case scale
        
        case size
        
        case orientation
        
        case maskColor
        
        case resizingInfo
        
        case antialiased
        
        case interpolation
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let contents = contents {
            switch contents {
            case .cgImage(let image):
                let codableCGImage = CodableCGImage(base: image)
                try container.encode(codableCGImage, forKey: .data)
            case .color(let color):
                try container.encode(color, forKey: .color)
            default:
                break
            }
        }
        try container.encode(scale, forKey: .scale)
        try container.encode(unrotatedPixelSize, forKey: .size)
        try container.encode(orientation.rawValue, forKey: .orientation)
        try container.encodeIfPresent(maskColor, forKey: .maskColor)
        try container.encodeIfPresent(resizingInfo, forKey: .resizingInfo)
        try container.encode(isAntialiased, forKey: .antialiased)
        try container.encode(interpolation.codingProxy, forKey: .interpolation)
    }
}

#endif
