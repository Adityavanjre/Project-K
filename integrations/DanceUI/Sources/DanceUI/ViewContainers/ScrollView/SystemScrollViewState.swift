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
internal struct SystemScrollViewState {
    

    internal var contentOffset: CGPoint
    

    internal var systemContentInsets: EdgeInsets
    

    internal var systemTranslation: CGSize
    

    internal var contentOffsetMode: ContentOffsetMode
    

    internal var updateSeed: UInt32
    
    internal func adjustContentOffset(by offset: CGSize, state: Attribute<SystemScrollViewState>) {
        guard offset != .zero else {
            return
        }
        
        let contentOffsetX = max(offset.width + contentOffset.x, 0)
        let contentOffsetY = max(offset.height + contentOffset.y, 0)
                
        let newState = SystemScrollViewState(
            contentOffset: CGPoint(x: contentOffsetX, y: contentOffsetY),
            systemContentInsets: systemContentInsets,
            systemTranslation: systemTranslation,
            contentOffsetMode: .adjustment(required: true),
            updateSeed: updateSeed
        )
        let attribute = WeakAttribute(state)
        newState.commit(to: attribute)
    }
    
    internal func commit(to state: WeakAttribute<SystemScrollViewState>) {
        
        guard let stateAttr = state.attribute else {
            return
        }
        
        let viewGraph = stateAttr.graph.graphHost()
        
        var transaction = Transaction()
        transaction.fromScrollView = true
        
        let mutation = CommitMutation(state: state, value: self)
        
        viewGraph.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: false)
        
        Update.enqueueAction {
            viewGraph.flushTransactions()
        }
    }
    
    private struct CommitMutation: GraphMutation {
        
#if DEBUG || DANCE_UI_INHOUSE
        @inline(__always)
        internal init(state: WeakAttribute<SystemScrollViewState>, value: SystemScrollViewState, file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) {
            _state = state
            self.value = value
            self.file = file
            self.line = line
            self.function = function
        }
#else
        @inline(__always)
        internal init(state: WeakAttribute<SystemScrollViewState>, value: SystemScrollViewState) {
            _state = state
            self.value = value
        }
#endif
        
        @WeakAttribute
        internal var state: SystemScrollViewState?
        
        internal var value: SystemScrollViewState
        
#if DEBUG || DANCE_UI_INHOUSE

        internal let file: StaticString
        

        internal let line: UInt
        

        internal let function: StaticString
#endif
        
        internal func apply() {
            
            guard let stateAttribute = $state else {
                return
            }
            let _ = stateAttribute.setValue(value)
        }
        
        mutating func combine<T: GraphMutation>(with mutation: T) -> Bool {
            guard let commitMutation = mutation as? CommitMutation else {
                return false
            }
            if $state == commitMutation.$state {
                self.value = commitMutation.value
                return true
            }
            
            return false
        }
        
    }

    internal enum ContentOffsetMode: CustomStringConvertible {

        case adjustment(required: Bool)

        indirect case target(ContentOffsetTarget, animated: Bool) // 1

        case system
        
        var isTarget: Bool {
            switch self {
            case .target:
                return true
            default:
                return false
            }
        }
        
        var description: String {
            switch self {
            case let .adjustment(required):
                return "<ContentOffsetMode; .adjustment(required = \(required))>"
            case let .target(contentOffsetTarget, animated):
                return "<ContentOffsetMode; .target(contentCffsetTarget = \(String(describing: contentOffsetTarget)), animated = \(animated)>"
            case .system:
                return "<ContentOffsetMode; .system>"
            }
        }

    }
}
