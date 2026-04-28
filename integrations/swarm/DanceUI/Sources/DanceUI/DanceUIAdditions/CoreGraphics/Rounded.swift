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
extension CGSize {
    
    internal mutating func round(_ rule: FloatingPointRoundingRule, toMultipleOf multiple: CGFloat) {
        width.round(rule, toMultipleOf: multiple)
        height.round(rule, toMultipleOf: multiple)
    }
    
}

@available(iOS 13.0, *)
extension FloatingPoint where Self == CGFloat {
    
    @inline(__always)
    internal mutating func round(_ rule: FloatingPointRoundingRule,
                        toMultipleOf: Self) {
        self = toMultipleOf == 1 ? self : self / toMultipleOf
        switch rule {
        case .toNearestOrAwayFromZero:
            self = CGFloat(Darwin.round(Double(self)))
        case .toNearestOrEven:
            self = CGFloat(rint(Double(self)))
        case .up:
            self = CGFloat(ceil(Double(self)))
        case .down:
            self = CGFloat(floor(Double(self)))
        case .awayFromZero:
            self = CGFloat(self < 0.0 ? floor(Double(self)) : ceil(Double(self)))
        default:
            self.round(rule)
        }
        self = self * toMultipleOf
    }
    
    @inline(__always)
    internal func roundedToNearestOrUp(toMultipleOf: Self) -> Self {
        var value = toMultipleOf * 0.5 + self
        value.round(.down, toMultipleOf: toMultipleOf)
        return value
    }
    
}

@available(iOS 13.0, *)
extension CGRect {
    
    @inline(__always)
    internal mutating func roundCoordinatesToNearestOrUp(toMultipleOf multiple: CGFloat) {
        _danceuiPrecondition(!isNull && !isInfinite)
        self = self.standardized

        let maxWidth: CGFloat = origin.x + size.width
        let maxHeight: CGFloat = origin.y + size.height
        
        origin.roundToNearestOrUp(toMultipleOf: multiple)

        var maxX: CGFloat = maxWidth + multiple * 0.5
        maxX.round(.down, toMultipleOf: multiple)

        var maxY: CGFloat = maxHeight + multiple * 0.5
        maxY.round(.down, toMultipleOf: multiple)
        
        size.width = maxX - origin.x
        size.height = maxY - origin.y
        
        size.width.round(.toNearestOrAwayFromZero, toMultipleOf: multiple)
        size.height.round(.toNearestOrAwayFromZero, toMultipleOf: multiple)
    }
    
}

@available(iOS 13.0, *)
extension CGPoint {
    
    @inline(__always)
    internal mutating func roundToNearestOrUp(toMultipleOf multiple: CGFloat) {
        x += (multiple * 0.5)
        y += (multiple * 0.5)
        
        x.round(.down, toMultipleOf: multiple)
        y.round(.down, toMultipleOf: multiple)
    }
    
    @inline(__always)
    internal var isInvalid: Bool {
        x.isInvalid || y.isInvalid
    }
}

@available(iOS 13.0, *)
extension CGSize {
    @inline(__always)
    internal var isInvalid: Bool {
        width.isInvalid || height.isInvalid
    }
}

@available(iOS 13.0, *)
extension CGFloat {
    @inline(__always)
    internal var isInvalid: Bool {
        self.isNaN || self.isInfinite
    }
    
    @inline(__always)
    internal var isNegative: Bool {
        self < 0
    }
}
