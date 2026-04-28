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
extension View {
    
    internal func accessibilityAction<Action: AccessibilityValueAction>(_ action: Action, _ handler: @escaping (Action.Value) -> ()) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityActions([AnyAccessibilityActionHandler(action: action, handler: handler)])
    }
    
    internal func accessibilityActions(_ actions: [AnyAccessibilityActionHandler]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibility(\.actions, actions)
    }
}

@available(iOS 13.0, *)
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {
    
    internal func accessibilityAction<A1: AccessibilityValueAction>(_ action: A1, _ handler: @escaping (A1.Value) -> ()) -> ModifiedContent<Content, Modifier> {
        accessibilityActions([AnyAccessibilityActionHandler(action: action, handler: handler)])
    }
    
    internal func accessibilityActions(_ actions: [AnyAccessibilityActionHandler]) -> ModifiedContent<Content, Modifier> {
        guard !actions.isEmpty else {
            return self
        }
        return modifiedAccessibilityProperties {
            var actions = actions
            actions.append(contentsOf: $0.actions)
            $0.actions = actions
        }
    }
    
}

@available(iOS 13.0, *)
internal protocol AccessibilityValueAction: Equatable {
    
    associatedtype Value

}
