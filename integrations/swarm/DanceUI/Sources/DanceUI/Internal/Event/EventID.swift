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
internal struct EventID: Hashable, CustomStringConvertible {

    internal var type: Any.Type

    internal var serial: Int

    var description: String {
        "<\(Swift.type(of: self)): type = \(type); serial = 0x\(String(UInt(bitPattern: serial), radix: 16))>"
    }
    
    internal static func == (lhs: EventID, rhs: EventID) -> Bool {
        lhs.type == rhs.type && lhs.serial == rhs.serial
    }
    
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
        hasher.combine(serial)
    }

}
