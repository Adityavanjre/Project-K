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
internal import DanceUIRuntime

@available(iOS 13.0, *)
internal struct BodyUnaryViewGenerator: UnaryViewGenerator {

    internal let body: (_ViewInputs) -> _ViewOutputs

    internal func makeView(inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?) -> _ViewOutputs {
        body(inputs)
    }

    internal func tryToReuse(by generator: BodyUnaryViewGenerator, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        DGCompareValues(lhs: self.body, rhs: generator.body)
    }

}
