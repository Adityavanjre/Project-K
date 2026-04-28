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

private class AnyEquatableBox {
    
    internal func isEqual(_ rhs: AnyEquatableBox) -> Bool {
        self === rhs
    }
}

private final class _AnyEquatableBox<Value: Equatable>: AnyEquatableBox {
    
    internal let value : Value
    
    internal override func isEqual(_ rhs: AnyEquatableBox) -> Bool {
        guard let rhs = rhs as? _AnyEquatableBox<Value> else {
            return false
        }
        return value == rhs.value
    }
    
    internal init(value: Value) {
        self.value = value
    }
    
}

struct AnyEquatable: Equatable {
    
    fileprivate var box : AnyEquatableBox
    
    internal init<V: Equatable>(value: V) {
        self.box = _AnyEquatableBox(value: value)
    }
    
    internal static func == (lhs: AnyEquatable, rhs: AnyEquatable) -> Bool {
        lhs.box.isEqual(rhs.box)
    }
    
}
