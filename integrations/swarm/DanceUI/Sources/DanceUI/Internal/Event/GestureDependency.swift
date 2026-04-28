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
internal enum GestureDependency {

    case none

    case pausedWhileActive

    /// For continuous gesture
    case pausedUntilFailed

    /// For discrete gesture
    case failIfActive

    @inlinable
    internal var canBePrevented: Bool {
        switch self {
        case .none, .failIfActive:
            return true
        case .pausedWhileActive, .pausedUntilFailed:
            return false
        }
    }

    internal struct Key: PreferenceKey {
        
        internal static var defaultValue: GestureDependency {
            .none
        }
        
        internal static func reduce(value: inout GestureDependency, nextValue: () -> GestureDependency) {
            let table: [GestureDependency: Int] = [
              .none: 0,
              .pausedWhileActive: 1,
              .pausedUntilFailed: 2,
              .failIfActive: 3,
            ]

            // Pseudo-decode:
            let left = table[value]!
            let right = table[nextValue()]!
            if right < left {
              value = nextValue()
            }
        }
        
    }
    
}
