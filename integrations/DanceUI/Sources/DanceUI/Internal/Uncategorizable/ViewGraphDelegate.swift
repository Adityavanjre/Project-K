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
internal protocol ViewGraphDelegate: GraphDelegate {

    func `as`<OtherType>(_ type: OtherType.Type) -> OtherType?

    func modifyViewInputs(_ inputs: inout _ViewInputs)

    func updateViewGraph<R>(body: (ViewGraph) -> R) -> R

    func outputsDidChange(outputs: ViewGraph.Outputs)

    func focusDidChange()

    func rootTransform() -> ViewTransform

}

@available(iOS 13.0, *)
extension ViewGraphDelegate {

    internal func `as`<OtherType>(_ otherType: OtherType.Type) -> OtherType? {
        nil
    }
    
    internal func updateGraph<R>(body: (GraphHost) -> R) -> R {
        updateViewGraph(body: body)
    }

    internal func rootTransform() -> ViewTransform {
        ViewTransform()
    }

}
