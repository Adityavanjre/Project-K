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
@_spi(DanceUI) import DanceUIObservation

@available(iOS 13.0, *)
internal struct StaticBody<Accessor: BodyAccessor>: StatefulRule, BodyAccessorRule, ObservationAttribute {

    internal typealias Value = Accessor.Body

    internal let accessor: Accessor

    @Attribute
    internal var container: Accessor.Container

    internal var previousObservationTrackings: [ObservationTracking]?

    internal var deferredObservationGraphMutation: DeferredObservationGraphMutation?

    internal static var container: Any.Type {
        Accessor.Container.self
    }

    internal static func value<A>(as type: A.Type, attribute: DGAttribute) -> A? {
        guard type == self.container else {
            return nil
        }
        return attribute.info.body.assumingMemoryBound(to: self.self).pointee.container as? A
    }

    internal static func buffer<A>(as type: A.Type, attribute: DGAttribute) -> _DynamicPropertyBuffer? {
        nil
    }

    internal static func metaProperties<A>(as type: A.Type, attribute: DGAttribute) -> [(String, DGAttribute)] {
        guard type == self.container else {
            return []
        }
        return [
            ("@self", attribute.info.body.assumingMemoryBound(to: self.self).pointee._container.identifier)
        ]
    }

    internal mutating func updateValue() {
        let (container, isContainerChanged) = $container.changedValue()
        withObservation(shouldCancelPrevious: isContainerChanged) { [accessor] in
            accessor.updateBody(of: container, changed: true)
        }
    }

}
