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
internal class MultiViewResponder: ViewResponder {
    
    private var _children: [ViewResponder]

    internal var cache: ContainsPointsCache

    internal var observers: ContentPathObservers

    internal func updateChildren(_ data: (value: [ViewResponder], changed: Bool)) {
        guard data.changed else {
            return
        }
        children = data.value
    }

    internal func childrenDidChange() {
        observers.notify()
    }
    
    internal override var children: [ViewResponder] {
        get {
            _children
        }
        set {
            var didInsertOrSwap = false
            
            var newIndex: Int = 0
            
            while newIndex < newValue.endIndex {
                let newChild = newValue[newIndex]
                
                if newChild.parent === self {
                    // When newChild's parent is self, then it was in children.
                    
                    let remainedSubrange = newIndex..<_children.count
                    
                    let oldIndex = _children[remainedSubrange].firstIndex(where: {$0 === newChild})!
                    
                    _children.swapAt(oldIndex, newIndex)
                    
                    newIndex += 1
                    
                    didInsertOrSwap = true
                    
                } else {
                    // Else, it was not in children.
                    newChild.parent = self

                    _children.append(newChild)
                    
                    didInsertOrSwap = true
                }
            }
            
            let needsRemove = newValue.count < _children.count
            
            if needsRemove {
                let removedRange = newValue.count..<_children.count
                _children[removedRange].forEach { child in
                    child.parent = nil
                }
                _children.replaceSubrange(removedRange, with: EmptyCollection())
            }
            
            if didInsertOrSwap || needsRemove {
                childrenDidChange()
            }
            
        }
    }
    
    internal override init() {
        _children = []
        cache = ContainsPointsCache()
        observers = ContentPathObservers()
        super.init()
    }
    
    internal override func bindEvent(_ event: EventType) -> ResponderNode? {
        for each in _children {
            if let bindNode = each.bindEvent(event) {
                return bindNode
            }
        }
        return nil
    }
    
    internal override func visit(applying visitor: (ResponderNode) -> ResponderVisitorResult) -> ResponderVisitorResult {
        let result = visitor(self)
        guard result == .continue else {
            return result
        }
        for each in _children {
            if each.visit(applying: visitor) == .stop {
                return .stop
            }
        }
        return .continue
    }
    
    internal override func containsGlobalPoints(_ globalPoints: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        cache.fetch(key: cacheKey) { () -> ContainsPointsResult in
            var mergedResult = children.reduce(ContainsPointsResult()) { (partial, child) -> ContainsPointsResult in
                let childResult = child.containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: cacheKey)
                return ContainsPointsResult(
                    mask: partial.mask.union(childResult.mask),
                    priority: max(partial.priority, childResult.priority),
                    children: []
                )
            }
            mergedResult.children = children
            return mergedResult
        }
    }
    
    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        observer.map {
            observers.add(observer: $0)
        }
        
        children.forEach {
            $0.addContentPath(to: &path, in: coordinateSpace, observer: observer)
        }
    }
    
    internal override func resetGesture() {
        children.forEach {
            $0.resetGesture()
        }
    }
    
    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        _children.map({$0.visualDebugGeometries}).flatMap({$0})
    }
}
