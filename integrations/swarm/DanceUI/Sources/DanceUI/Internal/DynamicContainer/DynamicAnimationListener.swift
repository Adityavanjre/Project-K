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
internal final class DynamicAnimationListener: AnimationListener {

    internal weak var viewGraph: ViewGraph?

    internal let asyncSignal: WeakAttribute<()>

    private var count: Int

    internal init(viewGraph: ViewGraph?, asyncSignal: WeakAttribute<()>) {
        self.viewGraph = viewGraph
        self.asyncSignal = asyncSignal
        self.count = 0
    }

    internal var isAnimating: Bool {
        count != 0
    }

    internal func animationWasAdded() {
        count &+= 1
    }

    internal func animationWasRemoved() {
        count &-= 1
        guard count == 0 else {
            return
        }

        guard let viewGraph = viewGraph else {
            return
        }
        viewGraph.continueTransaction { [weak self] in
            guard let self = self else {
                return
            }
            guard let attribute = self.asyncSignal.attribute else {
                return
            }
            attribute.invalidateValue()
        }
    }

    internal func checkDispatched() {
        _intentionallyLeftBlank()
    }

}
