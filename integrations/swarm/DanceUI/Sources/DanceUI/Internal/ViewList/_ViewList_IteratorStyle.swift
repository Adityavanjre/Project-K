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
internal struct _ViewList_IteratorStyle: Equatable {

    @usableFromInline
    internal var value: UInt

    @inlinable
    internal var headerFooterStyle: _ViewList_IteratorStyle {
        _ViewList_IteratorStyle(multiplier: multiplier,
                                needsMultiplier: headerFooterNeedsMultiplier)
    }

    @inlinable
    internal static var `default`: _ViewList_IteratorStyle {
        .init(multiplier: 0x1, needsMultiplier: false)
    }

    @inlinable
    internal init(multiplier: Int,
                  needsMultiplier: Bool = false) {
        self.value = 0
        self.multiplier = multiplier
        self.needsMultiplier = needsMultiplier
    }

    @inlinable
    internal var multiplier: Int {
        get {
            Int(value >> 0x1)
        }
        set {
            let needsMultiplier = value & 0x1
            value = (UInt(newValue) << 0x1) | needsMultiplier
        }
    }

    @inlinable
    internal var needsMultiplier: Bool {
        get {
            (value & 0x1) != 0
        }
        set {
            value &= (UInt.max - 1)
            value |= newValue ? 0x1 : 0x0
        }
    }

    private var headerFooterNeedsMultiplier: Bool {
        multiplier != 0x1
    }

    @inlinable
    internal func backward(from index: Int) -> Int {
        if multiplier != 1 {
            let remainder = index % multiplier
            if remainder != 0 {
                return index + (multiplier - remainder)
            }
        }
        return index
    }

    internal func alignToPreviousGranularityMultiple(_ value: inout Int) {
        guard value != 0 && multiplier != 0x1 else {
            return
        }
        value &-= (value % multiplier)
    }

}
