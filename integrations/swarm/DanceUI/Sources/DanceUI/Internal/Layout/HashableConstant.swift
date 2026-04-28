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
internal protocol _Constant {

    func hash(into hasher: inout Hasher)

    func isEqual(to other: _Constant) -> Bool

}

@available(iOS 13.0, *)
internal struct HashableConstant: Hashable {

    internal var value: _Constant

    internal init<ValueType>(_ value: ValueType, id: Int) {
        self.value = Constant(value: value, id: id)
    }

    internal func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }

    internal static func == (lhs: HashableConstant, rhs: HashableConstant) -> Bool {
        lhs.value.isEqual(to: rhs.value)
    }
}
