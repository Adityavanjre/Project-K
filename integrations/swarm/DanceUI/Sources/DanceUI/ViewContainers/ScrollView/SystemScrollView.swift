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
internal struct SystemScrollView<Content: View>: PrimitiveView, UnaryView {
    
    internal var configuration: ScrollViewConfiguration
    
    internal var content: Content
    
    internal var id: AnyHashable?
    
    internal typealias Body = Never
    
    internal static func _makeView(view: _GraphValue<SystemScrollView<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        let state = SystemScrollViewState(
            contentOffset: .zero,
            systemContentInsets: .zero,
            systemTranslation: .zero,
            contentOffsetMode: .adjustment(required: true),
            updateSeed: 0
        )
        let stateAttribute = Attribute(value: state)
        let configuration = SystemScrollViewAdjustedConfiguration(
            configuration: view.value.configuration,
            isEnabled: inputs.environmentAttribute(keyPath: \.isEnabled),
            isScrollEnabled: inputs.environmentAttribute(keyPath: \.isScrollEnabled),
            verticalIndicator: inputs.environmentAttribute(keyPath: \.verticalScrollIndicatorConfiguration),
            horizontalIndicator: inputs.environmentAttribute(keyPath: \.horizontalScrollIndicatorConfiguration),
            verticalBounceBehavior: inputs.environmentAttribute(keyPath: \.verticalScrollBounceBehavior),
            horizontalBounceBehavior: inputs.environmentAttribute(keyPath: \.horizontalScrollBounceBehavior),
            pagingEnabled: inputs.environmentAttribute(keyPath: \.scrollPagingEnabled)
        ).makeAttribute()
        let layoutDirection = inputs.environmentAttribute(keyPath: \.layoutDirection)
        let pixelLength = inputs.environmentAttribute(keyPath: \.pixelLength)
        let animatedPosition = inputs.animatedPosition
        let animatedSize = inputs.animatedSize
        let systemContentInsets = _GraphValue(stateAttribute)[{.of(&$0.systemContentInsets)}].value

        let contentFrame = SystemScrollViewContentFrame(
            size: animatedSize,
            configuration: configuration,
            systemContentInsets: systemContentInsets,
            pixelLength: pixelLength,
            contentComputer: OptionalAttribute(nil)
        )
        let contentFrameAttribute = Attribute(contentFrame)
        
        var contentFrameGraphValue = _GraphValue(contentFrameAttribute)
        
        ViewFrame._makeAnimatable(value: &contentFrameGraphValue, inputs: inputs.base)
        
        let adjustedState = SystemScrollViewAdjustedState(
            size: animatedSize,
            configuration: configuration,
            state: stateAttribute,
            contentFrame: contentFrameGraphValue.value,
            pixelLength: pixelLength,
            oldFrame: .zero,
            oldSize: .zero
        )
        
        let adjustedStateAttribute = Attribute(adjustedState)
        
        let safeAreaInsets = ResolvedSafeAreaInsets(
            regions: .all,
            environment: inputs.environment,
            size: inputs.size,
            position: inputs.position,
            transform: inputs.transform,
            safeAreaInsets: inputs.safeAreaInsets
        )
        
        let safeAreaAttribute = Attribute(safeAreaInsets)
        
        let scrollableAttribute = Attribute(type: Scrollable.self)
        
        var newInputs = inputs // input4
        newInputs.enableLayouts = true
        newInputs.size = contentFrameAttribute[\.size]
        let zeroPoint = (ViewGraph.currentHost as! ViewGraph).$zeroPoint
        newInputs.containerPosition = zeroPoint
        newInputs.position = zeroPoint

        let disabledGestureSimultaneouslyReceive = newInputs.consume(DisabledGestureSimultaneouslyReceiveInput.self)?.value
        
        let newOrigin = contentFrameAttribute[\.origin]
        
        let transform = SystemScrollViewTransform(
            configuration: configuration,
            contentOrigin: newOrigin,
            position: animatedPosition,
            size: animatedSize,
            transform: newInputs.transform,
            state: adjustedStateAttribute,
            safeAreaInsets: safeAreaAttribute
        )
        
        newInputs.transform = Attribute(transform)
        newInputs.safeAreaInsets = OptionalAttribute(nil)
        
        newInputs.scrollableView = scrollableAttribute
        newInputs.scrollableContainerSize = .init(animatedSize)
        

        newInputs.hitTestInsets = nil

        
        var outputs = Content.makeDebuggableView(value: view[{.of(&$0.content)}], inputs: newInputs)
        
        let scrollablePreference = outputs.scrollable
        
        var scrollable = TestableSystemScrollViewScrollable(
            state: stateAttribute,
            adjustedState: adjustedStateAttribute,
            size: animatedSize,
            contentFrame: contentFrameGraphValue.value,
            children: OptionalAttribute(scrollablePreference),
            lastUpdateSeed: 0,
            id: view[{.of(&$0.id)}].value
        )
        
        _ = scrollableAttribute.setValue(scrollable as Scrollable)
        
        if inputs.preferences.requiresScrollable {
            outputs.scrollable = Attribute(value: [scrollableAttribute.value])
        }
        
        if outputs.layout.attribute != nil {
            contentFrameAttribute.mutateBody(as: SystemScrollViewContentFrame.self, invalidating: true) { body in
                body.$contentComputer = outputs.layout.attribute
            }
        }
        let contentComputer = outputs.layout
        outputs.setLayout(inputs) {
            Attribute(SystemScrollViewLayoutComputer(
                configuration: configuration,
                systemContentInsets: systemContentInsets,
                contentComputer: contentComputer
            ))
        }
        
        let requiresViewResponders = inputs.preferences.requiresViewResponders
        let requiresDisplayList = inputs.preferences.requiresDisplayList
        
        
        var requiresViewResponderRelatedOutputs = requiresViewResponders || requiresDisplayList
        
        let requiresPlatformGestureRecognizerList = inputs.preferences.requiresPlatformGestureRecognizerList
        requiresViewResponderRelatedOutputs = requiresViewResponderRelatedOutputs || requiresPlatformGestureRecognizerList
        
        if requiresViewResponderRelatedOutputs {
            let hostingScrollView = HostingScrollView(
                viewType: Self.self,
                state: WeakAttribute(stateAttribute),
                disabledGestureSimultaneouslyReceive: disabledGestureSimultaneouslyReceive
            )

            let contentList: Attribute<DisplayList>? = outputs.displayList

            scrollable.scrollView = hostingScrollView
            _ = scrollableAttribute.setValue(scrollable as Scrollable)
            if inputs.preferences.requiresScrollable {
                outputs.scrollable = Attribute(value: [scrollableAttribute.value])
            }
            let updater = UpdatedHostingScrollView(
                scrollView: hostingScrollView,
                configuration: configuration,
                contentFrame: contentFrameGraphValue.value,
                safeAreaInsets: safeAreaAttribute,
                contentInsets: inputs.environmentAttribute(keyPath: \.scrollContentInsets),
                layoutDirection: layoutDirection,
                adjustedState: adjustedStateAttribute,
                lastUpdateSeed: 0x0
            )
            
            let updaterAttribute = Attribute(updater)

            if requiresViewResponders {
                let layoutResponder = DefaultLayoutViewResponder(inputs: newInputs)
                let scrollViewResponder = SystemScrollViewResponder(
                    scrollView: updaterAttribute,
                    position: animatedPosition,
                    size: animatedSize,
                    transform: inputs.transform,
                    hitTestInsets: inputs.hitTestInsets,
                    children: outputs.viewResponders,
                    responder: makeAnyHostingScrollViewResponder(layoutResponder: layoutResponder),
                    layoutResponder: layoutResponder
                )
                outputs.viewResponders = Attribute(scrollViewResponder)
            }

            if requiresDisplayList {

                let displayList = SystemScrollViewDisplayList(
                    scrollView: updaterAttribute,
                    configuration: configuration,
                    position: animatedPosition,
                    size: animatedSize,
                    containerPosition: inputs.containerPosition,
                    safeAreaInsets: safeAreaAttribute,
                    pixelLength: pixelLength,
                    contentList: contentList
                )

                outputs.displayList = Attribute(displayList)
            }

            if newInputs.preferences.requiresAccessibilityNodes {
                let accessibilityModifier = SystemScrollViewAccessibilityModifier(scrollView: hostingScrollView)
                outputs.accessibilityNodes = SystemScrollViewAccessibilityModifier.makeAccessibilityTransform(
                   modifier: _GraphValue(Attribute(value: accessibilityModifier)),
                   inputs: inputs,
                   outputs: outputs
               )
            }

        }
        
        return outputs
    }
    
}

@available(iOS 13.0, *)
private struct SystemScrollViewAdjustedState: StatefulRule {
    
    fileprivate typealias Value = SystemScrollViewState
    
    @Attribute
    fileprivate var size: ViewSize
    
    @Attribute
    fileprivate var configuration: ScrollViewConfiguration
    
    @Attribute
    fileprivate var state: SystemScrollViewState
    
    @Attribute
    fileprivate var contentFrame: ViewFrame
    
    @Attribute
    fileprivate var pixelLength: CGFloat
    
    fileprivate var oldFrame: CGRect
    
    fileprivate var oldSize: CGSize
    
    fileprivate mutating func updateValue() {
        
        let state = self.state
        let contentFrame = self.contentFrame
        let frame = CGRect(origin: contentFrame.origin.value, size: contentFrame.size.value)
        let size = self.size.value
        
        if size == oldSize && frame == oldFrame {
            value = state
            return
        }
        
        let configuration = self.configuration
        
        let axes = configuration.axes
        
        var offsetX = state.contentOffset.x
        let pixelLength = self.pixelLength
        
        if (axes == .all || !axes.contains(.horizontal)) &&
            frame.size.width > size.width &&
            frame.size.width != 0 &&
            oldFrame.size.width != 0 {
            
            let oldMidX = (oldSize.width * 0.5 + oldFrame.origin.x + offsetX) / oldFrame.size.width * frame.size.width
            let newMidX = frame.origin.x + size.width * 0.5
            offsetX = pixelLength * 0.5 + (oldMidX - newMidX)
            
            offsetX.round(.down, toMultipleOf: pixelLength)
        }
        
        var offsetY = state.contentOffset.y
        if (axes == .all || !axes.contains(.vertical)) &&
            frame.size.height > size.height &&
            frame.size.height != 0 &&
            oldFrame.size.height != 0 {
            
            let oldMidY = (oldSize.height * 0.5 + oldFrame.origin.y + offsetY) / oldFrame.size.height * frame.size.height
            let newMidY = size.height * 0.5 + frame.origin.y
            offsetY = pixelLength * 0.5 + (oldMidY - newMidY)
            
            offsetY.round(.down, toMultipleOf: pixelLength)
        }
        
        self.oldFrame = frame
        self.oldSize = size
        
        let newContentOffset = CGPoint(x: offsetX, y: offsetY)
        
        let newState = SystemScrollViewState(
            contentOffset: newContentOffset,
            systemContentInsets: state.systemContentInsets,
            systemTranslation: state.systemTranslation,
            contentOffsetMode: newContentOffset.equalTo(state.contentOffset) ? state.contentOffsetMode : .adjustment(required: false),
            updateSeed: state.updateSeed
        )
        
        value = newState
    }
    
}

@available(iOS 13.0, *)
private struct SystemScrollViewContentFrame: StatefulRule {
    
    internal typealias Value = ViewFrame
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var configuration: ScrollViewConfiguration
    
    @Attribute
    internal var systemContentInsets: EdgeInsets
    
    @Attribute
    internal var pixelLength: CGFloat
    
    @OptionalAttribute
    internal var contentComputer: LayoutComputer?
    
    internal mutating func updateValue() {
        
        let insetSize = size.value.inset(by: systemContentInsets)
        
        var frame = ScrollViewUtilities.contentFrame(in: insetSize, contentComputer: contentComputer, axes: configuration.axes)
        
        var rect = CGRect(origin: frame.origin.value, size: frame.size.value)
        rect.roundCoordinatesToNearestOrUp(toMultipleOf: pixelLength)
        frame.origin.value = rect.origin
        frame.size.value = rect.size
        value = frame
    }
    
}

@available(iOS 13.0, *)
private struct SystemScrollViewLayoutComputer: StatefulRule {
    
    internal typealias Value = LayoutComputer
    
    @Attribute
    internal var configuration: ScrollViewConfiguration
    
    @Attribute
    internal var systemContentInsets: EdgeInsets
    
    @OptionalAttribute
    internal var contentComputer: LayoutComputer?
    
    internal mutating func updateValue() {
        
        let engine = Engine(
            axes: configuration.axes,
            contentInsets: systemContentInsets,
            contentComputer: contentComputer,
            cache: .init()
        )
        
        value = LayoutComputer(seed: 0x0, engine: engine)
    }
    
    private struct Engine: LayoutEngine { // $b03d68
        
        internal let axes: Axis.Set
        
        internal let contentInsets: EdgeInsets
        
        internal let contentComputer: LayoutComputer?
        
        internal var cache: Cache3<_ProposedSize, CGSize>
        
        internal mutating func sizeThatFits(_ proposed: _ProposedSize) -> CGSize {
            if let cachedSize = cache[proposed] {
                return cachedSize
            }
            
            var newProposed = proposed
            if let width = newProposed.width {
                newProposed.width = width >= contentInsets.leading + contentInsets.trailing ? width : 0
            }
            
            if let height = newProposed.height {
                newProposed.height = height >= contentInsets.top + contentInsets.bottom ? height : 0
            }
            
            let contentSize = ScrollViewUtilities.sizeThatFits(in: newProposed,
                                                               contentComputer: contentComputer,
                                                               axes: axes)
            
            let size = contentSize ?? CGSize(width: newProposed.width ?? 10.0,
                                             height: newProposed.height ?? 10.0)
            
            
            let result = CGSize(width: contentInsets.leading + contentInsets.trailing + size.width,
                                height: contentInsets.top + contentInsets.bottom + size.height)
            cache[newProposed] = result
            return result
        }
        
        internal func requiresSpacingProjection() -> Bool {
            contentComputer?.engine.requiresSpacingProjection() ?? false
        }
        
        internal func spacing() -> Spacing {
            .zeroText
        }
    }
}

@available(iOS 13.0, *)
internal struct SystemScrollViewDisplayList: Rule {
    
    internal typealias Value = DisplayList
    
    @Attribute
    internal var scrollView: HostingScrollView
    
    @Attribute
    internal var configuration: ScrollViewConfiguration
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var containerPosition: ViewOrigin
    
    @Attribute
    internal var safeAreaInsets: EdgeInsets
    
    @Attribute
    internal var pixelLength: CGFloat
    
    @OptionalAttribute
    internal var contentList: DisplayList?
    

    internal let identity: DisplayList.Identity
    
    internal init(
        scrollView: Attribute<HostingScrollView>,
        configuration: Attribute<ScrollViewConfiguration>,
        position: Attribute<ViewOrigin>,
        size: Attribute<ViewSize>,
        containerPosition: Attribute<ViewOrigin>,
        safeAreaInsets: Attribute<EdgeInsets>,
        pixelLength: Attribute<CGFloat>,
        contentList: Attribute<DisplayList>?)
    {
        self._scrollView = scrollView
        self._configuration = configuration
        self._position = position
        self._size = size
        self._containerPosition = containerPosition
        self._safeAreaInsets = safeAreaInsets
        self._pixelLength = pixelLength
        self._contentList = OptionalAttribute(contentList)
        self.identity = .make()
    }
    
    internal var value: DisplayList {
        
        let safeAreaInsets = self.safeAreaInsets
        
        let configuration = self.configuration
        
        let edgeInsets = safeAreaInsets.in(configuration.scrollableEdges)
        
        let position = self.position.value
        let containerPositionValue = containerPosition.value
        let size = self.size.value
        let sizeOutset = size.outset(by: edgeInsets)
        
        let pixelLength = self.pixelLength
        
        let point = CGPoint(x: position.x - containerPositionValue.x - edgeInsets.leading,
                            y: position.y - containerPositionValue.y - edgeInsets.top)
        
        var rect = CGRect(origin: point, size: sizeOutset)
        rect.roundCoordinatesToNearestOrUp(toMultipleOf: pixelLength)
        
        let scrollView = self.scrollView
        
        let contentList = self.contentList ?? .empty
        var displayItem = DisplayList.Item(
            frame: rect,
            version: .make(),
            value: .effect(.platformGroup(group: scrollView), contentList),
            identity: identity
        )
        
        displayItem.canonicalize()
        return DisplayList(item: displayItem)
    }
    
}

@available(iOS 13.0, *)
private struct SystemScrollViewResponder: StatefulRule {
    
    internal typealias Value = [ViewResponder]
    
    @Attribute
    internal var scrollView: HostingScrollView
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var transform: ViewTransform
    

    @OptionalAttribute
    internal var hitTestInsets: EdgeInsets??
    
    @OptionalAttribute
    internal var children: [ViewResponder]?
    

    internal let responder: AnyHostingScrollViewResponder
    

    internal let layoutResponder: DefaultLayoutViewResponder
    
    internal init(
        scrollView: Attribute<HostingScrollView>,
        position: Attribute<ViewOrigin>,
        size: Attribute<ViewSize>,
        transform: Attribute<ViewTransform>,
        hitTestInsets: Attribute<EdgeInsets?>?,
        children: Attribute<[ViewResponder]>?,
        responder: AnyHostingScrollViewResponder,
        layoutResponder: DefaultLayoutViewResponder
    ) {
        self._scrollView = scrollView
        self._position = position
        self._size = size
        self._transform = transform
        self._hitTestInsets = OptionalAttribute(hitTestInsets)
        self._children = OptionalAttribute(children)
        self.responder = responder
        self.layoutResponder = layoutResponder
    }
    
    internal mutating func updateValue() {
        
        if DanceUIFeature.gestureContainer.isEnable {
            responder.representedView = scrollView.host
            responder.hostView = scrollView.superview
        } else {
            responder.scrollView = scrollView
            responder.child = layoutResponder
        }
        scrollView.responder = responder
        
        responder.helper.update(
            data: (TrivialContentResponder(), true),
            size: $size.changedValue(),
            position: $position.changedValue(),
            hitTestInsets: $hitTestInsets?.changedValue(),
            transform: $transform.changedValue(),
            parent: responder
        )
        
        let viewResponders = children ?? []
        layoutResponder.children = viewResponders
        
        if !context.hasValue {
            value = [responder]
        }
    }
}

@available(iOS 13.0, *)
private struct SystemScrollViewTransform: Rule {
    
    internal typealias Value = ViewTransform
    
    @Attribute
    internal var configuration: ScrollViewConfiguration
    
    @Attribute
    internal var contentOrigin: ViewOrigin
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var transform: ViewTransform
    
    @Attribute
    internal var state: SystemScrollViewState
    
    @Attribute
    internal var safeAreaInsets: EdgeInsets
    
    internal var value: ViewTransform {
        
        let inset = state.systemContentInsets + safeAreaInsets.in(configuration.scrollableEdges)
        let size = self.size.value
        let visibleRect = CGRect(origin: .zero, size: size).outset(by: inset)
        
        let contentPosition = contentOrigin.value + position.value
        
        var newTransform = transform
        
        newTransform.appendViewOrigin(ViewOrigin(
            value: contentPosition
        ))
        
        newTransform.clearPositionAdjustment()
        
        newTransform.appendScrollLayout(_ScrollLayout(
            contentOffset: .zero,
            size: size,
            visibleRect: visibleRect
        ))
        
        let stateTranslation = CGSize(
            width: state.contentOffset.x + state.systemTranslation.width,
            height: state.contentOffset.y + state.systemTranslation.height
        )
        
        newTransform.appendTranslation(stateTranslation)
        
        newTransform.appendCoordinateSpace(name: AnyHashable(ScrollableContentSpace()))
        
        return newTransform
    }
    
}

@available(iOS 13.0, *)
private struct UpdatedHostingScrollView: StatefulRule {
    
    fileprivate typealias Value = HostingScrollView
    
    private let scrollView: HostingScrollView
    

    @Attribute
    private var configuration: ScrollViewConfiguration
    

    @Attribute
    private var contentFrame: ViewFrame
    

    @Attribute
    private var safeAreaInsets: EdgeInsets
    

    @Attribute
    private var contentInsets: EdgeInsets
    

    @Attribute
    private var layoutDirection: LayoutDirection
    

    @Attribute
    private var adjustedState: SystemScrollViewState
    
    private var lastUpdateSeed: UInt32
    
    fileprivate init(
        scrollView: HostingScrollView,
        configuration: Attribute<ScrollViewConfiguration>,
        contentFrame: Attribute<ViewFrame>,
        safeAreaInsets: Attribute<EdgeInsets>,
        contentInsets: Attribute<EdgeInsets>,
        layoutDirection: Attribute<LayoutDirection>,
        adjustedState: Attribute<SystemScrollViewState>,
        lastUpdateSeed: UInt32
    ) {
        self.scrollView = scrollView
        self._configuration = configuration
        self._contentFrame = contentFrame
        self._safeAreaInsets = safeAreaInsets
        self._contentInsets = contentInsets
        self._layoutDirection = layoutDirection
        self._adjustedState = adjustedState
        self.lastUpdateSeed = lastUpdateSeed
    }
    
    fileprivate mutating func updateValue() {
        let adjustedState = adjustedState
        var mode = adjustedState.contentOffsetMode
        if case .target = mode {
            if adjustedState.updateSeed != lastUpdateSeed {
                lastUpdateSeed = adjustedState.updateSeed
            } else {
                mode = .system
            }
        }
        
        let (config, configurationIsChanged) = $configuration.changedValue()
        if configurationIsChanged {
            scrollView.configuration = config
        }
        
        var newMode = SystemScrollViewState.ContentOffsetMode.adjustment(required: false)
        if case .system = mode {
            
        } else {
            newMode = mode
        }
        
        let safeAreaInsets = $safeAreaInsets.changedValue()
        if !(configurationIsChanged || safeAreaInsets.changed) {
            newMode = mode
        }
        
        let offset = adjustedState.contentOffset
        let frame = contentFrame
        let layoutDirection = self.layoutDirection
        
        let safe = safeAreaInsets.value.in(configuration.scrollableEdges)
        
        DGGraphRef.withoutUpdate {
            scrollView.updateContent(
                offset: offset,
                frame: CGRect(origin: frame.origin.value, size: frame.size.value),
                safeAreaInsets: safe,
                extendInsets: contentInsets,
                layoutDirection: layoutDirection,
                mode: newMode
            )
        }
        
        value = scrollView
    }
    
}

#if BINARY_COMPATIBLE_TEST || DEBUG
@available(iOS 13.0, *)
private typealias TestableSystemScrollViewScrollable = _SystemScrollViewScrollable
@available(iOS 13.0, *)
internal struct _SystemScrollViewScrollable: Scrollable {
    
    private var rawValue: SystemScrollViewScrollable
    
    internal init(
        state: Attribute<SystemScrollViewState>,
        adjustedState: Attribute<SystemScrollViewState>,
        size: Attribute<ViewSize>,
        contentFrame: Attribute<ViewFrame>,
        children: OptionalAttribute<[Scrollable]>,
        lastUpdateSeed: UInt32,
        id: Attribute<AnyHashable?>
    ) {
        self.rawValue = SystemScrollViewScrollable(
            state: state,
            adjustedState: adjustedState,
            size: size,
            contentFrame: contentFrame,
            children: children,
            lastUpdateSeed: lastUpdateSeed,
            id: id
        )
    }
    
    internal var scrollView: HostingScrollView? {
        get {
            rawValue.scrollView
        }
        set {
            rawValue.scrollView = newValue
        }
    }
    
    internal var contentSize: CGSize? {
        rawValue.contentSize
    }
    
    internal var contentOffset: CGPoint? {
        rawValue.contentOffset
    }
    
    internal var adjustedContentInset: UIEdgeInsets? {
        rawValue.adjustedContentInset
    }
    
    internal var isDragging: Bool? {
        rawValue.isDragging
    }
    
    internal func scroll<ID>(to id: ID, anchor: UnitPoint?) -> Bool where ID : Hashable {
        rawValue.scroll(to: id, anchor: anchor)
    }
    
    internal func scroll(to contentOffset: CGPoint) -> Bool {
        rawValue.scroll(to: contentOffset)
    }
    
    internal func setContentOffset(target: @escaping ContentOffsetTarget) -> Bool {
        rawValue.setContentOffset(target: target)
    }
    
    internal func adjustContentOffset(by size: CGSize) -> Bool {
        rawValue.adjustContentOffset(by: size)
    }
    
    internal func containsScrollable<ID>(_ scrollViewID: ID) -> Bool where ID : Hashable {
        rawValue.containsScrollable(scrollViewID)
    }
    
    internal func scroll<ID>(_ scrollViewID: ID, to offset: CGPoint) -> Bool where ID : Hashable {
        rawValue.scroll(scrollViewID, to: offset)
    }
    
    internal func getScrollable<ID>(of scrollViewID: ID) -> Scrollable? where ID : Hashable {
        rawValue.getScrollable(of: scrollViewID)
    }
    
}

#else
@available(iOS 13.0, *)
private typealias TestableSystemScrollViewScrollable = SystemScrollViewScrollable

#endif
@available(iOS 13.0, *)
private struct SystemScrollViewScrollable: Scrollable { // $b03e78
    
    @Attribute
    private var state: SystemScrollViewState
    
    @Attribute
    private var adjustedState: SystemScrollViewState
    
    @Attribute
    private var size: ViewSize
    
    @Attribute
    private var contentFrame: ViewFrame
    
    @OptionalAttribute
    private var children: [Scrollable]?
    
    @MutableBox
    private var lastUpdateSeed: UInt32
    
    @Attribute
    private var id: AnyHashable?
    
    fileprivate weak var scrollView: HostingScrollView?
    
    fileprivate init(
        state: Attribute<SystemScrollViewState>,
        adjustedState: Attribute<SystemScrollViewState>,
        size: Attribute<ViewSize>,
        contentFrame: Attribute<ViewFrame>,
        children: OptionalAttribute<[Scrollable]>,
        lastUpdateSeed: UInt32,
        id: Attribute<AnyHashable?>
    ) {
        self._state = state
        self._adjustedState = adjustedState
        self._size = size
        self._contentFrame = contentFrame
        self._children = children
        self._lastUpdateSeed = MutableBox(lastUpdateSeed)
        self._id = id
        self.scrollView = nil
    }
    
    fileprivate func scroll<ID: Hashable>(to id: ID, anchor: UnitPoint?) -> Bool {
        for eachChild in children ?? [] {
            if eachChild.scroll(to: id, anchor: anchor) {
                return true
            }
        }
        
        return false
    }
    
    fileprivate func scroll(to contentOffset: CGPoint) -> Bool {
        setContentOffset { size, rect in
            contentOffset
        }
    }
    
    fileprivate func setContentOffset(target: @escaping ContentOffsetTarget) -> Bool {
        var adjustedState = self.adjustedState
        
        let systemTranslation = adjustedState.systemTranslation
        
        let targetWithoutSystemTranslation = systemTranslation == .zero ? target : { (size, rect) -> CGPoint? in
            guard let translation = target(size, rect) else {
                return nil
            }
            return CGPoint(
                x: translation.x - systemTranslation.width,
                y: translation.y - systemTranslation.height
            )
        }
        
        let isAnimated = Transaction.current.animation != nil && !Transaction.current.disablesAnimations
        
        adjustedState.contentOffsetMode = .target(
            targetWithoutSystemTranslation,
            animated: isAnimated
        )
        lastUpdateSeed &+= 1
        adjustedState.updateSeed = lastUpdateSeed
        
        let weakState = WeakAttribute($state)
        adjustedState.commit(to: weakState)
        
        return true
    }
    
    fileprivate func adjustContentOffset(by size: CGSize) -> Bool {
        adjustedState.adjustContentOffset(by: size, state: $state)
        return true
    }
    
    fileprivate func containsScrollable<ID: Hashable>(_ scrollViewID: ID) -> Bool {
        if let id = self.id, id == AnyHashable(scrollViewID) {
            return true
        }
        
        guard let children = children else {
            return false
        }
        return children.contains { $0.containsScrollable(scrollViewID) }
    }
    
    fileprivate func scroll<ID: Hashable>(_ scrollViewID: ID, to offset: CGPoint) -> Bool {
        func target(_ size: CGSize, _ rect: CGRect) -> CGPoint? {
            return offset
        }
                
        if let id = id, id == AnyHashable(scrollViewID) {
            return setContentOffset(target: target(_:_:))
        }
        
        guard let children = children else {
            return false
        }
        
        for child in children {
            if child.scroll(scrollViewID, to: offset) {
                return true
            }
        }
        return false
    }
    
    fileprivate var contentSize: CGSize? {
        scrollView?.contentSize
    }
    
    fileprivate var adjustedContentInset: UIEdgeInsets? {
        scrollView?.adjustedContentInset
    }
    
    fileprivate var contentOffset: CGPoint? {
        scrollView?.contentOffset
    }
    
    fileprivate var isDragging: Bool? {
        scrollView?.isDragging
    }
    
    fileprivate func getScrollable<ID: Hashable>(of scrollViewID: ID) -> Scrollable? {
        if let id = id, id == AnyHashable(scrollViewID) {
            return self
        }
        
        guard let children = children else {
            return nil
        }
        
        for child in children {
            if let scrollable = child.getScrollable(of: scrollViewID) {
                return scrollable
            }
        }
        
        return nil
    }
}

@available(iOS 13.0, *)
private struct SystemScrollViewAdjustedConfiguration: Rule {
    
    @Attribute
    internal var configuration: ScrollViewConfiguration

    @Attribute
    internal var isEnabled: Bool

    @Attribute
    internal var isScrollEnabled: Bool

//    @Attribute
//    var scrollDismissesKeyboard: ScrollDismissesKeyboardMode

    @Attribute
    internal var verticalIndicator: ScrollIndicatorConfiguration

    @Attribute
    internal var horizontalIndicator: ScrollIndicatorConfiguration

    @Attribute
    internal var verticalBounceBehavior: ScrollBounceBehavior

    @Attribute
    internal var horizontalBounceBehavior: ScrollBounceBehavior

//    @Attribute
//    var interactionActivityTag: Optional<String>

//    @Attribute
//    var onScrollToTopGesture: Optional<ScrollToTopGestureAction>

//    @Attribute
//    var refreshAction: Optional<RefreshAction>

//    @Attribute
//    var safeAreaTransitionState: Optional<SafeAreaTransitionState>
    

    @Attribute
    internal var pagingEnabled: Bool?
    
    fileprivate var value: ScrollViewConfiguration {
        
        let configuration = configuration
        let indicators: ScrollViewConfiguration.IndicatorStorage
        
        if case .initial(let show) = configuration.indicators, show == false {
            indicators = .initial(false)
        } else {
            indicators = .resolved(ScrollViewConfiguration.Indicators(
                horizontal: horizontalIndicator,
                vertical: verticalIndicator
            ))
        }
        
        let bounceBehavior = ScrollViewConfiguration.ScrollBounces(
            horizontal: horizontalBounceBehavior,
            vertical: verticalBounceBehavior
        )
        
        return ScrollViewConfiguration(
            axes: configuration.axes,
            indicators: indicators,
            bounceBehavior: bounceBehavior,
            isEnabled: isEnabled && isScrollEnabled,
            isPagingEnabled: pagingEnabled ?? false,
            extendedConfigs: configuration.extendedConfigs
        )
    }
    
    
}

#if BINARY_COMPATIBLE_TEST || DEBUG
@available(iOS 13.0, *)
internal struct SystemScrollViewAdjustedState_Testable: StatefulRule {
    
    internal typealias Value = SystemScrollViewState
    
    fileprivate var _state: SystemScrollViewAdjustedState
    
    internal var size: ViewSize { _state.size }
    
    internal var configuration: ScrollViewConfiguration { _state.configuration }
    
    internal var state: SystemScrollViewState { _state.state }
    
    internal var contentFrame: ViewFrame { _state.contentFrame }
    
    internal var pixelLength: CGFloat { _state.pixelLength }
    
    internal var oldFrame: CGRect { _state.oldFrame }
    
    internal var oldSize: CGSize { _state.oldSize }
    
    internal init(
        size: Attribute<ViewSize>,
        configuration: Attribute<ScrollViewConfiguration>,
        state: Attribute<SystemScrollViewState>,
        contentFrame: Attribute<ViewFrame>,
        pixelLength: Attribute<CGFloat>,
        oldFrame: CGRect, oldSize: CGSize
    ) {
        self._state = SystemScrollViewAdjustedState(
            size: size,
            configuration: configuration,
            state: state,
            contentFrame: contentFrame,
            pixelLength: pixelLength,
            oldFrame: oldFrame,
            oldSize: oldSize
        )
    }
    
    internal mutating func updateValue() {
        _state.updateValue()
    }
    
}

#endif
