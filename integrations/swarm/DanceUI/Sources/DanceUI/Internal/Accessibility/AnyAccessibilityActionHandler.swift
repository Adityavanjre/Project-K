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
internal struct AnyAccessibilityActionHandler {

    fileprivate let box: AnyAccessibilityActionHandlerBoxBase
    
    internal init<Action: AccessibilityValueAction>(action: Action, handler: @escaping (Action.Value) -> ()) {
        self.box = AnyAccessibilityActionHandlerBox(action: action, handler: handler)
    }
    
    @inline(__always)
    internal func perform<A1: AccessibilityValueAction>(action: A1, value: A1.Value) -> Bool {
        box.perform(action: action, value: value)
    }
    
    @inline(__always)
    internal func matches<A1: AccessibilityValueAction>(action: A1) -> Bool {
        box.matches(action: action)
    }
    
    @inline(__always)
    internal func namedAction() -> AccessibilityNamedActionHandler? {
        box.namedAction()
    }
    
    @inline(__always)
    internal func handler<A1: AccessibilityValueAction>(for action: A1) -> ((A1.Value) -> ())? {
        box.handler(for: action)
    }

}

@available(iOS 13.0, *)
fileprivate class AnyAccessibilityActionHandlerBoxBase {
    
    @inlinable
    internal func perform<A1: AccessibilityValueAction>(action: A1, value: A1.Value) -> Bool {
        _abstract(self)
    }
    
    @inlinable
    internal func matches<A1: AccessibilityValueAction>(action: A1) -> Bool {
        _abstract(self)
    }
    
    @inlinable
    internal func namedAction() -> AccessibilityNamedActionHandler? {
        _abstract(self)
    }
    
    @inlinable
    internal func handler<A1: AccessibilityValueAction>(for action: A1) -> ((A1.Value) -> Void)? {
        _abstract(self)
    }

}

@available(iOS 13.0, *)
private final class AnyAccessibilityActionHandlerBox<Action: AccessibilityValueAction>: AnyAccessibilityActionHandlerBoxBase {

    fileprivate let action: Action

    fileprivate let handler: (Action.Value) -> ()
    
    deinit {
        _intentionallyLeftBlank()
    }
    
    @inline(__always)
    fileprivate init(action: Action, handler: @escaping (Action.Value) -> ()) {
        self.action = action
        self.handler = handler
    }
    
    @inlinable
    internal override func perform<A: AccessibilityValueAction>(action: A, value: A.Value) -> Bool {
        guard matches(action: action) else {
            return false
        }
        
        Update.enqueueAction {
            guard let handler = self.handler as? (A.Value) -> () else {
                return
            }
            handler(value)
        }
        
        return true
    }
    
    @inlinable
    internal override func matches<A1: AccessibilityValueAction>(action: A1) -> Bool {
        guard let action = action as? Action else {
            return false
        }
        
        return action == self.action
    }
    
    @inlinable
    internal override func namedAction() -> AccessibilityNamedActionHandler? {
        guard let action = action as? AccessibilityVoidAction else {
            return nil
        }
        guard case let .named(named) = action.kind.kind else {
            return nil
        }
        
        return AccessibilityNamedActionHandler(name: named) {
            if let handler = self.handler as? (Void) -> Void {
                handler(())
            }
        }
    }
    
    @inlinable
    internal override func handler<A1: AccessibilityValueAction>(for action: A1) -> ((A1.Value) -> ())? {
        guard matches(action: action) else {
            return nil
        }
     
        guard let handler = handler as? (A1.Value) -> () else {
            return nil
        }
        return handler
    }

}
