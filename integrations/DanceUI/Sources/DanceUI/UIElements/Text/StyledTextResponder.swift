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
internal final class StyledTextResponder: ViewResponder, AnyGestureResponder_FeatureGestureContainer {
    @Attribute
    internal var view : StyledTextContentView
    
    @Attribute
    internal var style : _ShapeStyle_Shape.ResolvedStyle
    
    internal let inputs : _ViewInputs
    
    internal let viewSubgraph : DGSubgraphRef
    
    internal var helper : ContentResponderHelper<ShapeStyledResponderData<StyledTextContentView>>!
    
    internal var childSubgraph : DGSubgraphRef?
    
    internal var childViewSubgraph: DGSubgraphRef?
    
    internal lazy var gestureGraph: GestureGraph = {
        GestureGraph(rootResponder: self)
    }()
    
    internal lazy var bindingBridge: EventBindingBridge & GestureGraphDelegate = {
        let bridge = inputs.makeEventBindingBridge(bindingManager: gestureGraph.eventBindingManager, responder: self)
        gestureGraph.delegate  = bridge
        return bridge
    }()
    
    
    internal var gestureRecognizer: UIKitResponderGestureRecognizer?
    
    internal var observer: DGUniqueID?
    
    internal override var gestureContainer: UIView? {
        guard shouldEnableGestureContainer else {
            return nil
        }
        guard viewSubgraph.isValid else {
            return nil
        }
        setupViewSubgraphObserverIfNeeded()
        return gestureRecognizer?.view
    }
    
    @inline(__always)
    private var shouldEnableGestureContainer: Bool {
        guard viewSubgraph.isValid,
              let data = helper.data,
              let storage = data.view.resolvedStyledText.string,
              storage.hasTextInteractionAttributes // DanceUI modification
        else {
            return false
        }
        return true
    }
    
    internal var relatedAttribute: DGAttribute {
        _view.identifier
    }
    
    internal var eventSources: [any EventBindingSource] {
        bindingBridge.eventSources
    }
    
    internal func detachContainer() {
        // _gestureContainer = nil
    }
    
    internal var gestureType: any Any.Type {
        AnyGesture<Void>.self
    }
    
    internal var isValid: Bool {
        gestureRecognizer?.view != nil && viewSubgraph.isValid
    }
    
    internal override func resetGesture() {
        childSubgraph = nil
        childViewSubgraph = nil
    }
    
    internal init(view: Attribute<StyledTextContentView>, style: Attribute<_ShapeStyle_Shape.ResolvedStyle>, inputs: _ViewInputs, gestureRecognizer: UIKitResponderGestureRecognizer?) {
        self._view = view
        self._style = style
        self.inputs = inputs
        self.viewSubgraph = view.subgraph
        self.gestureRecognizer = gestureRecognizer
        super.init()
        self.helper = ContentResponderHelper(identifier: ObjectIdentifier(self))
    }
    
    internal override func bindEvent(_ event: any EventType) -> ResponderNode? {
        guard DanceUIFeature.gestureContainer.isEnable else {
            return nil
        }
        guard let hitTestableEvent = HitTestableEvent(event) else {
            return nil
        }
        return hitTest(globalPoint: hitTestableEvent.hitTestLocation, radius: hitTestableEvent.hitTestRadius)
    }
    
    internal override func makeGesture(inputs: _GestureInputs) -> _GestureOutputs<Void> {
        makeWrappedGesture(inputs: inputs) { childInputs in
            AnyGesture._makeGesture(gesture: _GraphValue($view.resolvedStyledText.textInteractionGesture), inputs: childInputs)
        }
    }
    
    internal override func makeGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        
        let outputs: _GestureOutputs<Void> = if DanceUIFeature.gestureContainer.isEnable {
            inputs.makeDefaultOutputs()
        } else {
            _GestureOutputs<Void>.makeDefault(viewGraph: .current, inputs: inputs)
        }
        
        guard viewSubgraph.isValid else {
            return outputs
        }
        
        let phase = Attribute(DefaultRule<GesturePhase<Void>>())
        
        let childSubgraph = DGSubgraphCreate(viewSubgraph.graph)
        
        viewSubgraph.add(child: childSubgraph)
        
        DGSubgraphRef.current!.add(child: childSubgraph)
        
        childSubgraph.apply { () -> Void in
            var childInputs = _GestureInputs(deepCopy: inputs)
            childInputs.transform = self.inputs.transform
            childInputs.position = self.inputs.position
            childInputs.size = self.inputs.size
            childInputs.hitTestInsets = self.inputs.hitTestInsets
            
            let outputs = AnyGesture._makeGesture(gesture: _GraphValue($view.resolvedStyledText.textInteractionGesture), inputs: childInputs)
            
            phase.overrideDefaultValue(outputs.phase, type: GesturePhase<Void>.self)
        }
        
        if let subgraph = self.childSubgraph {
            subgraph.invalidate()
        }
        
        self.childSubgraph = childSubgraph
        
        return outputs.withPhase(phase)
    }
    
    
    
    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        helper.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey, children: [])
    }
    
#if DEBUG
    internal var debugText: NSAttributedString?
#endif
    
    internal func update() {
        let (view, isViewChanged) = self.$view.changedValue()
        let (style, isStyleChanged) = self.$style.changedValue()
        let size = self.inputs.size.changedValue()
        let position = self.inputs.position.changedValue()
        let transform = self.inputs.transform.changedValue()
        let hitTestInsets = self.inputs.hitTestInsets?.changedValue()
        let data = ShapeStyledResponderData(view: view, style: style)
        let isDataChanged = isViewChanged || isStyleChanged
        helper.update(data: (data, isDataChanged), size: size, position: position, hitTestInsets: hitTestInsets, transform: transform, parent: self)
        if DanceUIFeature.gestureContainer.isEnable {
            attach()
        }
#if DEBUG
        debugText = view.resolvedStyledText.string
#endif
    }
    
    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        [helper.globalGeometry]
    }
    
    internal override var description: String {
#if DEBUG
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque()); text = \"\(debugText?.string ?? "nil")\" >"
#else
        // Text contents may be sensitive or confidential. Do not print in
        // release mode.
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())>"
#endif
    }
    
    internal func attach() {
        let _ = bindingBridge
        let _ = gestureContainer
    }
    
    internal var isCompanionGesture: Bool {
        false
    }
    
    deinit {
        if DanceUIFeature.gestureContainer.isEnable {
            tearDownViewSubgraphObserverIfNeeded()
        }
    }
    
}

@available(iOS 13.0, *)
private struct OpenURLGesture<Base: Gesture> : Gesture where Base.Value == URL {
    
    fileprivate typealias Value = URL
    
    fileprivate var base : Base
    
    @Environment(\.openURL)
    fileprivate var openURL : OpenURLAction
    
    fileprivate init(base: () -> Base) {
        self.base = base()
    }
    
    fileprivate var body: AnyGesture<URL> {
        AnyGesture(base.onEnded { url in
            openURL(url)
        })
    }
    
}

@available(iOS 13.0, *)
internal struct TextInteractionItemList {
    
    var items: [TextInteractionItem]
    
}

@available(iOS 13.0, *)
internal enum TextInteractionItem {
    
    case onTapAction(TextOnTapAction, NSAttributedString, NSRange, CGRect, Any?)
    
    case url(URL)
    
}

@available(iOS 13.0, *)
private struct TextOnTapOrOpenURLGesture<Base: Gesture> : Gesture where Base.Value == TextInteractionItemList {
    
    fileprivate typealias Value = TextInteractionItemList
    
    fileprivate var base : Base
    
    @Environment(\.openURL)
    fileprivate var openURL : OpenURLAction
    
    fileprivate init(base: () -> Base) {
        self.base = base()
    }
    
    fileprivate var body: AnyGesture<TextInteractionItemList> {
        AnyGesture(base.onEnded { itemList in
            for eachItem in itemList.items {
                switch eachItem {
                case .url(let url):
                    openURL(url)
                case .onTapAction(let action, let string, let subrange, let bounds, let info):
                    action(string, subrange, bounds, info)
                }
            }
        })
    }
    
}

@available(iOS 13.0, *)
extension ResolvedStyledText {
    
    fileprivate var gesture: AnyGesture<Void> {
        guard string?.hasLinkAttributes == true else {
            return AnyGesture(EmptyGesture())
        }
        
        typealias ErasedWorkingGesture = SizeGesture<
            _MapGesture<
                OpenURLGesture<
                    ModifierGesture<
                        StateContainerGesture<
                            State,
                            SpatialEvent,
                            URL
                        >,
                        TapGesture.SingleTap
                    >
                >
                ,
                Void
            >
        >
        
        let string = self.string
        
        struct State: GestureStateProtocol {
            
            internal var url : URL?
            
        }
        
        let gesture : ErasedWorkingGesture = SizeGesture { size in
            OpenURLGesture {
                TapGesture.SingleTap(maximumDuration: 0.75, maximumDistance: tapMovementThreshold)
                    ._updating(state: State.self) { state, phase -> GesturePhase<URL> in
                        if let url = state.url {
                            if string == self.string {
                                return phase.withValue(url)
                            }
                            return .failed
                        }
                        switch phase {
                        case .possible(let valueOrNil):
                            guard let value = valueOrNil,
                                  let url = self.linkURL(at: value.location, in: size) else {
                                return .possible(nil)
                            }
                            state.url = url
                            return .possible(url)
                        case .active(let value), .ended(let value):
                            let url = self.linkURL(at: value.location, in: size)
                            guard let url = url else {
                                return .failed
                            }
                            state.url = url
                            return phase.withValue(url)
                        case .failed:
                            return .failed
                        }
                    }
                
            }
            .map { _ in
                _intentionallyLeftBlank()
            }
        }
        
        return AnyGesture(gesture)
    }
    
    fileprivate var textInteractionGesture: AnyGesture<Void> {
        guard string?.hasTextInteractionAttributes == true else {
            return AnyGesture(EmptyGesture())
        }
        
        typealias TextInteractionGesture = SizeGesture<
            HitTestInsetsGesture<
                _MapGesture<
                    TextOnTapOrOpenURLGesture<
                        ModifierGesture<
                            StateContainerGesture<
                                State,
                                SpatialEvent,
                                TextInteractionItemList
                            >,
                            TapGesture.SingleTap
                        >
                    >
                        ,
                    Void
                >
            >
        >
        
        let string = self.string
        
        struct State: GestureStateProtocol {
            
            var interactionItemList : TextInteractionItemList?
            
        }
        
        let gesture: TextInteractionGesture = SizeGesture { (size) in
            HitTestInsetsGesture { (hitTestInsets) in
                TextOnTapOrOpenURLGesture {
                    TapGesture.SingleTap(maximumDuration: 0.75, maximumDistance: tapMovementThreshold)
                        ._updating(state: State.self) { state, phase -> GesturePhase<TextInteractionItemList> in
                            if let itemList = state.interactionItemList {
                                if string == self.string {
                                    return phase.withValue(itemList)
                                }
                                return .failed
                            }
                            switch phase {
                            case .possible(let valueOrNil):
                                guard let value = valueOrNil,
                                      let itemList = self.interactionItemList(at: value.location, in: size, hitTestInsets: hitTestInsets) else {
                                    return .possible(nil)
                                }
                                state.interactionItemList = itemList
                                return .possible(itemList)
                            case .active(let value), .ended(let value):
                                let itemList = self.interactionItemList(at: value.location, in: size, hitTestInsets: hitTestInsets)
                                guard let itemList = itemList else {
                                    return .failed
                                }
                                state.interactionItemList = itemList
                                return phase.withValue(itemList)
                            case .failed:
                                return .failed
                            }
                        }
                    
                }
                .map { _ in
                    _intentionallyLeftBlank()
                }
            }
        }
        
        return AnyGesture(gesture)
    }
    
}
