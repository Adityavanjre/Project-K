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

import CoreGraphics
internal import DanceUIGraph

@available(iOS 13.0, *)
internal final class ViewGraph: GraphHost {
    
    internal struct Outputs: Equatable, ExpressibleByArrayLiteral, RawRepresentable, SetAlgebra, OptionSet {
        
        internal typealias RawValue = UInt8
        
        internal var rawValue: UInt8 = 0
        
        internal init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        internal init() {
            self.rawValue = 0
        }
        
        internal func addRequestedPreferences(to inputs: inout _ViewInputs) {
            inputs.preferences.requiresHostPreferences = true
            
            if self.contains(.needHandleDisplayList) {
                inputs.preferences.requiresDisplayList = true
            }
            
            if self.contains(.needHandleViewResponder) {
                inputs.preferences.requiresViewResponders = true
            }
            
            if self.contains(.needHandlePlatformItemList) {
                inputs.preferences.requiresPlatformItemList = true
            }
            
            if self.contains(.needHandleAccessibilityNodes) {
                inputs.preferences.requiresAccessibilityNodes = true
            }

            if self.contains(.platformGestureRecognizerList) {
                inputs.preferences.requiresPlatformGestureRecognizerList = true
            }
        }
        
        internal static let needHandleDisplayList: Outputs = Outputs(rawValue: 1 << 0)

        internal static let needHandlePlatformItemList: Outputs = Outputs(rawValue: 1 << 1)

        internal static let needHandleViewResponder: Outputs = Outputs(rawValue: 1 << 2)

        internal static let needHandleAccessibilityNodes: Outputs = Outputs(rawValue: 1 << 3)

        internal static let needHandleLayouts: Outputs = Outputs(rawValue: 1 << 4)

        internal static let platformGestureRecognizerList: Outputs = Outputs(rawValue: 1 << 5)

        internal static let isRecognizingPlatformViewGesture: Outputs = Outputs(rawValue: 1 << 6)

        internal static let defaults: Outputs = [
            .needHandleDisplayList,
            .needHandleViewResponder,
            .platformGestureRecognizerList,
            .isRecognizingPlatformViewGesture
        ]
    }
    
    /// View renderer host for current `ViewGraph` instance.
    @inlinable
    internal static var viewRendererHost: ViewRendererHost? {
        current.viewRendererHost
    }
    
    @inlinable
    internal static var current: ViewGraph {
        unsafeDowncast(currentHost, to: ViewGraph.self)
    }

    /// View renderer host for `ViewGraph` instance.
    @inlinable
    internal var viewRendererHost: ViewRendererHost? {
        delegate as? ViewRendererHost
    }

    internal var rootViewType: Any.Type

    internal var makeRootView: (DGAttribute, _ViewInputs) -> _ViewOutputs

    internal weak var delegate: ViewGraphDelegate? = nil

    internal var centersRootView: Bool = true

    internal var rootView: DGAttribute

    @Attribute
    internal var rootTransform: ViewTransform

    @Attribute
    internal var zeroPoint: ViewOrigin

    @Attribute
    internal var emptyViewResponders: [ViewResponder]

    @Attribute
    internal var emptyPlatformItemList: PlatformItemList

    @Attribute
    internal var proposedSize: ViewSize

    @Attribute
    internal var safeAreaInsets: _SafeAreaInsetsModifier

    @Attribute
    internal var rootGeometry: ViewGeometry

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var dimensions: ViewSize

    @Attribute
    internal var updateSeed: UInt32

    @Attribute
    internal var gestureTime: Time

    @Attribute
    internal var gestureEvents: [EventID: EventType]

    @Attribute
    internal var inheritedPhase: _GestureInputs.InheritedPhase

    @Attribute
    internal var gestureResetSeed: UInt32

    @Attribute
    internal var failedPhase: GesturePhase<Void>

    @OptionalAttribute
    internal var rootPhase: GesturePhase<Void>?

    internal var eventSubgraph: DGSubgraphRef?

    @Attribute
    internal var defaultLayoutComputer: LayoutComputer

    @Attribute
    internal var focusedItem: FocusItem?

    @Attribute
    internal var focusedValues: FocusedValues

    @Attribute
    internal var focusStore: FocusStore

    // @Attribute
    // internal var accessibilityFocusStore: AccessibilityFocusStore

    // @Attribute
    // internal var accessibilityFocus: AccessibilityFocus

    @WeakAttribute
    internal var rootResponders: [ViewResponder]?

    @WeakAttribute
    internal var rootAccessibilityNodes: AccessibilityNodeList?

    @WeakAttribute
    internal var rootLayoutComputer: LayoutComputer?

    @WeakAttribute
    internal var rootDisplayList: (DisplayList, DisplayList.Version)?

    @WeakAttribute
    internal var rootPlatformItemList: PlatformItemList?

    internal var cachedSizeThatFits: CGSize = .invalidValue

    internal var sizeThatFitsObserver: SizeThatFitsObserver? {
        didSet {
            if sizeThatFitsObserver != nil {
                precondition(requestedOutputs.contains(.needHandleLayouts))
            }
        }
    }

    internal var requestedOutputs: Outputs {
        didSet {
            requestedOutputsDidChange(from: oldValue)
        }
    }

    internal var disabledOutputs: Outputs = Outputs()

    /// The initial main-thread update count in an update cycle of
    /// `ViewGraph.update(at:)`.
    internal var mainUpdates: Int = 0

    internal var needsFocusUpdate: Bool = false

    /// `ViewGraph`'s next update timing.
    ///
    /// - note: Use `scheduleNextGestureUpdate` and
    /// `scheduleNextViewUpdate` to mutate the value outside `ViewGraph`.
    internal private(set) var nextUpdate: (views: NextUpdate, gestures: NextUpdate) = (.distantFuture, .distantFuture)

    internal weak var _preferenceBridge: PreferenceBridge?

    @inlinable
    internal var preferenceBridge: PreferenceBridge? {
        get {
            _preferenceBridge
        }
        set {
            setPreferenceBridge(to: newValue, isInvalidating: false)
        }
    }

    internal var bridgedPreferences: [(AnyPreferenceKey.Type, DGAttribute)] = []

    internal var accessibilityRelationshipScope: AccessibilityRelationshipScope?

    internal var isUnlikelyToBeUninstantiated = false

    internal var addedBridgePreference: Bool = false
    
    internal var indexPath: IndexPath? = nil

#if FEAT_MONITOR
    internal var auditor: PerformanceAuditor?

    private var semanticRootViewType: Any.Type {
        var rootViewGraph: ViewGraph = self
        while let bridge = rootViewGraph.preferenceBridge {
            rootViewGraph = bridge.viewGraph
        }
        return rootViewGraph.rootViewType
    }

    internal var auditingCategory: [AnyHashable : Any] {
        [
            PerformanceAuditor.CategoryKeys.literalRootViewName: _typeName(rootViewType, qualified: true),
            PerformanceAuditor.CategoryKeys.semanticRootViewName: _typeName(semanticRootViewType, qualified: true)
        ]
    }

#endif
    
    internal override var graphDelegate: GraphDelegate? {
        delegate
    }
    
    internal override var parentHost: GraphHost? {
        guard let preferenceBridge = preferenceBridge else {
            return nil
        }
        
        return preferenceBridge.viewGraph
    }
    
    internal var responderNode: ResponderNode? {
        rootResponders?.first
    }
    
    internal var transform: ViewTransform {
        self.rootTransform
    }
    
    @discardableResult
    internal func invalidateTransform() -> Bool {
        guard !$rootTransform.valueState.contains(.isDirty) else {
            return false
        }
        
        $rootTransform.invalidateValue()
        _notifyDelegateGraphDidChange()
        return true
    }
    
    internal init<RootViewType: View>(rootViewType: RootViewType.Type,
                                      requestedOutputs: ViewGraph.Outputs,
                                      usedInAsyncComputation: Bool = false) {
        self.rootViewType = rootViewType
        self.requestedOutputs = requestedOutputs
        
        let data = GraphHost.Data(usedInAsyncComputation)
        
        DGSubgraphRef.current = data.globalSubgraph
        
        rootView = Attribute(type: RootViewType.self).identifier
        _rootTransform = Attribute(RootTransform())
        _zeroPoint = Attribute(value: ViewOrigin.zero)
        _emptyViewResponders = Attribute(value: [])
        _emptyPlatformItemList = Attribute(value: PlatformItemList())
        _proposedSize = Attribute(value: .zero)
        
        _safeAreaInsets = Attribute(
            value: _SafeAreaInsetsModifier(
                elements: [SafeAreaInsets.Element(regions: .container, insets: .zero)],
                nextInsets: nil
            )
        )
        
        _defaultLayoutComputer = Attribute(value: .defaultValue)
        _focusedItem = Attribute(value: nil)
        _focusedValues = Attribute(value: FocusedValues())
        _focusStore = Attribute(value: FocusStore())
        // _accessibilityFocusStore = ...
        // _accessibilityFocus = ...
        _gestureTime = Attribute(value: .zero)
        _gestureEvents = Attribute(value: [:])
        _inheritedPhase = Attribute(value: .failed)
        _gestureResetSeed = Attribute(value: 0)
        _failedPhase = Attribute(value: .failed)
        
        _emptyGestureRecognizerList = Attribute(value: nil)
        _emptyGestureRecognitionWitness = Attribute(value: GestureRecognitionWitness())
        _gestureObservers = Attribute(value: GestureObservers())
        
        let rootGeometry = RootGeometry(layoutDirection: .init(),
                                        proposedSize: _proposedSize,
                                        safeAreaInsets: .init(_safeAreaInsets),
                                        childLayoutComputer: .init())
        
        _rootGeometry = .init(rootGeometry)
        _position = _rootGeometry.origin()
        _dimensions = _rootGeometry.size()
        _updateSeed = .init(value: 0)
        
        makeRootView = { [_zeroPoint, _proposedSize, _safeAreaInsets] (identifer: DGAttribute, inputs: _ViewInputs) in
            
            var zeroInputs = inputs
            
            zeroInputs.position = _zeroPoint
            zeroInputs.containerPosition = _zeroPoint
            zeroInputs.size = _proposedSize
            
            let rootView = _GraphValue<RootViewType>(Attribute(identifier: identifer))
            return _SafeAreaInsetsModifier.makeDebuggableViewModifier(value: _GraphValue(_safeAreaInsets), inputs: zeroInputs) { graph, insetInputs in
                var modifiedRootViewInputs = insetInputs
                modifiedRootViewInputs.position = inputs.position
                modifiedRootViewInputs.containerPosition = inputs.containerPosition
                modifiedRootViewInputs.size = inputs.size
                return rootViewType.makeDebuggableView(value: rootView, inputs: modifiedRootViewInputs)
            }
        }
        // The ultimate runtime control of the feature "monitor"
#if FEAT_MONITOR
        if DanceUIFeature.monitor.isEnable {
            self.auditor = PerformanceAuditor()
        }
#endif
        super.init(data: data)
        DGSubgraphRef.current = nil
#if FEAT_MONITOR
        if DanceUIFeature.monitor.isEnable {
            NotificationCenter.default.addObserver(self, selector: #selector(handleWillTerminateNotification(_:)), name: UIApplication.willTerminateNotification, object: nil)
        }
#endif
    }

#if FEAT_MONITOR
    @objc
    func handleWillTerminateNotification(_ notification: Notification) {
        auditor?.traceRootViewComputationEnd()
        auditor?.enqueueCommit(on: .rootViewLifetimeDidEnd, category: auditingCategory)
    }
#endif

    deinit {
#if FEAT_MONITOR
        auditor?.traceRootViewComputationEnd()
        if DanceUIFeature.monitor.isEnable {
            NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        }
        auditor?.enqueueCommit(on: .rootViewLifetimeDidEnd, category: auditingCategory)
#endif
        removePreferenceOutlets(isInvalidating: true)
    }
    
    @inlinable
    internal var defaultViewInputs: _ViewInputs {
        _ViewInputs(base: graphInputs,
                    preferences: .init(hostKeys: self.data.$hostPreferenceKeys),
                    transform: $rootTransform,
                    position: $position,
                    containerPosition: $zeroPoint,
                    size: $dimensions,
                    safeAreaInsets: .init())
    }
    
    internal override func instantiateOutputs() {
#if DEBUG || DANCE_UI_INHOUSE
        Signpost.viewGraph.traceInterval("instantiateOutputs: hostingState: %s; %s", [graphDelegate?.hostingState() ?? "empty", graphDelegate?.hostingType() ?? "empty"]) {
            _instantiateOutputs()
        }
#else
        _instantiateOutputs()
#endif
    }
    
    private func _instantiateOutputs() {
        let outputs: _ViewOutputs = data.rootSubgraph.apply {
            var viewInputs = defaultViewInputs
            
            if requestedOutputs.contains(.needHandleLayouts) {
                viewInputs.enableLayouts = true
                viewInputs.needReposition = true
                viewInputs.enableFlag0x40 = true
                viewInputs.enableFlag0x80 = true
            }
            
            requestedOutputs.addRequestedPreferences(to: &viewInputs)
            
            preferenceBridge?.wrapInputs(inputs: &viewInputs)
            
            _ViewDebug.initialize()
            
            delegate?.modifyViewInputs(&viewInputs)
            
            if viewInputs.matchedGeometryScope == nil {
                viewInputs.matchedGeometryScope = MatchedGeometryScope(inputs: viewInputs)
            }
            
            if let relationshipScope = viewInputs.accessibilityRelationshipScope {
                accessibilityRelationshipScope = relationshipScope
            } else {
                let relationshipScope = AccessibilityRelationshipScope()
                viewInputs.accessibilityRelationshipScope = relationshipScope
                accessibilityRelationshipScope = relationshipScope
            }
            
            viewInputs.focusedItem = OptionalAttribute($focusedItem)
            
            viewInputs.focusedValues = OptionalAttribute($focusedValues)
            
            viewInputs.focusStore = OptionalAttribute($focusStore)

            viewInputs.gestureObservers = OptionalAttribute($gestureObservers)
            
            _rootGeometry.mutateBody(as: RootGeometry.self, invalidating: true) { body in
                body.$layoutDirection = viewInputs.environmentAttribute(keyPath: \.layoutDirection)
            }

            return makeRootView(rootView, viewInputs)
        }
        
        _rootGeometry.mutateBody(as: RootGeometry.self,
                                 invalidating: true) { body in
            body.$childLayoutComputer = outputs.layout.attribute
        }
        
        if requestedOutputs.contains(.needHandleDisplayList),
           let contentList = outputs.displayList {
            data.rootSubgraph.apply {
                self.$rootDisplayList = Attribute(RootDisplayList(content: contentList))
            }
        }
        
        if requestedOutputs.contains(.needHandlePlatformItemList) {
            self.$rootPlatformItemList = outputs.platformItemList ?? .init(identifier: .nil)
        }

        if requestedOutputs.contains(.needHandleViewResponder) {
            self.$rootResponders = outputs.viewResponders ?? .init(identifier: .nil)
        }
        if requestedOutputs.contains(. platformGestureRecognizerList) {
            self.$gestureRecognizerList = outputs.gestureRecognizerList ?? .init(identifier: .nil)
        }
        if requestedOutputs.contains(.needHandleAccessibilityNodes) {
            $rootAccessibilityNodes = outputs.accessibilityNodes ?? Attribute(identifier: .nil)
        }
        $rootLayoutComputer = outputs.layout.attribute
        setHostPreferenceValues(outputs.hostPreferences)
        makePreferenceOutlets(outputs: outputs)
    }
    
    internal func setRootView<RootViewType: View>(_ view: RootViewType) {
#if DEBUG || DANCE_UI_INHOUSE
        Signpost.viewGraph.traceInterval("setRootView: hostingState: %s; %s", [graphDelegate?.hostingState() ?? "empty", graphDelegate?.hostingType() ?? "empty"]) {
            _setRootView(view)
        }
#else
        _setRootView(view)
#endif
        
    }
    
    private func _setRootView<RootViewType: View>(_ view: RootViewType) {
#if FEAT_MONITOR
        // Check the rootView's valueState to end the previous root view
        // lifetime.
        if self.rootView.valueState.contains(.hasValue) {
            auditor?.traceRootViewComputationEnd()
            auditor?.enqueueCommit(on: .rootViewLifetimeDidEnd, category: auditingCategory)
        }
        defer {
            auditor?.traceRootViewComputationBegin()
        }
#endif
        @Attribute(identifier: self.rootView)
        var rootView: RootViewType
        
        rootView = view
    }

    @inlinable
    internal func updateOutput(at time: Time) {
        beginNextUpdate(at: time)
        updateOutputs()
    }
    
    private func updateObservedSizeThatFits() -> Bool {
        guard let observer = sizeThatFitsObserver else {
            return false
        }
        
        let oldSizeThatFit = cachedSizeThatFits
        
        let fittingSize = sizeThatFits(observer.proposal)
        
        cachedSizeThatFits = fittingSize
        
        guard oldSizeThatFit != .invalidValue else {
            return false
        }
        
        return fittingSize != oldSizeThatFit
    }
    
    internal func resetSizeThatFitsObserver() {
        precondition(requestedOutputs.contains(.needHandleLayouts))
        
        cachedSizeThatFits = .invalidValue
    }
    
    internal func displayList() -> (DisplayList, DisplayList.Version) {
#if DEBUG || DANCE_UI_INHOUSE
        return Signpost.viewGraph.traceInterval("displayList: hostingState: %s; %s", [graphDelegate?.hostingState() ?? "empty", graphDelegate?.hostingType() ?? "empty"]) {
            guard let rootDisplayList = self.rootDisplayList else {
                return (.empty, .zero)
            }
            
            return rootDisplayList
        }
#else
        guard let rootDisplayList = rootDisplayList else {
            return (.empty, .zero)
        }
        
        return rootDisplayList
#endif
    }
    
    fileprivate func idealSize() -> CGSize {
        sizeThatFits(.unspecified)
    }

#if DEBUG
    internal func testableIdealSize() -> CGSize {
        idealSize()
    }
#endif
    
    internal func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        let safeAreaInsets = self.safeAreaInsets.insets
        
        let insetWidth = size.width.map { width in
            max(width - (safeAreaInsets.leading + safeAreaInsets.trailing), 0)
        }
        
        let insetHeight = size.height.map { height in
            max(height - (safeAreaInsets.top + safeAreaInsets.bottom), 0)
        }
        
        let fitSize: CGSize
        
        if let layoutComputer = layoutComputer {
            let insetSize = _ProposedSize(width: insetWidth, height: insetHeight)
            fitSize = layoutComputer.engine.sizeThatFits(insetSize)
        } else {
            let width = insetWidth ?? 10
            let height = insetHeight ?? 10
            fitSize = CGSize(width: width, height: height)
        }
        
        return fitSize.outset(by: safeAreaInsets)
    }
    
#if DEBUG
    internal func testableSizeThatFits(_ size: _ProposedSize) -> CGSize {
        sizeThatFits(size)
    }
#endif
    
    internal func platformItemList() -> PlatformItemList {
        instantiateIfNeeded()
        disabledOutputs.remove(.needHandlePlatformItemList)
        return rootPlatformItemList ?? emptyPlatformItemList
    }

    internal func rootViewBaseLine(at size: CGSize) -> (CGFloat?, CGFloat?) {
        instantiateIfNeeded()
        
        guard let rootLayoutComputer = rootLayoutComputer else {
            return (nil, nil)
        }
        
        let edgeInsets = safeAreaInsets.insets
        let insetSize = size.inset(by: edgeInsets)
        
        let dimension = ViewDimensions(guideComputer: rootLayoutComputer, size: ViewSize(value: insetSize, _proposal: insetSize))
        
        let firstAlignment = dimension[explicit: VerticalAlignment.firstTextBaseline.key]
        let lastAlignment = dimension[explicit: VerticalAlignment.lastTextBaseline.key]
        
        let firstBaselineOffset = firstAlignment.map { $0 + edgeInsets.top }
        let lastBaselineOffset = lastAlignment.map { $0 + edgeInsets.top }
        
        return (firstBaselineOffset, lastBaselineOffset)
    }
    
    internal func sendEvents(_ events: [EventID: EventType],
                             rootNode: ResponderNode,
                             at time: Time) -> EventOutputs {
#if DEBUG
        _danceuiPrecondition(!frozen)
#endif
        return withTransaction {
            
            if gestureTime != time {
                gestureTime = time
                updateSeed += 1
                nextUpdate.gestures = .distantFuture
            }
            
            gestureEvents = events
            
            if $rootPhase == nil {
                let eventSubgraph = DGSubgraphCreate(graph)
                self.eventSubgraph = eventSubgraph
                
                var graphInputs = _GraphInputs(deepCopy: self.graphInputs)
                graphInputs.time = $gestureTime
                
                let gestureOutputs = eventSubgraph.apply { () -> _GestureOutputs<Void> in
                    let viewInputs = _ViewInputs(
                        base: graphInputs,
                        preferences: PreferencesInputs(hostKeys: data.$hostPreferenceKeys),
                        transform: $rootTransform,
                        position: $position,
                        containerPosition: $zeroPoint,
                        size: $dimensions,
                        safeAreaInsets: OptionalAttribute()
                    )
                    var gestureInputs = _GestureInputs(
                        viewInputs: viewInputs,
                        viewSubgraph: self.data.rootSubgraph,
                        preferences: PreferencesInputs(hostKeys: data.$hostPreferenceKeys),
                        events: $gestureEvents,
                        resetSeed: $gestureResetSeed,
                        inheritedPhase: $inheritedPhase,
                        platformInputs: PlatformGestureInputs()
                    )
                        .setRequiresGestureRecognitionWitness(true)
                        .setRequiresPlatformGestureRecognizerList(true)
                        .setRequiresActiveGestureRecognizerObservers(true)
#if DEBUG
                    // gestureInputs.includeDebugOutput = true
#endif
                    if DanceUIFeature.gestureContainer.isEnable {
                        gestureInputs.skipCombiners = false
                        gestureInputs.gestureGraph = false
                    }
                    let attr = Attribute<Void>(identifier: $zeroPoint.identifier)
                    return rootNode.makeGesture(gesture: _GraphValue(attr), inputs: gestureInputs)
                }
                $rootPhase = gestureOutputs.phase
                $rootGestureRecognitionWitness = gestureOutputs.gestureRecognitionWitness
            }

            var result = EventOutputs()
            var currentEvents = events
            var shouldContinue = true
            repeat {
                let currentContinuations = dequeueContinuations()
                currentContinuations.forEach { body in
                    body()
                }
                eventSubgraph!.update(.active)
                shouldContinue = true
                if continuations.isEmpty {
                    shouldContinue = false
                    result.gesturePhase = rootPhase!
                    if let rootGestureRecognitionWitness {
                        result.gestureRecognitionWitness = rootGestureRecognitionWitness
                    }
                } else {
                    if !currentEvents.isEmpty {
                        gestureEvents = [:]
                        currentEvents = [:]
                    }
                }
                
            } while shouldContinue
            
            return result
        }
    }
    
    internal func resetEvents() {
        guard let eventSubgraph = eventSubgraph else {
            return
        }
        
        self.eventSubgraph = nil
        $rootPhase = nil
        $rootGestureRecognitionWitness = nil
        
        eventSubgraph.willInvalidate(isInserted: true)
        eventSubgraph.invalidate()
        guard let responderNode else {
            return
        }
        responderNode.resetGesture()
    }
    
    @discardableResult
    internal func setSafeAreaInsets(_ elements: [SafeAreaInsets.Element]) -> Bool {
        let modifier = _SafeAreaInsetsModifier(elements: elements, nextInsets: nil)
        let changed = _safeAreaInsets.setValue(modifier)
        
        guard changed else {
            return false
        }
        
        _notifyDelegateGraphDidChange()
        return true
    }

    internal override func timeDidChange() {
        nextUpdate.views = .distantFuture
    }
    
    internal func setProposedSize(_ size: CGSize) {
        let changed = $proposedSize.setValue(ViewSize(value: size, _proposal: size))
        
        guard changed else {
            return
        }
        
        _notifyDelegateGraphDidChange()
    }
    
    internal override func isHiddenForReuseDidChange() {
        guard let preferenceBridge = preferenceBridge else {
            return
        }
        
        if data.isHiddenForReuse {
            for (key, value) in bridgedPreferences {
                preferenceBridge.removeValue(value, for: key)
            }
            preferenceBridge.removeHostValues(for: data.$hostPreferenceKeys, isInvalidating: false)
        } else {
            for (key, value) in bridgedPreferences {
                preferenceBridge.addValue(value, for: key)
            }
            if let hostPreferenceValues = hostPreferenceValues.attribute {
                preferenceBridge.addHostValues(hostPreferenceValues, for: data.$hostPreferenceKeys)
            }
        }
    }
    
    internal func setFocusedValues(focusedValues: FocusedValues) {
        let changed = _focusedValues.setValue(focusedValues)
        guard changed else {
            return
        }
        
        _notifyDelegateGraphDidChange()
    }
    
    internal func setFocusStore(_ focusStore: FocusStore) {
        let changed = $focusStore.setValue(focusStore)
        
        guard changed else {
            return
        }
        
        _notifyDelegateGraphDidChange()
    }
    
    internal func setFocusedItem(_ focusedItem: FocusItem?) {
        let changed = $focusedItem.setValue(focusedItem)
        
        guard changed else {
            return
        }
        
        _notifyDelegateGraphDidChange()
    }
    
    internal override func uninstantiateOutputs() {
        removePreferenceOutlets(isInvalidating: false)
        _rootGeometry.mutateBody(as: RootGeometry.self, invalidating: true) { body in
            body.$layoutDirection = nil
            body.$childLayoutComputer = nil
        }
        $rootPlatformItemList = nil
        $rootResponders = nil
        $rootAccessibilityNodes = nil
        $rootLayoutComputer = nil
        $rootDisplayList = nil
        setHostPreferenceValues(nil)
    }
    
    fileprivate func removePreferenceOutlets(isInvalidating: Bool) {
        guard let preferenceBridge = preferenceBridge else {
            return
        }
        
        bridgedPreferences.forEach { (key: AnyPreferenceKey.Type, attr: DGAttribute) in
            preferenceBridge.removeValue(attr, for: key)
        }
        
        bridgedPreferences = []
        preferenceBridge.removeHostValues(for: data.$hostPreferenceKeys, isInvalidating: isInvalidating)
        preferenceBridge.removeChild(viewGraph: self)
    }
    
    private func requestedOutputsDidChange(from: Outputs) {
        if requestedOutputs != from {
            uninstantiate(immediately: false)
        }
    }
    
    private func _notifyDelegateGraphDidChange() {
        guard !frozen else {
            return
        }
        self.delegate?.graphDidChange()
    }

    // MARK: Scheduling Next Update

    @inlinable
    internal func scheduleNextViewUpdate(byTime time: Time) {
        nextUpdate.views.time = min(time, nextUpdate.views.time)
    }

    @inlinable
    internal func scheduleNextGestureUpdate(byTime time: Time) {
        nextUpdate.gestures.time = min(time, nextUpdate.gestures.time)
    }
    
    // MARK: PreferenceBridge
    
#if DEBUG
    /// test only
    internal static var inconsistentPreferenceBridgeWarningCount: Int = 0
#endif
    
    private func setPreferenceBridge(to newBridge: PreferenceBridge?, isInvalidating: Bool) {
        guard newBridge !== preferenceBridge else {
            return
        }
        
        removePreferenceOutlets(isInvalidating: isInvalidating)
        _preferenceBridge = nil
        if isInstantiated {
            if UIHostingViewInconsistentPreferenceBridgeCheckKey.availability.isAvailable &&
                isUnlikelyToBeUninstantiated {
                print("[CRITICAL] ViewGraph is going to be uninstantiated due to the preference bridge was changed unexpectedly.")
                print("[CRITICAL] You can set environment variable \(UIHostingViewInconsistentPreferenceBridgeCheckKey.raw) to true or 1 and add a symbolic breakpoint DanceUIUIHostingViewInconsistentPreferenceBridgeWarning to find the first place cause this problem.")
#if DEBUG
                // test only
                ViewGraph.inconsistentPreferenceBridgeWarningCount += 1
#endif
            }
            uninstantiate(immediately: isInvalidating)
        }
        _preferenceBridge = newBridge
        newBridge?.addChild(viewGraph: self)
        updateRemovedState()
    }
    
    // MARK: Preferences
    
    internal func makePreferenceOutlets(outputs: _ViewOutputs) {
        guard let preferenceBridge = preferenceBridge else {
            return
        }
        
        for requestedPreference in preferenceBridge.requestedPreferences {
            if let identifier = outputs.preferences[requestedPreference] {
                preferenceBridge.addValue(identifier, for: requestedPreference)
                bridgedPreferences.append((requestedPreference, identifier))
            }
        }
        
        if let preferenceList = outputs.hostPreferences {
            preferenceBridge.addHostValues(preferenceList, for: data.$hostPreferenceKeys)
        }
    }
    
    // MARK: Outputs
    
    private func updateRequestedOutputs() -> Outputs {
        instantiateIfNeeded()
        
        var outputs = Outputs()
        
        if !disabledOutputs.contains(.needHandlePlatformItemList),
           $rootPlatformItemList?.changedValue().changed == true {
            disabledOutputs.insert(.needHandlePlatformItemList)
            outputs.insert(.needHandlePlatformItemList)
        }

        if !disabledOutputs.contains(.needHandleAccessibilityNodes),
            $rootAccessibilityNodes?.changedValue().changed == true {
            disabledOutputs.insert(.needHandleAccessibilityNodes)
            outputs.insert(.needHandleAccessibilityNodes)
        }
        
        return outputs
    }
    
    // MARK: NextUpdate
    
    internal struct NextUpdate {
        
        internal var time: Time
        
        private var _interval : Double
        
        /// The high-frame reasons send to `CADisplayLink`.
        internal var reasons : Set<UInt32>

        internal var interval: Double {
            return _interval.isInfinite || _interval.isNaN ? 0 : _interval
        }
        
        @inlinable
        internal static func time(_ time: Time) -> NextUpdate {
            NextUpdate(time: time, _interval: .infinity, reasons: [])
        }
        
        @inlinable
        internal static var distantFuture: NextUpdate {
            .time(Time.distantFuture)
        }
        
        internal mutating func interval(_ seconds: Double, reason: UInt32?) {
            let oldInterval = _interval
            // Threshold for frame rate interval comparison (approximately 0.017 seconds)
            let threshold = Double(bitPattern: 0x3f91_1111_1111_1111)
            if seconds != 0 {
                _interval = min(seconds, oldInterval)
            } else if oldInterval > threshold {
                _interval = .infinity
            }
            if let reason {
                reasons.insert(reason)
            }
        }
    }
    
    fileprivate func accessibilityNodeList() -> AccessibilityNodeList {
        instantiateIfNeeded()
        disabledOutputs.remove(.needHandleAccessibilityNodes)
        return rootAccessibilityNodes ?? .empty
    }
    
#if DEBUG
    internal func testableAccessibilityNodeList() -> AccessibilityNodeList {
        accessibilityNodeList()
    }
#endif

    @inlinable
    internal func invalidateAllValues() {
        self.data.graph?.invalidateAllValues()
    }
    
    internal func updateOutputs() {
#if DEBUG || DANCE_UI_INHOUSE
        Signpost.viewGraph.traceInterval("updateOutputs: hostingState: %s; %s", [graphDelegate?.hostingState() ?? "empty", graphDelegate?.hostingType() ?? "empty"]) {
            _updateOutputs()
        }
#else
        _updateOutputs()
#endif
    }
    
    private func _updateOutputs() {
#if DEBUG
        _danceuiPrecondition(!frozen)
#endif
        
        let oldCachedSizeThatFits = cachedSizeThatFits
        
        instantiateIfNeeded()
        
        var convergenceCount = 0
        
        var prefChanged: Bool = false
        var sizeThatFitsChanged: Bool = false
        var updatedRequestedOutputs: Outputs = Outputs()
        
        repeat {
            convergenceCount &+= 1
            
            withTransaction {
                runTransactions()
            }
            
            prefChanged = prefChanged || updatePreferences()
            sizeThatFitsChanged = sizeThatFitsChanged || updateObservedSizeThatFits()
            updatedRequestedOutputs.formUnion(updateRequestedOutputs())
            
            if !self.data.globalSubgraph.isDirty(1) {
                break
            }
            
        } while convergenceCount < Self.maxContinuationConvergenceCount
        
        if prefChanged || sizeThatFitsChanged || !updatedRequestedOutputs.isEmpty || !needsFocusUpdate {
            Update.syncMain {
                let delegate = self.delegate

                if prefChanged {
                    delegate?.preferencesDidChange()
                }
                if sizeThatFitsChanged {
                    self.sizeThatFitsObserver?.callback(oldCachedSizeThatFits, self.cachedSizeThatFits)
                }
                if !updatedRequestedOutputs.isEmpty {
                    delegate?.outputsDidChange(outputs: updatedRequestedOutputs)
                }

                if self.needsFocusUpdate {
                    self.needsFocusUpdate = false
                    delegate?.focusDidChange()
                }
            }
            
            mainUpdates &-= 1
        }
    }
    
    private var layoutComputer: LayoutComputer? {
        precondition(requestedOutputs.contains(.needHandleLayouts))

        instantiateIfNeeded()

        return rootLayoutComputer
    }

    private func beginNextUpdate(at time: Time) {
#if DEBUG
        _danceuiPrecondition(!frozen)
#endif
        setTime(time)
        updateSeed += 1
        mainUpdates = graph.mainUpdates
    }

    fileprivate func explicitAlignment(of alignment: HorizontalAlignment, at size: CGSize) -> CGFloat? {
        guard let layoutComputer = layoutComputer else {
            return nil
        }
        let insets = safeAreaInsets.insets
        let insetSize = size.inset(by: insets)
        let viewSize = ViewSize(value: insetSize, _proposal: insetSize)
        guard let alignment = layoutComputer.engine.explicitAlignment(alignment.key, at: viewSize) else {
            return nil
        }
        return insets.leading + alignment
    }

#if DEBUG
    internal func testableExplicitAlignment(of alignment: HorizontalAlignment, at size: CGSize) -> CGFloat? {
        explicitAlignment(of: alignment, at: size)
    }
#endif

    fileprivate func explicitAlignment(of alignment: VerticalAlignment, at size: CGSize) -> CGFloat? {
        guard let layoutComputer = layoutComputer else {
            return nil
        }
        let insets = safeAreaInsets.insets
        let insetSize = size.inset(by: insets)
        let viewSize = ViewSize(value: insetSize, _proposal: insetSize)
        guard let alignment = layoutComputer.engine.explicitAlignment(alignment.key, at: viewSize) else {
            return nil
        }
        return insets.top + alignment
    }

#if DEBUG
    internal func testableExplicitAlignment(of alignment: VerticalAlignment, at size: CGSize) -> CGFloat? {
        explicitAlignment(of: alignment, at: size)
    }
#endif

    internal func updateOutputsAsync(at time: Time) -> (list: DisplayList, version: DisplayList.Version)? {
#if DEBUG
        _danceuiPrecondition(!frozen)
#endif
        func check<A>(_ attribute: Attribute<A>?) -> Bool {
            guard let attribute = attribute else {
                return true
            }
            
            let valueState = attribute.valueState
            
            if valueState.contains(.isDirty) {
                return !valueState.contains(.requiresMainThreadFromOutput)
            } else {
                return true
            }
        }
        
        let disabledOutputs = self.disabledOutputs
        
        guard check($rootDisplayList) else {
            return nil
        }
        
        guard check(hostPreferenceValues.attribute) else {
            return nil
        }
        
        if self.sizeThatFitsObserver != nil {
            guard check($rootLayoutComputer) else {
                return nil
            }
        }
        
        if !disabledOutputs.contains(.needHandlePlatformItemList) {
            guard check($rootPlatformItemList) else {
                return nil
            }
        }
        
        var result: (list: DisplayList, version: DisplayList.Version)?

        graph.withMainThreadHandler { (body: () -> Void) -> Void in
            Update.syncMain(body)
        } do: {
            result = self.displayList()
        }
        
        self.disabledOutputs.remove(.needHandleLayouts)
        self.disabledOutputs.formUnion(disabledOutputs.intersection(.needHandleAccessibilityNodes))
        
        return result
    }

    internal var updateRequiredMainThread: Bool {
        graph.mainUpdates != mainUpdates
    }

    @Attribute
    internal var emptyGestureRecognitionWitness: GestureRecognitionWitness?

    @OptionalAttribute
    internal var rootGestureRecognitionWitness: GestureRecognitionWitness?

    @OptionalAttribute
    internal var gestureRecognizerList: PlatformGestureRecognizerList?

    /// Empty singleton for gesture recognizer list.
    @Attribute
    internal var emptyGestureRecognizerList: PlatformGestureRecognizerList?

    /// The storage of `gestureRecognizerObservers`. Inherited from view
    /// hierarchy and overriden by
    /// `_UIHostingView.localGestureRecognizerObservers`.
    @Attribute
    internal var gestureObservers: GestureObservers

    /// Update the ViewGraph root responders to update the entire view tree.
    /// View responders rely on view geometry data from the view tree to
    /// compute hit-test result. This can enforce the UIScrollView-based views
    /// (both ScrollView and UIViewRepresentable-based) to apply changes at the
    /// UIKit event phase and prevent from overwrites of UIScrollView
    /// scrolling-animation-driven bounds settings.
    internal func updateResponders() {
        DGGraphRef.withoutUpdate {
            let _ = self.responderNode
        }
    }

}

/// Put `ViewRendererHost`'s extension here and keep `ViewGraph`'s APIs fiileprivate to
/// prevent from abusing `ViewGraph`'s APIs.
///
@available(iOS 13.0, *)
extension ViewRendererHost {
    
    internal func sizeThatFits(_ proposedSize: _ProposedSize) -> CGSize {
        updateViewGraph { viewGraph in
            viewGraph.sizeThatFits(proposedSize)
        }
    }
    
    internal func explicitAlignment(of alignment: VerticalAlignment, at size: CGSize) -> CGFloat? {
        updateViewGraph { viewGraph in
            viewGraph.explicitAlignment(of: alignment, at: size)
        }
    }

    internal func explicitAlignment(of alignment: HorizontalAlignment, at size: CGSize) -> CGFloat? {
        updateViewGraph { viewGraph in
            viewGraph.explicitAlignment(of: alignment, at: size)
        }
    }

    internal var responderNode: ResponderNode? {
        updateViewGraph { viewGraph in
            viewGraph.responderNode
        }
    }

    internal var nextGestureUpdateTime: Time {
        updateViewGraph { viewGraph in
            viewGraph.nextUpdate.gestures.time
        }
    }

    internal func setInheritedPhase(_ phase: _GestureInputs.InheritedPhase) {
        viewGraph.inheritedPhase = phase
    }

    internal func gestureCategory() -> GestureCategory? {
        return nil
    }
    
    internal var accessibilityNodes: [AccessibilityNode] {
        updateViewGraph { viewGraph in
            viewGraph.accessibilityNodeList().nodes
        }
    }
    
    internal func idealSize() -> CGSize {
        updateViewGraph { viewGraph in
            viewGraph.idealSize()
        }
    }
    
}
