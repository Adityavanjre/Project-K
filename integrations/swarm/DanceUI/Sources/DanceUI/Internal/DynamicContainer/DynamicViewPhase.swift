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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct DynamicViewPhase: Rule {

    internal typealias Value = _GraphInputs.Phase

    @Attribute
    internal var info: DynamicContainer.Info

    @Attribute
    internal var phase: _GraphInputs.Phase

    internal let uniqueId: UInt32

    internal var value: _GraphInputs.Phase {
        var phase = phase
        let info = info
        guard let index = info.indexMap[uniqueId] else {
            return phase
        }
        phase.seed &+= info.items[index].resetSeed
        phase.invisible = info.items[index].phase == .didRemove
        return phase
    }

}
