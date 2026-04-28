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
import ObjectiveC
import MyShims
@available(iOS 13.0, *)
internal final class HostingScrollView: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate, AnyPlatformViewHost {

    internal let viewType: Any.Type
    
    internal let state: WeakAttribute<SystemScrollViewState>
    
    internal let host: PlatformGroupContainer
    
    internal weak var responder: AnyUIViewResponder?
    
    internal var layoutDirection: LayoutDirection
    
    internal var ignoreUpdates: Int32
    
    internal var pendingUpdate: Bool
    
    internal var animationTarget: ContentOffsetTarget?
    
    internal var animationOffset: CGPoint
    
    internal var isAnimationCompletionCheckPending: Bool

    @OptionalAttribute
    private var disabledGestureSimultaneouslyReceive: Bool?

    internal var configuration: ScrollViewConfiguration {
        didSet {
            updateForConfiguration(oldValue: oldValue)
        }
    }
    
    internal var panGestureStateAttribute: WeakAttribute<UIGestureRecognizer.State>? {
        didSet {
            startPanGestureStateObservation()
        }
    }

    private var panGestureStateObservation: NSKeyValueObservation?
    
    private var disabledBouncesAxis: Axis?
    
    // MARK: - override
    
    internal init(
        viewType: Any.Type,
        state: WeakAttribute<SystemScrollViewState>,
        disabledGestureSimultaneouslyReceive: Attribute<Bool>?
    ) {
        self.responder = nil
        self.layoutDirection = .leftToRight
        self.ignoreUpdates = 0x0
        self.pendingUpdate = true
        self.animationTarget = nil
        self.animationOffset = .zero
        self.isAnimationCompletionCheckPending = false

        self.viewType = viewType
        self.state = state

        self.configuration = ScrollViewConfiguration(
            axes: .all,
            indicators: .initial(true),
            bounceBehavior: ScrollViewConfiguration.ScrollBounces(horizontal: .automatic, vertical: .automatic),
            isEnabled: true,
            isPagingEnabled: false,
            extendedConfigs: ScrollViewExtendedConfigs()
        )

        self.host = PlatformGroupContainer()
        self._disabledGestureSimultaneouslyReceive = OptionalAttribute(disabledGestureSimultaneouslyReceive)

        self.panGestureStateObservation = nil
        self.panGestureStateAttribute = nil
        self.disabledBouncesAxis = nil

        super.init(frame: .zero)
        
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        
        if #available(iOS 13.0, *) {
            automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        addSubview(host)
        delegate = self
    }
    
    internal required init?(coder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }
    
    internal override func adjustedContentInsetDidChange() {
        super.adjustedContentInsetDidChange()
        if ignoreUpdates == 0 {
            updateGraphState()
        }
    }
    
//    internal override var contentInset: UIEdgeInsets {
//        didSet {
//            if oldValue != contentInset {
//                print("[DUI][ScrollView][contentInset] didSet old: \(oldValue), new: \(contentInset)")
//            }
//        }
//    }
    
    internal override var bounds: CGRect {
        didSet {
            guard state.attribute != nil else {
                return
            }
            
            if isTracking && animationTarget != nil {
                resetAnimatedScrollState()
            }
            
            withoutUpdate {
                if super.bounds != oldValue, let animationTarget = animationTarget {
                    self.animationTarget = nil
                    updateAnimationTarget(animationTarget)
                    if my__isAnimatingScroll {
                        self.animationTarget = animationTarget
                    }
                }
                
                if super.bounds.origin != oldValue.origin {
                    updateGraphState()
                }
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            guard oldValue != frame else {
                return
            }
        }
    }
    
    override internal var contentSize: CGSize {
        didSet {
            guard oldValue != contentSize else {
                return
            }
        }
    }

    internal override var safeAreaInsets: UIEdgeInsets {
        .zero
    }

    private func startPanGestureStateObservation() {
        panGestureStateObservation = observe(\.panGestureRecognizer.state, options: [.initial, .new]) { [weak self] scrollView, _ in
            guard let attribute = self?.panGestureStateAttribute, let _ = attribute.attribute else {
                self?.panGestureStateObservation = nil
                return
            }
//            print("[DEBUG][PanGestureVersion] sources: \(scrollView.panGestureRecognizer.state)")
            ViewGraph.setNeedUpdateWithNewValue(scrollView.panGestureRecognizer.state, of: attribute)
        }
    }

    // MARK: - UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let axis = disabledBouncesAxis else {
            return
        }
        guard contentSize.value(for: axis) > bounds.sizeValue(for: axis) else {
            return
        }
        
        let insets = EdgeInsets(contentInset)
        if scrollView.contentOffset.value(for: axis) + insets.value(for: Edge(axis: axis, alignment: .topLeading)) < 0 {
            scrollView.contentOffset = CGPoint(
                axis: axis, main: -insets.value(for: Edge(axis: axis, alignment: .topLeading)),
                sub: contentOffset.value(for: axis.minor)
            )
        }
        let maxOffsetValue = scrollView.contentSize.value(for: axis) - scrollView.bounds.sizeValue(for: axis) + insets.value(for: Edge(axis: axis, alignment: .bottomTrailing))
        if scrollView.contentOffset.value(for: axis) > maxOffsetValue {
            scrollView.contentOffset = CGPoint(
                axis: axis,
                main: maxOffsetValue,
                sub: contentOffset.value(for: axis.minor)
            )
        }
    }
    
    @objc internal func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimationCompletionCheckPending = true
    }
    
    @objc internal func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }

    // MARK: UIGestureRecognizerDelegate
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard disabledGestureSimultaneouslyReceive == false else {
            return false
        }
        guard gestureRecognizer is UIPanGestureRecognizer,
              otherGestureRecognizer is UIPanGestureRecognizer else {
            return false
        }
        return true
    }
    
    // MARK: - animation

    private func checkAnimationCompletion() {
        guard isAnimationCompletionCheckPending &&
                !isTracking && !my__isAnimatingScroll else {
            return
        }
        isAnimationCompletionCheckPending = false
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            guard let target = self.animationTarget else {
                return
            }
            
            self.withoutUpdate {
                if let offset = self.offset(for: target),
                   offset != self.animationOffset {
                    let inset = self.contentInset
                    let newContentOffset = CGPoint(
                        x: offset.x - inset.left,
                        y: offset.y - inset.top
                    )
                    
                    let currentContentOffset = self.contentOffset
                    let offsetDiff = CGPoint(
                        x: round(newContentOffset.x - currentContentOffset.x),
                        y: round(newContentOffset.y - currentContentOffset.y)
                    )
                    
                    if offsetDiff != .zero {
                        self.setContentOffset(newContentOffset, animated: true)
                        self.animationOffset = offset
                    } else {
                        self.animationTarget = nil
                    }
                } else {
                    self.animationTarget = nil
                }
            }
        }
    }
    
    private func resetAnimatedScrollState() -> () {
        isAnimationCompletionCheckPending = false
        animationTarget = nil
    }
    
    private func updateAnimationTarget(_ animationTarget: ContentOffsetTarget) {
        guard let targetOffset = offset(for: animationTarget) else {
            return
        }
        
        if targetOffset != animationOffset {
            let contentInset = self.contentInset
            
            let insetOffset = CGPoint(
                x: targetOffset.x - contentInset.left,
                y: targetOffset.y - contentInset.top
            )
            
            if my__isAnimatingScroll && my_respondsToUpdateScrollAnimationForChangedTargetOffset() {
                my__updateScrollAnimation(forChangedTargetOffset: insetOffset)
            } else {
                contentOffset = insetOffset
            }
        }
        
        animationOffset = targetOffset
        
    }
    
    // MARK: - update
    
    private func withoutUpdate(_ body: () -> Void) {
        disableUpdates()
        body()
        reenableUpdates()
    }
    
    private func disableUpdates() {
        ignoreUpdates &+= 1
    }

    private func reenableUpdates() {
        
        ignoreUpdates &-= 1
        
        guard ignoreUpdates == 0 && pendingUpdate else {
            return
        }
        
        updateGraphState()
        
    }
    
    private func updateForConfiguration(oldValue: ScrollViewConfiguration) {
        isScrollEnabled = !configuration.axes.isEmpty && configuration.isEnabled
        isPagingEnabled = configuration.isPagingEnabled

        if configuration.axes.contains(.horizontal) {
            configIndicator(axis: .horizontal)
            let bouncesBehavior = configuration.bounceBehavior.axis(.horizontal)
            configAlwaysBounces(axis: .horizontal, bouncesBehavior: bouncesBehavior)
            configBounces(with: .horizontal, behavior: bouncesBehavior)
        } else {
            showsHorizontalScrollIndicator = false
            alwaysBounceHorizontal = false
        }

        if configuration.axes.contains(.vertical) {
            configIndicator(axis: .vertical)
            let bouncesBehavior = configuration.bounceBehavior.axis(.vertical)
            configAlwaysBounces(axis: .vertical, bouncesBehavior: bouncesBehavior)
            configBounces(with: .vertical, behavior: bouncesBehavior)
        } else {
            showsVerticalScrollIndicator = false
            alwaysBounceVertical = false
        }

        func configIndicator(axis: Axis) {
            switch configuration.indicators {
            case .initial(let show):
                setScrollIndicatorVisible(axis, show)
            case .resolved(let config):
                let indicatorVisibility = config.axis(axis).visibility.role
                self.configIndicator(axis: axis, indicatorVisibility: indicatorVisibility)
            }
        }

        func configBounces(with axis: Axis, behavior: ScrollBounceBehavior.Role) {
            switch behavior {
            case .never:
                if configuration.axes == Axis.Set(axis: axis) ||
                    configuration.bounceBehavior.axis(axis.minor) == .never {
                    bounces = false
                } else {
                    disabledBouncesAxis = axis
                    bounces = true
                }
            default:
                break
            }
        }
    }

    private func configAlwaysBounces(axis: Axis, bouncesBehavior: ScrollBounceBehavior.Role) {
        switch bouncesBehavior {
        case .automatic, .always:
            setAlwaysBounce(axis, true)
        case .basedOnSize:
            setAlwaysBounce(axis, false)
        case .never:
            setAlwaysBounce(axis, false)
        }
    }

    private func configIndicator(axis: Axis, indicatorVisibility: ScrollIndicatorVisibility.Role) {
        switch indicatorVisibility {
        case .visible, .automatic:
            setScrollIndicatorVisible(axis, true)
        case .never, .hidden:
            setScrollIndicatorVisible(axis, false)
        }
    }

    @inline(__always)
    private func setAlwaysBounce(_ axis: Axis, _ value: Bool) {
        switch axis {
        case .horizontal:
            alwaysBounceHorizontal = value
        case .vertical:
            alwaysBounceVertical = value
        }
    }

    @inline(__always)
    private func setScrollIndicatorVisible(_ axis: Axis, _ value: Bool) {
        switch axis {
        case .horizontal:
            showsHorizontalScrollIndicator = value
        case .vertical:
            showsVerticalScrollIndicator = value
        }
    }

    private func updateGraphState() {
        guard ignoreUpdates == 0 else {
            pendingUpdate = true
            return
        }
        
        pendingUpdate = false
        
        let contentOffset = self.contentOffset
        let contentInset = self.contentInset
        
        let scrollViewState = SystemScrollViewState(
            contentOffset: CGPoint(x: contentOffset.x + contentInset.left, y: contentOffset.y + contentInset.top),
            systemContentInsets: .zero,
            systemTranslation: .zero,
            contentOffsetMode: .system,
            updateSeed: 0
        )
        
        scrollViewState.commit(to: state)
    }
    
    private func setSkipsContentOffsetAdjustmentsIfScrollingFlag(_ skip: Bool) {
        if respondsToSelectorSkipsContentOffsetAdjustmentsIfScrollingFlag {
            my__setSkipsContentOffsetAdjustmentsIfScrolling(skip)
        } else {
            skipsAdjustmentIfScrolling = skip
        }
    }
    
    internal func updateContent(
        offset: CGPoint,
        frame: CGRect,
        safeAreaInsets: EdgeInsets,
        extendInsets: EdgeInsets,
        layoutDirection: LayoutDirection,
        mode: SystemScrollViewState.ContentOffsetMode
    ) {
        withoutUpdate {
            my__setAutomaticContentOffsetAdjustmentEnabled(false)
            setSkipsContentOffsetAdjustmentsIfScrollingFlag(true)
            
            let safeInsets = UIEdgeInsets(safeAreaInsets, layoutDirection: layoutDirection)
            let extendInsets = UIEdgeInsets(extendInsets, layoutDirection: layoutDirection)
            let resolvedInsets = safeInsets + extendInsets
            
            contentInset = resolvedInsets
            scrollIndicatorInsets = safeInsets
            
            host.frame = frame
            
            switch mode {
            case .adjustment(let required):
                let newOffset = CGPoint(
                    x: offset.x - resolvedInsets.left,
                    y: offset.y - resolvedInsets.top)
                isAnimationCompletionCheckPending = false
                guard newOffset != contentOffset else {
                    break
                }
                guard required || !isDragging else {
                    break
                }
                contentOffset = newOffset
                animationOffset = CGPoint(
                    x: animationOffset.x + newOffset.x,
                    y: animationOffset.y + newOffset.y)
                
            case .target(let body, let animated):
                resetAnimatedScrollState()
                let bounds = super.bounds
                let rect = CGRect(
                    origin: offset,
                    size: CGSize(
                        width: max(bounds.width - resolvedInsets.left - resolvedInsets.right, 0),
                        height: max(bounds.height - resolvedInsets.top - resolvedInsets.bottom, 0))
                )
                
                guard let offset = body(frame.size, rect) else {
                    animationTarget = nil
                    break
                }
                
                let oldContentOffset = contentOffset
                let newOffset = CGPoint(x: offset.x - resolvedInsets.left, y: offset.y - resolvedInsets.top)
                setContentOffset(newOffset, animated: animated)
                animationOffset = newOffset
                
                if animated && oldContentOffset != newOffset {
                    animationTarget = body
                } else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.animationTarget = body
                        self.animationOffset = CGPoint(x: CGFloat.infinity, y: .infinity)
                        self.updateAnimationTarget(body)
                    }
                }
            case .system:
                checkAnimationCompletion()
            }
            if contentSize != frame.size {
                contentSize = frame.size
            }
            if self.layoutDirection != layoutDirection {
                self.layoutDirection = layoutDirection
                updateGraphState()
            }
            
        }
        
        my__setAutomaticContentOffsetAdjustmentEnabled(true)
        setSkipsContentOffsetAdjustmentsIfScrollingFlag(false)
    }
    // MARK: - calculate

    private func offset(for body: ContentOffsetTarget) -> CGPoint? {
        
        let contentInset = self.contentInset
        
        let contentInsetHeight = contentInset.top + contentInset.bottom
        let contentInsetWidth = contentInset.left + contentInset.right
        
        let contentOffset = self.contentOffset
        
        let origin = CGPoint(
            x: contentInset.left + contentOffset.x,
            y: contentInset.top + contentOffset.y
        )
        
        let bounds = self.bounds
        
        let boundsWidth = max(bounds.size.width - contentInsetWidth, 0)
        let boundsHeight = max(bounds.size.height - contentInsetHeight, 0)
        
        let boundsSize = CGSize(width: boundsWidth, height: boundsHeight)
        
        return body(
            self.contentSize,
            CGRect(origin: origin, size: boundsSize)
        )
    }
    
    // MARK: - Accessibility
    
    internal func applyAccessibilityElements() {
        shouldGroupAccessibilityChildren = true
    }
    
    internal override var accessibilityElements: [Any]? {
        get {
            accessibilityNodeForPlatformElement?.accessibilityElements
        }
        set {
            _intentionallyLeftBlank()
        }
    }

    internal struct ObservableState {

        internal let contentOffset: Attribute<CGPoint?>?

        internal let contentSize: Attribute<CGSize?>?

        internal let adjustedContentInset: Attribute<UIEdgeInsets?>?

    }
    
    // DanceUI addition
    internal override func my_needsDelegateProxy() -> Bool {
        true
    }
}

@available(iOS 13.0, *)
// MARK: - protocol  PlatformGroupFactory
extension HostingScrollView: CustomPlatformGroupFactory {
    
    internal func _updatePlatformGroup(_ : inout UIView) {
        _intentionallyLeftBlank()
    }
    
    internal func _makePlatformGroup() -> UIView {
        self
    }
    
    internal func _platformGroupContainer(_: UIView) -> UIView {
        host
    }
    
    internal func _renderPlatformGroup(_ displayList: DisplayList, in context: GraphicsContext, size: CGSize, renderer: DisplayList.GraphicsRenderer) {
        _notImplemented()
    }
    
    internal final class PlatformGroupContainer: UIHookFreeView {
        
        internal override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
    }
}

@available(iOS 13.0, *)
extension HostingScrollView: AnyViewFactory {
    
    internal func encoding() -> (id: String, data: Codable)? {
        nil
    }
    
#if DEBUG
    internal func testableCheckAnimationCompletion() {
        checkAnimationCompletion()
    }
#endif
}
