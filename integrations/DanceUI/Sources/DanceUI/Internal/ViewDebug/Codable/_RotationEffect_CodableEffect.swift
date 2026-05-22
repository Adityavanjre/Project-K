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
extension _RotationEffect: CodableByProxy {
    
    internal typealias CodingProxy = _RotationEffect.CodableEffect
    
    internal static func unwrap(codingProxy: CodableEffect) -> _RotationEffect {
        _RotationEffect(angle: codingProxy.angle, anchor: codingProxy.anchor)
    }
    
    internal var codingProxy: CodableEffect {
        CodableEffect(angle: angle, anchor: anchor)
    }
}

@available(iOS 13.0, *)
extension _RotationEffect {
    
    internal struct CodableEffect: Encodable {
        
        @ProxyCodable
        internal var angle: Angle
        
        @ProxyCodable
        internal var anchor: UnitPoint
        
        private enum CodingKeys: CodingKey, Hashable {
            
            case angle
            
            case anchor
            
        }
        
    }
}

@available(iOS 13.0, *)
extension Angle: CodableByProxy {
    @inline(__always)
    internal static func unwrap(codingProxy: Double) -> Angle {
        Angle(radians: codingProxy)
    }
    
    @inline(__always)
    internal var codingProxy: Double {
        self.radians
    }
}

@available(iOS 13.0, *)
extension UnitPoint: CodableByProxy {
    
    @inline(__always)
    internal var codingProxy: CodableUnitPoint {
        .init(base: self)
    }
}

@available(iOS 13.0, *)
internal struct CodableUnitPoint: CodableProxy {
    
    internal var base: UnitPoint
    
    internal func encode(to encoder: Encoder) throws {
        
    }
}

#endif
