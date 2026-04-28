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

internal import Resolver

#if os(iOS)
import UIKit
#endif

import Foundation
internal import DanceUIGraph
import MyShims


@available(iOS 13.0, *)
internal protocol UIHostingViewDelegate: AnyObject {
    func hostingView<ViewType: View>(_ hostingView: _UIHostingView<ViewType>, didMoveTo: UIWindow?)

    func hostingView<ViewType: View>(_ hostingView: _UIHostingView<ViewType>, willUpdate: inout EnvironmentValues)

    func hostingView<ViewType: View>(_ hostingView: _UIHostingView<ViewType>, didUpdate: inout EnvironmentValues)

    func hostingView<ViewType: View>(_ hostingView: _UIHostingView<ViewType>, didChangePreferences: PreferenceList)

    func hostingView<ViewType: View>(_ hostingView: _UIHostingView<ViewType>, didChangePlatformItemList: PlatformItemList)

}

@available(iOS 13.0, *)
open class _UIHostingView<Content: View>: __MyHostingView,
                                          FocusBridgeProvider,
                                          AnyUIHostingView,
                                          ViewRendererHost,
                                          UIHostingViewTraits,
                                          XcodeViewDebugDataProvider,
                                          EventGraphHost,
                                          CurrentEventProvider,
                                          UIKitEventGraphHost
{
    internal typealias HostingRootViewType = ModifiedContent<ModifiedContent<Content, EditModeScopeModifier>, HitTestBindingModifier>

    fileprivate var _rootView: Content

    internal var viewGraph: ViewGraph

    internal let renderer: ViewRenderer = ViewRenderer()

    internal let eventBindingManager: EventBindingManager

    internal var currentTimestamp: Time = .zero

    internal var propertiesNeedingUpdate: ViewRendererHostProperties = .all

    internal var isRendering: Bool = false

    internal var accessibilityVersion: DisplayList.Version = .zero

    internal var externalUpdateCount: Int = 0

    internal var disabledBackgroundColor: Bool = false

    internal var allowFrameChanges: Bool = true

    internal var wantsTransparentBackground: Bool = false

    public var explicitSafeAreaInsets: EdgeInsets? {
        didSet {
            self.safeAreaInsetsDidChange()
            if explicitSafeAreaInsets == nil {
                self.addKeyboardObserver()
            } else {
                self.removeKeyboardObserver()
            }
        }
    }

    internal private(set) var keyboardFrame: CGRect?

    internal var currentEvent: UIEvent?
    
    internal func setKeyboardFrame(_ frame: CGRect?, seed: UInt32) {
        guard keyboardSeed == seed else {
            return
        }
        if frame != keyboardFrame {
            keyboardFrame = frame
            invalidateProperties(.safeArea, mayDeferUpdate: false)
        }
    }

    internal var defaultAddsKeyboardToSafeAreaInsets: Bool?

    internal private(set) var keyboardSeed: UInt32 = 0

    internal var isHiddenForReuse: Bool = false

    internal var inheritedEnvironment: EnvironmentValues?

    internal var environmentOverride: EnvironmentValues? {
        didSet {
            invalidateProperties(.environment)
        }
    }

    internal weak var viewController: UIHostingController<Content>? {
        didSet {
            updateBackgroundColor()
        }
    }

    internal private(set) weak var tracker: PropertyList.Tracker? = nil

    /// Optional type is a DanceUI modification. In case that the
    /// gesture container is enabled.
    internal let eventBridge: UIKitEventBindingBridge?

    internal var displayLink: DisplayLink?

    fileprivate var lastRenderTime: Time = .zero

    internal var canAdvanceTimeAutomatically: Bool = true

    internal var pendingPreferencesUpdate: Bool = false

    fileprivate var nextTimerTime: Time?
    
    #if DEBUG
    internal var testableNextTimerTime: Time? {
        get {
            nextTimerTime
        }
        set {
            nextTimerTime = newValue
        }
    }
    #endif

    internal var updateTimer: Timer?

    /// Indicates the latest update was requested from visible or invisible
    /// `_UIHostingView` instance.
    internal var requiresUpdateWhenVisible: Bool = true

    /// Sometimes we need to layout even the `_UIHostingView` is not visible
    internal var allowLayoutWhenNotVisible: Bool = false

    internal var colorScheme: ColorScheme? {
        didSet {
            if colorScheme == oldValue {
                return
            }

            if let viewController = self.viewController {
                if #available(iOS 13, *) {
                    viewController.overrideUserInterfaceStyle = UIUserInterfaceStyle(colorScheme)
                }
            }
            invalidateProperties(.environment, mayDeferUpdate: true)
        }
    }

    internal var invertLayoutDirection: Bool = false

    internal var navigationBridge: NavigationBridge_PhoneTV<Content> = NavigationBridge_PhoneTV()

    internal let alertBridge: AlertBridge<Content, Alert.Presentation> = AlertBridge(style: .alert)

    internal let actionSheetBridge: AlertBridge<Content, ActionSheet.Presentation> = AlertBridge(style: .actionSheet)

    internal let sheetBridge: SheetBridge<Content> = SheetBridge()

    internal private(set) var focusBridge: FocusBridge = FocusBridge()

    internal var inspectorBridge: UIKitInspectorBridge<Content>?

    internal private(set) var statusBarBridge: UIKitStatusBarBridge<Content> = UIKitStatusBarBridge()

    internal var accessibilityEnabled: Bool = false

    internal weak var delegate: UIHostingViewDelegate?

    fileprivate var rootViewDelegate: RootViewDelegate?

    internal var focusedValues: FocusedValues = FocusedValues() {
        didSet {
            invalidateProperties(.focusedValues, mayDeferUpdate: true)
        }
    }

    internal weak var parentAccessibilityElement: AnyObject?

    /// A type-erased storage for `UIWindowScene` such that we can ship DanceUI
    /// to iOS prior to 13.0
    private weak var observedSceneStorage: AnyObject?

    @available(iOS 13.0, *)
    internal private(set) var observedScene: UIWindowScene? {
        get {
            observedSceneStorage as? UIWindowScene
        }
        set {
            observedSceneStorage = newValue
        }
    }

    #if DEBUG
    internal var observedSceneStorageForTest: AnyObject? {
        observedSceneStorage
    }

    @available(iOS 13.0, *)
    internal func setObservedSceneForTest(_ observedScene: UIWindowScene?) {
        self.observedScene = observedScene
    }
    #endif

    /// Indicates that the `_UIHostingView` is entering foreground on its scene.
    internal var isEnteringForeground: Bool = false

    internal var currentResponderCommands: [Selector: CommandAction] = ResponderCommandsKey.defaultValue
    
    /// metadata + 0x208, 0x1d0(iOS 14.3)
    fileprivate lazy var _forwardingTarget = _MyTSHostingViewInvocationTarget(handler: { [weak self] (aSelector: Selector) in
        guard let strongSelf = self else {
            return
        }

        strongSelf.responderAction(for: aSelector)?.perform()
    })

    internal lazy var foreignSubviews: NSHashTable<UIView> = .weakObjects()

    internal var isInsertingRenderedSubview: Bool = false

    internal var shouldCheckHostingControllerExists: Bool = false

    internal weak var pairedHostingController: AnyHostingController?

    public var gestureRecognizerConfiguration: UIHostingGestureRecognizerConfiguration

    // For gesture container
    private let independentGestureRecognizer: IndependentGestureRecognizer?

    // MARK: Computed Properties
    internal final class var isPlatformItemListHost: Bool {
        false
    }
    
    open override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            guard allowFrameChanges else {
                return
            }
            let oldSize = super.frame.size
            super.frame = newValue
            frameDidChange(oldValue: .init(origin: .zero, size: oldSize))
        }
    }
    
    open override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            guard allowFrameChanges else {
                return
            }
            let oldSize = super.bounds.size
            super.bounds = newValue
            frameDidChange(oldValue: .init(origin: .zero, size: oldSize))
        }
    }

    open override var safeAreaInsets: UIEdgeInsets {
        guard let explicitSafeAreaInsets = explicitSafeAreaInsets else {
            return super.safeAreaInsets
        }
        
        let layoutDirection = Update.ensure {
            self.viewGraph.environment.layoutDirection
        }
        
        var (left, right) = (explicitSafeAreaInsets.leading, explicitSafeAreaInsets.trailing)
        if layoutDirection != .leftToRight {
            (left, right) = (right, left)
        }
        
        return UIEdgeInsets(top: explicitSafeAreaInsets.top,
                            left: left,
                            bottom: explicitSafeAreaInsets.bottom,
                            right: right)
    }

    open override var transform: CGAffineTransform {
        didSet {
            if DanceUIFeature.gestureContainer.isEnable {
                if transform != oldValue {
                    invalidateProperties(.transform)
                }
            }
        }
    }

    open override var transform3D: CATransform3D {
        didSet {
            if DanceUIFeature.gestureContainer.isEnable {
                if !CATransform3DEqualToTransform(transform3D, oldValue) {
                    invalidateProperties(.transform)
                }
            }
        }
    }
    
    open override var clipsToBounds: Bool {
        didSet {
            if DanceUIFeature.gestureContainer.isEnable {
                if clipsToBounds != oldValue {
                    invalidateProperties(.transform)
                }
            }
        }
    }
    
    @_spi(DanceUITests)
    public var rootView: Content {
        get {
            _rootView
        }
        set {
            _rootView = newValue
            invalidateProperties(.rootView, mayDeferUpdate: true)
        }
    }
    
    final public var _rendererConfiguration: _RendererConfiguration {
        get {
            Update.withLock {
                renderer.configuration
            }
        }
        set {
            Update.withLock {
                renderer.configuration = newValue
            }
        }
    }
    
    public final var _rendererObject: AnyObject? {
        return Update.withLock {
            let (rendererBase, _, _) = renderer.updateRenderer(rootView: self)
            return rendererBase.exportedObject
        }
        
    }
    
    internal var ancestorHasInvertFilterApplied: Bool {
        guard self.my_respondsToAncestorHasInvertFilterApplied() else {
            return false
        }
        
        let ancestorHasInvertFilterApplied = self.my_ancestorHasInvertFilterApplied()
        
        guard let window = self.window else {
            return ancestorHasInvertFilterApplied
        }
        
        return ancestorHasInvertFilterApplied || window.appliedDoubleInvertFilter
    }
    
    open override dynamic var backgroundColor: UIColor? {
        get {
            super.backgroundColor
        }
        set {
            disabledBackgroundColor = true
            super.backgroundColor = newValue
        }
    }
    
    internal var deferToChildViewController: Bool {
        statusBarBridge.deferToChildViewController
    }
    
    internal var isWindowRoot: Bool {
        guard let window = self.window else {
            return false
        }
        
        guard let rootViewController = window.rootViewController else {
            return false
        }
        
        guard let view = rootViewController.viewIfLoaded else {
            return false
        }
        
        // Pointer equality check
        return view === self
    }
    
    internal var containingNavControllerFromLastAttemptedPop: UINavigationController? {
        get {
            navigationBridge.containingNavControllerFromLastAttemptedPop
        }
        set {
            navigationBridge.containingNavControllerFromLastAttemptedPop = newValue
        }
    }
    
    internal var preferredStatusBarStyle: UIStatusBarStyle {
        UIStatusBarStyle(self.traitCollection.effectiveColorScheme)
    }
    
    internal var prefersStatusBarHidden: Bool {
        statusBarBridge.statusBarHidden
        /// || navigationBridge.statusBarHidden
    }
    
    fileprivate var supportsToolbar: Bool {
        guard let viewController = self.viewController else {
            return false
        }
        
        if viewController.navigationController != nil {
            return true
        }
        
        return viewController.allowedBehaviors.contains(.customToolbarManagement)
    }
    
    internal var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }
    
    //    internal var toolbarCoordinator: UIKitToolbar {}

    /// Whether to handle safeAreaInset
    internal var handleSafeAreaInset: Bool {
        true
    }

    /// Whether to handle keyboard show/hide logic
    internal var handleKeyboard: Bool {
        true
    }

    // MARK: Init & Deinit
    internal override init(frame: CGRect) {
        _danceuiFatalError("init(frame:) has not been implemented")
    }

    public required init?(coder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }
    
    open override func setNeedsLayout() {
        super.setNeedsLayout()
        // PerThreadOSCallback.traceEvent("[_UIHostingView] setNeedsLayout", identifier: self)
    }
    
    open override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        if DanceUIFeature.gestureContainer.isEnable {
            guard !isInsertingRenderedSubview else {
                return
            }

            foreignSubviews.add(subview)
        }
    }
    
    open override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)

        if DanceUIFeature.gestureContainer.isEnable {
            foreignSubviews.remove(subview)
        }
    }

#if DEBUG
    internal var isHitTestLogEnabled: Bool {
        EnvValue.isHitTestLogEnabled
    }
#endif

    internal func hitTestLog(_ message: @autoclosure () -> String, _ function: StaticString = #function) {
#if DEBUG
        if isHitTestLogEnabled {
            print("[\(_typeName(type(of: self), qualified: false))] [\(function)] [\(Unmanaged.passUnretained(self).toOpaque())] \(message())")
        }
#endif
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let retVal: UIView?
        
        hitTestLog("BEGAN")
        defer {
            hitTestLog("ENDED <- \(retVal?.description ?? "nil")")
        }
        
        // Firstly, let's hit test with super implementation to hit test the
        // views in the conventional way.
        let superHitView = super.hitTest(point, with: event)
        hitTestLog(" | super.hitTest")
        
        guard DanceUIFeature.gestureContainer.isEnable else {
            retVal = superHitView
            hitTestLog(" < super.hitTest: \(retVal?.description ?? "nil")")
            return retVal
        }
        
        retVal = ensureSubtreeRootHitTestContext(point: point) {
            let viewHitTestResult: UIView?
            
            guard Self._myShims_currentHitTestContext != nil else { // BDCOV_EXCL_BLOCK
                viewHitTestResult = superHitView
                hitTestLog(" | super.hitTest = \(viewHitTestResult?.description ?? "nil") : no hit-test context == nil")
                return viewHitTestResult
            }
            
            if let superHitView = superHitView {
                hitTestLog(" | super.hitTest = \(superHitView.description)")
                
                let foreignHitView = foreignSubviews.allObjects.first { eachForeignSubview in
                    let isDescendant = superHitView.isDescendant(of: eachForeignSubview)
                    hitTestLog(" | super hit-view \(isDescendant ? "is" : "is not") a descendant of foreign subview: \(eachForeignSubview)")
                    return isDescendant
                }
                
                if foreignHitView != nil {
                    hitTestLog(" | viewHitTestResult = superHitView(\(superHitView)) : super hit view is a descendant of the foreign subview")
                    viewHitTestResult = superHitView
                } else {
                    currentEvent = event
                    hitTestLog(" | super hit view is not a descendant of all foreign subviews")
                    if self.point(inside: point, with: event) {
                        hitTestLog(" | viewHitTestResult = self : self.point(inside: point, with: event) == true")
                        viewHitTestResult = self
                    } else {
                        hitTestLog(" | viewHitTestResult = nil : self.point(inside: point, with: event) == false")
                        viewHitTestResult = nil
                    }
                }
            } else {
                currentEvent = event
                hitTestLog(" | super hit view is nil")
                if !self.isUserInteractionEnabled || self.isHidden || self.alpha == 0 {
                    // _UIHostingView is often used standalone in DanceUI's
                    // business. We need to take UIKit operations into consideration
                    hitTestLog(" | viewHitTestResult = nil : self.isUserInteractionEnabled = \(self.isUserInteractionEnabled), self.isHidden = \(self.isHidden) , self.alpha = \(self.alpha)")
                    viewHitTestResult = nil
                } else if self.point(inside: point, with: event) {
                    hitTestLog(" | viewHitTestResult = self : self.point(inside: point, with: event) == true")
                    viewHitTestResult = self
                } else {
                    hitTestLog(" | viewHitTestResult = nil : self.point(inside: point, with: event) == false")
                    viewHitTestResult = nil
                }
            }
            
            return viewHitTestResult
        } then: { viewHitTestResult, context in
            if let viewHitTestResult {
                let contextHitTestResult = viewHitTestResult._myShims_hitTest(with: context)
                if let contextHitTestResult {
                    hitTestLog(" < contextHitTestResult: \(contextHitTestResult.description)")
                    return contextHitTestResult
                } else {
                    hitTestLog(" < viewHitTestResult: \(viewHitTestResult)")
                    return viewHitTestResult
                }
            } else {
                hitTestLog(" < nil")
                return nil
            }
        }
        
        return retVal
    }
    
    // A helper function simulate UIKitCore iOS 18 performHit process.
    private func ensureSubtreeRootHitTestContext(point: CGPoint, do viewBasedHitTest: () -> UIView?, then contextBasedHitTest: (_ viewHitTestResult: UIView?, _: _MyHitTestContext) -> UIView?) -> UIView? {
        let globalPoint = convert(point, to: window)
        let definesContext: Bool
        let context: _MyHitTestContext
        if Self._myShims_currentHitTestContext == nil {
            context = _MyHitTestContext(point: globalPoint, radius: defaultMajorRadius)
            Self._myShims_currentHitTestContext = context
            definesContext = true
        } else {
            context = _MyHitTestContext(point: globalPoint, radius: defaultMajorRadius)
            definesContext = false
        }
        defer {
            if definesContext {
                Self._myShims_currentHitTestContext = nil
            }
        }
        let viewHitTestResult = viewBasedHitTest()
        if definesContext {
            return contextBasedHitTest(viewHitTestResult, context)
        } else {
            return viewHitTestResult
        }
    }
    
    // We do contextual hit-testing in -[UIView hitTest:withEvent:]. Since
    // contextual hit-testing
    open override func _myShims_hitTest(with context: _MyHitTestContext) -> UIView? {
        let hitView: UIView?
        
        hitTestLog("BEGAN")
        defer {
            hitTestLog("ENDED <- \(hitView?.description ?? "nil")")
        }
        
        hitTestLog(" | probing \"gesture container\" from the responder node")
        
        let result = Update.perform { () -> GestureContainerProbingResult in
            defer {
                currentEvent = nil
            }

            // Update transform without geometry observation
            self.updateTransformWithoutGeometryObservation()

            // Extract point and radius from context
            let radius: CGFloat = context.radius
            
            // Get responder node from ViewRendererHost protocol witness
            guard let responderNode = (self as ViewRendererHost).responderNode else {
                hitTestLog(" < self : responderNode = nil")
                return .view(self)
            }
            
            hitTestLog(" | found responder node = \(responderNode)")
            
            // Try to cast to ViewResponder
            guard let viewResponder = responderNode as? ViewResponder else {
                hitTestLog(" < self : responderNode is no ViewResponder")
                return .view(self)
            }

#if DEBUG
            if isHitTestLogEnabled {
                viewResponder.printTree()
            }
#endif
            
            hitTestLog(" | responder node is ViewResponder, hit-test")

            let globalPoint = context.point
            let hitResponder = viewResponder.hitTest(
                globalPoint: globalPoint,
                radius: radius
            )
            
            guard let hitResponder else {
                hitTestLog(" < self : hit-responder = nil")
                return .view(self)
            }
            
            // Get the last key to access cached result
            let key = ViewResponder.hitTestKey
            
            hitTestLog(" | hit-responder = \(hitResponder.description)")
            
            // Try to cast to UIViewResponder (likely a protocol or base class)
            if let uiViewResponder = hitResponder as? UIViewResponder_FeatureGestureContainer,
               var hostView = uiViewResponder.hostView {

                if let scrollViewResponder = uiViewResponder as? AnyHostingScrollViewResponder, let representedView = scrollViewResponder.representedView?.superview {
                    // Hit-test from the HostingScrollView, else there would be
                    // an infinite loop since we don't implement
                    // PlatformContainer.
                    hostView = representedView
                }

                hitTestLog(" | hit-responder is PlatformViewResponderBase, hit-test")
                
                // Call closure to perform platform-specific hit test
                let hitView = { () -> UIView? in
                    // Access lastResult
                    if let lastResult = uiViewResponder.lastResult {
                        // If lastResult.key == key, return lastResult.hitView
                        if lastResult.key == key {
                            return lastResult.hitView
                        }
                    }
                    // Convert point to hostView's coordinate space
                    let localPoint = hostView.convert(globalPoint, from: nil)
                    // Call hitTest(_:with:) on hostView
                    let result = hostView.hitTest(localPoint, with: currentEvent)
                    // Return the result
                    return result
                }()
                
                if let hitView = hitView {
                    if let result = hitView._myShims_hitTest(with: context) {
                        hitTestLog(" < hit-view hitTestWithContext result: \(result)")
                        return .gestureContainer(result)
                    } else {
                        hitTestLog(" < hit-view hitTestWithContext result: \(hitView)")
                        return .view(hitView)
                    }
                } else {
                    hitTestLog(" < self : no hit-view")
                    return .view(self)
                }
            } else if let gestureResponder = hitResponder as? AnyGestureContainingResponder,
                      let gestureContainer = gestureResponder.gestureContainer {
                
                hitTestLog(" | hit-responder is AnyGestureContainingResponder, using gestureContainer")
                
                // (Debug logging omitted)
                // Return the gesture container if present
                return .gestureContainer(gestureContainer)
            } else {
                hitTestLog(" | search hit-responder ancestors to find a nearest gesture container")
                
                // Otherwise, walk up the parent chain to find a responder with a representedView or host
                var parentResponder: ViewResponder? = hitResponder.parent
                while let parent = parentResponder {
                    hitTestLog(" | evaluating ancestor \(parent)")
                    if let gestureContainer = parent.gestureContainer {
                        hitTestLog(" | hit-responder ancestor has gestureContainer, using it")
                        return .view(gestureContainer)
                    }
                    if let platformParent = parent as? UIViewResponder_FeatureGestureContainer,
                       let representedView = platformParent.representedView { // The _UIHostingView
                        hitTestLog(" | hit-responder ancestor is UIViewResponder, try to use the representedView: \(representedView)")
                        return .view(representedView)
                    }
                    hitTestLog(" | continue searching ancestor")
                    parentResponder = parent.parent
                }
                
                // If still not found, try to get the host (ViewGraphDelegate)
                if let host = hitResponder.host,
                   let view = host.as(UIView.self) {
                    hitTestLog(" | hit-responder's host is UIView, using it")
                    return .view(view)
                }
                
                return .view(self)
            }
        }
        
        switch result {
        case .view(let view):
            hitView = view
        case .gestureContainer(let gestureContainer):
            hitView = gestureContainer
        }
        
        return hitView
    }
    
    private var registeredForGeometryChanges: Bool = false
    
    private func updateTransformWithoutGeometryObservation() {
        assert(DanceUIFeature.gestureContainer.isEnable)
        
        defer {
            if registeredForGeometryChanges {
                my__unregisterForGeometryChanges()
                registeredForGeometryChanges = false
            }
        }

        guard viewGraph.invalidateTransform() else {
            return
        }
    }

    /// Set `true` to use hit-testing logic provided by DanceUI ``View`` that
    /// hosted by this view.
    public var _usesContentHitTesting: Bool = false
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard _usesContentHitTesting else {
            return super.point(inside: point, with: event)
        }
        let globalPoint = self.convert(point, to: nil)
        return eventBindingManager.point(inside: globalPoint, with: event)
    }

    @_specialize(where Content == AnyView)
    public init(rootView: Content) {
        
        _rootView = rootView
        
        self.parentAccessibilityElement = nil
        self.eventBindingManager = EventBindingManager()
        self.eventBridge = if DanceUIFeature.gestureContainer.isEnable {
            nil
        } else {
            UIKitEventBindingBridge(eventBindingManager: eventBindingManager)
        }
        let viewGraph = Self.createViewGraph()
        self.viewGraph = viewGraph
        self.independentGestureRecognizer = if DanceUIFeature.gestureContainer.isEnable {
            IndependentGestureRecognizer(viewGraph: viewGraph)
        } else {
            nil
        }
        self.gestureRecognizerConfiguration = UIHostingGestureRecognizerConfiguration()
        super.init(frame: .zero)
        initializeAndSetupViewGraph(viewGraph)

#if DANCE_UI_INHOUSE || DEBUG
        if DanceUIFeature.badge.isEnable {
            // Add DanceUI badge for identification
            setupDanceUIBadge()
        }
#endif // DANCE_UI_INHOUSE || DEBUG
        
        renderer.host = self

        statusBarBridge.host = self
        
        alertBridge.host = self
        
        actionSheetBridge.host = self
        
        sheetBridge.host = self

        focusBridge.host = self
        focusBridge.addPreferences()
        
        self.navigationBridge.host = self
        self.navigationBridge.addPreferences(to: self.viewGraph)
        
        eventBindingManager.host = self
        eventBindingManager.delegate = eventBridge
        
        NotificationCenter.default.addObserver(self, selector: #selector(externalEnvironmentDidChange), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(externalEnvironmentDidChange), name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        if DanceUIFeature.gestureContainer.isEnable {
            if let independentGestureRecognizer {
                addGestureRecognizer(independentGestureRecognizer)
            }
        } else {
            if let eventBridge {
                eventBridge.attach(to: self)
                my__registerForGeometryChanges()
                // DanceUI addition began
                eventBridge.bindingActivateHandler = { [unowned self] (responderNode) in
                    if EnvValue.isResponderNodeVisualDebugEnabled {
                        responderVisualDebugView.boundResponderUUIDs.insert(responderNode.visualDebugID)
                    }
                }
                eventBridge.bindingDeactivateHandler = { [unowned self] (responderNode) in
                    if EnvValue.isResponderNodeVisualDebugEnabled {
                        responderVisualDebugView.boundResponderUUIDs.remove(responderNode.visualDebugID)
                    }
                }
            }
        }
        
        if handleKeyboard {
            addKeyboardObserver()
        }
        // accessibility notification
    }
    
    deinit {
        updateRemovedState()
        NotificationCenter.default.removeObserver(self)
        clearDisplayLink()
        clearUpdateTimer()
        invalidate()
        Update.ensure {
            self.viewGraph.preferenceBridge = nil
            self.viewGraph.invalidate()
        }
    }
    
    internal static func createViewGraph(usedInAsyncComputation: Bool = false) -> ViewGraph {
        let defaultOutputs: ViewGraph.Outputs = .defaults
        var requestedOutputs: ViewGraph.Outputs = .needHandleAccessibilityNodes
        requestedOutputs.insert(.needHandleLayouts)
        if !defaultOutputs.contains(.needHandlePlatformItemList) && Self.isPlatformItemListHost {
            requestedOutputs.insert(.needHandlePlatformItemList)
        }
        requestedOutputs = requestedOutputs.union(defaultOutputs)
        
        let viewGraph = ViewGraph(rootViewType: HostingRootViewType.self, 
                                  requestedOutputs: requestedOutputs,
                                  usedInAsyncComputation: usedInAsyncComputation)
        if !viewGraph.disabledOutputs.contains(.needHandleAccessibilityNodes) {
            viewGraph.disabledOutputs.insert(.needHandleAccessibilityNodes)
        }
        return viewGraph
    }
    
    internal func initializeAndSetupViewGraph(_ viewGraph: ViewGraph) {
        initializeViewGraph()
        if !viewGraph.addedBridgePreference {
            statusBarBridge.addPreferences(to: viewGraph)
            alertBridge.addPreferences(to: viewGraph)
            actionSheetBridge.addPreferences(to: viewGraph)
            sheetBridge.addPreferences(to: viewGraph)

            self.navigationBridge.addPreferences(to: viewGraph)
        }
        if let current = PlatformViewRepresentableValues.current,
            let bridge = current.preferenceBridge {
            self.setPreferenceBridge(bridge)
        }
    }
    
    // MARK: DanceUI Badge

#if DANCE_UI_INHOUSE || DEBUG

    private func setupDanceUIBadge() {
        // Create a label for the badge
        let badgeLabel = UILabel()
        badgeLabel.text = "DanceUI"
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.6)
        badgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        badgeLabel.textAlignment = .center
        
        // Set size and position
        let targetSize = CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        var fitSize = badgeLabel.systemLayoutSizeFitting(targetSize)
        fitSize.round(.toNearestOrEven, toMultipleOf: UIScreen.main.scale)
        let cornerRadius = fitSize.height * (1 - 0.618)
        let badgeSize = CGSize(width: fitSize.width + cornerRadius * 2, height: fitSize.height)
        badgeLabel.frame = CGRect(x: 0, y: 0, width: badgeSize.width, height: badgeSize.height)
        
        // Add corner radius for a rounded appearance
        badgeLabel.layer.cornerRadius = cornerRadius
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.layer.shouldRasterize = true
        badgeLabel.clipsToBounds = true
        badgeLabel.isUserInteractionEnabled = false
        
        // Add to the view
        addSubview(badgeLabel)
        
        // Store reference to badge for potential future updates
        self.danceUIBadge = badgeLabel
    }

    private func updateDanceUIBadgePosition() {
        guard let badge = danceUIBadge else {
            return
        }
        
        // Position the badge in the top-left corner with some padding
        let badgeSize = badge.bounds.size
        badge.frame = CGRect(x: 0, y: 0, width: badgeSize.width, height: badgeSize.height)
        
        // Ensure the badge is always on top
        bringSubviewToFront(badge)
    }

    weak private var danceUIBadge: UILabel?

#endif // DANCE_UI_INHOUSE || DEBUG
    
    // MARK: Callback
    @objc
    internal func externalEnvironmentDidChange() {
        invalidateProperties(.environment, mayDeferUpdate: true)
    }

    @objc
    internal func contentSizeCategoryDidChange() {
        invalidateProperties(.environment, mayDeferUpdate: true)
    }
    
    open override func didMoveToWindow() {
        if delegate == nil, isWindowRoot {
            if rootViewDelegate == nil {
                rootViewDelegate = RootViewDelegate()
            }
            delegate = rootViewDelegate
        }
        
        if let delegate = delegate {
            delegate.hostingView(self, didMoveTo: window)
        }
        
        if window != nil {
            if DanceUIFeature.gestureContainer.isEnable {
                invalidateProperties(.transform)
            }
            updateRemovedState()
            componentUsageTracker?.launch()
        } else {
            UIApplication.shared._myShims_performBlockAfterCATransactionCommits { [weak self] in
                self?.updateRemovedState()
            }
        }
        
        updateSceneNotifications()
        updateApplicationNotifications()
        requestUpdateForFidelityIfNeeded()
    }
    
    private func updateSceneNotifications() {
        guard useSceneIfAvailable, #available(iOS 13.0, *) else {
            return
        }
        
        let windowScene = window?.windowScene
        
        guard windowScene != observedScene else {
            return
        }
        
        if let observedScene = observedScene {
            NotificationCenter.default.removeObserver(
                self,
                name: UIScene.didEnterBackgroundNotification,
                object: observedScene
            )
            NotificationCenter.default.removeObserver(
                self,
                name: UIScene.didActivateNotification,
                object: observedScene
            )
        }
        
        if let windowScene = windowScene {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneActivationStateDidChange(notification:)),
                name: UIScene.didEnterBackgroundNotification,
                object: windowScene
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneActivationStateDidChange(notification:)),
                name: UIScene.willEnterForegroundNotification,
                object: windowScene
            )
        }
        
        observedScene = windowScene
    }

    /// We have to ship DanceUI to iOS prior to 13.0. In this case,
    /// we use `UIApplication` notification instead of `UIScene` notifications.
    @available(iOS, deprecated: 13.0, message: "Only for shipping DanceUI to iOS prior to 13.0")
    private func updateApplicationNotifications() {
        if useSceneIfAvailable, #available(iOS 13.0, *) {
            return
        }
        
        let hasWindow = window != nil
        
        if !hasWindow {
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.didEnterBackgroundNotification,
                object: UIApplication.shared
            )
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.didBecomeActiveNotification,
                object: UIApplication.shared
            )
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationStateDidChange(notification:)),
                name: UIApplication.didEnterBackgroundNotification,
                object: UIApplication.shared
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationStateDidChange(notification:)),
                name: UIApplication.willEnterForegroundNotification ,
                object: UIApplication.shared
            )
        }
    }
    
    #if DEBUG
    @available(iOS 13.0, *)
    internal func sceneActivationStateDidChangeForTest(notification: Notification) {
        sceneActivationStateDidChange(notification: notification)
    }
    
    internal var latestSceneActivationStateDidChangeNotificationForTest: Notification?
    #endif
    
    // Intentional @available markup
    @available(iOS 13.0, *)
    @objc
    private func sceneActivationStateDidChange(notification: Notification) {
        if notification.name == UIScene.willEnterForegroundNotification {
            isEnteringForeground = true
            onNextMainRunLoop {
                self.isEnteringForeground = false
            }
        }
        requestUpdateForFidelityIfNeeded()
#if DEBUG
        latestSceneActivationStateDidChangeNotificationForTest = notification
#endif
    }
    
    #if DEBUG
    @available(iOS, deprecated: 13.0, message: "Only for shipping DanceUI to iOS prior to 13.0")
    internal func applicationStateDidChangeForTest(notification: Notification) {
        applicationStateDidChange(notification: notification)
    }
    
    internal var latestApplicationStateDidChangeNotificationForTest: Notification?
    #endif

    /// Intentional @available markup
    @available(iOS, deprecated: 13.0, message: "Only for shipping DanceUI to iOS prior to 13.0")
    @objc
    private func applicationStateDidChange(notification: Notification) {
        if notification.name == UIApplication.willEnterForegroundNotification {
            isEnteringForeground = true
            onNextMainRunLoop {
                self.isEnteringForeground = false
            }
        }
        requestUpdateForFidelityIfNeeded()
#if DEBUG
        latestApplicationStateDidChangeNotificationForTest = notification
#endif
    }

    private func requestUpdateForFidelityIfNeeded() {
        if !updatesWillBeVisible {
            clearDisplayLink()
            clearUpdateTimer()
            if layer.needsLayout() {
                allowLayoutWhenNotVisible = true
                return
            }
        }

        if updatesWillBeVisible {
            if requiresUpdateWhenVisible {
                requestImmediateUpdate()
            }
        }
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateBackgroundColor()
        if let transaction = Transaction.currentUIViewTransaction(canDisableAnimations: true) {
            viewGraph.asyncTransaction(transaction, 
                                        mutation: EmptyGraphMutation(),
                                        style: .ignoresFlush,
                                        mayDeferUpdate: true)
        }
        invalidateProperties(.environment, mayDeferUpdate: true)
    }
    
    internal func viewControllerWillAppear(transitionCoordinator: UIViewControllerTransitionCoordinator?, animated: Bool) {
        focusBridge.hostingControllerWillAppear()
        navigationBridge.hostingControllerWillAppear(transitionCoordinator: transitionCoordinator,
                                                     animated: animated)
    }
    
    internal func viewControllerDidAppear(transitionCoordinator: UIViewControllerTransitionCoordinator?, animated: Bool) {
        guard window != nil else {
            runtimeIssue(type: .warning, "the view controller's appearance has changed without its view has been added to a view hierarchy.")
            return
        }
        focusBridge.hostingControllerDidAppear()
        navigationBridge.hostingControllerDidAppear()
    }
    
    internal func viewControllerWillDisappear(transitionCoordinator: UIViewControllerTransitionCoordinator?, animated: Bool) {
        focusBridge.hostingControllerWillDisappear()
        navigationBridge.hostingControllerWillDisappear()
    }
    
    fileprivate func frameDidChange(oldValue: CGRect) {
        guard oldValue.size != bounds.size else {
            return
        }
        if handleSafeAreaInset {
            invalidateProperties([.size, .safeArea], mayDeferUpdate: false)
        } else {
            invalidateProperties([.size], mayDeferUpdate: false)
        }

    }

    // MARK: Override
    open dynamic override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateProperties(.safeArea, mayDeferUpdate: false)
    }
    
    open dynamic override func sizeThatFits(_ size: CGSize) -> CGSize {
        var width: CGFloat? = size.width
        var height: CGFloat? = size.height
        
        if size.width > dimensionExtremum {
            width = nil
        }
        
        if size.height > dimensionExtremum {
            height = nil
        }
        var fittingSize = sizeThatFits(.init(width: width, height: height))
        fittingSize.round(.up, toMultipleOf: viewGraph.environment.pixelLength)
        return fittingSize
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        // PerThreadOSCallback.traceInterval("layoutSubviews", identifier: self) {

        guard needsFidelityUpdate else {
            return
        }

        // Additional filter for bounds.size.isNull. PageView may trigger layout
        // when bounds.size == .zero, causing size/position to compute as NaN
        guard !bounds.size.isNull else {
            return
        }

#if DEBUG || DANCE_UI_INHOUSE
        if shouldCheckHostingControllerExists {
            if pairedHostingController == nil {
                withVaList([]) { args in
                    _danceuiException("UIHostingController.view cannot be taken outside and used standalone.")
                }
            }
        }
#endif
        _danceuiPrecondition(!self.viewGraph.frozen)
        
        Update.withLock {
            cancelAsyncRendering()
            
            let interval: Double
            
            if let displayLink, displayLink.willRender {
                interval = 0
            } else {
                interval = self.renderInterval(timestamp: Time.now) / Double(__MyUIAnimationDragCoefficient())
            }
            
            render(interval: interval)
            
            allowLayoutWhenNotVisible = false

#if DEBUG || DANCE_UI_INHOUSE
            if EnvValue.isResponderNodeVisualDebugEnabled {

                let geometries = (Update.perform({
                    viewGraph.rootResponders
                }) ?? []).map({$0.visualDebugGeometries}).flatMap({$0})

                responderVisualDebugView.frame = bounds
                responderVisualDebugView.geometries = geometries

            } else {

                if isResponderNodeVisualDebugViewLoaded {
                    _responderVisualDebugView?.removeFromSuperview()
                    _responderVisualDebugView = nil
                }

            }
#endif
        }

#if DANCE_UI_INHOUSE || DEBUG
        if DanceUIFeature.badge.isEnable {
            // Update DanceUI badge position
            updateDanceUIBadgePosition()
        }
#endif // DANCE_UI_INHOUSE || DEBUG

        // } end of PerThreadOSCallback.traceInterval("layoutSubviews", identifier: self)
    }

    private var needsFidelityUpdate: Bool {
        if updatesWillBeVisible {
            return canAdvanceTimeAutomatically
        } else {
            return allowLayoutWhenNotVisible
        }
    }

#if DEBUG
    private var _sceneActivationStateForTest: Any? = nil

    @available(iOS 13.0, *)
    internal var sceneActivationStateForTest: UIScene.ActivationState? {
        get {
            guard let value = _sceneActivationStateForTest else {
                return nil
            }
            return value as? UIScene.ActivationState
        }
        set {
            _sceneActivationStateForTest = newValue
        }
    }
#endif

    @available(iOS 13.0, *)
    internal func sceneActivationState(for scene: UIWindowScene) -> UIScene.ActivationState {
#if DEBUG
        if let testValue = sceneActivationStateForTest {
            return testValue
        }
#endif
        return scene.activationState
    }

#if DEBUG
    internal var applicationStateForTest: UIApplication.State? = nil
#endif

    internal func applicationState(for application: UIApplication) -> UIApplication.State {
#if DEBUG
        if let testValue = applicationStateForTest {
            return testValue
        }
#endif
        return application.applicationState
    }
    
    
#if DEBUG
    internal var useSceneIfAvailableForTest: Bool = true
#endif
    
    @inline(__always)
    internal var useSceneIfAvailable: Bool {
#if DEBUG
        return useSceneIfAvailableForTest
#else
        return true
#endif
    }

    internal var updatesWillBeVisible: Bool {
        guard let window = self.window else {
            return false
        }

        if useSceneIfAvailable, #available(iOS 13.0, *) {
            // DanceUI currently does not support UIScene (which requires AppGraph).
            // This function always returns true.
            guard let windowScene = window.windowScene else {
                // For host apps that don't use `UISceneDelegate` but
                // `UIApplicationDelegate`, `window?.windowScene` may be `nil`
                // when the app is in foreground.
                if applicationState(for: UIApplication.shared) != .background {
                    return true
                }

                if isEnteringForeground {
                    return true
                }

                return false
            }
            
            let environment = masterEnvironment
            
            let scenePhase = environment.scenePhase
            
            if sceneActivationState(for: windowScene) != .background {
                return true
            }
            
            if isEnteringForeground {
                return true
            }
            
            if scenePhase != .background {
                return true
            }
            
            return false
        } else {
            // On iOS prior to 13.0, we use UIApplication's `applicationState`
            // instead of UIWindowScene's `activationState`.
            if applicationState(for: UIApplication.shared) != .background {
                return true
            }
            
            if isEnteringForeground {
                return true
            }
            
            return false
        }
    }
    
    internal func cancelAsyncRendering() {
        Update.withLock {
            displayLink?.setCancelled()
        }
    }
    
    // iOS13 之前是 geometryChanges
    @objc(my_geometryChanges:forAncestor:)
    internal func my_geometryChanges(_: [AnyHashable : Any], forAncestor: UIView?) {
        // iOS 15.5 verified
        invalidateProperties(.transform, mayDeferUpdate: false)
    }
    
    // iOS14 变成了 geometryChanged
    @objc(my_geometryChanged:forAncestor:)
    internal func my_geometryChanged(_: UnsafeRawPointer, forAncestor: UIView?) {
        // iOS 15.5 verified
        if DanceUIFeature.gestureContainer.isEnable {
            if registeredForGeometryChanges {
                invalidateProperties(.transform, mayDeferUpdate: false)
            } else {
                LogService.debug(module: .hosting, keyword: .view, "com.bytedance.DanceUI.AsyncRenderer Received _geometryChanged with no registration.", info: [
                    "view" : _typeName(Self.self),
                    "object" : Unmanaged.passUnretained(self).toOpaque(),
                ])
            }
        } else {
            invalidateProperties(.transform, mayDeferUpdate: false)
        }
    }
    
    open override func my_insertRenderedSubview(_ subview: UIView, at index: Int) {
        isInsertingRenderedSubview = true
        defer {
            isInsertingRenderedSubview = false
        }
        self.insertSubview(subview, at: index)
    }
    
    @_implementationOnly
    open override func my__axesForDerivingIntrinsicContentSizeFromLayoutSize() -> Int32 {
        return 0x3;
    }
    
    @_implementationOnly
    open override func my__layoutHeightDependsOnWidth() -> Bool {
        return true
    }
    
    @_implementationOnly
    open override func my__baselineOffsets(at size: CGSize) -> MyUIKitBaselineOffset {
        var proposedSize = size
        if size == .zero {
            proposedSize = sizeThatFits(_ProposedSize.unspecified)
        }
        
        let defaultValue = CGFloat(Float64.leastNonzeroMagnitude)
        
        let firstBaselineOffsetOrNil = explicitAlignment(of: .firstTextBaseline, at: proposedSize)
        let lastBaselineOffsetOrNil = explicitAlignment(of: .lastTextBaseline, at: proposedSize)
        
        let firstBaselineOffset = firstBaselineOffsetOrNil ?? defaultValue
        let lastBaselineOffset = lastBaselineOffsetOrNil == nil ? defaultValue : proposedSize.height - lastBaselineOffsetOrNil!
        
        return MyUIKitBaselineOffset(firstTextBaselineOffset: firstBaselineOffset,
                                          lastTextBaselineOffset: lastBaselineOffset)
    }
    
    @_implementationOnly
    open override func my__didChange(toFirstResponder responder: UIResponder?) {
        focusBridge.firstResponderDidChange(to: responder, rootResponder: responderNode)
    }
    
    open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        focusBridge.didUpdateFocus(in: context, with: coordinator)
    }
    
    @_implementationOnly
    open override func my__forwardingTarget() -> _MyTSHostingViewInvocationTarget {
        _forwardingTarget
    }
    
    open override dynamic var canBecomeFirstResponder: Bool {
        let hasResponderCommands = currentResponderCommands.count > 0
        let result = hasResponderCommands || focusBridge.acceptsFirstResponder
        return result
    }
    
    open override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        let responderAction = self.responderAction(for: action)
        if responderAction == nil || super.responds(to: action) {
            return super.target(forAction: action, withSender: responderAction)
        }
        
        return _forwardingTarget
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if super.canPerformAction(action, withSender: sender) {
            return true
        }

        return responderAction(for: action) != nil
    }
    
    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if responderAction(for: aSelector) == nil || super.responds(to: aSelector) {
            return super.forwardingTarget(for: aSelector)
        }

        return _forwardingTarget
    }
    
    open override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        
        return responderAction(for: aSelector) != nil
    }
    
    open override func tintColorDidChange() {
        contentSizeCategoryDidChange()
    }
    
    // MARK: Keyboard
    internal var shouldAddKeyboardToSafeAreaInsets: Bool {
        // Check if window is on main screen
        guard let selfWindow = window?.screen else {
            return false
        }
        guard selfWindow == UIScreen.main else {
            return false
        }
        // end
        
        // First check if superview is not nil, otherwise return false
        guard var currentView = self.superview else {
            return false
        }

        // Then recursively check if superview is UITextEffectsWindow or UIScrollView, return if so
        // If superview becomes nil, return true
        while let superview = currentView.superview {
            if let textEffectsWindowClass = Static.textEffectWindowClass, type(of: superview) == textEffectsWindowClass {
                return false
            }
            
            if superview is UIScrollView {
                return false
            }
            
            currentView = superview
        }
        
        return true
    }
    
    @objc(keyboardWillHideWithNotification:)
    internal func keyboardWillHide(note: Notification) {
        self.keyboardSeed &+= 1
        let keyboardSeed = self.keyboardSeed
        
        if let uiViewController = self.viewController, !uiViewController.hasAppeared {
            setKeyboardFrame(nil, seed: keyboardSeed)
        } else if updatesWillBeVisible, let animation = note.keyboardAnimation, viewGraph.isInstantiated {
            var transaction = Transaction()
            transaction.animation = animation
            let mutation = CustomGraphMutation { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.setKeyboardFrame(nil, seed: keyboardSeed)
            }
            viewGraph.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
        } else {
            setKeyboardFrame(nil, seed: keyboardSeed)
        }
    }
    
    @objc(keyboardWillShowWithNotification:)
    internal func keyboardWillShow(note: Notification) {
        self.keyboardSeed &+= 1
        let keyboardSeed = self.keyboardSeed
        
        let frame: CGRect?
        if shouldAddKeyboardToSafeAreaInsets,
            let keyboardFrame = note.keyboardFrame {
            frame = keyboardFrame
        } else {
            frame = nil
        }
        
        if let uiViewController = self.viewController, !uiViewController.hasAppeared {
            setKeyboardFrame(frame, seed: keyboardSeed)
        } else if let animation = note.keyboardAnimation, viewGraph.isInstantiated {
            var transaction = Transaction()
            transaction.animation = animation
            let mutation = CustomGraphMutation { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.setKeyboardFrame(frame, seed: keyboardSeed)
            }
            viewGraph.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
        } else {
            setKeyboardFrame(frame, seed: keyboardSeed)
        }
    }
    
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(note:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func removeKeyboardObserver() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
#if DEBUG
    private func printKeyboardNotification(_ notification: NSNotification, function: StaticString = #function) {
        guard let userInfo = notification.userInfo else {
            return
        }
        print("[\(Self.self)] \(function) \(notification.name.rawValue) BEGIN")
        let indices = userInfo.indices.sorted(by: {userInfo[$0].key.description < userInfo[$1].key.description})
        for index in indices {
            print("[\(Self.self)] \(function) \(userInfo[index].key): \(userInfo[index].value)")
        }
        print("[\(Self.self)] \(function) \(notification.name.rawValue) END")
    }
#endif

    open override func accessibilityElementCount() -> Int {
        accessibilityElements?.count ?? 0
    }
    
    open override var accessibilityElements: [Any]? {
        get {
            if !accessibilityEnabled {
                enableAccessibility()
            }
            let layoutDirection = effectiveUserInterfaceLayoutDirection
            return accessibilityNodes.sorted(with: LayoutDirection(layoutDirection)).map { node in
                switch node.attachment {
                case .properties:
                    node.accessibilityContainer = self
                    return node
                case .platform(_ , let object, _):
                    let obj = object as! NSObject
                    obj.accessibilityContainer = self
                    return obj
                }
            }
        }
        set {
            _intentionallyLeftBlank()
        }
    }

    // internal func accessibilityFocus(id: AnyHashable, in: Namespace.ID)
    
    internal func enableAccessibility() {
        guard !accessibilityEnabled else {
            return
        }
        NSObject.swizzledMethods()
        accessibilityEnabled = true
        invalidateProperties(.environment, mayDeferUpdate: true)
        updateParentAccessibilityElement()
        
        for node in accessibilityNodes {
            node.updatePlatformProperties(includingRelations: true)
        }
        
        if !Accessibility.enabledGlobally {
            Accessibility.enabledGlobally = true
            NotificationCenter.default.post(
                name: UIAccessibility.differentiateWithoutColorDidChangeNotification,
                object: Accessibility.self
            )
        }
        
        Accessibility.Notification.LayoutChanged().post()
    }
    
    internal func updateParentAccessibilityElement() {
        guard accessibilityEnabled, let parentAccessibilityElement = parentAccessibilityElement else {
            return
        }
        guard let node = accessibilityElements?.first as? AccessibilityNode else {
            return
        }
        
        node.applyExternalProperties(to: parentAccessibilityElement)
    }
    
    // Temporary shadow function for invalidateIntrinsicContentSize to avoid extra cost from calls in other places that have been removed in higher versions
    internal func shadowInvalidateIntrinsicContentSize() {
        _intentionallyLeftBlank()
    }
    
    // MARK: UIHostingView Track Enable
    internal var isTrackVisible: Bool { true }

    // MARK: Unclassfied
    
    
    internal func updateRemovedState() {
        var removedState = GraphHost.RemovedState()
        
        if self.window == nil {
            removedState.insert(.noWindow)
        }
        
        if isHiddenForReuse {
            removedState.insert(.hiddenForReuse)
        }
        
        Update.ensure {
            self.viewGraph.setRemovedState(removedState)
        }
        
    }
    
    internal func updatePreferences() {
        guard !pendingPreferencesUpdate else {
            return
        }
        var renderInterval = self.renderInterval(timestamp: .now)
        let coefficient = __MyUIAnimationDragCoefficient()
        renderInterval /= Double(coefficient)
        render(interval: renderInterval, updateDisplayList: false)
    }
    
    
    internal func setRootView(_ rootView: Content, transaction: Transaction) {
        _rootView = rootView
    }
    
    internal func makeRootView() -> HostingRootViewType {
        let rootView = self._rootView
        
        let modifier = EditModeScopeModifier(editMode: .default)
        let modifiedContent = rootView.modifier(modifier)
        return _UIHostingView.makeRootView(view: modifiedContent)
    }
    
    fileprivate func updateBackgroundColor() {
        guard self.viewController != nil else {
            return
        }
        
        let backgroundColor: UIColor
        if #available(iOS 13.0, *) {
            backgroundColor = UIColor.systemBackground
        } else {
            backgroundColor = UIColor.white
        }
        
        self.setBackground(color: backgroundColor)
    }
    
    fileprivate func setBackground(color: UIColor) {
        guard !disabledBackgroundColor else {
            return
        }
        
        super.backgroundColor = color
    }
    
    
    internal func setPreferenceBridge(_ preferenceBridge: PreferenceBridge) {
        guard viewGraph.preferenceBridge !== preferenceBridge else {
            return
        }
        
        viewGraph.preferenceBridge = preferenceBridge
    }
    
    // MARK: Render
    
    
    fileprivate func renderInterval(timestamp: Time) -> Double {
        if lastRenderTime == .zero || lastRenderTime > timestamp {
            self.lastRenderTime = timestamp - .microseconds(1)
        }
        let interval = timestamp - lastRenderTime
        lastRenderTime = timestamp
        return interval.seconds
    }
    
    
    internal func requestImmediateUpdate() {
        cancelAsyncRendering()
        
        if updatesWillBeVisible {
            setNeedsLayout()
            requiresUpdateWhenVisible = false
        } else {
            requiresUpdateWhenVisible = true
            guard !pendingPreferencesUpdate else {
                return
            }
            
            pendingPreferencesUpdate = true
            DispatchQueue.main.async(group: nil, qos: .unspecified, flags: []) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.pendingPreferencesUpdate = false
                strongSelf.updatePreferences()
            }
        }
    }
    
    
    internal func startUpdateTimer(delay: Double) {
        if !Thread.isMainThread {
            displayLink?.setCancelled()
            Update.syncMain {
                startUpdateTimer(delay: delay)
            }
        } else {
            cancelAsyncRendering()
            let delay = max(delay, 0.1)
            let scheduledUpdateTime = currentTimestamp.advanced(by: delay)
            
            guard (nextTimerTime ?? Time.distantFuture) > scheduledUpdateTime else {
                return
            }
            
            updateTimer?.invalidate()
            
            nextTimerTime = scheduledUpdateTime
            
            updateTimer = withDelay(delay) { [unowned self] in
                updateTimer = nil
                nextTimerTime = nil
                requestImmediateUpdate()
            }
        }
    }
    
    internal var updatesAtFullFidelity: Bool {
        updatesWillBeVisible
    }
    
    
    internal func startDisplayLink(delay: Double) {
        ensureDisplayLinkIfNecessary()
        
        if let displayLink = displayLink {
            let interval = viewGraph.nextUpdate.views.interval
            let reasons = viewGraph.nextUpdate.views.reasons
            displayLink.setNextUpdate(delay: delay, interval: interval, reasons: reasons)
            clearUpdateTimer()
        } else {
            startUpdateTimer(delay: delay)
        }
    }
    

    @inline(__always)
    private func ensureDisplayLinkIfNecessary() {
        guard displayLink == nil, updatesAtFullFidelity, let window = window else {
            return
        }
        
        displayLink = DisplayLink(host: self, window: window)
    }
    
    
    internal func clearUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        nextTimerTime = nil
    }
    
    internal func clearDisplayLink() {
        cancelAsyncRendering()
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: Safe-Area Insets
    
    // didUpdateFocus
    // _forwardingTarget
    // _childFocusRegions
    
    internal var hostSafeAreaElements: [SafeAreaInsets.Element] {
        let isLeftToRight = viewGraph.environment.layoutDirection == .leftToRight
        let safeAreaInsets = self.safeAreaInsets
        let top = safeAreaInsets.top
        var bottom = safeAreaInsets.bottom
        let left = isLeftToRight ? safeAreaInsets.left : safeAreaInsets.right
        let right = isLeftToRight ? safeAreaInsets.right : safeAreaInsets.left
        var elements: [SafeAreaInsets.Element] = []
        
        // space: When keyboard appears, the difference between the bottom of this view and the top of the keyboard
        var space: CGFloat = 0
        if let keyboardFrame = self.keyboardFrame {
            // Landscape example: frame: (0, 166, 812, 209), rect: (0, 0, 812, 375), rect.maxY = 375, keyboard.minY = 166, return 209
            let rect = convert(self.bounds, to: nil)
            space = rect.maxY - keyboardFrame.minY
        }
        
        if space >= bottom {
            // Keyboard is shown and space is not less than bottom
            space = space - bottom
            if let element = _safeAreaElementFromEdgeInsets(top: top,
                                                            leading: left,
                                                            bottom: bottom,
                                                            trailing: right,
                                                            regions: .container) {
                elements.append(element)
            }
            
            if let element = _safeAreaElementFromEdgeInsets(top: 0,
                                                            leading: 0,
                                                            bottom: space,
                                                            trailing: 0,
                                                            regions: .keyboard) {
                elements.append(element)
            }
        } else {
            bottom = bottom - space
            if let element = _safeAreaElementFromEdgeInsets(top: 0,
                                                            leading: 0,
                                                            bottom: space,
                                                            trailing: 0,
                                                            regions: [.keyboard, .container]) {
                elements.append(element)
            }
            
            // Most common case: when keyboard is not shown, space is zero, returns edgeInsets
            if let element = _safeAreaElementFromEdgeInsets(top: top,
                                                            leading: left,
                                                            bottom: bottom,
                                                            trailing: right,
                                                            regions: .container) {
                elements.append(element)
            }
            
        }
        return elements
    }
    
    @inline(__always)
    private func _safeAreaElementFromEdgeInsets(top: CGFloat,
                                                leading: CGFloat,
                                                bottom: CGFloat,
                                                trailing: CGFloat,
                                                regions: SafeAreaRegions) -> SafeAreaInsets.Element? {
        let edgeInsets = EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        guard edgeInsets != .zero else {
            return nil
        }
        return SafeAreaInsets.Element(regions: regions, insets: edgeInsets)
    }
    
    // MARK: Target & Action
    
    fileprivate func responderAction(for aSelector: Selector?) -> CommandAction? {
        guard let selector = aSelector else {
            return nil
        }
        
        guard let commandAction = self.currentResponderCommands[selector] else {
            return nil
        }
        
        return commandAction
    }
    
    // MARK: For Debug & Test

    @objc
    internal func makeViewDebugData() -> Data? {
        return nil
    }

    internal func setTestSafeAreaInsets(edgeInsets: EdgeInsets) {
        explicitSafeAreaInsets = edgeInsets
    }
    
    // MARK: AnyUIHostingView
    
    
    internal func displayLinkTimer(timestamp: Time, isAsyncThread: Bool) {
        clearUpdateTimer()
        let interval = renderInterval(timestamp: timestamp) / Double(__MyUIAnimationDragCoefficient())
        
        if isAsyncThread {
            if let renderedTime = renderAsync(interval: interval) {
                if renderedTime.seconds > 0 || renderedTime.seconds.isNaN {
                    /// 1.0e-06
                    let d1Eminus06 = Double(bitPattern: 0x3eb0_c6f7_a0b5_ed8)
                    let delay = max(interval - currentTimestamp.seconds, d1Eminus06)
                    requestUpdate(after: delay)
                }
                if !viewGraph.updateRequiredMainThread, let displayLink = displayLink {
                    displayLink.setCancelled()
                }
            } else {
                displayLink?.setCancelled()
                requestUpdate(after: 0)
            }
        } else {
            render(interval: interval)
            if let displayLink = displayLink,
                displayLink.willRender,
                !viewGraph.updateRequiredMainThread {
                displayLink.setBegan()
            }
        }
    }
    
    // MARK: GraphDelegate
    
    
    internal func preferencesDidChange() {
        let preferenceList = viewGraph.preferenceValues()

        alertBridge.preferencesDidChange(preferencesList: preferenceList)

        actionSheetBridge.preferencesDidChange(preferencesList: preferenceList)

        sheetBridge.preferencesDidChange(preferenceList)

        inspectorBridge?.preferencesDidChange(preferenceList)

        navigationBridge.preferencesDidChange(preferenceList: preferenceList)

        focusBridge.preferencesDidChange(preferenceList)

        delegate?.hostingView(self, didChangePreferences: preferenceList)
        return
    }

    // MARK: ViewGraphDelegate

    internal func `as`<OtherType>(_ otherType: OtherType.Type) -> OtherType? {
        if ObjectIdentifier(otherType) == ObjectIdentifier(EventGraphHost.self) {
            return self as? OtherType
        }
        if ObjectIdentifier(otherType) == ObjectIdentifier(ViewRendererHost.self) {
            return self as? OtherType
        }
        if ObjectIdentifier(otherType) == ObjectIdentifier(CurrentEventProvider.self) {
            return self as? OtherType
        }
        if ObjectIdentifier(otherType) == ObjectIdentifier(UIView.self) {
            return self as? OtherType
        }
        return nil
    }
    
    internal func modifyViewInputs(_ inputs: inout _ViewInputs) {
        if inputs[InterfaceIdiom.Input.self] == nil {
            
            var updatedIdiom: AnyInterfaceIdiomType?
            
            Update.syncMain {
                updatedIdiom = self.traitCollection.userInterfaceIdiom.idiom
            }
            
            if let updatedIdiom = updatedIdiom {
                inputs[InterfaceIdiom.Input.self] = updatedIdiom
            }
        }
    }
    
    internal func outputsDidChange(outputs: ViewGraph.Outputs) {
        if outputs.contains(.needHandlePlatformItemList) {
            delegate?.hostingView(self, didChangePlatformItemList: viewGraph.platformItemList())
        }
        
        if outputs.contains(.needHandleAccessibilityNodes), accessibilityEnabled {
            updateParentAccessibilityElement()
            for node in accessibilityNodes {
                node.updatePlatformProperties(includingRelations: true)
            }
            Accessibility.Notification.Info().post(name: .layoutChanged)
        }
    }
    
    internal func focusDidChange() {
        focusBridge.focusDidChange(rootResponder: responderNode)
    }
    
    
    internal func rootTransform() -> ViewTransform {
        var rootTransform = ViewTransform()
        
        if DanceUIFeature.gestureContainer.isEnable {
            if !registeredForGeometryChanges {
                registeredForGeometryChanges = true
                my__registerForGeometryChanges()
            }
        }
        
        // Append the transform in the window
        withUnsafeMutablePointer(to: &rootTransform) { rootTransform in
            func appendTransform(_ context: UnsafeMutableRawPointer,
                                 _ transform3DPtr: UnsafePointer<CATransform3D>,
                                 _ inverse: Bool) {
                let transform3D = transform3DPtr.pointee
                let rootTransform = context.assumingMemoryBound(to: ViewTransform.self)
                if CATransform3DIsIdentity(transform3D) {
                    return
                } else if !CATransform3DIsAffine(transform3D) {
                    let projectionTransform = ProjectionTransform(transform3D)
                    rootTransform.pointee.appendProjectionTransform(projectionTransform, inverse: inverse)
                } else {
                    let transform = CATransform3DGetAffineTransform(transform3D)
                    if transform.isTranslation {
                        rootTransform.pointee.appendTranslation(CGSize(width: transform.tx, height: transform.ty))
                    } else {
                        rootTransform.pointee.appendAffineTransform(transform, inverse: inverse)
                    }
                }
            }
            
            MyCALayerMapGeometry(
                window?.layer,
                self.layer,
                { (context, transform3D) in
                    appendTransform(context, transform3D, true)
                },
                { (context, transform3D) in
                    appendTransform(context, transform3D, false)
                },
                rootTransform
            )
        }
        
        // Append hosting view coordinate space
        rootTransform.appendCoordinateSpace(name: HostingViewCoordinateSpace())
        
        return rootTransform
    }
    
    internal func hostingType() -> String {
        "<\(_typeName(Content.self, qualified: false))>"
    }

    internal func hostingState() -> String {
        ""
    }

    // MARK: ViewRendererHost
    
    internal func addImplicitPropertiesNeedingUpdate(to: inout ViewRendererHostProperties) {
        _intentionallyLeftBlank()
    }
    
    internal func updateRootView() {
        let rootView = makeRootView()
        viewGraph.setRootView(rootView)
    }
    
    // swift-format-ignore: NoBlockComments
    internal func updateEnvironment() {

        checkInconsistentPreferenceBridge()

        let (inheritedEnvironment, inheritedViewPhase) = overridenMasterEnvironmentAndViewPhase
        
        var resolvedEnvironment = inheritedEnvironment
        
        if tintAdjustmentMode == .dimmed {
            resolvedEnvironment.tintAdjustmentMode = .desaturated
        }
        
        if resolvedEnvironment.accessibilityInvertColors {
            resolvedEnvironment.ignoreInvertColorsFilterActive = ancestorHasInvertFilterApplied
        }
        
        delegate?.hostingView(self, willUpdate: &resolvedEnvironment)
        
        if #available(iOS 13.0, *) {
            resolvedEnvironment.sceneSession = window?.windowScene?.session ?? nil
        }
        
        if invertLayoutDirection {
            resolvedEnvironment.layoutDirection = .rightToLeft
        }
        resolvedEnvironment.undoManager = self.undoManager
        
        let openURLAction: OpenURLAction = OpenURLAction(handler: {[weak self] url, completion in
            guard let self = self else {
                return
            }
            if #available(iOS 13.0, *) {
                if let windowScene = self.window?.windowScene {
                    windowScene.open(url, options: .none, completionHandler: completion)
                } else {
                    UIApplication.shared.open(url, options: [:], completionHandler: completion)
                }
            } else {
                UIApplication.shared.open(url, options: [:], completionHandler: completion)
            }
        }, isDefault: false)
        
        resolvedEnvironment.openURL = openURLAction
        
        if let tintColor = self.tintColor,
           let resolvedTintColor = Color.Resolved(tintColor) {
            resolvedEnvironment.accentColor = Color(resolvedTintColor)
        }
        
        resolvedEnvironment.accessibilityEnabled = accessibilityEnabled
        
        resolvedEnvironment.accessibilityEnabled = accessibilityEnabled
        
        /*
        let focusAction: ((AnyHashable, Namespace.ID) -> ())?
        if accessibilityEnabled {
            focusAction = { [weak self] (id: AnyHashable, namespace: Namespace.ID) in
                self?.accessibilityFocus(id: id, in: namespace)
            }
        } else {
            focusAction = nil
        }
        
        resolvedEnvironment.requestAccessibilityFocus = AccessibilityRequestFocusAction(onAccessibilityFocus: focusAction)
         */
        
        navigationBridge.update(environment: &resolvedEnvironment)
        /*
         toolbarCoordinator.update(in: resolvedEnvironment)
         
         if let contextMenuBridge = contextMenuBridge {
         contextMenuBridge.update(environment: &resolvedEnvironment)
         }
         */
        
        focusBridge.updateEnvironment(&resolvedEnvironment)
        
        /*
         toolBarBridge.update(environment: resolvedEnvironment)
         
         */
        
        alertBridge.update(environment: resolvedEnvironment)
        actionSheetBridge.update(environment: resolvedEnvironment)
        sheetBridge.update(environment: &resolvedEnvironment)
        
        viewGraph.setEnvironment(values: resolvedEnvironment)
        viewGraph.setPhase(phase: inheritedViewPhase)
        
        delegate?.hostingView(self, didUpdate: &resolvedEnvironment)
        
        if let environmentPreferenceBridge = resolvedEnvironment.preferenceBridge,
           viewGraph.preferenceBridge !== environmentPreferenceBridge {
            viewGraph.isUnlikelyToBeUninstantiated = true
            // Potential view graph uninstantiation may cause crashes
            viewGraph.preferenceBridge = environmentPreferenceBridge
            viewGraph.isUnlikelyToBeUninstantiated = false
        }
    }
    
    internal static func updateEnvironment(_ viewGraph: ViewGraph, traitCollection: UITraitCollection) {

        let resolvedEnvironment = traitCollection.resolvedEnvironment(base: traitCollection.baseEnvironment)
        
        viewGraph.setEnvironment(values: resolvedEnvironment)
        viewGraph.setPhase(phase: traitCollection.viewPhase)
        
        if let environmentPreferenceBridge = resolvedEnvironment.preferenceBridge,
           viewGraph.preferenceBridge !== environmentPreferenceBridge {
            viewGraph.isUnlikelyToBeUninstantiated = true
            // Potential view graph uninstantiation may cause crashes
            viewGraph.preferenceBridge = environmentPreferenceBridge
            viewGraph.isUnlikelyToBeUninstantiated = false
        }
    }
    
    internal func updateFocusedItem() {
        viewGraph.setFocusedItem(focusedItem)
    }
    
    internal func updateFocusedValues() {
        viewGraph.setFocusedValues(focusedValues: focusedValues)
    }
    
    internal func updateTransform() {
        if DanceUIFeature.gestureContainer.isEnable {
            guard viewGraph.invalidateTransform() else {
                if registeredForGeometryChanges {
                    my__unregisterForGeometryChanges()
                    registeredForGeometryChanges = false
                }
                return
            }
        } else {
            viewGraph.invalidateTransform()
        }
        
        inspectorBridge?.transformDidChange()
        if keyboardFrame != nil {
            safeAreaInsetsDidChange()
        }
        
        guard handleSafeAreaInset, explicitSafeAreaInsets != nil else {
            return
        }
        
        invalidateProperties(.safeArea, mayDeferUpdate: false)
    }
    
    internal func updateSize() {
        viewGraph.setProposedSize(self.bounds.size)
    }
    
    internal func updateSafeArea() {
        guard viewGraph.setSafeAreaInsets(hostSafeAreaElements) == true else {
            return
        }
        self.invalidateIntrinsicContentSize()
        self.shadowInvalidateIntrinsicContentSize()
    }
    
    internal func updateFocusStore() {
        viewGraph.setFocusStore(focusBridge.currentFocusStore)
    }

    internal var willRenderDeferedUpdates: Bool {
        viewGraph.mayDeferUpdate && displayLink?.willRender == true
    }
    
    
    internal func requestUpdate(after limitTime: Double) {
        // PerThreadOSCallback.traceEvent("request update: limitTime = \(limitTime)", identifier: self)
        
        Update.withLock {
            if limitTime != 0 || willRenderDeferedUpdates {
                let coefficient = __MyUIAnimationDragCoefficient()
                let delay = limitTime * Double(coefficient)
                if delay >=  0.25 {
                    startUpdateTimer(delay: delay)
                } else {
                    startDisplayLink(delay: delay)
                }
            } else {
                DispatchQueue.performOnMainQueue {
                    self.requestImmediateUpdate()
                }
            }
        }
    }
    
    
    internal func renderDisplayList(_ displayList: DisplayList, asynchronously: Bool, time: Time, nextTime: Time, version: DisplayList.Version, maxVersion: DisplayList.Version) -> Time {
        
        if asynchronously,
           let renderedTime = renderer.renderAsync(to: displayList, time: time, version: version, maxVersion: maxVersion) {
            return renderedTime
        }
        
        var renderedTime: Time = time
        
        Update.syncMain {
            let scale = window?.screen.scale ?? 1
            renderedTime = renderer.render(
                rootView: self,
                from: displayList,
                time: renderedTime,
                nextTime: nextTime,
                version: version,
                maxVersion: maxVersion,
                contentsScale: scale
            )
        }
        
        return renderedTime
    }
    
    internal func didRender() {
        #warning("UIKitContentScrollViewBridge.didRender()")
    }
    
    internal func focusResponder(for item: FocusItem) -> FocusResponder? {
        return nil
    }

    internal func focus(item: FocusItem) {
    }

    internal var focusedItem: FocusItem? {
        focusBridge.focusedItem
    }

    internal func invalidateHoverState() {
    }

    // From EventGraphHost
    internal var focusedResponder: ResponderNode? {
        focusBridge.focusedResponder
    }
    
    internal var uiViewController: UIViewController? {
        self.viewController
    }
    
    // MARK: Gesture Observers

    /// The storage of `gestureRecognizerObservers` retained by this
    /// `_UIHostingView`.
    fileprivate var localGestureObservers: GestureObservers = GestureObservers()

    public var gestureObservers: GestureObservers {
        get {
            updateViewGraph { viewGraph in
                viewGraph.gestureObservers
            }
        }
        set {
            localGestureObservers = newValue
            invalidateProperties(.gestureObservers)
        }
    }

    @inline(__always)
    internal var inheritedGestureRecognizerObservers: GestureObservers {
        traitCollection.baseGestureRecognizerObservers
    }
    
    /// Synthesizing inherited gesture recognizer observers and local
    /// gesture recognizer observers.
    internal func updateGestureObservers() {
        viewGraph.gestureObservers = inheritedGestureRecognizerObservers.merged(with: localGestureObservers)
    }
    
    // MARK: Environment


    /// `EnvironmentValues` masters the update of this `_UIHostingView`. The
    /// `EnvironmentValues` could be `_UIHostingView.inheritedEnvironment` or
    /// fetched from `UIView.traitCollection`.
    private var masterEnvironment: EnvironmentValues {
        inheritedEnvironment ?? traitCollection.baseEnvironment
    }

    @inline(__always)
    internal var overridenMasterEnvironmentAndViewPhase: (environmentValues: EnvironmentValues, viewPhase: _GraphInputs.Phase) {
        let overridenEnvironment = masterEnvironment
            .byOverriding(with: environmentOverride)
            .withTracker(self.tracker)
        let traitCollection = self.traitCollection
        let resolvedEnvironment = traitCollection.resolvedEnvironment(base: overridenEnvironment)
        return (resolvedEnvironment, traitCollection.viewPhase)
    }
    
    // MARK: UIKitEventGraphHost

    internal var rootGestureRecognitionWitness: GestureRecognitionWitness? {
        updateViewGraph { viewGraph in
            viewGraph.rootGestureRecognitionWitness
        }
    }

    internal var gestureRecognizerList: PlatformGestureRecognizerList? {
        updateViewGraph { viewGraph in
            viewGraph.gestureRecognizerList
        }
    }

    // MARK: Responder Node Visual Debug

    private var _responderVisualDebugView: ResponderVisualDebugView?

    internal var responderVisualDebugView: ResponderVisualDebugView {
        if let view = _responderVisualDebugView {
            return view
        } else {
            let view = ResponderVisualDebugView()
            addSubview(view)
            _responderVisualDebugView = view
            return view
        }
    }

    internal var isResponderNodeVisualDebugViewLoaded: Bool {
        _responderVisualDebugView != nil
    }

    // MARK: DanceUI Preview Support

    /// Probably migrated from PreviewHost in iOS 14.3
    internal func invalidateEverything() {
        self.viewGraph.invalidateAllValues()
    }

    // Used for usage tracking and reporting
    private lazy var componentUsageTracker: ComponentUsageTracker? = {
        guard DanceUIFeature.componentUsageTraceEnable.isEnable else {
            return nil
        }
        return .init(componentName: "DanceUI", tag: _typeName(type(of: self)), params: ["root_view": usageTrackRootViewName])
    }()
    
    internal var usageTrackRootViewName: String {
        if let anyView = _rootView as? AnyView {
            return _typeName(anyView.storage.type)
        }
        return _typeName(Content.self)
    }
}

private struct Static {
    private static let textEffectWindowClassName: String = [
        "UI", "Text", "Effects", "Window"
    ].joined()
    static let textEffectWindowClass: AnyClass? = NSClassFromString(textEffectWindowClassName)
}

private enum GestureContainerProbingResult {
    
    case gestureContainer(UIView)
    case view(UIView)
    
}

@available(iOS 13.0, *)
extension UIWindow {
    
    internal var appliedDoubleInvertFilter: Bool {
        let isDarkWindow = my__accessibilityInvertColorsIsDarkWindow()
        let supportsDarkWindowInvert = my__accessibilityInvertColorsSupportsDarkWindowInvert()
        return isDarkWindow && supportsDarkWindowInvert
    }
    
}

@available(iOS 13.0, *)
internal protocol CommandAction {
    
    func perform()
    
}

#if FEAT_HOSTING_VC_FOR_CELL
@available(iOS 13.0, *)
extension _UIHostingView {

    public func _wrapPreferenceBridge(_ preferenceBridge: AnyObject?) {
        var environmentOverride = environmentOverride ?? EnvironmentValues()
        environmentOverride.preferenceBridge = preferenceBridge as? PreferenceBridge
        self.environmentOverride = environmentOverride
    }
    
}
#endif

@available(iOS 13.0, *)
extension Notification {
    
    fileprivate var keyboardFrame: CGRect? {
        guard let info = userInfo,
              let anyFrame = info[UIResponder.keyboardFrameEndUserInfoKey],
              let frameValue = anyFrame as? NSValue else {
            return nil
        }
        
        return frameValue.cgRectValue
    }
    
    fileprivate var keyboardAnimation: Animation? {
        guard let info = userInfo,
              let anyDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey],
              let duration = anyDuration as? Double,
              let anyCurve = info[UIResponder.keyboardAnimationCurveUserInfoKey],
              let curve = anyCurve as? Int else {
            return nil
        }
        
        return Animation.uiViewAnimation(curve: curve, duration: duration)
    }
    
}

internal let dimensionExtremum: CGFloat = 2.77778e+06

@_spi(DanceUIExtension)
public protocol HostingViewUpdateEnvironmentable {
    
    @available(iOS 13.0, *)
    func updateEnvironments(_ body: (inout EnvironmentValues) -> Void)
}

@_spi(DanceUIExtension)
@available(iOS 13.0, *)
extension _UIHostingView: HostingViewUpdateEnvironmentable {
    
    public func updateEnvironments(_ body: (inout EnvironmentValues) -> Void) {
        var environment = self.environmentOverride ?? EnvironmentValues()
        body(&environment)
        self.environmentOverride = environment
        self.invalidateProperties(.environment)
    }
}

/// This gesture recognizer offers UIKit-gesture-graph-independent timing that
/// DanceUI without gesture-container does.
///
private class IndependentGestureRecognizer: UIGestureRecognizer {
    
    fileprivate weak var viewGraph: ViewGraph?
    
    fileprivate init(viewGraph: ViewGraph) {
        self.viewGraph = viewGraph
        super.init(target: nil, action: nil)
        self.allowedPressTypes = UIPress.PressType.allValues.map { NSNumber(value: $0.rawValue) }
        self.delaysTouchesEnded = false
    }
    
    fileprivate override func reset() {
        viewGraph?.updateResponders()
    }
    
}

@available(iOS 13.0, *)
internal enum HostingLogKeyword: String, LogKeyword {
    
    case view
    
    internal static var moduleName: String { "Hosting" }
}

@available(iOS 13.0, *)
extension LogService.Module where K == HostingLogKeyword {
    
    internal static let hosting: Self = .init()
    
}

// _UIHostingView is a generic class that cannot declare stored
// properties.

@available(iOS 13.0, *)
private struct HitTestLogEnabledKey: DefaultFalseBoolEnvKey {
    
    static var raw: String {
        "DANCEUI_PRINT_HIT_TEST"
    }
}

@available(iOS 13.0, *)
extension EnvValue where K == HitTestLogEnabledKey {
    
    private static let store: Self = .init()
    
    fileprivate static var isHitTestLogEnabled: Bool {
        store.value
    }
}
