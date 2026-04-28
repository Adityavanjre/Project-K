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
internal struct StyleBodyAccessor<A: StyleModifier, B: StyleableView>: BodyAccessor {

    internal typealias Container = A.Style

    internal typealias Body = A.SubjectBody

    @Attribute
    internal var view: B

    internal func updateBody(of container: Container, changed: Bool) {

        let (view, isViewChanged) = $view.changedValue()

        guard changed || isViewChanged else {
            return
        }

        if let subject = view as? A.Subject {
            setBody {
                A.body(view:subject, style:container)
            }
        }
    }
}
