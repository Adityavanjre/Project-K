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
extension ViewModifier {
    
    /// Returns a new version of the modifier that will apply the
    /// transaction mutation function `transform` to all transactions
    /// within the modifier.
    @inlinable
    public func transaction(_ transform: @escaping (inout Transaction) -> Void) -> some ViewModifier {
        _PushPopTransactionModifier(content: self, transform: transform)
    }
  
    /// Returns a new version of the modifier that will apply
    /// `animation` to all animatable values within the modifier.
    @inlinable
    public func animation(_ animation: Animation?) -> some ViewModifier {
        return transaction { t in
            if !t.disablesAnimations {
                t.animation = animation
            }
        }
    }
}
