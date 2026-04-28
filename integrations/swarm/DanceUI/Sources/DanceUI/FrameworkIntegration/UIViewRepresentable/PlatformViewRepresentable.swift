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
@_spi(DanceUI) import DanceUIObservation

@available(iOS 13.0, *)
internal protocol PlatformViewRepresentable: View {
    
    associatedtype PlatformViewProvider
    
    associatedtype Coordinator
    
    associatedtype PlatformView

    var base: PlatformView { get }

    static func dynamicProperties() -> DynamicPropertyCache.Fields

    func makeViewProvider(context: PlatformViewRepresentableContext<Self>) -> PlatformViewProvider

    func updateViewProvider(_ provider: PlatformViewProvider, context: PlatformViewRepresentableContext<Self>)

    static func dismantleViewProvider(_ provider: PlatformViewProvider, coordinator: Coordinator)

    static func platformView(for provider: PlatformViewProvider) -> UIView

    func makeCoordinator() -> Coordinator

    func _identifiedViewTree(in provider: PlatformViewProvider) -> _IdentifiedViewTree

    func overrideSizeThatFits(_ size: inout CGSize, in: _ProposedSize, platformView: PlatformViewProvider, context: PlatformViewRepresentableContext<Self>)

    func overrideLayoutTraits(_ layoutTraits: inout _LayoutTraits, for provider: PlatformViewProvider)

    static var isViewController: Bool { get }
}

@available(iOS 13.0, *)
extension PlatformViewRepresentable {
    
    internal var body: Body {
        bodyError()
    }
    
    internal func intrinsicLayoutTraits(for view: UIView) -> _LayoutTraits {
        _LayoutTraits(
            width: layoutTraitsDimension(for: view, axis: .horizontal),
            height: layoutTraitsDimension(for: view, axis: .vertical),
            spacing: Spacing(minima: [
                .init(category: .edgeBelowText, edge: .bottom): 0,
                .init(category: .edgeAboveText, edge: .top): 0
            ])
        )
    }
    
    internal static func platformView(for provider: PlatformViewProvider) -> UIView {
        provider as! UIView
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        
        typealias Child = PlatformViewChild<Self>
        
        // Archiving has not been implemented in DanceUI
        guard !inputs.isArchived else {
            
            var outputs = _ViewOutputs()
            
            guard inputs.preferences.requiresDisplayList else {
                return outputs
            }
            
            
            return outputs
        }
        
        var childInputs = inputs
        var graphInputs = childInputs.base
        
        let preferenceBridge = PreferenceBridge(viewGraph: ViewGraph.current)
        
        let child = _DynamicPropertyBuffer.makeTraced(fields: Self.dynamicProperties(), container: view, inputs: &graphInputs) { links -> Child in
            return Child(
                view: view.value,
                environment: inputs.environment,
                transaction: inputs.transaction,
                phase: inputs.phase,
                focusedValues: inputs.focusedValues,
                gestureRecognizerObservers: inputs.gestureObservers,
                bridge: preferenceBridge,
                links: links,
                platformView: nil,
                resetSeed: 0,
                isRecognizingPlatformViewGesture: inputs.isRecognizingPlatformViewGesture)
            
        }.makeAttribute()
        
        child.setFlags([.active, .removable, .invalidatable], mask: .reserved)
#if DEBUG || DANCE_UI_INHOUSE
        child.association = .bodyAccessor(containerType: Self.self)
#endif
        
        let childValue = _GraphValue(child)
        
        let viewLeafView = childValue[\Child.Value.content.content.content].value
        
        childInputs.preferences.remove(_IdentifiedViewsKey.self)
        
        let needsFocusUpdate = Attribute(UIViewNeedsFocusUpdate(provider: PlatformRepresentableFocusableViewProvider(view: viewLeafView),
                                                                focusedItem: inputs.focusedItem.attribute!))
        
        needsFocusUpdate.setFlags(.active, mask: .reserved)
        
        childInputs.updateCachedEnvironment(attribute: inputs.environment)
        
        var outputs = Child.Value.makeDebuggableView(value: childValue, inputs: childInputs)
        
        if inputs.preferences.requiresViewResponders {
            outputs.viewResponders = Attribute(ViewResponderFilter(
                view: viewLeafView,
                position: inputs.animatedPosition,
                size: inputs.animatedSize,
                transform: inputs.transform,
                hitTestInsets: inputs.hitTestInsets)
            )
        }
        
        outputs.makePreferenceWriter(
            inputs: childInputs,
            key: _IdentifiedViewsKey.self,
            value: Attribute(PlatformViewIdentifiedViews<Self>(leafView: viewLeafView, time: inputs.time))
        )
        
        preferenceBridge.wrapOutputs(outputs: &outputs, inputs: childInputs)
        
        return outputs
    }
    
    internal static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        .unaryViewList(view: view, inputs: inputs)
    }
    
    @inlinable
    internal func layoutTraitsDimension(for platformView: UIView,  axis: NSLayoutConstraint.Axis) -> _LayoutTraits.Dimension {
        let intrinsicContentSize = platformView.intrinsicContentSize
        
        let dimension = axis.dimension(for: intrinsicContentSize)
        
        let min: CGFloat
        let ideal: CGFloat
        let max: CGFloat
        
        if dimension == UIView.noIntrinsicMetric {
            min = 0
            ideal = 0
            max = .infinity
        } else {
            ideal = Swift.max(0, dimension)
            min = platformView.contentCompressionResistancePriority(for: axis) < .defaultHigh ? 0 : ideal
            max = platformView.contentHuggingPriority(for: axis) < .defaultHigh ? CGFloat.infinity : ideal
        }
        
        return _LayoutTraits.Dimension(min: min, ideal: ideal, max: max)
    }
    
}

@available(iOS 13.0, *)
private struct PlatformViewChild<PlatformView: PlatformViewRepresentable>: StatefulRule, ObservedAttribute, RemovableAttribute, InvalidatableAttribute, ObservationAttribute {
    
    fileprivate typealias Value = ModifiedContent<
        ModifiedContent<
            ModifiedContent<
                ViewLeafView<PlatformView>,
                AccessibilityPlatformModifier
            >,
            _AlignmentWritingModifier
        >,
        _AlignmentWritingModifier
    >
    
    @Attribute
    fileprivate var view: PlatformView

    @Attribute
    fileprivate var environment: EnvironmentValues

    @Attribute
    fileprivate var transaction: Transaction

    @Attribute
    fileprivate var phase: _GraphInputs.Phase

    @OptionalAttribute
    fileprivate var focusedValues: FocusedValues?

    @OptionalAttribute
    fileprivate var gestureRecognizerObservers: GestureObservers?

    fileprivate let bridge: PreferenceBridge

    fileprivate var links: _DynamicPropertyBuffer

    fileprivate var coordinator: PlatformView.Coordinator?

    fileprivate var platformView: PlatformViewHost<PlatformView>?

    fileprivate var resetSeed: UInt32

    fileprivate let tracker: PropertyList.Tracker

    fileprivate let isRecognizingPlatformViewGesture: Bool

    fileprivate var previousObservationTrackings: [ObservationTracking]?

    fileprivate var deferredObservationGraphMutation: DeferredObservationGraphMutation?
    
    fileprivate init(view: Attribute<PlatformView>,
                     environment: Attribute<EnvironmentValues>,
                     transaction: Attribute<Transaction>,
                     phase: Attribute<_GraphInputs.Phase>,
                     focusedValues: OptionalAttribute<FocusedValues>,
                     gestureRecognizerObservers: OptionalAttribute<GestureObservers>,
                     bridge: PreferenceBridge,
                     links: _DynamicPropertyBuffer,
                     coordinator: PlatformView.Coordinator? = nil,
                     platformView: PlatformViewHost<PlatformView>?,
                     resetSeed: UInt32,
                     isRecognizingPlatformViewGesture: Bool) {
        self._view = view
        self._environment = environment
        self._transaction = transaction
        self._phase = phase
        self._focusedValues = focusedValues
        self._gestureRecognizerObservers = gestureRecognizerObservers
        self.bridge = bridge
        self.links = links
        self.coordinator = coordinator
        self.platformView = platformView
        self.resetSeed = resetSeed
        self.tracker = PropertyList.Tracker()
        self.isRecognizingPlatformViewGesture = isRecognizingPlatformViewGesture
    }
    
    fileprivate mutating func updateValue() {
#if DANCE_UI_INHOUSE || DEBUG
        Signpost.platformUpdate.traceInterval(object: nil,
                                              "PlatformUpdate (%p) %{public}%@ [ %p ]",
                                              [DGGraphRef.current.graphIdentity,
                                              _typeName(PlatformView.PlatformViewProvider.self, qualified: false),
                                              UInt(platformView)]) {
            _updateValue()
        }
#else
        _updateValue()
#endif
    }
    
    fileprivate mutating func _updateValue() {
            func perform(_ workItem: @escaping () -> Void) {
                let rendererHost = ViewGraph.viewRendererHost
                DGGraphRef.withoutUpdate {
                    if let host = rendererHost /* checked */ {
                        Update.ensure {
                            host.performExternalUpdate(workItem)
                        }
                    } else {
                        workItem()
                    }
                }
            }
            
            var (view, isViewChanged) = $view.changedValue()
            
            let (phase, isPhaseChanged) = $phase.changedValue()
            
            var (environment, isEnvironmentChanged) = $environment.changedValue()
            
            if phase.seed != resetSeed {
                links.reset()
                destroyPlatformView()
                resetSeed = phase.seed
            }
            
            let hasLinksUpdated = withUnsafeMutablePointer(to: &view) { view in
                links.update(container: view, phase: phase)
            }
            
            let hasAnyUpdates = hasLinksUpdated || !hasValue || isViewChanged || AnyRuleContext.wasModified
        
            let shouldCancelPreviousObservationTrackings = hasLinksUpdated || isViewChanged
            
            let transaction: Transaction = DGGraphRef.withoutUpdate {
                if coordinator == nil {
                    coordinator = view.makeCoordinator()
                }
                return self.transaction
            }
            
            let (focusedValues, isFocusedValueChanged) = $focusedValues!.changedValue()
            
            let (gestureRecognizerObservers, isGestureRecognizerObserversChanged) = $gestureRecognizerObservers!.changedValue()
            
            environment.preferenceBridge = bridge
            
            let context: PlatformViewRepresentableContext<PlatformView>
            
            let needsSetValue: Bool
            
            if platformView == nil {
                needsSetValue = true
                
                let trackedEnvironment = environment.withTracker(tracker)
                
                let values = PlatformViewRepresentableValues(preferenceBridge: bridge,
                                                             transaction: transaction,
                                                             environment: trackedEnvironment)
                
                context = PlatformViewRepresentableContext<PlatformView>(
                    values: values,
                    coordinator: self.coordinator!
                )
                
                let viewRendererHost = ViewGraph.viewRendererHost
                
                self.platformView = withObservation(shouldCancelPrevious: shouldCancelPreviousObservationTrackings) { [isRecognizingPlatformViewGesture] in
                    DGGraphRef.withoutUpdate {
                        let platformView = context.values.asCurrent {
                            
                            let viewProvider = view.makeViewProvider(context: context)
                            
                            let platformView = PlatformViewHost<PlatformView>(viewProvider,
                                                                              host: viewRendererHost,
                                                                              focusedValues: focusedValues,
                                                                              gestureRecognizerObservers: gestureRecognizerObservers,
                                                                              environment: environment,
                                                                              viewPhase: phase)
                            return platformView
                        }
                        if isRecognizingPlatformViewGesture {
                            platformView.delaysTouchesBegan = true
                        }
                        return platformView
                    }
                }
                
            } else {
                
                if isEnvironmentChanged && environment.hasDifferentUsedValues(with: tracker) {
                    tracker.reset()
                    needsSetValue = true
                } else {
                    var _needsSetValue = isFocusedValueChanged || isPhaseChanged || hasAnyUpdates
                    _needsSetValue = _needsSetValue || isGestureRecognizerObserversChanged
                    needsSetValue = _needsSetValue
                }
                
                let trackedEnvironment = environment.withTracker(tracker, resets: false)
                
                DGGraphRef.withoutUpdate {
                    platformView!.updateEnvironment(trackedEnvironment, viewPhase: phase, focusedValues: focusedValues)
                }
                
                let values = PlatformViewRepresentableValues(preferenceBridge: bridge,
                                                             transaction: transaction,
                                                             environment: trackedEnvironment)
                
                context = PlatformViewRepresentableContext<PlatformView>(
                    values: values,
                    coordinator: self.coordinator!
                )
            }
            
            guard needsSetValue else {
                return
            }
        
            withObservation(shouldCancelPrevious: shouldCancelPreviousObservationTrackings) { [representedViewProvider] in
                perform {
                    view.updateViewProvider(representedViewProvider!, context: context)
                }
            }
            
            let representedView = platformView!.representedView
            
            self.value = ViewLeafView(content: view, platformView: platformView!, coordinator: coordinator!)
                .accessibility(platformView: representedView)
                .alignment(key: VerticalAlignment.firstTextBaseline.key) { (dimension) -> CGFloat in
                    representedView.my__baselineOffsets(at: dimension.size.value).firstTextBaselineOffset
                }
                .alignment(key: VerticalAlignment.lastTextBaseline.key) { (dimension) -> CGFloat in
                    let baselineOffset = representedView.my__baselineOffsets(at: dimension.size.value).lastTextBaselineOffset
                    
                    let key = VerticalAlignment.bottom.key
                    
                    let bottomAlignment: CGFloat = dimension[key]
                    
                    return bottomAlignment - baselineOffset
                }
    }
    
    fileprivate mutating func destroy() {
        links.destroy()
        destroyPlatformView()
    }
    
    fileprivate static func willRemove(attribute: DGAttribute) {
        attribute.info.body.assumingMemoryBound(to: Self.self).pointee.bridge.removeStateDidChange()
    }
    
    fileprivate static func didReinsert(attribute: DGAttribute) {
        willRemove(attribute: attribute)
    }
    
    fileprivate static func willInvalidate(attribute: DGAttribute) {
        willRemove(attribute: attribute)
    }
    
    fileprivate var representedViewProvider: PlatformView.PlatformViewProvider? {
        guard let platformView = self.platformView else {
            return nil
        }
        
        return platformView.representedViewProvider
    }
    
    fileprivate mutating func destroyPlatformView() {

        guard let coordinator = self.coordinator else {
            return
        }
        
        guard let platformView = self.representedViewProvider else {
            return
        }
        
        PlatformView.dismantleViewProvider(
            platformView,
            coordinator: coordinator
        )
        
        self.platformView = nil
        
        self.coordinator = nil
    }
    
}

@available(iOS 13.0, *)
private struct PlatformRepresentableFocusableViewProvider<A: PlatformViewRepresentable>: UIViewFocusableViewProvider {
    
    @Attribute
    fileprivate var view: ViewLeafView<A>
    
    fileprivate var focusableView: UIView {
        view.platformView.representedView
    }
    
}

@available(iOS 13.0, *)
private struct ViewResponderFilter<A: PlatformViewRepresentable>: StatefulRule {
    
    fileprivate typealias Value = [ViewResponder]
    
    @Attribute
    private var view: ViewLeafView<A>
    
    @Attribute
    private var position: ViewOrigin
    
    @Attribute
    private var size: ViewSize
    
    @Attribute
    private var transform: ViewTransform
    
    @OptionalAttribute
    private var hitTestInsets: EdgeInsets??
    
    private let responder: AnyUIViewResponder
    
    fileprivate init(view: Attribute<ViewLeafView<A>>,
                     position: Attribute<ViewOrigin>,
                     size: Attribute<ViewSize>,
                     transform: Attribute<ViewTransform>,
                     hitTestInsets: Attribute<EdgeInsets?>?) {
        self._view = view
        self._position = position
        self._size = size
        self._transform = transform
        self._hitTestInsets = OptionalAttribute(hitTestInsets)
        self.responder = makeAnyUIViewResponder()
    }
    
    fileprivate mutating func updateValue() {
        let viewLeafView = self.view
        responder.hostView = viewLeafView.platformView
        viewLeafView.platformView.responder = responder
        responder.representedView = viewLeafView.platformView.representedView
        
        responder.helper.update(data: (TrivialContentResponder(), true),
                                size: $size.changedValue(),
                                position: $position.changedValue(),
                                hitTestInsets: $hitTestInsets?.changedValue(),
                                transform: $transform.changedValue(),
                                parent: responder)
        
        if !hasValue {
            value = [responder]
        }
    }
    
}

@available(iOS 13.0, *)
extension NSLayoutConstraint.Axis {
    
    @inline(__always)
    internal func dimension(for size: CGSize) -> CGFloat {
        switch self {
        case .horizontal:   return size.width
        case .vertical:     return size.height
        @unknown default:
            assertionFailure("Unknown NSLayoutConstraint.Axis type.")
            return size.height
        }
    }
    
}
