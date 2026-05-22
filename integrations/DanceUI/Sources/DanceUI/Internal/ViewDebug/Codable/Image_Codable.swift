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
internal struct CodableImageInterpolation : CodableProxy {
    
    private enum CodingValue : Int, RawRepresentable, Decodable, Encodable {
        
        case none
        
        case low
        
        case medium
        
        case high
        
        fileprivate typealias RawValue = Int
        
        fileprivate func toBase() -> Base {
            switch self {
            case .none:
                return .none
            case .low:
                return .low
            case .medium:
                return .medium
            case .high:
                return .high
            }
        }
        
        fileprivate init(base: Image.Interpolation) {
            switch base {
            case .none:
                self = .none
            case .low:
                self = .low
            case .medium:
                self = .medium
            case .high:
                self = .high
            }
        }
        
    }
    
    internal typealias Base = Image.Interpolation
    
    internal var base: Image.Interpolation
    
    internal init(base: Image.Interpolation) {
        self.base = base
    }
    
    internal init(from: Decoder) throws {
        let container = try from.singleValueContainer()
        let codingValue = try container.decode(CodingValue.self)
        self.base = codingValue.toBase()
    }
    
    internal func encode(to: Encoder) throws {
        var container = to.singleValueContainer()
        try container.encode(CodingValue(base: base))
    }
}

@available(iOS 13.0, *)
extension Image.Interpolation: CodableByProxy {
    
    @inline(__always)
    internal var codingProxy : CodableImageInterpolation {
        CodableImageInterpolation(base: self)
    }
}

@available(iOS 13.0, *)
internal struct CodableImageResizingMode : CodableProxy {
    
    internal enum CodingValue : Int, RawRepresentable, Decodable, Encodable {
        
        case tile
        
        case stretch
        
        internal typealias RawValue = Int
        
        fileprivate func toBase() -> Base {
            switch self {
            case .tile:
                return .tile
            case .stretch:
                return .stretch
            }
        }
        
        fileprivate init(base: Image.ResizingMode) {
            switch base {
            case .tile:
                self = .tile
            case .stretch:
                self = .stretch
            }
        }
    }
    
    internal typealias Base = Image.ResizingMode
    
    internal var base: Image.ResizingMode
    
    internal init(base: Image.ResizingMode) {
        self.base = base
    }
    
    internal init(from: Decoder) throws {
        let container = try from.singleValueContainer()
        let codingCalue = try container.decode(CodingValue.self)
        self.base = codingCalue.toBase()
        
    }
    
    internal func encode(to: Swift.Encoder) throws {
        var container = to.singleValueContainer()
        try container.encode(CodingValue(base: base))
    }
}

@available(iOS 13.0, *)
extension Image.ResizingMode: CodableByProxy {
    
    internal var codingProxy: CodableImageResizingMode {
        CodableImageResizingMode(base: self)
    }
}

@available(iOS 13.0, *)
extension Image.ResizingInfo: Encodable {
    
    fileprivate enum CodingKeys: String, CodingKey, Hashable {
        
        case capInsets
        
        case mode
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(capInsets.codingProxy, forKey: .capInsets)
        try container.encode(mode.codingProxy, forKey: .mode)
    }
}

@available(iOS 13.0, *)
extension Image.Orientation : CodableByProxy {
        
    internal static func unwrap(codingProxy: UInt8) -> Image.Orientation {
        
        guard let orientation = Image.Orientation(rawValue: codingProxy) else {
            _danceuiFatalError("can not resolve codingProxy to orientation")
        }
        return orientation
    }
    
    internal var codingProxy: UInt8 {
        rawValue
    }
}

#endif
