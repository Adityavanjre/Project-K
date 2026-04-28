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
internal protocol GestureViewModifier: MultiViewModifier, PrimitiveViewModifier {
    
    associatedtype ContentGesture: Gesture
    
    associatedtype Combiner: GestureCombiner = DefaultGestureCombiner
        
    var gesture: ContentGesture { get }
    
    var name: String? { get }

    var gestureMask: GestureMask { get }

    var extendedConfigs: GestureExtendedConfigs { get }

    var isCancellable: Bool { get }
    
}

@available(iOS 13.0, *)
extension GestureViewModifier {
    
    internal var name: String? { nil }

    internal var gestureMask: GestureMask { .all }
    
    internal var isCancellable: Bool {
        false
    }
    
    internal static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeView(modifier: modifier, inputs: inputs, body: body)
    }
    
    internal static func makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        if DanceUIFeature.gestureContainer.isEnable {
            typealias Child = GestureContainerViewModifierChild<Self>
            @Attribute(Child(wrappedModifier: modifier.value))
            var child
            return Child.Value._makeView(modifier: _GraphValue($child), inputs: inputs, body: body)
        } else {
            var bodyInputs = inputs
            bodyInputs.hitTestInsets = nil

            var outputs = body(_Graph(), bodyInputs)
            
            if inputs.preferences.requiresViewResponders {
                
                let gestureResponder = GestureResponder(modifier: modifier.value, inputs: inputs)
                
                let layoutResponder = DefaultLayoutViewResponder(inputs: inputs)

                gestureResponder.child = layoutResponder
                
                let children = outputs.viewResponders ?? ViewGraph.current.$emptyViewResponders
                
                let gestureFilter = DanceUIGraph.Attribute(
                    GestureFilter(children: children, responder: gestureResponder, layoutResponder: layoutResponder)
                )
                outputs.viewResponders = gestureFilter
                
                if inputs.preferences.requiresPlatformGestureRecognizerList {
                    let gestureRecognizerListFilter = Attribute(GestureViewPlatformGestureRecognizerFilter(view: OptionalAttribute(outputs.gestureRecognizerList),
                                                                                                           gesture: gestureResponder.viewPlatformGestureRecognizerListOutlet))
                    outputs.gestureRecognizerList = gestureRecognizerListFilter
                }
            }
            return outputs
        }
    }
    
    internal var extendedConfigs: GestureExtendedConfigs {
        .empty
    }
    
}

///
/// Helping manage the UIKitGestureContainingView life-cycle
///
@available(iOS 13.0, *)
private struct GestureContainerViewModifierChild<ModifierType: GestureViewModifier>: Rule {
    
    fileprivate typealias Value = GestureContainerViewModifier<ModifierType>
    
    @Attribute
    fileprivate var wrappedModifier: ModifierType
    
    fileprivate var gestureRecognizer: UIGestureRecognizer? = nil
    
    fileprivate var value: Value {
        GestureContainerViewModifier(wrappedModifier: wrappedModifier, gestureRecognizer: gestureRecognizer)
    }
    
}

///
/// Leveraing `RenderEffect` to allow the `UIGestureRecognizer` to be
/// attached to `gestureContainingView`.
///
@available(iOS 13.0, *)
private struct GestureContainerViewModifier<ModifierType: GestureViewModifier>: GestureViewModifier, RendererEffect {
    
    fileprivate typealias ContentGesture = ModifierType.ContentGesture
    
    fileprivate typealias Combiner = ModifierType.Combiner
    
    fileprivate var wrappedModifier: ModifierType
    
    fileprivate var gestureRecognizer: UIGestureRecognizer?
    
    fileprivate var isCancellable: Bool {
        wrappedModifier.isCancellable
    }
    
    fileprivate var gesture: ContentGesture {
        wrappedModifier.gesture
    }
    
    fileprivate var name: String? {
        wrappedModifier.name
    }
    
    fileprivate var gestureMask: GestureMask {
        wrappedModifier.gestureMask
    }
    
    fileprivate var extendedConfigs: GestureExtendedConfigs {
        wrappedModifier.extendedConfigs
    }

    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        if let gestureRecognizer = gestureRecognizer {
            return .gestureRecognizers([gestureRecognizer])
        } else {
            return .identity
        }
    }

    fileprivate static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var bodyInputs = inputs
        bodyInputs.hitTestInsets = nil

        var outputs = makeRendererEffect(effect: modifier, inputs: bodyInputs, body: body)

        if inputs.preferences.requiresViewResponders {
            let gestureRecognizer = UIKitResponderGestureRecognizer()
            modifier.value.mutateBody(as: GestureContainerViewModifierChild<ModifierType>.self, invalidating: false) { body in
                body.gestureRecognizer = gestureRecognizer
            }
            
            let filter = GestureFilter_FeatureGestureContainer(
                children: outputs.viewResponders ?? GraphHost.currentHost.intern([], id: 0),
                modifier: modifier.value,
                inputs: inputs,
                viewSubgraph: .current!,
                gestureRecognizer: gestureRecognizer
            )
            outputs.viewResponders = Attribute(filter)
        }
        
        let provider = inputs.gestureAccessibilityProvider
        provider.makeGesture(mask: modifier[\.gestureMask].value, inputs: inputs, outputs: &outputs)
        return outputs
    }
    
}

@available(iOS 13.0, *)
private struct GestureFilter<Modifier: GestureViewModifier>: StatefulRule {
        
    internal typealias Value = [ViewResponder]
    
    @Attribute
    internal var children: [ViewResponder]

    internal let responder: GestureResponder<Modifier>

    internal let layoutResponder: DefaultLayoutViewResponder
    
    internal mutating func updateValue() {
        let (inputViewResponders, wasInputViewResponderChanged) = $children.changedValue()
        if wasInputViewResponderChanged {
            layoutResponder.children = inputViewResponders
        }
        
        if !context.hasValue {
            value = [responder]
        }
    }
    
}

@available(iOS 13.0, *)
private struct GestureFilter_FeatureGestureContainer<Modifier>: StatefulRule where Modifier: GestureViewModifier {
    
    internal typealias Value = [ViewResponder]
    
    @DanceUIGraph.Attribute
    internal var children: [ViewResponder]
    
    @DanceUIGraph.Attribute
    internal var modifier: Modifier
    
    internal var inputs: _ViewInputs
    
    internal var viewSubgraph: DGSubgraphRef

    internal let gestureRecognizer: UIKitResponderGestureRecognizer?
    
    internal lazy var responder: GestureResponder_FeatureGestureContainer<Modifier> = {
        viewSubgraph.apply {
            GestureResponder_FeatureGestureContainer(
                modifier: $modifier,
                inputs: inputs,
                gestureRecognizer: gestureRecognizer
            )
        }
    }()
    
    internal mutating func updateValue() {
        let responder = responder
        let (_, childrenChanged) = $children.changedValue()
        if childrenChanged {
             responder.children = children
        }
        if !hasValue {
            self.responder.attach()
            value = [self.responder]
        }
    }
}

@available(iOS 13.0, *)
internal protocol GestureAccessibilityProvider {
    static func makeGesture(
        mask: @autoclosure () -> Attribute<GestureMask>,
        inputs: _ViewInputs,
        outputs: inout _ViewOutputs
    )
}

@available(iOS 13.0, *)
private struct GestureAccessibilityProviderKey: GraphInput {
    fileprivate static var defaultValue: (any GestureAccessibilityProvider.Type) {
        EmptyGestureAccessibilityProvider.self 
    }
}

@available(iOS 13.0, *)
private struct EmptyGestureAccessibilityProvider: GestureAccessibilityProvider {
    fileprivate static func makeGesture(
        mask: @autoclosure () -> Attribute<GestureMask>,
        inputs: _ViewInputs,
        outputs: inout _ViewOutputs
    ) {
    }
}

@available(iOS 13.0, *)
extension _GraphInputs {
    fileprivate var gestureAccessibilityProvider: (any GestureAccessibilityProvider.Type) {
        get { self[GestureAccessibilityProviderKey.self] }
        set { self[GestureAccessibilityProviderKey.self] = newValue }
    }
}

@available(iOS 13.0, *)
extension _ViewInputs {
    fileprivate var gestureAccessibilityProvider: (any GestureAccessibilityProvider.Type) {
        get { base.gestureAccessibilityProvider }
        set { withMutableGraphInputs { $0.gestureAccessibilityProvider = newValue } }
    }
}

@available(iOS 13.0, *)
private struct GestureViewPlatformGestureRecognizerFilter: Rule {
    
    internal typealias Value = PlatformGestureRecognizerList
    
    @OptionalAttribute
    internal var view: PlatformGestureRecognizerList?
    
    @OptionalAttribute
    internal var gesture: PlatformGestureRecognizerList?
    
    internal var value: PlatformGestureRecognizerList {
        view.appending(gesture) ?? PlatformGestureRecognizerList()
    }
    
}

@available(iOS 13.0, *)
private class AnyGestureResponder: UnaryViewResponder {
    
    func makeSubviewsGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        super.makeGesture(gesture: gesture, inputs: inputs)
    }
    
}

@available(iOS 13.0, *)
private final class GestureResponder<Modifier: GestureViewModifier>: AnyGestureResponder {
    
    internal let modifier: Attribute<Modifier>

    internal let inputs: _ViewInputs

    internal let viewSubgraph: DGSubgraphRef

    internal var childSubgraph: DGSubgraphRef?

    internal var viewPlatformGestureRecognizerListOutlet: OptionalAttribute<PlatformGestureRecognizerList>
    
    internal init(modifier: Attribute<Modifier>, inputs: _ViewInputs) {
        self.modifier = modifier
        self.inputs = inputs
        self.viewSubgraph = DGSubgraphRef.current!
        self.viewPlatformGestureRecognizerListOutlet = OptionalAttribute(Attribute(DefaultRule<PlatformGestureRecognizerList>(weakValue: WeakAttribute(nil))))
        super.init()
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
        
        let childSubgraph = DGSubgraphCreate(viewSubgraph.graph)
        self.childSubgraph = childSubgraph
        
        viewSubgraph.add(child: childSubgraph)
        
        DGSubgraphRef.current!.add(child: childSubgraph)
        
        childSubgraph.apply { () -> Void in
            
            let gestureViewChild = Attribute(GestureViewChild(modifier: modifier,
                                                              environment: self.inputs.environment,
                                                              viewPhase: self.inputs.phase,
                                                              node: self))
            
            var childInputs = _GestureInputs(deepCopy: inputs)
            childInputs.position = self.inputs.position
            childInputs.transform = self.inputs.transform
            childInputs.size = self.inputs.size
            
            let modifierOutputs = Modifier.Combiner.Result._makeGesture(
                gesture: _GraphValue(gestureViewChild),
                inputs: childInputs
            ).unsafeCast(to: Void.self)

            phase.overrideDefaultValue(modifierOutputs.phase, type: GesturePhase<()>.self)

            @inline(__always)
            func overrideOptionalDefault<Value: Defaultable>(keyPath: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>) where Value.Value == Value {
                guard let src = modifierOutputs[keyPath: keyPath],
                      let dest = outputs[keyPath: keyPath] else {
                    return
                }
                dest.overrideDefaultValue(src, type: Value.self)
            }
            @inline(__always)
            func overrideOutlet<Value: Defaultable>(requires: KeyPath<_ViewInputs, Bool>,
                                                    src: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>,
                                                    dest: KeyPath<GestureResponder<Modifier>, OptionalAttribute<Value>>) where Value.Value == Value {
                guard self.inputs[keyPath: requires] else {
                    return
                }
                guard let src = modifierOutputs[keyPath: src],
                      let dest = self[keyPath: dest].attribute else {
                    return
                }
                dest.overrideDefaultValue(src, type: Value.self)
            }
            
            overrideOptionalDefault(keyPath: \.gestureRecognitionWitness)
            overrideOptionalDefault(keyPath: \.platformGestureRecognizerList)
            
            // Gesture's data-flow is self-contained. We need to manually direct
            // Gesture's optional outputs to view's data-flow
            overrideOutlet(requires: \.preferences.requiresPlatformGestureRecognizerList, src: \.platformGestureRecognizerList, dest: \.viewPlatformGestureRecognizerListOutlet)

        }
        
        return outputs
    }
    
    internal override func resetGesture() {
        childSubgraph = nil
        super.resetGesture()
    }
    
    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        var superResult = super.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey)
        superResult.priority = 16
        return superResult
    }
    
}

/// Composites the result `Gesture` value combined by `Modifier.Combiner`. In
/// simple cases, we can directly combine the subviews gesture and content
/// gesture with the combiner specified by the `Modifier`, but we still need to
/// check the environment and gesture masks.
@available(iOS 13.0, *)
private struct GestureViewChild<Modifier: GestureViewModifier>: Rule {
    
    typealias Value = Modifier.Combiner.Result
    
    @Attribute
    fileprivate var modifier: Modifier

    @Attribute
    fileprivate var environment: EnvironmentValues

    @Attribute
    fileprivate var viewPhase: _GraphInputs.Phase
    
    fileprivate let node: AnyGestureResponder
    
    @inline(__always)
    private var shouldReceiveEvents: Bool {
        modifier.gestureMask.contains(.gesture) && environment.isEnabled
    }
    
    @inline(__always)
    private var subviewsGesture: AnyGesture<Void> {
        if modifier.gestureMask.contains(.subviews) {
            return AnyGesture(SubviewsGesture(node: node))
        } else {
            return AnyGesture(EmptyGesture())
        }
    }
    
    @inline(__always)
    private var contentGesture: AnyGesture<Void> {
        if shouldReceiveEvents {
            typealias BodyValue = Modifier.ContentGesture.Value
            let contentGesture = modifier.gesture
                .modifier(ContentGesture<BodyValue>())
                .modifier(ContentGestureRecognitionWitnessModifier(modifier: modifier))
            return AnyGesture(contentGesture)
        } else {
            return AnyGesture(EmptyGesture())
        }
    }
    
    fileprivate var value: Value {
        Modifier.Combiner.combine(subviewsGesture, contentGesture)
    }
    
}

@available(iOS 13.0, *)
private struct GestureViewChild_FeatureGestureContainer<Modifier: GestureViewModifier>: Rule {
    @DanceUIGraph.Attribute
    internal var modifier: Modifier
    
    @DanceUIGraph.Attribute
    internal var isEnabled: Bool
    
    @DanceUIGraph.Attribute
    internal var viewPhase: _GraphInputs.Phase
    
    typealias Value = AnyGesture<Void>

    var value: Value {
        let shouldReceiveEvents = modifier.gestureMask.contains(.gesture) && isEnabled
        guard shouldReceiveEvents else {
            return AnyGesture(EmptyGesture())
        }
        if modifier.isCancellable {
            return AnyGesture(modifier.gesture.cancellable().map { _ in })
        } else {
            return AnyGesture(modifier.gesture.map { _ in })
        }
    }
}

@available(iOS 13.0, *)
private struct CombiningGestureViewChild_FeatureGestureContainer<Modifier: GestureViewModifier>: Rule {
    @DanceUIGraph.Attribute
    fileprivate var modifier: Modifier
    
    @DanceUIGraph.Attribute
    fileprivate var isEnabled: Bool
    
    @DanceUIGraph.Attribute
    fileprivate var viewPhase: _GraphInputs.Phase
    
    fileprivate let node: any AnyGestureResponder_FeatureGestureContainer
    
    // Original: Modifier.Combiner.Result.Value
    fileprivate typealias Value = AnyGesture<Modifier.Combiner.Result.Value>

    @inline(__always)
    private var shouldReceiveEvents: Bool {
        modifier.gestureMask.contains(.gesture) && isEnabled
    }

    @inline(__always)
    private var shouldReceiveSubviewEvents: Bool {
        modifier.gestureMask.contains(.subviews)
    }

    @inline(__always)
    private var subviewsGesture: AnyGesture<Void> {
        if shouldReceiveSubviewEvents {
            return AnyGesture(SubviewsGesture_FeatureGestureContainer(node: node))
        } else {
            return AnyGesture(EmptyGesture())
        }
    }

    @inline(__always)
    private var contentGesture: AnyGesture<Void> {
        if shouldReceiveEvents {
            typealias BodyValue = Modifier.ContentGesture.Value
            let contentGesture = modifier.gesture
                .modifier(ContentGesture<BodyValue>())
            return AnyGesture(contentGesture)
        } else {
            return AnyGesture(EmptyGesture())
        }
    }

    fileprivate var value: Value {
        if modifier.isCancellable {
            return AnyGesture(Modifier.Combiner.combine(subviewsGesture, contentGesture).cancellable())
        } else {
            return AnyGesture(Modifier.Combiner.combine(subviewsGesture, contentGesture))
        }
    }
}

@available(iOS 13.0, *)
private struct ContentGesture<BodyValue>: GestureModifier {
    
    fileprivate typealias Value = Void
    
    fileprivate static func _makeGesture(modifier: _GraphValue<Self>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<()> {
        let bodyOutputs = body(inputs)
        
        let phase = Attribute(ContentPhase(phase: bodyOutputs.phase,
                                           resetSeed: inputs.resetSeed,
                                           reset: GestureReset()))
        
        return .make(phase: phase)
    }
    
}

@available(iOS 13.0, *)
private struct ContentPhase<A>: ResettableGestureRule {
    
    internal typealias Value = GesturePhase<Void>
    
    internal typealias PhaseValue = Void

    @Attribute
    internal var phase: GesturePhase<A>
    
    @Attribute
    internal var resetSeed: UInt32

    internal var reset: GestureReset
    
    internal mutating func updateValue() {
        guard resetIfNeeded(&reset) else {
            return
        }
        
        value = phase.set(Void())
    }

}

@available(iOS 13.0, *)
private struct ContentGestureRecognitionWitnessModifier<Modifier: GestureViewModifier, BodyValue>: GestureModifier {

    var modifier: Modifier

    fileprivate static func _makeGesture(modifier: _GraphValue<Self>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<BodyValue> {
        var bodyOutputs = body(inputs)

        if inputs.requiresGestureRecognitionWitness {
            if let bodyGRW = bodyOutputs.gestureRecognitionWitness {
                let gestureRecognitionWitness = Attribute(ContentGestureRecognitionWitness(gestureRecognitionWitness: bodyGRW, modifier: modifier.value))
                bodyOutputs = bodyOutputs
                    .withGestureRecognitionWitness(gestureRecognitionWitness)
            } else {
                bodyOutputs = bodyOutputs
                    .withGestureRecognitionWitness(modifier.value.modifier.extendedConfigs.gestureRecognitionWitness)
            }
        }

        return bodyOutputs
    }

}

@available(iOS 13.0, *)
private struct ContentGestureRecognitionWitness<Modifier: GestureViewModifier, BodyValue>: Rule {

    internal typealias Value = GestureRecognitionWitness

    @Attribute
    internal var gestureRecognitionWitness: GestureRecognitionWitness
    
    @Attribute
    internal var modifier: ContentGestureRecognitionWitnessModifier<Modifier, BodyValue>
    
    internal var value: Value {
        gestureRecognitionWitness.merged(with: modifier.modifier.extendedConfigs.gestureRecognitionWitness)
    }

}

@available(iOS 13.0, *)
private struct SubviewsGesture: Gesture {
    
    internal typealias Value = ()

    internal typealias Body = Never

    internal let node: AnyGestureResponder
    
    fileprivate static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        .makeSubviews(gesture: gesture.value, inputs: inputs)
    }

}

@available(iOS 13.0, *)
private struct SubviewsGesture_FeatureGestureContainer: PrimitiveGesture {
    internal typealias Value = ()

    internal typealias Body = Never

    internal let node: AnyGestureResponder_FeatureGestureContainer

    fileprivate static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        let outputs: _GestureOutputs<Void> = inputs.makeIndirectOutputs()
        let currentSubgraph = DGSubgraphRef.current!
        
        let subviewValue = Attribute(SubviewsPhase_FeatureGestureContainer(
            gesture: gesture.value,
            resetSeed: inputs.resetSeed,
            inputs: inputs,
            outputs: outputs,
            parentSubgraph: currentSubgraph,
            oldNode: nil,
            oldSeed: 0,
            childSubgraph: nil,
            childPhase: .init(),
            childDebugData: .init()
        ))
        outputs.setIndirectDependency(subviewValue.identifier)
        return outputs
    }
}

@available(iOS 13.0, *)
private struct SubviewsPhase_FeatureGestureContainer: StatefulRule, ObservedAttribute {

    internal struct Value {
        internal var phase: GesturePhase<Void>

        internal var debugData: GestureDebug.Data
    }

    @Attribute
    internal var gesture: SubviewsGesture_FeatureGestureContainer

    @Attribute
    internal var resetSeed: UInt32

    internal let inputs: _GestureInputs

    internal let outputs: _GestureOutputs<Void>

    internal let parentSubgraph: DGSubgraphRef

    internal var oldNode: AnyGestureResponder_FeatureGestureContainer?

    internal var oldSeed: UInt32

    internal var childSubgraph: DGSubgraphRef?

    @OptionalAttribute
    internal var childPhase: GesturePhase<Void>?

    @DanceUIGraph.OptionalAttribute
    internal var childDebugData: GestureDebug.Data?


    internal mutating func updateValue() {
        setupSubviewsGestureIfNeeded()
        value = Value(
            phase: childPhase ?? .failed,
            debugData: .init()
        )
    }

    @inline(__always)
    private mutating func setupSubviewsGestureIfNeeded() {
        let gesture = self.gesture
        let resetSeed = self.resetSeed

        guard resetSeed != oldSeed || oldNode !== gesture.node else {
            return
        }

        setupSubviewsGesture(gesture, resetSeed: resetSeed)
    }

    @inline(__always)
    private mutating func setupSubviewsGesture(_ gesture: SubviewsGesture_FeatureGestureContainer, resetSeed: UInt32) {
        if let subgraph = childSubgraph {
            childSubgraph = nil
            _childPhase = OptionalAttribute(nil)
            
            subgraph.willRemove()
            subgraph.invalidate()
        }
        
        if let node = oldNode {
            node.resetGesture()
        }
        
        let currentAttribute = DGAttribute.current!
        let child = DGSubgraphCreate(parentSubgraph.graph)
        
        childSubgraph = child
        parentSubgraph.add(child: child)
        
        let childOutputs = child.apply {
            // Fainally dispatches to `DefaultLayoutViewResponder.makeGesture`
            gesture.node.makeSubviewsGesture(inputs: inputs)
        }
        
        _childPhase = OptionalAttribute(childOutputs.phase)
        
        oldSeed = resetSeed
        oldNode = gesture.node
    }
    
    
    func destroy() {
        if let oldNode {
            oldNode.resetGesture()
        }
    }
}

@available(iOS 13.0, *)
private struct SubviewsInfo: StatefulRule {
    
    @Attribute
    fileprivate var gesture: SubviewsGesture

    @Attribute
    fileprivate var resetSeed: UInt32

    fileprivate let inputs: _GestureInputs

    fileprivate let parentSubgraph: DGSubgraphRef

    fileprivate struct Value {
        
        fileprivate var node: AnyGestureResponder

        fileprivate var seed: UInt32

        fileprivate var childSubgraph: DGSubgraphRef
        
        fileprivate var childOutputs: _GestureOutputs<Void>
        
        fileprivate static func make(gesture: SubviewsGesture, seed: UInt32, inputs: _GestureInputs, parentSubgraph: DGSubgraphRef) -> Value {
            let currentAttribute = DGAttribute.current!
            let childSubgraph = DGSubgraphCreate(parentSubgraph.graph)
            parentSubgraph.add(child: childSubgraph)
            let childOutputs = childSubgraph.apply {
                // Fainally dispatches to `DefaultLayoutViewResponder.makeGesture`
                gesture.node.makeSubviewsGesture(gesture: _GraphValue(Attribute(identifier: currentAttribute)), inputs: inputs)
            }
            return Value(node: gesture.node, seed: seed, childSubgraph: childSubgraph, childOutputs: childOutputs)
        }
        
        fileprivate func tearDown() {
            childSubgraph.willRemove()
            childSubgraph.invalidate()

            node.resetGesture()
        }
        
        @inline(__always)
        fileprivate func matches(seed: UInt32, ndoe: AnyGestureResponder) -> Bool {
            self.seed == seed && self.node === node
        }
        
    }
    
    fileprivate var oldValue: Value?
    
    fileprivate init(gesture: Attribute<SubviewsGesture>,
                     resetSeed: Attribute<UInt32>,
                     inputs: _GestureInputs,
                     parentSubgraph: DGSubgraphRef) {
        self._gesture = gesture
        self._resetSeed = resetSeed
        self.inputs = inputs
        self.parentSubgraph = parentSubgraph
        self.oldValue = nil
    }
    
    fileprivate mutating func updateValue() {
        let gesture = self.gesture
        let resetSeed = self.resetSeed
        
        if oldValue?.matches(seed: resetSeed, ndoe: gesture.node) == true {
            return
        }
        
        if let value = oldValue {
            value.tearDown()
            oldValue = nil
        }
        
        let value = Value.make(gesture: gesture,
                               seed: resetSeed,
                               inputs: inputs,
                               parentSubgraph: parentSubgraph)
        
        oldValue = value
        
        self.value = value
    }
}

@available(iOS 13.0, *)
private struct SubviewsInfoPhase: Rule {
    
    fileprivate typealias Value = GesturePhase<Void>
    
    @Attribute
    fileprivate var info: SubviewsInfo.Value
    
    fileprivate var value: Value {
        info.childOutputs.phase.value
    }

}

@available(iOS 13.0, *)
private struct SubviewsInfoOutput<Value>: Rule {
    
    @Attribute
    fileprivate var info: SubviewsInfo.Value
    
    fileprivate var keyPath: KeyPath<_GestureOutputs<Void>, Attribute<Value>?>
    
    fileprivate var defaultValue: () -> Value
    
    fileprivate var value: Value {
        info.childOutputs[keyPath: keyPath]?.value ?? defaultValue()
    }

}

@available(iOS 13.0, *)
extension _GestureOutputs where A == Void {
    
    fileprivate static func makeSubviews(gesture: Attribute<SubviewsGesture>, inputs: _GestureInputs) -> _GestureOutputs {
        let newInputs = inputs
        let subgraph = DGSubgraphRef.current!

        @Attribute(SubviewsInfo(gesture: gesture,
                                resetSeed: inputs.resetSeed,
                                inputs: newInputs,
                                parentSubgraph: subgraph))
        var info

        let phase = Attribute(SubviewsInfoPhase(info: $info))

        var outputs = _GestureOutputs.make(phase: phase)

        if inputs.requiresGestureRecognitionWitness {
            let attribute = Attribute(SubviewsInfoOutput(info: $info, keyPath: \.gestureRecognitionWitness, defaultValue: {GestureRecognitionWitness()}))
            outputs = outputs.withGestureRecognitionWitness(attribute)
        }

        if inputs.requiresPlatformGestureRecognizerList {
            let attribute = Attribute(SubviewsInfoOutput(info: $info, keyPath: \.platformGestureRecognizerList, defaultValue: {PlatformGestureRecognizerList()}))
            outputs = outputs.withPlatformGestureRecognizerList(attribute)
        }

        if inputs.requiresActiveGestureRecognizerObservers {
            let attribute = Attribute(SubviewsInfoOutput(info: $info, keyPath: \.activeGestureRecognizerObservers, defaultValue: { [] }))
            outputs = outputs.withActiveGestureRecognizerObservers(attribute)
        }

        return outputs
    }
    
}

@available(iOS 13.0, *)
internal protocol AnyGestureContainingResponder: ViewResponder {

    var viewSubgraph: DGSubgraphRef { get }

    var eventSources: [any EventBindingSource] { get }

    func detachContainer()

    var gestureType: any Any.Type { get }

    var isValid: Swift.Bool { get }
}

@available(iOS 13.0, *)
internal protocol GestureContainerFactory {
    static func makeGestureContainer(responder: any AnyGestureContainingResponder) -> AnyObject
}

@available(iOS 13.0, *)
internal struct GestureContainerFactoryInput: ViewInput {
    internal static let defaultValue: (any GestureContainerFactory.Type)? = nil

    internal typealias Value = (any GestureContainerFactory.Type)?
}

@available(iOS 13.0, *)
internal protocol AnyGestureResponder_FeatureGestureContainer: AnyGestureContainingResponder {

    var inputs: _ViewInputs { get }

    var childSubgraph: DGSubgraphRef? { get set }

    var childViewSubgraph: DGSubgraphRef? { get set }

    var exclusionPolicy: GestureResponderExclusionPolicy { get }

    var label: String? { get }

    var gestureGraph: GestureGraph { get }

    var relatedAttribute: DGAttribute { get }

    func makeSubviewsGesture(inputs: _GestureInputs) -> _GestureOutputs<Void>

    var gestureRecognizer: UIKitResponderGestureRecognizer? { get }

    func attach()

    var isCompanionGesture: Bool { get }

    var observer: DGUniqueID? { get set }

}

@available(iOS 13.0, *)
extension AnyGestureResponder_FeatureGestureContainer {
    internal var exclusionPolicy: GestureResponderExclusionPolicy { .default }
    
    internal func makeSubviewsGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        var inputs = inputs
        return _GestureOutputs.make(phase: inputs.intern(.failed, id: .init()))
    }

    internal func makeWrappedGesture(
        inputs: _GestureInputs,
        makeChild: (_GestureInputs) -> _GestureOutputs<Void>
    ) -> _GestureOutputs<Void> {
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
            let subgraph = (childViewSubgraph ?? childSubgraph)!
            var childInputs = inputs
            childInputs.position = self.inputs.position
            childInputs.transform = self.inputs.transform
            childInputs.size = self.inputs.size
            childInputs.setViewSubgraph(subgraph)
            let childOutputs = makeChild(childInputs)
            outputs.overrideDefaultValues(childOutputs)
        }
        return outputs
    }

    internal var label: String? { nil }

    internal var isCancellable: Bool {
        gestureGraph.isCancellable
    }
    
    internal var requiredTapCount: Int? {
        gestureGraph.requiredTapCount
    }
    
    /// - Parameter isCompanionGesture: `Button` and `View.onLongPressGesture`
    /// requires a companion gesture to implement a cancellable highlight/pressing
    /// gesture without using an iOS 18-only API:
    /// `-[UIGestureRecognizer _gestureRecognizer:canBeCancelledBy:]`.
    /// These kinds of gestures shall be exclusive to each other to prevent
    /// sticky highlight/pressing recognitions in nested
    /// Button/View.onLongPressGesture scene. This parameter is a DanceUI
    /// addition.
    ///
    internal func canPrevent(
        _ other: ViewResponder,
        otherExclusionPolicy: GestureResponderExclusionPolicy,
        isCompanionGesture: Bool = false
    ) -> Bool {
        guard isPrioritized(over: other, otherExclusionPolicy: otherExclusionPolicy, isCompanionGesture: isCompanionGesture) else {
            return false
        }
        guard let other = other as? any AnyGestureResponder_FeatureGestureContainer else {
            return true
        }
        return other.dependency.canBePrevented
    }
    
    /// - Parameter isCompanionGesture: see documentation below.
    ///
    private func isPrioritized(over other: ViewResponder, otherExclusionPolicy: GestureResponderExclusionPolicy, isCompanionGesture: Bool) -> Bool {
        func defaultToDefault() -> Bool {
            if self === other {
                return false
            }
            if other.isDescendant(of: self) {
                return false
            } else {
                // May be in different DSL hosts
                let hostView = self.host?.as(UIView.self)
                let otherHostView = other.host?.as(UIView.self)
                guard let hostView, let otherHostView else {
                    // undefined behavior
                    return false
                }
                return hostView.isDescendant(of: otherHostView)
            }
        }
        switch (otherExclusionPolicy, exclusionPolicy) {
        case (.default, .default):
            return defaultToDefault()
        case (.default, .highPriority):
            return true
        case (.default, .simultaneous):
            return false
        case (.highPriority, .default):
            return false
        case (.highPriority, .highPriority):
            if self === other {
                return true
            }
            if other.isDescendant(of: self) {
                return true
            } else {
                // May be in different DSL hosts
                let hostView = self.host?.as(UIView.self)
                let otherHostView = other.host?.as(UIView.self)
                guard let hostView, let otherHostView else {
                    // undefined behavior
                    return false
                }
                return !hostView.isDescendant(of: otherHostView)
            }
        case (.highPriority, .simultaneous):
            return false
        case (.simultaneous, .default):
            return false
        case (.simultaneous, .highPriority):
            return false
        case (.simultaneous, .simultaneous):
            if self.isCompanionGesture && isCompanionGesture {
                // Why hard code  as `.default` to `.default` works here?
                // Because this is only for Button highlight gesture and
                // View.onLongPressGesture pressing gesture. Both of these are
                // attached to the view with default exclusion policy.
                return defaultToDefault()
            }
            return false
        }
    }
    
    private var dependency: GestureDependency {
        gestureGraph.gestureDependency
    }
    
    internal func shouldRequireFailure(of other: any AnyGestureResponder_FeatureGestureContainer) -> Bool {
        guard exclusionPolicy != .simultaneous,
              other.exclusionPolicy != .simultaneous,
              let requiredTapCount,
              let otherRequiredTapCount = other.requiredTapCount,
              otherRequiredTapCount != requiredTapCount
        else {
            let result = other.isPrioritized(over: self, otherExclusionPolicy: exclusionPolicy, isCompanionGesture: isCompanionGesture) && dependency != .none
            gestureGraphLog(" | exclusionPolicy = \(exclusionPolicy), other.exclusionPolicy = \(other.exclusionPolicy) \(self.name) -> \(other.name)")
            gestureGraphLog(" | isCompanionGesture = \(isCompanionGesture), other.isCompanionGesture = \(other.isCompanionGesture) \(self.name) -> \(other.name)")
            gestureGraphLog(" | requiredTapCount = \(self.requiredTapCount?.description ?? "nil"), other.requiredTapCount = \(other.requiredTapCount?.description ?? "nil") \(self.name) -> \(other.name)")
            gestureGraphLog(" | result = \(result)")
            return result
        }
        gestureGraphLog(" | requiredTapCount \(requiredTapCount) < otherRequiredTapCount \(otherRequiredTapCount) \(self.name) -> \(other.name)")
        return requiredTapCount < otherRequiredTapCount
    }
    
    private var name: String {
        if let label = Update.ensure({ [self] in
            return label
        }) {
            return label
        }

        return _typeName(gestureType, qualified: false)
    }

    internal func setupViewSubgraphObserverIfNeeded() {
        if observer == nil {
            observer = viewSubgraph.add { [weak self] in
                guard let self else {
                    return
                }
                guard !self.viewSubgraph.isValid else {
                    return
                }

                if let gestureRecognizer = self.gestureRecognizer,  let view = self.gestureRecognizer?.view {
                    if gestureRecognizer.state != .possible {
                        gestureRecognizer.reset()
                    }
                    view.removeGestureRecognizer(gestureRecognizer)
                }

                self.observer = nil
            }
        }
    }

    internal func tearDownViewSubgraphObserverIfNeeded() {
        if let observer {
            self.viewSubgraph.remove(observer: observer)
        }
    }

}

@available(iOS 13.0, *)
internal final class GestureResponder_FeatureGestureContainer<Modifier: GestureViewModifier>: DefaultLayoutViewResponder, AnyGestureResponder_FeatureGestureContainer where Modifier: GestureViewModifier {

    internal let modifier: DanceUIGraph.Attribute<Modifier>

    internal var childSubgraph: DGSubgraphRef?

    internal var childViewSubgraph: DGSubgraphRef?

    internal lazy var gestureGraph: GestureGraph = {
        GestureGraph(rootResponder: self)
    }()

    internal lazy var bindingBridge: EventBindingBridge & GestureGraphDelegate = {
        let bridge = inputs.makeEventBindingBridge(bindingManager: gestureGraph.eventBindingManager, responder: self)
        gestureGraph.delegate  = bridge
        return bridge
    }()

    internal let gestureRecognizer: UIKitResponderGestureRecognizer?

    internal var observer: DGUniqueID?

    internal override var gestureContainer: UIView? {
        guard viewSubgraph.isValid else {
            return nil
        }

        setupViewSubgraphObserverIfNeeded()

        return gestureRecognizer?.view
    }

    internal init(modifier: DanceUIGraph.Attribute<Modifier>, inputs: _ViewInputs, gestureRecognizer: UIKitResponderGestureRecognizer?) {
        self.modifier = modifier
        self.gestureRecognizer = gestureRecognizer
        super.init(inputs: inputs)
    }

    internal var relatedAttribute: DGAttribute {
        modifier.identifier
    }

    internal var eventSources: [any EventBindingSource] {
        bindingBridge.eventSources
    }

    internal var exclusionPolicy: GestureResponderExclusionPolicy {
        Modifier.Combiner.exclusionPolicy
    }

    internal var label: String? {
        guard viewSubgraph.isValid else {
            return nil
        }
        return DGGraphRef.withoutUpdate {
            viewSubgraph.apply {
                modifier.name.value
            }
        }
    }

    internal var isValid: Bool {
        gestureRecognizer?.view != nil && viewSubgraph.isValid
    }

    internal func detachContainer() {
        
    }

    internal func makeSubviewsGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        makeGesture(inputs: inputs)
    }

    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        var superResult = super.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey)
        // if options.contains(.useZDistanceAsPriority) {
        superResult.priority = 16
        // }
        return superResult
    }

    internal override func bindEvent(_ event: any EventType) -> ResponderNode? {
        guard DanceUIFeature.gestureContainer.isEnable else {
            return super.bindEvent(event)
        }
        guard let hitTestableEvent = HitTestableEvent(event) else {
            return nil
        }
        return hitTest(globalPoint: hitTestableEvent.hitTestLocation, radius: hitTestableEvent.hitTestRadius)
    }
    
    internal override func makeGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        makeWrappedGesture(inputs: inputs) { childInputs in
            let closure: () -> _GestureOutputs<Void> = { [self] in
                if inputs.options.contains(.skipCombiners) {
                    let childGesture = Attribute(GestureViewChild_FeatureGestureContainer(
                        modifier: modifier,
                        // Here the isEnabled attribute is in GestureGraph owned subgraph
                        isEnabled: childInputs.environment.isEnabled,
                        viewPhase: childInputs.phase
                    ))
                    return AnyGesture<Void>.makeDebuggableGesture(gesture: _GraphValue(childGesture), inputs: childInputs)
                } else {
                    let childGesture = Attribute(CombiningGestureViewChild_FeatureGestureContainer(
                        modifier: modifier,
                        // Here the isEnabled attribute is in GestureGraph owned subgraph
                        isEnabled: childInputs.environment.isEnabled,
                        viewPhase: childInputs.phase,
                        node: self
                    ))
                    return AnyGesture<Modifier.Combiner.Result.Value>.makeDebuggableGesture(gesture: _GraphValue(childGesture), inputs: childInputs)
                }
            }
            guard inputs.options.contains(.includeDebugOutput) else {
                return closure()
            }
            return closure()
        }
    }

    internal override func resetGesture() {
        childSubgraph = nil
        childViewSubgraph = nil
        super.resetGesture()
    }

    internal override func extendPrintTree(string: inout String) {
        string.append("\(Modifier.ContentGesture.self)")
    }

    internal var gestureType: any Any.Type {
        Modifier.ContentGesture.self
    }

    internal func attach() {
        let _ = bindingBridge
        let _ = gestureContainer
    }

    deinit {
        tearDownViewSubgraphObserverIfNeeded()
    }

    internal var isCompanionGesture: Bool {
        gestureGraph.isCompanionGesture
    }

}
