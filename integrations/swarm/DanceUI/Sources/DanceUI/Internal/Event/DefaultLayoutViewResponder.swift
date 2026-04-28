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
internal class DefaultLayoutViewResponder: MultiViewResponder {
    
    internal var inputs: _ViewInputs

    internal var viewSubgraph: DGSubgraphRef

    private var childSubgraph: DGSubgraphRef?

    private var childViewSubgraph: DGSubgraphRef?

    internal var invalidateChildren: (() -> ())?
    
    internal init(inputs: _ViewInputs) {
        self.inputs = inputs
        self.invalidateChildren = nil
        self.childSubgraph = nil
        self.viewSubgraph = DGSubgraphRef.current!
        super.init()
    }
    
    internal override func childrenDidChange() {
        if let invalidateChildren = invalidateChildren {
            invalidateChildren()
        }
        
        observers.notify()
    }
    
    internal override func makeGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        
        let phase = Attribute(
            DefaultRule<GesturePhase<()>>(weakValue: WeakAttribute(nil))
        )
        
        func makeOptionalDefault<Value: Defaultable>(_ valueType: Value.Type, requires requiresInputKeyPath: KeyPath<_GestureInputs, Bool>) -> Attribute<Value>? where Value.Value == Value {
            guard inputs[keyPath: requiresInputKeyPath] else {
                return nil
            }
            return Attribute(DefaultRule<Value>(weakValue: WeakAttribute(nil)))
        }
        
        let gestureRecognitionWitness = makeOptionalDefault(GestureRecognitionWitness.self, requires: \.requiresGestureRecognitionWitness)

        let platformGestureRecognizerList = makeOptionalDefault(PlatformGestureRecognizerList.self, requires: \.requiresPlatformGestureRecognizerList)

        let outputs = _GestureOutputs.make(phase: phase)
            .withGestureRecognitionWitness(gestureRecognitionWitness)
            .withPlatformGestureRecognizerList(platformGestureRecognizerList)
        
        guard viewSubgraph.isValid else {
            return outputs
        }
        
        childSubgraph = DGSubgraphCreate(viewSubgraph.graph)
        
        viewSubgraph.add(child: childSubgraph!)
        DGSubgraphRef.current!.add(child: childSubgraph!)
        
        childSubgraph!.apply {
            
            let defaultLayoutGesture = Attribute(value: DefaultLayoutGesture(responder: self))
            let weakDLG = WeakAttribute(defaultLayoutGesture)
            
            self.invalidateChildren = {
                Update.enqueueAction {
                    weakDLG.attribute?.invalidateValue()
                }
            }
            
            var childInputs = _GestureInputs(deepCopy: inputs)
            childInputs.transform = self.inputs.transform
            childInputs.position = self.inputs.position
            childInputs.size = self.inputs.size
            
            let laiedOutputs = DefaultLayoutGesture._makeGesture(gesture: _GraphValue(defaultLayoutGesture), inputs: childInputs)
            
            phase.overrideDefaultValue(laiedOutputs.phase, type: GesturePhase<Void>.self)
            
            @inline(__always)
            func overrideOptionalDefault<Value: Defaultable>(keyPath: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>) where Value.Value == Value {
                guard let src = laiedOutputs[keyPath: keyPath],
                      let dest = outputs[keyPath: keyPath] else {
                    return
                }
                dest.overrideDefaultValue(src, type: Value.self)
            }
            
            overrideOptionalDefault(keyPath: \.gestureRecognitionWitness)
            overrideOptionalDefault(keyPath: \.platformGestureRecognizerList)
        }

        return outputs
    }

    internal override func makeGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        assert(DanceUIFeature.gestureContainer.isEnable)
        let outputs: _GestureOutputs<Void> = inputs.makeDefaultOutputs()
        guard viewSubgraph.isValid else {
            return outputs
        }
        let currentSubgraph = DGSubgraphRef.current!
        let needGestureGraph = inputs.options.contains(.gestureGraph)
        childSubgraph = DGSubgraphCreate((needGestureGraph ? currentSubgraph : viewSubgraph).graph)
        viewSubgraph.add(child: childSubgraph!)
        currentSubgraph.add(child: childSubgraph!)
        if needGestureGraph {
            childViewSubgraph = DGSubgraphCreate(viewSubgraph.graph)
            childSubgraph!.add(child: childViewSubgraph!)
        }
        childSubgraph!.apply {
            let defaultLayoutGesture = Attribute(value: DefaultLayoutGesture(responder: self))
            let weakDLG = WeakAttribute(defaultLayoutGesture)
            
            self.invalidateChildren = {
                Update.enqueueAction {
                    weakDLG.attribute?.invalidateValue()
                }
            }
            let subgraph = (childViewSubgraph ?? childSubgraph)!
            var childInputs = inputs
            childInputs.mergeViewInputs(self.inputs, viewSubgraph: subgraph)
            let laiedOutputs = DefaultLayoutGesture._makeGesture(gesture: _GraphValue(defaultLayoutGesture), inputs: childInputs)
            outputs.overrideDefaultValues(laiedOutputs)
        }
        return outputs
    }
    
    internal override func resetGesture() {
        invalidateChildren = nil
        if DanceUIFeature.gestureContainer.isEnable {
            // Check invalidate
            childViewSubgraph = nil
        }
        childSubgraph = nil
        super.resetGesture()
    }
    
}

@available(iOS 13.0, *)
internal struct DefaultLayoutGesture: LayoutGesture {

    internal typealias Value = Void

    internal var responder: MultiViewResponder
    
}

@available(iOS 13.0, *)
internal protocol LayoutGesture: PrimitiveGesture {

    var responder: MultiViewResponder { get }

    func receive(events: [EventID : EventType], children: LayoutGestureChildBindings)

    /// Returns events bound to specific child with given `index` in `children`.
    func childEvents(events: [EventID : EventType], index: Int, children: LayoutGestureChildBindings) -> [EventID : EventType]

    func phase(children: LayoutGestureChildPhases) -> GesturePhase<()>

    func childShouldReset(index: Int, children: LayoutGestureChildPhases) -> Bool

    func value<Value>(children: LayoutGestureChildPhases, keyPath: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>, reduce: (inout Value, Value) -> Void) -> Value?

}

@available(iOS 13.0, *)
private struct Visitor<Content: LayoutGesture>: PreferenceKeyVisitor {

    internal var preferences: PreferencesOutputs

    internal let gesture: DanceUIGraph.Attribute<Content>

    internal let boxValue: DanceUIGraph.Attribute<LayoutGestureBox.Value>

    internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
        preferences[key] = Attribute(
            LayoutGesturePreferenceCombiner<Content, Key>(
                gesture: gesture,
                boxValue: boxValue
            )
        )
    }
}

@available(iOS 13.0, *)
extension LayoutGesture {
    
    /// Wries the data-flow into:
    ///
    /// ```
    /// @Attribute
    /// LayouGestureBox.Value(LayoutChildren) -+
    ///                                        |
    ///                                        |   @Attribute
    ///                                        +-> GesturePhase(LayoutPhase)
    ///                                        |
    /// @Attribute                             |
    /// Self ----------------------------------+
    /// ```
    /// `LayoutGestureBox` encapsulates child responders data-flow preparation,
    /// event binding, sending and reset. The child responders data-flow
    /// preparation contains calls to `makeGesture` and grouping input events by
    /// each subview's event-responder binding pair.
    ///
    /// `LayoutChildren` produces a value of `LayoutGestureBox.Value` which is a
    /// seed versioned `LayoutGestureBox`.
    ///
    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> where Value == Void {
        if DanceUIFeature.gestureContainer.isEnable {
            let box = LayoutGestureBox(inputs: inputs)
            let boxValue = Attribute(
                UpdateLayoutGestureBox(
                    gesture: gesture.value,
                    events: inputs.events,
                    resetSeed: inputs.resetSeed,
                    box: box
                )
            )
            let phase = Attribute(
                LayoutPhase<Self>(
                    gesture: gesture.value,
                    box: boxValue
                )
            )
            var outputs = _GestureOutputs.make(phase: phase)
            if inputs.options.contains(.includeDebugOutput) {
                // Unimplemented: outputs.debugData
            }
            // We cann't nested Visitor type in generic context. So the Visitor is defined elsewhere in the file
            var visitor = Visitor(preferences: outputs.preferences, gesture: gesture.value, boxValue: boxValue)
            for key in inputs.preferences.keys {
                key.visitKey(&visitor)
            }
            outputs.preferences = visitor.preferences
            return outputs
        } else {
            // Original logic
            return .makeLaied(gesture: gesture.value, inputs: inputs)
        }
    }
    
    internal func childEvents(events: [EventID : EventType], index: Int, children: LayoutGestureChildBindings) -> [EventID : EventType] {
        events.optimisticFilter { (_, event) in
            guard let binding = event.binding else {
                return false
            }
            let child = children.box.children[index]
            return binding.responder.isDescendant(of: child.responder)
        }
    }
    
    internal func childShouldReset(index: Int, children: LayoutGestureChildPhases) -> Bool {
        children.shouldResetChild(at: index)
    }
    
    internal func phase(children: LayoutGestureChildPhases) -> GesturePhase<()> {
        children.mergedPhase()
    }
    
    internal func value<Value>(children: LayoutGestureChildPhases, keyPath: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>, reduce: (inout Value, Value) -> Void) -> Value? {
        children.mergedValue(keyPath: keyPath, reduce: reduce)
    }
    
    internal func receive(events: [EventID: EventType], children: LayoutGestureChildBindings) {
        let eventsToRebind = events.optimisticFilter { (_, event) in
            type(of: event).rebindsEachEvent
        }
        
        if !eventsToRebind.isEmpty {
            HitTestingLayoutGesture(responder: responder, bindChildExclusively: true)
                .receive(events: eventsToRebind, children: children)
        }
    }
}

@available(iOS 13.0, *)
private final class LayoutGestureBox {

    internal let inputs: _GestureInputs

    internal weak var bindings: EventBindingManager?

    internal let parentSubgraph: DGSubgraphRef

    internal var phase: Attribute<GesturePhase<Void>>?

    internal private(set) var children: [Child]

    internal var nextUniqueId: UInt32

    internal var seed: UInt32

    internal var resetSeed: UInt32

    internal var activeEvents: Set<EventID>
    
    internal init(inputs: _GestureInputs) {
        self.inputs = inputs
        self.phase = nil
        self.children = []
        self.nextUniqueId = 0x0
        self.seed = 0x0
        self.resetSeed = 0x0
        self.activeEvents = []
        self.bindings = EventBindingManager.current
        self.parentSubgraph = DGSubgraphRef.current!
    }
    
    internal subscript(uniqueId: UInt32) -> LayoutGestureBox.Child? {
        children.first { $0.uniqueId == uniqueId }
    }
    
    internal func didSendEvents<G: LayoutGesture>(gesture: G) {
        for (index, child) in children.enumerated() where child.active {
            if gesture.childShouldReset(index: index, children: .init(box: self)) {
                resetChildGesture(index: index)
            }
        }
    }
    
    internal func rebindEvent(_ event: EventID, to responder: ResponderNode?) {
        guard let manager = bindings else {
            return
        }
        
        guard let newNode = manager.rebindEvent(event, to: responder) else {
            return
        }
        
        if let index = children.firstIndex(where: {
            newNode.isDescendant(of: $0.responder)
        }) {
            children[index].resetDelta.inc()
            seed.inc()
        }
    }
    
    internal func resetChildGesture(index: Int) {
        var child = children[index]
        guard children[index].active else {
            return
        }
        
        if child.phase != nil {
            child.outputs = nil
            if let subgraph = child.subgraph {
                child.subgraph = nil
                subgraph.willRemove()
                subgraph.invalidate()
            }
            
            child.responder.resetGesture()
        }
        
        child.active = false
        child.events = [:]
        child.seenEventIDs = activeEvents
        child.resetDelta.inc()
        children[index] = child    
        seed.inc()
    }
    
    internal func updateResetSeed(_ newResetSeed: UInt32) {
        guard resetSeed != newResetSeed else {
            return
        }
        resetSeed = newResetSeed
        
        for i in children.indices {
            resetChildGesture(index: i)
        }
        seed.inc()
    }
    
    /// Updates `children` with given responder.
    internal func updateResponder(_ responder: MultiViewResponder) {
        var hasChanged = false
        
        for (index, child) in responder.children.enumerated() {
            var hasFoundChild = false
            for offset in index..<children.count where children[offset].responder === child {
                hasFoundChild = true
                if offset != index {
                    hasChanged = true
                    children.swapAt(index, offset)
                }
                break
            }
            if !hasFoundChild {
                let newChild = Child(
                    responder: child,
                    uniqueId: nextUniqueId,
                    resetDelta: 0x0,
                    events: [:],
                    subgraph: nil,
                    seenEventIDs: [],
                    active: false,
                    outputs: nil
                )
                children.append(newChild)
                nextUniqueId.inc()
                if index != children.count - 1 {
                    children.swapAt(index, children.count - 1)
                }
            }
            hasChanged = true
        }
        
        for idx in (responder.children.count..<children.count).reversed() {
            resetChildGesture(index: idx)
            children.removeLast()
        }
        
        if hasChanged {
            seed.inc()
        }
    }
    
    /// Invokes child responders' `makeGesture`.
    ///
    internal func willSendEvents<LayoutGestureType: LayoutGesture>(_ events: [EventID: EventType],
                                                                   gesture: LayoutGestureType,
                                                                   childrenAttribute: Attribute<LayoutGestureBox.Value>) {
        for index in children.indices where !children[index].events.isEmpty {
            children[index].events = [:]
            seed.inc()
        }
        
        guard !events.isEmpty else {
            return
        }
        
        // children = { self, G.vwt, G.pwt}
        gesture.receive(events: events, children: LayoutGestureChildBindings(box: self))
        
        var hadRemovedActiveEvent = false
        
        for (id, type) in events {
            if type.phase == .active {
                activeEvents.insert(id)
            } else {
                activeEvents.remove(id)
                hadRemovedActiveEvent = true
            }
        }
        
        for index in children.indices {
            
            if hadRemovedActiveEvent {
                let oldResetEvent = children[index].seenEventIDs
                let needResetEvent = oldResetEvent.intersection(activeEvents)
                if needResetEvent.count != oldResetEvent.count {
                    children[index].seenEventIDs = needResetEvent
                }
            }
            
            var filterDic: [EventID: EventType] = [:]
            
            for (id, type) in events {
                
                if children[index].seenEventIDs.contains(id) {
                    continue
                }
                
                filterDic[id] = type
            }
            guard !filterDic.isEmpty else {
                continue
            }
            
            // children { self, G.vwt, G.pwt}
            let childEvents = gesture.childEvents(events: filterDic, index: index, children: .init(box: self))
            guard !childEvents.isEmpty else {
                continue
            }
            
            children[index].events = childEvents
            
            children[index].active = true
            seed.inc()
            
            guard children[index].phase == nil else {
                continue
            }
            
            let outputs: _GestureOutputs<Void>
            
            if parentSubgraph.isValid {
                let uniqueId = children[index].uniqueId
                let child = DGSubgraphCreate(parentSubgraph.graph)
                parentSubgraph.add(child: child)
                outputs = child.apply {
                    var newInputs = _GestureInputs(deepCopy: inputs)
                    
                    let layoutChildEvents = LayoutChildEvents(
                        children: childrenAttribute,
                        uniqueId: uniqueId
                    ).makeAttribute()
                    
                    let layoutChildResetSeed = LayoutChildSeed(
                        children: childrenAttribute,
                        uniqueId: uniqueId
                    ).makeAttribute()
                    
                    newInputs.events = layoutChildEvents
                    newInputs.resetSeed = layoutChildResetSeed
                    
                    let outputs: _GestureOutputs<Void>
                    
                    if DanceUIFeature.gestureContainer.isEnable {
                        outputs = children[index].responder.makeGesture(
                            inputs: newInputs
                        )
                    } else {
                        outputs = children[index].responder.makeGesture(
                            gesture: _GraphValue(childrenAttribute).unsafeBitCast(to: Void.self),
                            inputs: newInputs
                        )
                    }
                    
                    return outputs
                }
                children[index].subgraph = child
            } else {
                let newInputs = _GestureInputs(deepCopy: inputs)
                outputs = if DanceUIFeature.gestureContainer.isEnable {
                    newInputs.makeDefaultOutputs()
                } else {
                    .makeDefault(viewGraph: ViewGraph.current, inputs: newInputs)
                }
            }

            children[index].outputs = outputs
        }
    }


    internal struct Child {

        internal let responder: ViewResponder

        internal let uniqueId: UInt32

        internal var resetDelta: UInt32

        internal var events: [EventID: EventType]

        internal var subgraph: DGSubgraphRef?

        internal var phase: Attribute<GesturePhase<Void>>? {
            return outputs?.phase
        }

        internal var seenEventIDs: Set<EventID>

        /// Sets `true` in `willSendEvents`; sets `false` in `resetChildGesture`.
        internal var active: Bool

        internal var outputs: _GestureOutputs<Void>?

        internal var preferences: PreferencesOutputs? { outputs?.preferences }
    }
    
    internal struct Value {
        
        fileprivate let box: LayoutGestureBox
        
        private let seed: UInt32
        
        internal init(box: LayoutGestureBox, seed: UInt32) {
            self.box = box
            self.seed = seed
        }
        
        @inlinable
        internal func didSendEvents<LayoutGestureType: LayoutGesture>(gesture: LayoutGestureType) {
            box.didSendEvents(gesture: gesture)
        }
        
        @inlinable
        internal subscript(index: UInt32) -> LayoutGestureBox.Child? {
            box[index]
        }
        
        @inlinable
        internal var resetSeed: UInt32 {
            box.resetSeed
        }
        
        @inlinable
        internal var phase: LayoutGestureChildPhases {
            LayoutGestureChildPhases(box: box)
        }
        
    }
    
}

/// Updates children in `LayoutGestureBox` and prepares event sending (e.g.
/// invoking `makeGesture`).
@available(iOS 13.0, *)
fileprivate struct LayoutChildren<G: LayoutGesture>: Rule {
        
    internal typealias Value = LayoutGestureBox.Value
    
    @Attribute
    internal var gesture: G
    
    @Attribute
    internal var events: [EventID: EventType]
    
    @Attribute
    internal var resetSeed: UInt32
    
    internal let box: LayoutGestureBox
    
    internal var value: LayoutGestureBox.Value {
        box.updateResetSeed(resetSeed)
        
        let (gesture, changed) = $gesture.changedValue()

        if changed {
            box.updateResponder(gesture.responder)
        }
        
        box.willSendEvents(
            events,
            gesture: gesture,
            childrenAttribute: context.attribute
        )
        
        return LayoutGestureBox.Value(box: box, seed: box.seed)
    }
    
}

/// Returns events bound to specific child in current layout.
@available(iOS 13.0, *)
fileprivate struct LayoutChildEvents: Rule {
        
    internal typealias Value = [EventID: EventType]
    
    @Attribute
    internal var children: LayoutGestureBox.Value

    internal let uniqueId: UInt32
    
    internal var value: [EventID : EventType] {
        let child = children[uniqueId]
        let childEvents = child?.events
        return childEvents ?? [:]
    }

}

/// Returns reset seed of specific child in current layout.
@available(iOS 13.0, *)
fileprivate struct LayoutChildSeed: Rule {
        
    internal typealias Value = UInt32

    @Attribute
    internal var children: LayoutGestureBox.Value

    internal let uniqueId: UInt32
    
    internal var value: UInt32 {
        let delta = children[uniqueId]?.resetDelta ?? 0x10000
        return children.resetSeed &+ delta
    }

}

@available(iOS 13.0, *)
fileprivate struct LayoutPhase<LayoutGestureType: LayoutGesture>: Rule {

    internal typealias Value = GesturePhase<Void>
    
    @Attribute
    internal var gesture: LayoutGestureType
    
    /// Representing child gestures that laied out and prepared.
    @Attribute
    internal var box: LayoutGestureBox.Value
    
    internal var value: Value {
        let gesture = self.gesture
        let box = self.box
        let phase = gesture.phase(children: box.phase)
        box.didSendEvents(gesture: gesture)
        return phase
    }
    
}

@available(iOS 13.0, *)
internal struct LayoutGestureChildPhases {
    
    private let box: LayoutGestureBox
    
    @inline(__always)
    fileprivate init(box: LayoutGestureBox) {
        self.box = box
    }
    
    internal func child(at index: Int) -> Child {
        Child(box: box, index: index)
    }
    
    // The non-`active`s are filtered out.
    @inline(__always)
    internal func mergedPhase() -> GesturePhase<Void> {
        box.children.enumerated()
            .compactMap { (index, child) in
                guard child.active else {
                    return nil
                }
                return self.child(at: index).phase
            }
            .merged()
    }
    
    internal func mergedValue<Value>(keyPath: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>, reduce: (inout Value, Value) -> Void) -> Value? {
        box.children.enumerated()
            .compactMap { (index, child) -> Value? in
                guard child.active else {
                    return nil
                }
                return self.child(at: index).outputs?[keyPath: keyPath]?.value
            }.reduce(Value?.none) { partial, element -> Value? in
                guard var partial = partial else {
                    return element
                }
                reduce(&partial, element)
                return partial
            }
    }
    
    @inline(__always)
    internal func shouldResetChild(at index: Int) -> Bool {
        child(at: index).shouldReset
    }
    
    internal struct Child {
        
        private let box: LayoutGestureBox
        
        private let index: Int
        
        fileprivate init(box: LayoutGestureBox, index: Int) {
            self.box = box
            self.index = index
        }
        
        /// Transforms child's `phase` into `.possible(nil)` if child's `active`
        /// is `true`, else returns child's `phase!.value`.
        internal var phase: GesturePhase<Void> {
            let child = box.children[index]
            guard child.active else {
                return .possible(nil)
            }
            return child.phase!.value
        }
        
        internal var outputs: _GestureOutputs<Void>? {
            let child = box.children[index]
            guard child.active else {
                return nil
            }
            return child.outputs
        }
        
        internal var preferences: PreferencesOutputs? {
            let child = box.children[index]
            guard child.active else {
                return nil
            }
            return child.preferences
        }
        
        @inline(__always)
        internal var shouldReset: Bool {
            switch phase {
            case .ended, .failed:
                return true
            case .active, .possible:
                return false
            }
        }
    }
    
}

@available(iOS 13.0, *)
internal struct LayoutGestureChildBindings {
    
    fileprivate var box: LayoutGestureBox
    
    @inline(__always)
    internal func firstIndex(where predicate: (Child) -> Bool) -> Int? {
        return box.children.indices.firstIndex { (index) -> Bool in
            return predicate(Child(box: box, index: index))
        }
    }
    
    @inline(__always)
    internal func lastIndex(where predicate: (Child) -> Bool) -> Int? {
        return box.children.indices.firstIndex { (index) -> Bool in
            return predicate(Child(box: box, index: index))
        }
    }
    
    @inline(__always)
    internal func child(at index: Int) -> Child {
        Child(box: box, index: index)
    }
    
    internal struct Child {
        
        fileprivate var box: LayoutGestureBox
        
        fileprivate var index: Int
        
        #if DEBUG
        
        internal static func testableMake(input: _GestureInputs, index: Int) -> Child {
            Child(box: .init(inputs: input), index: index)
        }
        
        internal func testableBoxUpdateResponder(responder: MultiViewResponder) {
            box.updateResponder(responder)
        }
        
        internal func testableBoxSeed() -> UInt32 {
            box.seed
        }
        
        #endif
        
        @inline(__always)
        internal func wasBound(to event: EventType) -> Bool {
            guard let binding = event.binding else {
                return false
            }
            
            return binding.responder.isDescendant(of: box.children[index].responder)
        }
        
        @inline(__always)
        internal func containsGlobalPoints(_ globalPoints: [CGPoint], cacheKey: UInt32?) -> BitVector64 {
            box.children[index].responder.containsGlobalPoints(globalPoints, isDerived: globalPoints.map({ _ in false}), cacheKey: cacheKey).mask
        }
        
        internal func bind(to eventType: EventType, id: EventID, hitTest: Bool) {
            let child = box.children[index]
            if hitTest,
               let event = HitTestableEvent(eventType),
               let responder = child.responder.hitTest(globalPoint: event.hitTestLocation, radius: event.hitTestRadius) {
                let shouldRebind = responder !== child.responder || !responder.isEmptyResponder
                if shouldRebind {
                    box.rebindEvent(id, to: responder)
                }
            } else {
                box.rebindEvent(id, to: child.responder)
            }
        }
        
        internal func unbindEvent(_ event: EventType, id: EventID) {
            guard let manager = box.bindings, let binding = event.binding else {
                return
            }
            let child = box.children[index]
            if binding.responder.isDescendant(of: child.responder) {
                box.rebindEvent(id, to: nil)
            }
        }
        
    }
    
}

@available(iOS 13.0, *)
extension Collection where Element == GesturePhase<()> {
    
    #if BINARY_COMPATIBLE_TEST
    
    internal func fileprivate_merged() -> GesturePhase<()> {
        merged()
    }
    
    #endif
    
    fileprivate func merged() -> GesturePhase<()> {
        var hasNoEnded = true
        var hasNoPossibleOrActive = true
        var hasActive = false
        
        let lastIndex = count - 1
        // .possible makes other .failed stay .possible
        // .active makes other .possible/.active/.ended/.failed stay .active
        // .ended makes other .failed stay .ended
        for (phaseIndex, eachPhase) in enumerated() {
            switch eachPhase {
            case .possible:
                // When the last phase is possible:
                //  If there was phase in active before:
                //    return .active
                //  Else
                //    return .possible
                guard phaseIndex != lastIndex else {
                    return hasActive ? .active(()) : .possible(nil)
                }
                hasNoPossibleOrActive = false
            case .active:
                // When the last phase is active:
                //  return .active
                hasActive = true
                guard phaseIndex != lastIndex else {
                    return .active(())
                }
                hasNoPossibleOrActive = false

            case .ended:
                hasActive = true
                hasNoEnded = false
                // When the last phase is ended:
                //  If there was phase in possible or active before:
                //    return .active
                //  Else
                //    return .ended
                guard phaseIndex != lastIndex else {
                    return hasNoPossibleOrActive ? .ended(()) : .active(())
                }
            case .failed:
                // When the last phase is failed:
                //  If there was phase in possible or active before:
                //    If there is no phase ended:
                //      return .failed
                //    Else:
                //      return .ended
                //  Else
                //    If there is no phase active:
                //      return .active
                //    Else:
                //      return .possible
                guard phaseIndex != lastIndex else {
                    if hasNoPossibleOrActive {
                        return hasNoEnded ? .failed : .ended(())
                    } else {
                        return hasActive ? .active(()) : .possible(nil)
                    }
                }
            }
        }
        
        return .failed
    }
    
}

@available(iOS 13.0, *)
extension _GestureOutputs where A == Void {
    
    fileprivate static func makeLaied<GestureType: LayoutGesture>(
        gesture: Attribute<GestureType>,
        inputs: _GestureInputs
    ) -> _GestureOutputs {
        let box = LayoutGestureBox(inputs: inputs)
        
        @Attribute(LayoutChildren(gesture: gesture,
                                  events: inputs.events,
                                  resetSeed: inputs.resetSeed,
                                  box: box))
        var boxValue
        
        let layoutPhase = Attribute(LayoutPhase(gesture: gesture, box: $boxValue))
        
        box.phase = layoutPhase
        
        var base = _GestureOutputs.make(phase: layoutPhase)
        
        if inputs.requiresGestureRecognitionWitness {
            let attribute = Attribute(
                LaiedOutput(
                    gesture: gesture,
                    box: $boxValue,
                    keyPath: \.gestureRecognitionWitness,
                    reduce: {$0.merge(with: $1)},
                    defaultValue: { GestureRecognitionWitness() }
                )
            )
            base = base.withGestureRecognitionWitness(attribute)
        }
        if inputs.requiresPlatformGestureRecognizerList {
            let attribute = Attribute(
                LaiedOutput(
                    gesture: gesture,
                    box: $boxValue,
                    keyPath: \.platformGestureRecognizerList,
                    reduce: {$0.append($1)},
                    defaultValue: { PlatformGestureRecognizerList() }
                )
            )
            base = base.withPlatformGestureRecognizerList(attribute)
        }
        if inputs.requiresActiveGestureRecognizerObservers {
            let attribute = Attribute(
                LaiedOutput(
                    gesture: gesture,
                    box: $boxValue,
                    keyPath: \.activeGestureRecognizerObservers,
                    reduce: { $0.append(contentsOf: $1) },
                    defaultValue: { [] }
                )
            )
            base = base.withActiveGestureRecognizerObservers(attribute)
        }
        
        return base
    }
    
}

@available(iOS 13.0, *)
private struct LaiedOutput<LayoutGestureType: LayoutGesture, Value>: Rule {

    @DanceUIGraph.Attribute
    internal var gesture: LayoutGestureType
    
    /// Representing child gestures that laied out and prepared.
    @DanceUIGraph.Attribute
    internal var box: LayoutGestureBox.Value
    
    internal let keyPath: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>
    
    internal let reduce: (inout Value, Value) -> Void
    
    internal let defaultValue: () -> Value
    
    internal var value: Value {
        gesture.value(children: box.phase, keyPath: keyPath, reduce: reduce) ?? defaultValue()
    }
    
}

@available(iOS 13.0, *)
private struct LayoutGesturePreferenceCombiner<Content, Key>: Rule, AsyncAttribute where Content: LayoutGesture, Key: PreferenceKey {
    @DanceUIGraph.Attribute
    internal var gesture: Content
    
    @DanceUIGraph.Attribute
    internal var boxValue: LayoutGestureBox.Value
    
    internal typealias Value = Key.Value
    
    internal static var initialValue: Value { Key.defaultValue }

    internal var value: Value {
        gesture.preferenceValue(key: Key.self, box: boxValue.box)
    }
}

@available(iOS 13.0, *)
extension LayoutGesture {
    fileprivate func preferenceValue<Key>(key: Key.Type, box: LayoutGestureBox) -> Key.Value where Key: PreferenceKey {
        var result = Key.defaultValue
        var isInitialValue = true
        for child in box.children {
            guard !child.seenEventIDs.isEmpty,
                  let preferences = child.preferences,
                  let attribute = preferences[key]
            else {
                continue
            }
            if isInitialValue {
                result = attribute.value
            } else {
                Key.reduce(value: &result) {
                    attribute.value
                }
            }
            isInitialValue = false
        }
        return result
    }
}

@available(iOS 13.0, *)
private struct UpdateLayoutGestureBox<T>: Rule where T: LayoutGesture {
    @DanceUIGraph.Attribute
    internal var gesture: T
    
    @DanceUIGraph.Attribute
    internal var events: [EventID: any EventType]
    
    @DanceUIGraph.Attribute
    internal var resetSeed: UInt32
    
    internal let box: LayoutGestureBox
    
    internal typealias Value = LayoutGestureBox.Value
    
    internal var value: Value {
        box.updateResetSeed(resetSeed)
        let (gesture, gestureChanged) = $gesture.changedValue()
        if gestureChanged {
            box.updateResponder(gesture.responder)
        }
        box.willSendEvents(events, gesture: gesture, childrenAttribute: attribute)
        return .init(box: box, seed: box.seed)
    }
}
