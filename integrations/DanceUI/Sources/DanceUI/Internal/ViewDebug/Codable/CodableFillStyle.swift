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
internal struct CodableFillStyle: CodableProxy {
    
    internal var base: FillStyle
    
    internal func encode(to encoder: Encoder) throws {
        
    }
    
    private enum CodingKeys: CodingKey, Hashable {
        
        case eoFilled
        
        case antialiased
        
    }
    
}

@available(iOS 13.0, *)
extension FillStyle : CodableByProxy {
    
    @inline(__always)
    internal var codingProxy: CodableFillStyle {
        .init(base: self)
    }
}

#endif
