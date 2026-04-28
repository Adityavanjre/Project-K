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

@usableFromInline
@available(iOS 13.0, *)
internal struct BloomFilter: Equatable {

    @usableFromInline
    internal var value: UInt

    @usableFromInline
    internal init(hashValue: Int) {
        let value = UInt(hashValue)
        let a0 = 1 &<< (value &>> 0x10)
        let a1 = 1 &<< (value &>> 0xa)
        let a2 = 1 &<< (value &>> 0x4)
        self.value = a0 | a1 | a2
    }
    
    @usableFromInline
    internal init(type: Any.Type) {
        let pointer = unsafeBitCast(type, to: OpaquePointer.self)
        self.init(hashValue: Int(bitPattern: pointer))
    }
}
