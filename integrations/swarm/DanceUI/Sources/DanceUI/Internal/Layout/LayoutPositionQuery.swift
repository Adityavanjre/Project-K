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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct LayoutPositionQuery: StatefulRule {

    internal typealias Value = ViewOrigin

    @Attribute
    internal var parentPosition: ViewOrigin

    @Attribute
    internal var localPosition: ViewOrigin


    internal mutating func updateValue() {
        let parentPosition = self.parentPosition.value
        var newPosition: CGPoint = localPosition.value
        newPosition.x += parentPosition.x
        newPosition.y += parentPosition.y
        value = ViewOrigin(value: newPosition)
    }
}
