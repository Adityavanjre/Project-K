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
internal class ResponderNode: ResponderNodeVisualDebug {
    
    internal init() {}

    internal var nextResponder: ResponderNode? {
        preconditionFailure("")
    }

    internal func bindEvent(_ event: any EventType) -> ResponderNode? {
        nil
    }

    @discardableResult
    internal func visit(applying visitor: (ResponderNode) -> ResponderVisitorResult) -> ResponderVisitorResult {
        visitor(self)
    }

    /// - Note: Pre-gesture-container process
    internal func makeGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        _abstract(self)
    }

    internal func makeGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        _GestureOutputs(inputs: inputs)
    }

    internal func resetGesture() {
        _intentionallyLeftBlank()
    }
    
    internal final var sequence: ResponderSequence {
        ResponderSequence(node: self)
    }
    
    internal final var sequenceFeatureGestureContainer: some Sequence<ResponderNode> {
        Swift.sequence(first: self) { $0.nextResponder }
    }
    
    internal final func isDescendant(of responder: ResponderNode) -> Bool {
        if DanceUIFeature.gestureContainer.isEnable {
            for eachNext in sequenceFeatureGestureContainer where eachNext === responder {
                return true
            }
        } else {
            for eachNext in sequence where eachNext === responder {
                return true
            }
        }
        return false
    }
    
    internal final func firstAncestor<T>(ofType type: T.Type = T.self) -> T? {
        Swift.sequence(first: self) { $0.nextResponder }
            .first(ofType: type)
    }

    internal var asUIViewResponder: AnyUIViewResponder? {
        nil
    }
    
    // MARK: Deprecated
    
    @available(*, deprecated, message: "Pre-gesture-container process.")
    internal func visitFocusResponders(applying body: (FocusResponder) -> ResponderVisitorResult) {
        visit { node in
            if let focuseResponder = node as? FocusResponder {
                return body(focuseResponder)
            } else {
                return .continue
            }
        }
    }
    
    @available(*, deprecated, message: "Pre-gesture-container process.")
    internal func log(_ triggers: _EventDebugTriggers, action: String, data: Any?)  {
        #warning("not implemented")
    }

    @available(*, deprecated, message: "Pre-gesture-container process.")
    internal func log(action: String, data: Any?) {
        #warning("not implemented")
    }
}

// MARK: - ResponderVisitorResult

@available(iOS 13.0, *)
internal enum ResponderVisitorResult {
    
    /// Guessed semantics: not found
    @available(*, deprecated, renamed: "next")
    static var `continue`: ResponderVisitorResult { .next }
    
    /// Guessed semantics: found
    @available(*, deprecated, renamed: "cancel")
    static var stop: ResponderVisitorResult { .cancel }
    
    case next
    
    case skipToNextSibling
    
    case cancel
    
}

// MARK: - Sequence

@available(iOS 13.0, *)
extension Sequence {
    
    internal func first<T>(ofType: T.Type) -> T? {
        first { $0 is T } as? T
    }
    
}

internal struct ResponderSequence: Sequence {
    
    internal let node: ResponderNode
    
    @inline(__always)
    internal func makeIterator() -> Iterator {
        Iterator(node: node)
    }
    
    internal struct Iterator: IteratorProtocol {
        
        internal var node: ResponderNode?
        
        @inline(__always)
        internal init(node: ResponderNode) {
            self.node = node
        }
        
        @inline(__always)
        internal mutating func next() -> ResponderNode? {
            let retVal = node
            node = node?.nextResponder
            return retVal
        }
        
    }
    
}
