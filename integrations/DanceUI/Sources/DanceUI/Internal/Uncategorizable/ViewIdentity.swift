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
internal struct ViewIdentity: Hashable {

    internal let seed: UInt32

    private static var nextSeed: UInt32 = 0x1
    
    @inline(__always)
    private init(seed: UInt32) {
        self.seed = seed
    }
    
    @inlinable
    internal static var zero: ViewIdentity {
        ViewIdentity(seed: 0x0)
    }
    
    @inlinable
    internal static func make() -> ViewIdentity {
        defer {
            let newNextSeed = nextSeed &+ 1
            if newNextSeed != 0x1 {
                nextSeed = newNextSeed
            }
        }
        return ViewIdentity(seed: nextSeed)
    }
    
    internal struct Tracker {

        internal var id: ViewIdentity

        internal var resetSeed: UInt32
    }
}
