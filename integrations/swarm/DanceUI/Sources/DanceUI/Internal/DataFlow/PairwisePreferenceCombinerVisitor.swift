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

@available(iOS 13.0, *)
internal struct PairwisePreferenceCombinerVisitor: PreferenceKeyVisitor {
    
    internal var outputs: (_ViewOutputs, _ViewOutputs)

    internal var result: _ViewOutputs
    
    @inline(__always)
    internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
        
        let value0 = outputs.0[key]
        let value1 = outputs.1[key]
        
        guard value0 != nil || value1 != nil else {
            return
        }
        
        if let firstValue = value0, let secondValue = value1 {
            result[key] = .init(PairPreferenceCombiner<Key>(attributes: (firstValue, secondValue)))
        } else {
            result[key] = value0 ?? value1
        }
    }
    
}
