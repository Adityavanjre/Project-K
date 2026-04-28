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
extension StackLayout {
    
    internal struct Child: CustomDebugStringConvertible {
        
        internal var layoutPriority: Double
        
        internal var majorAxisRangeCache: MajorAxisRangeCache
        
        internal var distanceToPrevious: CGFloat
        
        internal var fittingOrder: Int
        
        internal var offer: _ProposedSize
        
        internal var geometry: ViewGeometry
        
        internal var lastProposedSize: _ProposedSize?
        
        @usableFromInline
        internal mutating func cleanMajorAxisRangeCache() {
            majorAxisRangeCache.min = nil
            majorAxisRangeCache.max = nil
        }
        
        internal var debugDescription: String {
            "<StackLayout.Child>: layoutPriority: \(layoutPriority); majorAxisRangeCache:\(majorAxisRangeCache); distanceToPrevious: \(distanceToPrevious); fittingOrder: \(fittingOrder); geometry: \(geometry)"
        }
    }
}

@available(iOS 13.0, *)
extension UnsafeMutableBufferPointer where Element == StackLayout.Child {
    
    @usableFromInline
    internal func find(_ startIndex: Int = 0, endIndex: Int = 0, condition: (Element) -> Bool) -> (index: Int, child: Element)? {
        guard startIndex < endIndex else {
            return nil
        }
        var index = startIndex
        while index < endIndex {
            let value = self[index]
            let reslut: Bool = condition(value)
            if reslut {
                return (index, value)
            }
            index &+= 1
        }
        return nil
    }
    
    @usableFromInline
    internal func reduce<Result>(_ initialResult: Result, startIndex: Int = 0, endIndex: Int = 0, _ nextPartialResult: (Result, Self.Element) -> Result) -> Result {
        guard startIndex < endIndex else {
            return initialResult
        }
        
        var result: Result = initialResult
        var index = startIndex
        while index < endIndex {
            let value = self[index]
            result = nextPartialResult(result, value)
            index &+= 1
        }
        return result
    }
}
