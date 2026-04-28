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

#if os(iOS)
import UIKit
#else
#error("Unsupported platform")
#endif
@available(iOS 13.0, *)
internal protocol AnyHostingController: UIViewController {
    
    // `_UIHostingView` is designed to be used along with `UIHostingController`.
    // Futhurmore, the hosting controller itself ought to be added in
    // view-controller tree. This flag helps check this point.
    var isInViewControllerTree: Bool { get }
    
    // `_UIHostingView` is designed to be used along with `UIHostingController`.
    // Futhurmore, the hosting controller itself ought to be added in
    // view-controller tree. This flag helps check this point.
    var isRootViewController: Bool { get }
    
}

/// A UIKit view controller that manages a DanceUI view hierarchy.
///
/// Create a `UIHostingController` object when you want to integrate DanceUI
/// views into a UIKit view hierarchy. At creation time, specify the DanceUI
/// view you want to use as the root view for this view controller; you can
/// change that view later using the ``DanceUI/UIHostingController/rootView``
/// property. Use the hosting controller like you would any other view
/// controller, by presenting it or embedding it as a child view controller
/// in your interface.
@available(OSX, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
open class UIHostingController<Content: View>: UIViewController, AnyHostingController, _UIHostingViewable, UIHostingViewTraits {
    
    internal struct AllowedBehaviors: OptionSet {
        
        let rawValue: Int
        
        internal init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        internal static var customToolbarManagement: AllowedBehaviors {
            AllowedBehaviors(rawValue: 0x1 << 0)
        }
        
        internal static var keyboardShortcutManagement: AllowedBehaviors {
            AllowedBehaviors(rawValue: 0x1 << 1)
        }
    }
    
    /// The root view of the DanceUI view hierarchy managed by this view
    /// controller.
    public var rootView: Content {
        get {
            host.rootView
        }
        set {
            host.rootView = newValue
        }
    }
    
    internal var hasAppeared: Bool {
        my__appearState == 2
    }
    
    internal var allowedBehaviors: AllowedBehaviors {
        didSet {
            didChangeAllowedBehaviors(from: oldValue, to: allowedBehaviors)
        }
    }
    
    internal var host: _UIHostingView<Content>

    internal let toolbarCoordinator: UIKitToolbarCoordinator

    internal var danceUIToolbar: DanceUIToolbar?

    internal var isInViewControllerTree: Bool = false

    internal var isRootViewController: Bool {
        if !isViewLoaded {
            return false
        }
        return view.window?.rootViewController === self
    }
    
    internal var _renderObject: AnyObject? {
        host._rendererObject
    }
    
    /// Sets the `safeAreaInsets` of the `UIHostingController`'s view.
    ///
    /// Once this property is set to a non-`nil` value, DanceUI will ignore the system-provided
    /// safe area insets as well as keyboard appearance and dismissal handling.
    ///
    /// For more details, see the documentation: 
    public var explicitSafeAreaInsets: EdgeInsets? {
        get {
            host.explicitSafeAreaInsets
        }
        
        set {
            host.explicitSafeAreaInsets = newValue
        }
    }
    
    public var gestureRecognizerConfiguration: UIHostingGestureRecognizerConfiguration {
        get {
            host.gestureRecognizerConfiguration
        }
        set {
            host.gestureRecognizerConfiguration = newValue
        }
    }
    
    open override func loadView() {
        self.view = host
    }
    
    /// Creates a hosting view object detached with controller that wraps the specified DanceUI
    /// view.
    ///
    /// - Parameter rootView: The root view of the DanceUI view hierarchy that
    ///   you want to manage using the hosting view.
    ///
    /// - Returns: A `UIView` object initialized with the
    ///   specified DanceUI view.
    @available(*, deprecated, message: "use UIHostingConfiguration.makeContentView(widthResizingMask, heightResizingMask) instead!")
    public static func _detached(rootView: Content) -> UIView {
        
        let view = _UIHostingView<Content>(rootView: rootView)
        view.explicitSafeAreaInsets = .zero
        Self._commonInit(host: view)
        return view
    }
    
    /// Creates a hosting controller object that wraps the specified DanceUI
    /// view.
    ///
    /// - Parameter rootView: The root view of the DanceUI view hierarchy that
    ///   you want to manage using the hosting view controller.
    ///
    /// - Returns: A `UIHostingController` object initialized with the
    ///   specified DanceUI view.
    public init(rootView: Content) {
        /// UIKitToolbarCoordinator
        /// ToolbarBridge
        self.host = _UIHostingView<Content>(rootView: rootView)

        // Temporary implementation
        allowedBehaviors = .customToolbarManagement
        
        toolbarCoordinator = UIKitToolbarCoordinator()
        
        super.init(nibName: nil, bundle: nil)
        self._commonInit()
    }
    
    /// Creates a hosting controller object from the contents of the specified
    /// archive.
    ///
    /// The default implementation of this method throws an exception. To create
    /// your view controller from an archive, override this method and
    /// initialize the superclass using the ``init(coder:rootView:)`` method
    /// instead.
    ///
    /// -Parameter coder: The decoder to use during initialization.
    @objc
    public required dynamic init?(coder aDecoder: NSCoder) {
        allowedBehaviors = AllowedBehaviors()
        toolbarCoordinator = UIKitToolbarCoordinator()
        danceUIToolbar = nil
        _danceuiFatalError("init(coder:) has not been implemented")
    }
    
    /// Creates a hosting controller object from an archive and the specified
    /// DanceUI view.
    /// - Parameters:
    ///   - coder: The decoder to use during initialization.
    ///   - rootView: The root view of the DanceUI view hierarchy that you want
    ///     to manage using this view controller.
    ///
    /// - Returns: A `UIViewController` object that you can present from your
    ///   interface.
    public init?(coder aDecoder: NSCoder, rootView: Content) {
        /// UIKitToolbarCoordinator
        /// ToolbarBridge
        self.host = _UIHostingView<Content>(rootView: rootView)
        
        // Temporary implementation
        allowedBehaviors = .customToolbarManagement
        
        toolbarCoordinator = UIKitToolbarCoordinator()
        
        super.init(coder: aDecoder)
        self._commonInit()
    }
    
    private func _commonInit() {
        Self._commonInit(host: host, self)
    }
    
    internal static func _commonInit(host: _UIHostingView<Content>,
                                    _ self: UIHostingController<Content>? = nil) {
        // Disable navigationBar adjusts scrollView insets automatically in iOS 10.x
        // In higher iOS version. `ScrollView.contentInsetAdjustmentBehavior` will take control this behavior
        if #available(iOS 11.0, *) {
            
        } else {
            self?.automaticallyAdjustsScrollViewInsets = false
        }
       
        host.viewController = self

        /// ToolbarBridge.addPreferences
        let inspectorBridge = UIKitInspectorBridge<Content>()
        let hostView = host
        inspectorBridge.host = hostView
        inspectorBridge.addPreferences(to: hostView.viewGraph)
        hostView.inspectorBridge = inspectorBridge
        
        host.shouldCheckHostingControllerExists = self != nil
        host.pairedHostingController = self

        self?.view = host
    }
    
    @objc
    public override dynamic init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        _danceuiFatalError("init(nibName:bundle:) has not been implemented")
    }
    
    /// Set `true` to use hit-testing logic provided by DanceUI ``View`` that
    /// hosted by this view controller.
    ///
    public var _usesContentHitTesting: Bool {
        get {
            host._usesContentHitTesting
        }
        set {
            host._usesContentHitTesting = newValue
        }
    }
    
    open override var keyCommands: [UIKeyCommand]? {
        return super.keyCommands
    }
    
    /// The preferred status bar style for the view controller.
    @objc
    open override dynamic var preferredStatusBarStyle: UIKit.UIStatusBarStyle {
        UIStatusBarStyle(traitCollection.effectiveColorScheme)
    }
    
    /// A Boolean value that indicates whether the view controller prefers the
    /// status bar to be hidden or shown.
    @objc
    open override dynamic var prefersStatusBarHidden: Bool {
        host.prefersStatusBarHidden
    }

    /// The animation style to use when hiding or showing the status bar for
    /// this view controller.
    @objc
    open override dynamic var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        host.preferredStatusBarUpdateAnimation
    }
    
    @objc
    open override dynamic var childForStatusBarHidden: UIViewController? {
        guard host.deferToChildViewController else {
            return nil
        }
        
        return self.children.first
    }
    
    @objc
    open override dynamic func preferredContentSizeDidChange(forChildContentContainer container: UIKit.UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        guard let containerController = container as? UIViewController,
              let superView = containerController.view.superview,
              let platformLayoutContainer = superView as? PlatformLayoutContainer else {
            return
        }

        platformLayoutContainer.enqueueLayoutInvalidation()
    }
    
    /// Notifies the view controller that its view is about to be added to a
    /// view hierarchy.
    ///
    /// DanceUI calls this method before adding the hosting controller's root
    /// view to the view hierarchy. You can override this method to perform
    /// custom tasks associated with the appearance of the view. If you
    /// override this method, you must call `super` at some point in your
    /// implementation.
    ///
    /// - Parameter animated: If `true`, the view is being added
    ///   using an animation.
    @objc
    open override dynamic func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        host.viewControllerWillAppear(transitionCoordinator: transitionCoordinator, animated: animated)
    }
    
    /// Notifies the view controller that its view has been added to a
    /// view hierarchy.
    ///
    /// DanceUI calls this method after adding the hosting controller's root
    /// view to the view hierarchy. You can override this method to perform
    /// custom tasks associated with the appearance of the view. If you
    /// override this method, you must call `super` at some point in your
    /// implementation.
    ///
    /// - Parameter animated: If `true`, the view is being added
    ///   using an animation.
    @objc
    open override dynamic func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        host.viewControllerDidAppear(transitionCoordinator: transitionCoordinator, animated: animated)
    }
    
    /// Notifies the view controller that its view will be removed from a
    /// view hierarchy.
    ///
    /// DanceUI calls this method before removing the hosting controller's root
    /// view from the view hierarchy. You can override this method to perform
    /// custom tasks associated with the disappearance of the view. If you
    /// override this method, you must call `super` at some point in your
    /// implementation.
    ///
    /// - Parameter animated: If `true`, the view is being removed
    ///   using an animation.
    @objc
    open override dynamic func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        host.viewControllerWillDisappear(transitionCoordinator: transitionCoordinator, animated: animated)
    }
    
    @objc
    open override dynamic func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        _viewWillLayoutSubviews()
    }
    
    internal func _viewWillLayoutSubviews() {
        layoutToolbarIfNeeded()
    }
    
    @objc
    open override dynamic func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        host.invalidateProperties(.rootView)
    }

    @objc
    open override dynamic func willMove(toParent parent: UIViewController?) {
        isInViewControllerTree = parent != nil
        super.willMove(toParent: parent)
        host.containingNavControllerFromLastAttemptedPop = self.navigationController
    }

    @objc
    open override dynamic func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        host.containingNavControllerFromLastAttemptedPop = nil
        isInViewControllerTree = parent != nil
    }
    
    open override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        guard NSStringFromSelector(action) != Static._pskc else {
            return nil
        }

        /*
        let scrollViewProvider = sender as? UIScrollViewProvider
        
        return super.target(forAction: action, withSender: scrollViewProvider)
         */
        
        return super.target(forAction: action, withSender: sender)
    }
    
    open override var canBecomeFirstResponder: Bool {
        host.canBecomeFirstResponder
    }
    
    @objc
    internal func _toggleLayoutDirection() {
    }
    
    // UIHostingController.
    internal func didChangeAllowedBehaviors(from: AllowedBehaviors, to: AllowedBehaviors) {
        return
    }
    
    open override func responds(to aSelector: Selector!) -> Bool {
        if NSStringFromSelector(aSelector) == "contentScrollView" {
            return true
        }
        return super.responds(to: aSelector)
    }

    internal func updateToolbarVisibility(navControllerOverride: UINavigationController?) {
    }
    
    fileprivate func layoutToolbarIfNeeded() {
        guard let danceUIToolbar = danceUIToolbar else {
            return
        }
    }
    
    fileprivate func createToolbarIfNeeded() -> DanceUIToolbar? {
        nil
    }
    
    public func disableHostingControllerExistsCheck() {
        host.shouldCheckHostingControllerExists = false
    }
    
    @_spi(DanceUIPreview)
    /// Used by DanceUI Preview, triggers view refresh when code changes
    public func refreshForPreview() {
        host.invalidateEverything()
        self.view.layoutSubviews()
    }
    
// MARK: _UIHostingViewable

    var _disableSafeArea: Bool {
        get {
            host.explicitSafeAreaInsets != nil
        }
        set {
            host.explicitSafeAreaInsets = newValue ? .zero : nil
        }
    }
    
    var _rendererConfiguration: _RendererConfiguration {
        get {
            host._rendererConfiguration
        }
        set {
            host._rendererConfiguration = newValue
        }
    }
    
    /// Calculates and returns the most appropriate size for the current view.
    ///
    /// - Parameter size: The proposed new size for the view.
    ///
    /// - Returns: The size that offers the best fit for the root view and its
    ///   contents.
    public func sizeThatFits(in size: CGSize) -> CGSize {
        self.host.sizeThatFits(size)
    }
    
    
    func _render(seconds: Double) {
        host.render(interval: seconds, updateDisplayList: true)
    }
}

/// Since `UIHostingController` is generic, and you cannot define stored static
/// member in a generic type, this type is placed here.
@available(iOS 13.0, *)
fileprivate struct Static {
    
    fileprivate static let _pskc: String = _makePskc()
    
    @_optimize(none)
    fileprivate static func _makePskc() -> String {
        "_" + "perform" + "Shortcut" + "Key" + "Command" + ":"
    }
    
}

#if FEAT_HOSTING_VC_FOR_CELL
@available(iOS 13.0, *)
extension UIHostingController {
    
    public func _wrapPreferenceBridge(_ preferenceBridge: AnyObject?) {
        var environmentOverride = host.environmentOverride ?? EnvironmentValues()
        environmentOverride.preferenceBridge = preferenceBridge as? PreferenceBridge
        host.environmentOverride = environmentOverride
    }
    
}
#endif
@available(iOS 13.0, *)
extension UIHostingController {
    
    public var gestureObservers: GestureObservers {
        get {
            host.gestureObservers
        }
        set {
            host.gestureObservers = newValue
        }
    }
}
