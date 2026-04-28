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

@available(iOS 13.0, *)
internal protocol EventBindingManagerDelegate: AnyObject {

    func didBind(to binding: EventBinding, id: EventID)

    func didUpdate(phase: GesturePhase<()>, in manager: EventBindingManager)

    func didUpdate(gestureCategory: GestureCategory, in manager: EventBindingManager)

    func willActivateBinding(_ eventBinding: EventBinding, for id: EventID)

    func didUpdateBinding(_ eventBinding: EventBinding, for id: EventID)

    func willDeactivateBinding(_ eventBinding: EventBinding, for id: EventID)

}

@available(iOS 13.0, *)
extension EventBindingManagerDelegate {
    
    internal func didBind(to binding: EventBinding, id: EventID) {
        
    }
    
    internal func didUpdate(gestureCategory: GestureCategory, in manager: EventBindingManager) {
        
    }
    
}
