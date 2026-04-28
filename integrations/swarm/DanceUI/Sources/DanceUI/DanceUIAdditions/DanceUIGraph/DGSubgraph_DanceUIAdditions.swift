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
extension DGSubgraphRef {

    internal func willRemove() {
        forEach(.removable) { attribute in
            if let removableType = attribute._bodyType.type as? RemovableAttribute.Type {
                removableType.willRemove(attribute: attribute)
            }
        }
    }
    
    internal func didReinsert() {
        forEach(.removable) { attribute in

            if let observationType = attribute._bodyType.type as? ObservationAttribute.Type {
                observationType.scheduleDeferredObservationGraphMutation(attribute: attribute)
            }

            if let removableType = attribute._bodyType.type as? RemovableAttribute.Type {
                removableType.didReinsert(attribute: attribute)
            }
        }
    }
}

@available(iOS 13.0, *)
extension DGSubgraphRef {

    /// Repalces `willRemove`
    internal func willInvalidate(isInserted: Bool) {
        forEach(isInserted ? [.removable, .invalidatable] : .invalidatable) { attribute in
            let attributeType = attribute._bodyType.type
            if let invalidatable = attributeType as? InvalidatableAttribute.Type {
                invalidatable.willInvalidate(attribute: attribute)
            } else if isInserted, let removable = attributeType as? RemovableAttribute.Type {
                removable.willRemove(attribute: attribute)
            }
        }
    }
    
}
