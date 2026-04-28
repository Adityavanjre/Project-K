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
internal class UnaryViewResponder: ViewResponder {

    internal var _child: ViewResponder?
    
    internal var child: ViewResponder? {
        get {
            _child
        }
        set {
            _child = newValue
            _child?.parent = self
        }
    }
    
    internal override init() {
        _child = nil
        super.init()
    }
    
    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) -> () {
        _child?.addContentPath(to: &path, in: coordinateSpace, observer: observer)
    }
    
    internal override func bindEvent(_ event: EventType) -> ResponderNode? {
        _child?.bindEvent(event)
    }
    
    internal override var children: [ViewResponder] {
        _child.map({[$0]}) ?? []
    }
    
    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        return child?.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey) ?? ContainsPointsResult()
    }
    
    internal override var isEmptyResponder: Bool {
        guard let child = _child else {
            return false
        }
        
        return child.isEmptyResponder
    }
    
    internal override func makeGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        guard let child = _child else {
            return super.makeGesture(gesture: gesture, inputs: inputs)
        }
        
        return child.makeGesture(gesture: gesture, inputs: inputs)
    }
    
    internal override func makeGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        assert(!DanceUIFeature.gestureContainer.isEnable)
        return super.makeGesture(inputs: inputs)
    }
    
    internal override func resetGesture() {
        guard let child = _child else {
            return
        }
        
        return child.resetGesture()
    }
    
    internal override func visit(applying visitor: (ResponderNode) -> ResponderVisitorResult) -> ResponderVisitorResult {
        let result = visitor(self)
        
        guard result == .continue else {
            return result
        }
        
        guard let child = _child else {
            return .continue
        }
        
        return child.visit(applying: visitor)
    }
    
    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        _child?.visualDebugGeometries ?? []
    }

}
