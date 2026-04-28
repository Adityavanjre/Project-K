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

import UIKit
import MyShims

@available(iOS 13.0, *)
internal final class PlatformViewHost<A: PlatformViewRepresentable>: UIHookFreeView, AnyPlatformViewHost, PlatformLayoutContainer {

    internal var environment: EnvironmentValues

    internal var viewPhase: _GraphInputs.Phase

    /// The provider of the represented view.
    ///
    /// May be a platform specific view controller or view.
    ///
    internal var /* let */ representedViewProvider: A.PlatformViewProvider?

    internal weak var host: ViewRendererHost?

    internal var focusedValues: FocusedValues

    internal var gestureRecognizerObservers: GestureObservers

    internal weak var responder: AnyUIViewResponder?

    internal var layoutInvalidator: Optional<() -> ()>

    internal var invalidationPending: Bool

    private let delaysTouchesBeganGestureRecognizer: DelaysTouchesBeganGestureRecognizer

    internal var delaysTouchesBegan: Bool = false {
        didSet {
            if delaysTouchesBegan {
                addGestureRecognizer(delaysTouchesBeganGestureRecognizer)
            } else {
                removeGestureRecognizer(delaysTouchesBeganGestureRecognizer)
            }
        }
    }

    internal var isUnused: Bool = false
    
    internal var representedView: UIView {
        A.platformView(for: representedViewProvider!)
    }
    
    internal init(_ provider: A.PlatformViewProvider,
                  host: ViewRendererHost?,
                  focusedValues: FocusedValues,
                  gestureRecognizerObservers: GestureObservers,
                  environment: EnvironmentValues,
                  viewPhase: _GraphInputs.Phase) {
        self.environment = environment
        self.viewPhase = viewPhase
        self.host = host
        self.focusedValues = focusedValues
        self.gestureRecognizerObservers = gestureRecognizerObservers
        self.responder = nil
        self.representedViewProvider = provider
        self.layoutInvalidator = nil
        self.invalidationPending = false
        self.delaysTouchesBeganGestureRecognizer = DelaysTouchesBeganGestureRecognizer()
        super.init(frame: .zero)
        if DanceUIFeature.fixIOS18Dot3UIViewRepresentableNoLongerRespondsToSizeChange.isEnable {
            fixIOS18Dot3LayoutInvalidationNotInvokeIfNeeded(platformViewHost: self)
        }
        
        if !A.isViewController {
            addSubview(representedView)
        }
        
        updateEnvironment(environment, viewPhase: viewPhase, focusedValues: focusedValues)
    }
    
    internal override init(frame: CGRect) {
        _unimplementedInitializer(className: "DanceUI.PlatformViewHost")
    }

    internal required init?(coder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }
    
    internal func updateEnvironment(_ environment: EnvironmentValues, viewPhase: _GraphInputs.Phase, focusedValues: FocusedValues) {
        self.environment = environment
        self.viewPhase = viewPhase
        self.focusedValues = focusedValues
        
        let currentTraitCollection = traitCollection
        
        let overriddenTraitCollection = currentTraitCollection.byOverriding(with: environment,
                                                                            viewPhase: viewPhase,
                                                                            focusedValues: focusedValues)
            .byMutating(gestureRecognizerObservers: gestureRecognizerObservers)
        
        if let providerViewController = representedViewProvider as? UIViewController {
            
            if let hostViewController = host?.uiViewController {
                hostViewController.setOverrideTraitCollection(overriddenTraitCollection, forChild: providerViewController)
            }
            
        } else {
            my__noteTraitsDidChangeRecursively()
            
            if #available(iOS 17, *) {
                // no-op
            } else {
                my__processDidChangeRecursively(fromOldTraits: currentTraitCollection, toCurrentTraits: overriddenTraitCollection, forceNotification: true)
            }
        }
        
        adoptEnvironment(environment, hostedSubview: representedView)
    }
    
    internal override func willMove(toSuperview superview: UIView?) {
        defer {
            super.willMove(toSuperview: superview)
        }
        
        guard superview != nil else {
            return
        }

        if let providerViewController = representedViewProvider as? UIViewController {
            
            let providerRootView = providerViewController.view!
            providerRootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            if let hostViewController = host?.uiViewController {
                if hostViewController != providerViewController.parent && self.window != nil {
                    hostViewController.addChild(providerViewController)
                    addSubview(providerRootView)
                }
                
                let emptyTraitCollection = UITraitCollection()
                
                let overriddenTraitCollection = emptyTraitCollection.byOverriding(with: environment,
                                                                                  viewPhase: viewPhase,
                                                                                  focusedValues: focusedValues)
                    .byMutating(gestureRecognizerObservers: gestureRecognizerObservers)
                
                hostViewController.setOverrideTraitCollection(overriddenTraitCollection, forChild: providerViewController)
                
            } else {
            addSubview(providerRootView) // coverage flakiness
            }
            
            providerRootView.frame = providerRootView.frame(forAlignmentRect: bounds)
            
        }
    }
    
    internal override func didMoveToSuperview() {
        defer {
            super.didMoveToSuperview()
        }
        guard superview != nil,
              let providerViewController = representedViewProvider as? UIViewController,
              let hostViewController = host?.uiViewController else {
            return
        }
        providerViewController.didMove(toParent: hostViewController)
    }
    
    internal override func layoutSubviews() {
        #warning("Dedicated frame setting may confuses containing collection view's preferred-size calculation.")
        
        guard !isUnused else {
            super.layoutSubviews()
            return
        }
        
        updateHostedViewBounds()
        
        super.layoutSubviews()
    }
    
    internal func updateHostedViewBounds() {
        let hostedView = representedView
        
        hostedView.frame = hostedView.frame(forAlignmentRect: bounds)
    }
    
    internal override func didMoveToWindow() {
        defer {
            super.didMoveToWindow()
        }
        guard window != nil,
              let providerViewController = representedViewProvider as? UIViewController,
              let hostViewController = host?.uiViewController else {
            return
        }
        { (hostViewController: UIViewController) in
            
            let providerRootView = providerViewController.view!
            hostViewController.addChild(providerViewController)
            addSubview(providerRootView)
            providerViewController.didMove(toParent: hostViewController)
            
        }(hostViewController)
    }

    internal override func my__traitCollection(forChildEnvironment childEnvironment: UITraitEnvironment) -> UITraitCollection? {
        if representedViewProvider is UIViewController {
            return super.my__traitCollection(forChildEnvironment: childEnvironment)!
        } else {
            return traitCollection.byOverriding(with: environment,
                                                viewPhase: viewPhase,
                                                focusedValues: focusedValues)
            .byMutating(gestureRecognizerObservers: gestureRecognizerObservers)
        }
    }

    internal override func removeFromSuperview() {
        if let providerViewController = representedViewProvider as? UIViewController {
            
            providerViewController.willMove(toParent: nil)
            
            if providerViewController.isViewLoaded {
                let providerView = providerViewController.view!
                providerView.removeFromSuperview()
            }
            
            super.removeFromSuperview()
            
            providerViewController.removeFromParent()
            
            host?.uiViewController?.setOverrideTraitCollection(nil, forChild: providerViewController)
            
        } else {
            super.removeFromSuperview()
        }
    }
    
    internal override func my_constraintsDidChange(inEngine engine: NSObject) { // BDCOV_EXCL_BLOCK
        super.my_constraintsDidChange(inEngine: engine)
        
        enqueueLayoutInvalidation()
    }
    
    internal override func my__intrinsicContentSizeInvalidated(forChildView childView: UIView) {
        super.my__intrinsicContentSizeInvalidated(forChildView: childView)
        enqueueLayoutInvalidation()
    }
    
    // Only for fixing the iOS 18.3 layout invalidation not invoke issue
    @objc
    fileprivate func fixIOS18Dot3IntrinsicContentSizeInvalidated(forChildView childView: UIView) { // BDCOV_EXCL_BLOCK relevant issue can only reproduce on devices, non-testable on simulator.
        MyIOS18Dot3NoLayoutInvalidationFixPlatformViewHostCallSuperIntrinsicContentSizeDidChangeForChild(self, PlatformViewHost<A>.self, childView)
        enqueueLayoutInvalidation()
    }
    
    internal override var intrinsicContentSize: CGSize {
        if representedViewProvider is UIViewController {
            return super.intrinsicContentSize
        } else {
            return representedView.intrinsicContentSize
        }
    }
    
    internal override func contentHuggingPriority(for axis: NSLayoutConstraint.Axis) -> UILayoutPriority {
        if representedViewProvider is UIViewController {
            return super.contentHuggingPriority(for: axis)
        } else {
            return representedView.contentHuggingPriority(for: axis)
        }
    }
    
    internal override func contentCompressionResistancePriority(for axis: NSLayoutConstraint.Axis) -> UILayoutPriority {
        if representedViewProvider is UIViewController {
            return super.contentCompressionResistancePriority(for: axis)
        } else {
            return representedView.contentCompressionResistancePriority(for: axis)
        }
    }
    
    internal func enqueueLayoutInvalidation() {
        guard let layoutInvalidator = self.layoutInvalidator, !invalidationPending else {
            return
        }
        onNextMainRunLoop {
            guard self.host != nil else {
                return
            }
            layoutInvalidator()
            self.invalidationPending = false
        }
        invalidationPending = true
    }
    
//    // DanceUI addition
//    internal func prepareForUnuse() {
//        let representedView = self.representedView
//
//        if representedView.superview !== nil {
//            representedView.removeFromSuperview()
//        }
//
//        self.layoutInvalidator = nil
//        /*
//         这里注释掉，因为 Navigation 测出了一个 Crash
//         背景是这里会导致 representedViewProvider 释放，比如它其实是个 UIHostingController
//         还会导致内部的 ViewGraph 和图被释放，最终导致 crash
//         */
////        self.representedViewProvider = nil
//        self.responder = nil
//        self.isUnused = true
//    }
//    
//    // DanceUI addition
//    internal func prepareForReuse(viewPhase: _GraphInputs.Phase, provider: A.PlatformViewProvider) {
//        self.viewPhase = viewPhase
//        self.responder = nil
//        self.representedViewProvider = provider
//        self.invalidationPending = false
//        self.isUnused = false
//        if !A.isViewController {
//            addSubview(representedView)
//        }
//
//        updateViewPhase(viewPhase: viewPhase)
//    }
//
//    // DanceUI addition
//    internal func updateViewPhase(viewPhase: _GraphInputs.Phase) {
//        self.viewPhase = viewPhase
//
//        let originalTraitCollection = traitCollection
//
//        let overridenTraitCollection = traitCollection.byOverriding(with: environment,
//                                                                    viewPhase: viewPhase,
//                                                                    focusedValues: focusedValues)
//            .byMutating(gestureRecognizerObservers: gestureRecognizerObservers)
//
//        if let providerViewController = representedViewProvider as? UIViewController {
//            if let hostViewController = host?.uiViewController {
//                hostViewController.setOverrideTraitCollection(overridenTraitCollection, forChild: providerViewController)
//            }
//        } else {
//            my__noteTraitsDidChangeRecursively()
//
//            my__processDidChangeRecursively(fromOldTraits: originalTraitCollection, toCurrentTraits: overridenTraitCollection, forceNotification: true)
//        }
//    }
    
    /// This override fixes the issue that invocation to `PlatformViewHost`
    /// does not cause trait collection propagations on iOS 17.
    ///
    /// UIView's instantiation process checks if the derived class
    /// implements a specific method. Only classes that passed this check
    /// can activate trait propagation.
    ///
    internal override func method(for aSelector: Selector!) -> IMP! {
        // To prevent potential break to the established behavior
        // on lower version iOS, we cannot port the following logic to
        // versions of iOS lower than iOS 17.0.
        //
        if #available(iOS 17.0, *) {
            if aSelector == traitCollectionForChildEnv {
                return super.method(for: #selector(UIView.my__traitCollection(forChildEnvironment:)))
            }
        }
        return super.method(for: aSelector)
    }
    
    internal override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if DanceUIFeature.gestureContainer.isEnable {
            if let responder = responder as? UIViewResponder_FeatureGestureContainer {
                let globalPoint = convert(point, to: nil)
                let (globalPoints, _, derived) = hitPoints(point: globalPoint, radius: defaultMajorRadius)
                let result = responder.helper.containsGlobalPoints(globalPoints, isDerived: derived, cacheKey: ViewResponder.hitTestKey, children: [])
                if result.mask.isEmpty {
                    let _ = responder.helper.containsGlobalPoints(globalPoints, isDerived: derived, cacheKey: ViewResponder.hitTestKey, children: [])
                    return nil
                }
            }
            if DanceUIFeature.unifiedHitTesting.isEnable {
                let view = super.hitTest(point, with: event)
                if view !== self {
                    return view
                }
                return nil
            } else {
                if let hitSubview = super.hitTest(point, with: event) {
                    return hitSubview
                }
                // Filtered by the previous `responder.helper.containsGlobalPoints`
                // Edge outsets enlarged the view, return self instead.
                return self
            }
        } else {
            return super.hitTest(point, with: event)
        }
    }
    
}

private let traitCollectionForChildEnv: Selector = {
    let components = ["_", "trait", "Collection", "For", "Child", "Environment", ":"]
    return NSSelectorFromString(components.joined())
}()

/// This gesture recognizer is designed for simulating UITouchGesture
/// in UIKit's UIGestureRecognizer-based gesture recognition system.
///
/// Since UITouchGesture encapsulates the raw touches handling of a UIView
/// instance managed by UIViewRepresentable into a DanceUI gesture,
/// handling UITouchGesture means to handling with DanceUI's gesture
/// implementation -- which is the UIGestureRecognizer-based gesture
/// recognition system from UIKit.
///
/// This gesture recognizer class is designed to tell the UIKit that
/// "there is a gesture recognizer on the UIView and this gesture
/// recognizer meets what UITouchGesture needs."
///
@available(iOS 13.0, *)
private class DelaysTouchesBeganGestureRecognizer: UIGestureRecognizer {
    
    private class Delegate: NSObject, UIGestureRecognizerDelegate {
        
        fileprivate func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // The instances of this class can only be the delegates of
            // DelaysTouchesBeganGestureRecognizer instances.
            // Returns true unconditionally.
            return true
        }
        
    }
    
    private let desginatedDelegate: Delegate
    
    fileprivate override init(target: Any?, action: Selector?) {
        desginatedDelegate = Delegate()
        super.init(target: target, action: action)
        delaysTouchesBegan = true
        self.delegate = desginatedDelegate
    }
    
    fileprivate override var delaysTouchesBegan: Bool {
        didSet {
#if DEBUG || DANCE_UI_INHOUSE
            _danceuiPrecondition(delaysTouchesBegan, "DelaysTouchesBeganGestureRecognizer.delaysTouchesBegan can only set to true.")
#endif
        }
    }
    
    fileprivate override var delegate: UIGestureRecognizerDelegate? {
        didSet {
#if DEBUG || DANCE_UI_INHOUSE
            _danceuiPrecondition(delegate !== desginatedDelegate || delegate !== nil, "Cannot set delegate of DelaysTouchesBeganGestureRecognizer to others instead of its internal implementation.")
#endif
        }
    }
    
}

@available(iOS 13.0, *)
private func fixIOS18Dot3LayoutInvalidationNotInvokeIfNeeded<ProviderType: PlatformViewRepresentable>(platformViewHost: PlatformViewHost<ProviderType>) { // BDCOV_EXCL_BLOCK relevant issue can only reproduce on devices, non-testable on simulator.
    guard MyShouldApplyIOS18Dot3NoLayoutInvalidationFix() else {
        return
    }

    guard let fixSubclass = getPlatformViewHostIOS18LayoutInvalidationNotInvokeFixClass(for: ProviderType.self) else {
        return
    }
    object_setClass(platformViewHost, fixSubclass)
}

@available(iOS 13.0, *)
private struct IOS18LayoutInvalidationNotInvokeFixClassFactory {
    
    private enum ClassInfo {
        case failed
        case succeeded(AnyClass, String)
        
        @inline(__always)
        fileprivate var classType: AnyClass? {
            switch self {
            case .failed:
                return nil
            case .succeeded(let anyClass, _):
                return anyClass
            }
        }
        
    }
    
    private static var lock: Lock = Lock()
    
    private static var cache: [ObjectIdentifier : ClassInfo] = [:]
    
    private static func makeFixClass<ProviderType: PlatformViewRepresentable>(for providerType: ProviderType.Type) -> (AnyClass, String)? {
        let className = "PlatformViewHostFixIOS18LayoutInvalidation_\(_typeName(providerType, qualified: true))"
        
        guard let classType = className.withCString({ classNamePtr in
            // The storage of classNamePtr is in the heap.
            // We need to return the `classType` and hold it in the cache.
            return objc_allocateClassPair(PlatformViewHost<ProviderType>.self, classNamePtr, 0)
        }) else {
            return nil
        }
        
        if let impl = class_getMethodImplementation(PlatformViewHost<ProviderType>.self, #selector(PlatformViewHost<ProviderType>.fixIOS18Dot3IntrinsicContentSizeInvalidated(forChildView:))) {
            let selectorName = [
                "_",
                "intrinsic",
                "Content",
                "Size",
                "Invalidated",
                "For",
                "Child",
                "View",
                ":"
            ].joined()
            class_addMethod(classType, NSSelectorFromString(selectorName), impl, "@:@")
        }
        
        objc_registerClassPair(classType)
        
        return (classType, className)
    }
    
    fileprivate static func fixClass<ProviderType: PlatformViewRepresentable>(for providerType: ProviderType.Type) -> AnyClass? {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        let cacheKey = ObjectIdentifier(providerType)
        
        if let cachedClass = cache[cacheKey] {
            return cachedClass.classType
        } else {
            if let (classType, className) = makeFixClass(for: providerType) {
                cache[cacheKey] = .succeeded(classType, className)
                return classType
            } else {
                cache[cacheKey] = .failed
                return nil
            }
        }
    }
    
}

@available(iOS 13.0, *)
private func getPlatformViewHostIOS18LayoutInvalidationNotInvokeFixClass<ProviderType: PlatformViewRepresentable>(for providerType: ProviderType.Type) -> AnyClass? {
    IOS18LayoutInvalidationNotInvokeFixClassFactory.fixClass(for: ProviderType.self)
}
