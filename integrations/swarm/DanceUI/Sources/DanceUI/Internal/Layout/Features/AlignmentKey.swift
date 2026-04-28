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

@usableFromInline
@available(iOS 13.0, *)
@frozen
internal struct AlignmentKey: Hashable, Comparable {
    
    @usableFromInline
    internal enum AlignmentBits: Hashable, Comparable {
        
        case horizontal(AlignmentID.Type)
        case vertical(AlignmentID.Type)
        
        @usableFromInline
        internal func hash(into hasher: inout Hasher) {
            switch self {
            case .horizontal(let type):
                hasher.combine(ObjectIdentifier(type))
            case .vertical(let type):
                hasher.combine(ObjectIdentifier(type))
            }
        }
        
        @usableFromInline
        internal static func < (lhs: AlignmentKey.AlignmentBits, rhs: AlignmentKey.AlignmentBits) -> Bool {
            switch (lhs, rhs) {
                case (.horizontal(let lhsType), .horizontal(let rhsType)):
                    return ObjectIdentifier(lhsType) < ObjectIdentifier(rhsType)
                case (.vertical(let lhsType), .vertical(let rhsType)):
                    return ObjectIdentifier(lhsType) < ObjectIdentifier(rhsType)
                default:
                    return false
            }
        }
        
        @usableFromInline
        internal static func == (lhs: AlignmentKey.AlignmentBits, rhs: AlignmentKey.AlignmentBits) -> Bool {
            switch (lhs, rhs) {
                case (.horizontal(let lhsType), .horizontal(let rhsType)):
                    return lhsType == rhsType
                case (.vertical(let lhsType), .vertical(let rhsType)):
                    return lhsType == rhsType
                default:
                    return false
            }
        }
    }
    
    @usableFromInline
    internal let bits: AlignmentBits
    
    @usableFromInline
    internal var id: AlignmentID.Type {
        switch bits {
        case .horizontal(let type):
            return type
        case .vertical(let type):
            return type
        }
    }
    
    @usableFromInline
    internal static func < (lhs: AlignmentKey, rhs: AlignmentKey) -> Bool {
        return lhs.bits < rhs.bits
    }
    
    @usableFromInline
    internal static func == (lhs: AlignmentKey, rhs: AlignmentKey) -> Bool {
        return lhs.bits == rhs.bits
    }
    
    @usableFromInline
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(self.bits)
    }
}

@available(iOS 13.0, *)
extension ViewGeometry {
    
    @usableFromInline
    internal func originValue(for alignment: AlignmentKey) -> CGFloat {
        switch alignment.bits {
        case .horizontal :
            return origin.value.x
        case .vertical:
            return origin.value.y
        }
    }
}
