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
internal struct BitVector64: OptionSet, CustomStringConvertible {
    
    @inlinable
    internal init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    internal var rawValue: UInt64
    
    @inlinable
    internal init() {
        self.init(rawValue: 0)
    }
    
    @inlinable
    internal static var zero: BitVector64 {
        BitVector64(rawValue: 0x0)
    }
    
    @inlinable
    internal static var max: BitVector64 {
        BitVector64(rawValue: 0x3f)
    }
    
    internal var description: String {
        return "<BitVector64; rawValue = 0b\(String(rawValue, radix: 2))>"
    }
    
    @inlinable
    internal subscript(bit: Int) -> Bool {
        get {
            return (rawValue & (0b1 << bit)) != 0
        }
        mutating set {
            if newValue {
                rawValue = rawValue | (0b1 << bit)
            } else {
                rawValue = rawValue & ~(0b1 << bit)
            }
        }
    }
    
    @inlinable
    internal mutating func containing<S: Sequence>(points: S, predicate: (CGPoint) -> Bool) where S.Element == CGPoint {
        for (index, point) in points.enumerated() {
            self[index] = index < 64 ? predicate(point) : false
        }
    }
    
    @inlinable
    internal func contained<S: Sequence>(points: S, predicate: (CGPoint) -> Bool) -> BitVector64 where S.Element == CGPoint {
        var copied = self
        copied.containing(points: points, predicate: predicate)
        return copied
    }
    
}
