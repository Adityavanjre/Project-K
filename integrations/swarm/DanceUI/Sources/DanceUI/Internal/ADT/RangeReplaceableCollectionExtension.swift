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

extension RangeReplaceableCollection where Self : MutableCollection {

    /// Removes all the elements at the specified offsets from the collection.
    ///
    /// - Complexity: O(*n*) where *n* is the length of the collection.
    ///
    public mutating func remove(atOffsets offsets: IndexSet) {
        for range in offsets.rangeView.reversed() {
            let lower = index(startIndex, offsetBy: range.lowerBound)
            let upper = index(startIndex, offsetBy: range.upperBound)
            removeSubrange(lower..<upper)
        }
    }
}
