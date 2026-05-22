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
internal protocol LeafViewLayout {
    
    func spacing() -> Spacing
    
    func sizeThatFits(in size: _ProposedSize) -> CGSize
    
}

@available(iOS 13.0, *)
extension LeafViewLayout {
    internal func spacing() -> Spacing {
        .zeroText
    }
}

@available(iOS 13.0, *)
extension LeafViewLayout {
    
    internal static func makeLeafLayout(_ outputs: inout _ViewOutputs, view: _GraphValue<Self>, inputs: _ViewInputs) {
        outputs.setLayout(inputs) {
            Attribute(LeafLayoutComputer(view: view.value))
        }
    }
}
