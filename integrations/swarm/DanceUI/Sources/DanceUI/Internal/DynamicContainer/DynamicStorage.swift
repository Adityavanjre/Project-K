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
internal final class DynamicStorage {

    internal var identifier : AnyHashable {
        _abstract(self)
    }

    internal var needsTransitions: Bool {
        _abstract(self)
    }

    internal func makeView<A: DynamicContainerAdaptor>(uniqueId: UInt32, container: Attribute<DynamicContainer.Info>, inputs: _ViewInputs, adaptor: A.Type) -> _ViewOutputs where A.Item == AnyDynamicItem {
        _abstract(self)
    }

    internal func matchesIdentity(of: DynamicStorage) -> Bool {
        _abstract(self)
    }

    internal func visitContent<A: ViewVisitor>(_: inout A, phase: TransitionPhase) {
        _abstract(self)
    }

}
