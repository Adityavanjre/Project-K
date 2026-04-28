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
internal class PlatformUnaryViewResponder: UIViewResponder_FeatureGestureContainer {
    internal init(layoutResponder: DefaultLayoutViewResponder) {
        self.layoutResponder = layoutResponder
        super.init()
        layoutResponder.parent = self
    }
    
    internal var layoutResponder: DefaultLayoutViewResponder
    
    internal override var children: [ViewResponder] {
        [layoutResponder]
    }
    
    internal override func bindEvent(_ event: any EventType) -> ResponderNode? {
        layoutResponder.bindEvent(event)
    }
    
    internal override func makeGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        layoutResponder.makeGesture(inputs: inputs)
    }
    
    internal override func makeGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        layoutResponder.makeGesture(inputs: inputs)
    }
    
    internal override func resetGesture() {
        layoutResponder.resetGesture()
    }
    
    internal override func visit(applying visitor: (ResponderNode) -> ResponderVisitorResult) -> ResponderVisitorResult {
        layoutResponder.visit(applying: visitor)
    }
}
