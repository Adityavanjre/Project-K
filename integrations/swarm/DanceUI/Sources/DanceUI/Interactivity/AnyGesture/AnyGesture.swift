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

/// A type-erased gesture.
@available(iOS 13.0, *)
@frozen
public struct AnyGesture<Value>: Gesture {

    fileprivate var storage: AnyGestureStorageBase<Value>

    /// Creates an instance from another gesture.
    ///
    /// - Parameter gesture: A gesture that you use to create a new gesture.
    public init<T>(_ gesture: T) where Value == T.Value, T : Gesture {
        storage = AnyGestureStorage(gesture: gesture)
    }

    public static func _makeGesture(gesture: _GraphValue<AnyGesture<Value>>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        let copiedInputs = inputs

        let outputs: _GestureOutputs<Value> = copiedInputs.makeIndirectOutputs()
        
        @Attribute(AnyGestureInfo(gesture: gesture.value,
                                  inputs: copiedInputs,
                                  outputs: outputs,
                                  oldInfo: nil))
        var info;
        
        $info.setFlags(.active, mask: .reserved)
        
        outputs.setIndirectDependency($info.identifier)
        
        return outputs
    }

}

@available(iOS 13.0, *)
fileprivate struct AnyGestureInfo<GestureValue>: StatefulRule {

    @Attribute
    fileprivate var gesture: AnyGesture<GestureValue>

    fileprivate var inputs: _GestureInputs

    fileprivate var outputs: _GestureOutputs<GestureValue>

    fileprivate let parentSubgraph: DGSubgraphRef

    fileprivate var oldInfo: Value?
    
    internal init(gesture: Attribute<AnyGesture<GestureValue>>, inputs: _GestureInputs, outputs: _GestureOutputs<GestureValue>, parentSubgraph: DGSubgraphRef, oldInfo: AnyGestureInfo<GestureValue>.Value? = nil) {
        self._gesture = gesture
        self.inputs = inputs
        self.outputs = outputs
        self.parentSubgraph = parentSubgraph
        self.oldInfo = oldInfo
    }
    
    fileprivate mutating func updateValue() {
        let info = ensureItem()
        oldInfo = info
        value = info
    }
    
    @inline(__always)
    private func ensureItem() -> Value {
        if let oldInfo = self.oldInfo {
            if !oldInfo.item.matches(gesture.storage) {
                eraseItem(info: oldInfo)
                return makeItem(item: gesture.storage, uniqueId: oldInfo.uniqueId + 1)
            } else {
                return Value(item: gesture.storage, subgraph: oldInfo.subgraph, uniqueId: oldInfo.uniqueId)
            }
        } else {
            return makeItem(item: gesture.storage, uniqueId: 0)
        }
    }
    
    private func eraseItem(info: AnyGestureInfo<GestureValue>.Value) {
        outputs.detachIndirectOutputs()
        info.subgraph.willRemove()
        info.subgraph.invalidate()
    }
    
    private func makeItem(item: AnyGestureStorageBase<GestureValue>, uniqueId: UInt32) -> AnyGestureInfo<GestureValue>.Value {
        
        
        let itemSubgraph = DGSubgraphCreate(parentSubgraph.graph)
        parentSubgraph.add(child: itemSubgraph)
        
        let currentAttribute = Attribute<AnyGestureInfo<GestureValue>.Value>(identifier: DGAttribute.current!)
        
        return itemSubgraph.apply {
            var copiedInputs = _GestureInputs(deepCopy: self.inputs)
            
            copiedInputs.resetSeed = AnyResetSeed(
                resetSeed: copiedInputs.resetSeed,
                info: currentAttribute
            ).makeAttribute()
            
            let childOutputs = item.makeChild(
                uniqueId: uniqueId,
                container: currentAttribute,
                inputs: copiedInputs
            )
            outputs.attachIndirectOutputs(childOutputs)
            
            return AnyGestureInfo<GestureValue>.Value(item: item, subgraph: itemSubgraph, uniqueId: uniqueId)
        }
    }
    
    @inline(__always)
    fileprivate init(gesture: Attribute<AnyGesture<GestureValue>>, inputs: _GestureInputs, outputs: _GestureOutputs<GestureValue>, oldInfo: AnyGestureInfo<GestureValue>.Value?) {
        self._gesture = gesture
        self.inputs = inputs
        self.outputs = outputs
        self.parentSubgraph = DGSubgraphRef.current!
        self.oldInfo = oldInfo
    }

    fileprivate struct Value {

        fileprivate var item: AnyGestureStorageBase<GestureValue>

        fileprivate var subgraph: DGSubgraphRef

        fileprivate var uniqueId: UInt32

    }

}

@available(iOS 13.0, *)
@usableFromInline
internal class AnyGestureStorageBase<Value> {

    fileprivate func matches(_ another: AnyGestureStorageBase<Value>) -> Bool {
        _abstract(self)
    }

    fileprivate func makeChild(uniqueId: UInt32, container: Attribute<AnyGestureInfo<Value>.Value>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        _abstract(self)
    }

    fileprivate func updateChild(context: DanceUIGraph.AnyRuleContext) {
        _abstract(self)
    }

}

@available(iOS 13.0, *)
private final class AnyGestureStorage<G: Gesture> : AnyGestureStorageBase<G.Value> {

    fileprivate var gesture: G

    fileprivate init(gesture: G) {
        self.gesture = gesture
    }
    
    fileprivate override func matches(_ another: AnyGestureStorageBase<G.Value>) -> Bool {
        type(of: another) === type(of: self)
    }
    
    fileprivate override func makeChild(uniqueId: UInt32, container: Attribute<AnyGestureInfo<G.Value>.Value>, inputs: _GestureInputs) -> _GestureOutputs<G.Value> {
        
        let child = Attribute(AnyGestureChild<G>(info: container, uniqueId: uniqueId))
        return G._makeGesture(gesture: _GraphValue(child), inputs: inputs)
    }
    
    fileprivate override func updateChild(context: DanceUIGraph.AnyRuleContext) {
        let context = RuleContext<G>(attribute: Attribute(identifier: context.attribute))
        context.value = gesture
    }

}

@available(iOS 13.0, *)
fileprivate struct AnyGestureChild<G: Gesture>: StatefulRule {
    
    fileprivate typealias Value = G

    @Attribute
    fileprivate var info: AnyGestureInfo<G.Value>.Value

    fileprivate let uniqueId: UInt32
    
    fileprivate mutating func updateValue() {
        let info = self.info
        guard uniqueId == info.uniqueId else {
            return
        }
        
        info.item.updateChild(context: DanceUIGraph.AnyRuleContext.current)
    }

}

@available(iOS 13.0, *)
fileprivate struct AnyResetSeed<A>: Rule {
    
    @Attribute
    fileprivate var resetSeed: UInt32

    @Attribute
    fileprivate var info: AnyGestureInfo<A>.Value
    
    fileprivate var value: UInt32 {
        resetSeed &+ info.uniqueId
    }
    
}
