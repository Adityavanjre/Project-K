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
import UIKit

@available(iOS 13.0, *)
internal final class UIKitInspectorBridge<ContentView : View> : NSObject, UIPopoverPresentationControllerDelegate, PresentationHostingControllerDelegate, UIHostingViewDelegate {
    
    internal weak var host: _UIHostingView<ContentView>?
    
    internal weak var uiBarButton: UIBarButtonItem?
    
    internal weak var presenterOverride: UIViewController?
    
    internal var activePresentation: PresentationKind
    
    internal var activeInspectorAnchor: Anchor<CGRect?>?
    
    internal var presentedVC: PresentationHostingController<AnyView>? {
        willSet {
            if newValue == nil, let vc = presentedVC {
                vc.host.render(updateDisplayList: false)
            }
        }
    }
    
    internal var inspectorSeed: VersionSeed
    
    internal var anchorSeed: VersionSeed
    
    internal var popoverSeed: VersionSeed
    
    internal var lastInspectorValues: [ViewIdentity: InspectorStorage]
    
    internal var lastAnchorValues: [AnyHashable: Anchor<Optional<CGRect>>]
    
    internal var lastPopoverPresentation: PopoverPresentation?
    
    @objc
    internal override init() {
        host = nil
        uiBarButton = nil
        presenterOverride = nil
        activePresentation = .none
        activeInspectorAnchor = nil
        presentedVC = nil
        inspectorSeed = .zero
        anchorSeed = .zero
        popoverSeed = .zero
        lastInspectorValues = [:]
        lastAnchorValues = [:]
        lastPopoverPresentation = nil
        super.init()
    }
    
    internal func adjustAnchorIfNeeded(_ controller: UIViewController, idealSize: CGSize) {
        if let popoverController = controller.popoverPresentationController, let targetRect = adjustSourceRect(popoverController, idealSize: idealSize) {
            popoverController.sourceRect = targetRect
            popoverController.containerView?.setNeedsLayout()
        }
    }
    
    private func adjustSourceRect(_ popoverController: UIPopoverPresentationController, idealSize: CGSize) -> CGRect? {
        
        guard let frame = popoverController.presentedView?.frame,
              frame.size.width < idealSize.width - 1 ||
                frame.size.height < idealSize.height - 1 else {
            return nil
        }
        
        guard let viewGraph = host?.viewGraph,
              let sourceRect = lastPopoverPresentation?.targetAnchor.box.convert(to: viewGraph.transform) else {
            return nil
        }
        
        if let window = host?.window, let hostRect = host?.convert(window.bounds, from: window), hostRect.intersects(sourceRect) {
            let rect = hostRect.intersection(sourceRect)
            return CGRect(x: rect.midX, y: rect.midY, width: 0, height: 0)
        }
        return CGRect(x: sourceRect.midX, y: sourceRect.midY, width: 0, height: 0)

    }
    
    @objc
    internal func popoverPresentationController(_ controller: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        guard let presentation = lastPopoverPresentation else {
            return
        }
        
        
        if DanceUIFeature.enablePopoverAutoAdjustAnchor.isEnable,
           let popoverController = presentedVC,
           let targetRect = adjustSourceRect(controller, idealSize: popoverController.host.idealSize()) {
            rect.pointee = targetRect
            controller.containerView?.setNeedsLayout()
        } else {
            if let viewGraph = host?.viewGraph,
               let sourceRect = presentation.targetAnchor.box.convert(to: viewGraph.transform) {
                rect.pointee = sourceRect
            }
        }
    }
    
    @objc
    internal func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        guard let containerView = popoverPresentationController.containerView else {
            return
        }
        if DanceUIFeature.gestureContainer.isEnable {
            let layerView = PopoverDimmingView(frame: containerView.bounds) { [weak self] in
                LogService.debug(module: .popover,
                                 keyword: .dimmingViewHitTest, "popover dismiss by PopoverDimmingView hitTest")
                self?.didDismissViewController()
            }
            layerView.popoverPresentationController = popoverPresentationController
            let interaction = MenuLikeDismissalInteraction(presentationController: popoverPresentationController)
            self.menuLikeDismissalInteraction = interaction
            layerView.menuLikeDismissalInteraction = interaction
            containerView.addSubview(layerView)
            // Make all the contents under the popover passthroughable.
            let windowChildrenViews = host?.window?.subviews ?? []
            popoverPresentationController.passthroughViews = windowChildrenViews.reversed()
        } else {
            guard lastPopoverPresentation?.dismissedProgramatically == true else {
                return
            }
            self.presentedVC?.dismissedProgramatically = true
            let layerView = PopoverDimmingView(frame: containerView.bounds) { [weak self] in
                LogService.debug(module: .popover,
                                 keyword: .dimmingViewHitTest, "popover dismiss by PopoverDimmingView hitTest")
                self?.didDismissViewController()
            }
            layerView.popoverPresentationController = popoverPresentationController
            containerView.addSubview(layerView)
        }
    }
    
    private var menuLikeDismissalInteraction: MenuLikeDismissalInteraction?
    

    private class MenuLikeDismissalInteraction: NSObject, UIInteraction, UIGestureRecognizerDelegate {
        
        class MenuLikeDismissingGestureRecognizer: UIGestureRecognizer {
            
            internal override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            }
            
            internal override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
                state = .ended
            }
            
            internal override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
                state = .ended
            }
            
            internal override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
                state = .cancelled
            }
            
        }
        
        let gestureRecognizer: MenuLikeDismissingGestureRecognizer
        
        let presentationController: UIPopoverPresentationController
        
        private var isDismissed: Bool = false
        
        weak var view: UIView?
        
        init(presentationController: UIPopoverPresentationController) {
            self.presentationController = presentationController
            self.gestureRecognizer = MenuLikeDismissingGestureRecognizer()
            super.init()
            self.gestureRecognizer.addTarget(self, action: #selector(handleDismissal(_:)))
            self.gestureRecognizer.delegate = self
        }
        
        fileprivate func willMove(to view: UIView?) {
            if self.view == nil, let window = view as? UIWindow {
                setUp(window)
                self.view = view
            }
        }
        
        fileprivate func didMove(to view: UIView?) {
            if self.view != nil && view == nil {
                tearDown()
                self.view = nil
            }
        }
        
        func setUp(_ window: UIWindow) {
            window.addGestureRecognizer(self.gestureRecognizer)
        }
        
        func tearDown() {
            self.gestureRecognizer.view?.removeGestureRecognizer(self.gestureRecognizer)
        }
        
        @objc
        func handleDismissal(_ gestureRecognizer: UIGestureRecognizer) {
            if gestureRecognizer.state == .ended {
                dismissIfNeeded()
            }
        }
        
        private func dismissIfNeeded() {
            if !isDismissed {
                presentationController.presentedViewController.dismiss(animated: true)
                isDismissed = true
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if let presentedView = presentationController.presentedView {
                if otherGestureRecognizer.view?.isDescendant(of: presentedView) == false {
                    return true
                }
            }
            return false
        }
        
    }
    
    private class PopoverDimmingView: UIView, UIGestureRecognizerDelegate {
                
        private var dismissAction: (() -> Void)?
        
        fileprivate weak var popoverPresentationController: UIPopoverPresentationController?
        
        fileprivate weak var menuLikeDismissalInteraction: MenuLikeDismissalInteraction?
        
        fileprivate init(frame: CGRect, dismissAction: @escaping () -> Void) {
            self.dismissAction = dismissAction
            super.init(frame: frame)
        }
        
        fileprivate required init?(coder: NSCoder) {
            self.dismissAction = { }
            super.init(coder: coder)
        }
        
        fileprivate override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if !DanceUIFeature.gestureContainer.isEnable {
                dismissAction?()
            }
            let view = super.hitTest(point, with: event)
            return view == self ? nil : view
        }
        
        fileprivate override func didMoveToWindow() {
            super.didMoveToWindow()
            if DanceUIFeature.gestureContainer.isEnable {
                if let interaction = menuLikeDismissalInteraction {
                    popoverPresentationController?.containerView?.window?.addInteraction(interaction)
                    menuLikeDismissalInteraction = nil
                }
            }
        }
    }
    
    @objc
    internal func presentationControllerShouldDismiss(_ controller : UIPresentationController) -> Bool {
        true
    }
    
    fileprivate func dismissAndReset(viewController: UIViewController) {
        viewController.dismiss(animated: true) { [weak self] in
            if let self = self {
                self.reset()
            }
        }
    }
    
    fileprivate func initialPopoverContentSize(for controller: PresentationHostingController<AnyView>) -> CGSize {
        let size = controller.preferredContentSize
        if !size.equalTo(.zero) {
            return controller.sizeThatFits(in: size)
        }
        let idealSize = controller.host.idealSize()
        return CGSize(width: size.width != 0 ? size.width : idealSize.width,
                      height: size.height != 0 ? size.height : idealSize.height)
    }
    
    fileprivate func makePresentedHost(_ content: AnyView) -> PresentationHostingController<AnyView> {
        let controller = PresentationHostingController(rootView: content, delegate: self, drawsBackground: true)
        let host = controller.host
        host.viewGraph.sizeThatFitsObserver = SizeThatFitsObserver(proposal: .unspecified, callback: { [weak controller] lhs, rhs in
            guard let controller = controller else {
                return
            }
            guard let view = controller.view else {
                return
            }
            guard !lhs.equalTo(rhs) else {
                return
            }
            var size = CGSize.zero
            if #available(iOS 11.0, *) {
                let safeAreaInsets = view.safeAreaInsets
                size = CGSize(width: rhs.width - safeAreaInsets.left - safeAreaInsets.right, height: rhs.height - safeAreaInsets.top - safeAreaInsets.bottom)
            } else {
                size = rhs
            }
            let result = CGSize(width: max(size.width, 0), height: max(size.height, 0))
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    controller.preferredContentSize = result
                }
            }
        })
        return controller
    }
    
    fileprivate func preparePopover(presented: PresentationHostingController<AnyView>, anchor: Anchor<CGRect?>, environment: EnvironmentValues) {
        let host = presented.host
        host.environmentOverride = environment
        if host.colorScheme == nil, let colorScheme = environment.explicitPreferredColorScheme {
            host.colorScheme = colorScheme
        }
        presented.prepareModalPresentationStyle(.popover)
        let size = initialPopoverContentSize(for: presented)
        presented.preferredContentSize = size
        if let controller = presented.popoverPresentationController {
            controller.delegate = self
            updateAnchor(anchor, popoverPresentationController: controller)
        }
    }

    fileprivate func presentNewInspector(_ storage: InspectorStorage, id: ViewIdentity, anchors: [AnyHashable : Anchor<CGRect?>]) {
        guard let presenter = presenter else {
            return
        }
        guard !activePresentation.isInspector else {
            _danceuiFatalError("activePresentation already is a inspector")
        }
        let controller = makePresentedHost(storage.content!)
        var popoverController: UIPopoverPresentationController? = nil
        let anchorFormID = anchors[storage.dataID!]
        if let anchor = anchorFormID, UIDevice.current.userInterfaceIdiom == .pad {
            preparePopover(presented: controller, anchor: anchor, environment: storage.environment)
            popoverController = controller.popoverPresentationController
        }
        if let popover = popoverController {
            popover.passthroughViews = [host!]
        } else {
            let controllerHost = controller.host
            controllerHost.environmentOverride = storage.environment
            if controllerHost.colorScheme == nil, let colorScheme = storage.environment.explicitPreferredColorScheme {
                controllerHost.colorScheme = colorScheme
            }
            controller.prepareModalPresentationStyle(.fullScreen)
            if #available(iOS 15.0, *) {
                if let sheetController = controller.presentationController as? UISheetPresentationController {
                    let detent = UISheetPresentationController.Detent.medium()
                    sheetController.detents = [detent]
                    sheetController.largestUndimmedDetentIdentifier = .medium
                    sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
                }
            }
        }
        presenter.present(controller, animated: true, completion: nil)
        presentedVC = controller
        activeInspectorAnchor = anchorFormID
    }
    
    fileprivate func presentNewPopover(presentation: PopoverPresentation, presenter: UIViewController) {
        guard !activePresentation.isPopover else {
            _danceuiFatalError("activePresentation already is a popover")
        }
        let controller = makePresentedHost(presentation.content)
        presentedVC = controller
        preparePopover(presented: controller, anchor: presentation.targetAnchor, environment: presentation.environment)
        if let vc = presenter.presentedViewController {
            vc.dismiss(animated: false) {
                presenter.present(controller, animated: true, completion: nil)
            }
        } else {
            presenter.present(controller, animated: true, completion: nil)
        }
        let kind = presentation.itemID.map { id in
            return PresentationKind.popoverItem(id)
        }
        activePresentation = kind ?? .popover(presentation.viewID)
    }
    
    fileprivate var presenter: UIViewController? {
        if let presenterOverride = presenterOverride {
            return presenterOverride
        }
        if let vc = host!.viewController {
            return vc
        }
        return host!.my__viewControllerForAncestor()
    }
    
    fileprivate func replaceExistingPopover(_ controller: PresentationHostingController<AnyView>, with presentation: PopoverPresentation, presenter: UIViewController) {
        let kind = presentation.itemID.map { id in
            return PresentationKind.popoverItem(id)
        }
        activePresentation = kind ?? .popover(presentation.viewID)
        controller.dismiss(animated: true) { [weak self] in
            controller.rootView = presentation.content
            self?.preparePopover(presented: controller, anchor: presentation.targetAnchor, environment: presentation.environment)
            presenter.present(controller, animated: true, completion: nil)
        }
    }
    
    fileprivate func reset() {
        if DanceUIFeature.gestureContainer.isEnable {
            needsCancelDismissalAnimationCompletionReset = false
            if let menuLikeDismissalInteraction {
                host?.window?.removeInteraction(menuLikeDismissalInteraction)
                self.menuLikeDismissalInteraction = nil
            }
        }
        activeInspectorAnchor = nil
        presentedVC = nil
        lastAnchorValues.removeAll()
        lastInspectorValues.removeAll()
        lastPopoverPresentation = nil
        activePresentation = .none
    }
    
    fileprivate func updateAnchor(_ anchor: Anchor<CGRect?>, popoverPresentationController: UIPopoverPresentationController) {
        if let button = uiBarButton {
            popoverPresentationController.barButtonItem = button
            return
        }
        popoverPresentationController.sourceView = host!
        guard let viewGraph = host?.viewGraph,
              let rect = anchor.box.convert(to: viewGraph.transform) else {
            return
        }
        popoverPresentationController.sourceRect = rect
        if let presentation = lastPopoverPresentation, !presentation.adaptivePresentationStyle {
            if let arrowEdge = presentation.arrowEdge {
                popoverPresentationController.permittedArrowDirections = arrowEdge.arrowDirection
            }
            if !presentation.hasArrowBackgroundView {
                popoverPresentationController.popoverBackgroundViewClass = PopoverWithoutArrowBackgroundView.self
            }
            popoverPresentationController.canOverlapSourceViewRect = presentation.canOverlapSourceViewRect
            if let margins = presentation.layoutMargins {
                popoverPresentationController.popoverLayoutMargins = UIEdgeInsets(top: margins.top, left: margins.leading, bottom: margins.bottom, right: margins.trailing)
            }
            if let backgroundClass = presentation.backgroundViewClass {
                popoverPresentationController.popoverBackgroundViewClass = backgroundClass
                popoverPresentationController.presentedViewController.view.backgroundColor = .clear
            }
        }
        popoverPresentationController.containerView?.setNeedsLayout()
        popoverPresentationController.containerView?.layoutIfNeeded()
    }

    fileprivate func updateExistingInspector(_ controller: PresentationHostingController<AnyView>, values: [ViewIdentity : InspectorStorage]) {
        let inspectorStorage = values[activePresentation.viewID]
        var isPresented = false
        if let storage = inspectorStorage, storage.isPresented.wrappedValue {
            let anchor = lastAnchorValues[AnyHashable(storage.dataID)]
            activeInspectorAnchor = anchor
            if let popoverController = controller.popoverPresentationController, let activeAnchor = activeInspectorAnchor {
                updateAnchor(activeAnchor, popoverPresentationController: popoverController)
            }
            controller.rootView = storage.content!
            isPresented = true
        } else {
            dismissAndReset(viewController: controller)
        }
        inspectorStorage?.isPresented.wrappedValue = isPresented
    }

    fileprivate func updateInspectorIfNeeded(_ rreferenceList: PreferenceList) {
        _notImplemented()
    }
    
    fileprivate func updatePopoverIfNeeded(_ value: PreferenceList.Value<[PopoverPresentation]>) {
        guard value.value.count <= 1 else {
            return
        }
        guard !activePresentation.isInspector, let presenter = presenter else {
            return
        }
        if popoverSeed == .invalid, value.seed == .invalid, popoverSeed == value.seed {
            return
        }
        
        popoverSeed = value.seed

        // The following function is extracted for reusing.
        updatePopover(value)
    }

    fileprivate func updatePopover(_ value: PreferenceList.Value<[PopoverPresentation]>) {

        guard !activePresentation.isInspector, let presenter = presenter else {
            return
        }

        
        // Shall be blocked by on-going UIKit presentation
        // false(gesture), true(gesture), false (completion)
        if DanceUIFeature.gestureContainer.isEnable {
            if presentedVC?.isBeingDismissed == true {
                needsCancelDismissalAnimationCompletionReset = true
                return
            }
        }
        
        let popoverPresentation = value.value.last
        lastPopoverPresentation = popoverPresentation
        guard let presentedVC = presentedVC else {
            LogService.debug(module: .popover,
                             keyword: .preferencesDidChange, "updatePopover without presentedVC") {
                if let presentation = popoverPresentation {
                    ["viewID": presentation.viewID]
                }
            }
            if let presentation = popoverPresentation {
                presentNewPopover(presentation: presentation, presenter: presenter)
            }
            return
        }
        
        func compareAndUpdate<A1: Hashable>(_ lhs: A1, _ rhs: A1?, presented: PresentationHostingController<AnyView>) {
            if lhs == rhs {
                presented.rootView = popoverPresentation!.content
                presented.host.environmentOverride = popoverPresentation!.environment
            } else {
                LogService.debug(module: .popover,
                                 keyword: .preferencesDidChange, "updatePopover with presenting") {
                    if let presentation = popoverPresentation {
                        ["viewID": presentation.viewID]
                    }
                }
                if let presentation = popoverPresentation {
                    replaceExistingPopover(presented, with: presentation, presenter: presenter)
                } else {
                    dismissAndReset(viewController: presented)
                }
            }
        }
        
        switch activePresentation {
        case .popoverItem(let anyHashable):
            compareAndUpdate(anyHashable, popoverPresentation?.itemID, presented: presentedVC)
        case .popover(let viewIdentity):
            compareAndUpdate(viewIdentity, popoverPresentation?.viewID ?? .zero, presented: presentedVC)
        default:
            _danceuiFatalError("activePresentation is not a popover")
        }
    }
    

    private var needsCancelDismissalAnimationCompletionReset: Bool = false
    
    internal func addPreferences(to graph: ViewGraph) {
        DGGraphRef.withoutUpdate {
            graph.addPreference(InspectorStorage.PreferenceKey.self)
        }
        DGGraphRef.withoutUpdate {
            graph.addPreference(InspectorAnchorPreferenceKey.self)
        }
        DGGraphRef.withoutUpdate {
            graph.addPreference(PopoverPresentation.Key.self)
        }
    }
    
    internal func preferencesDidChange(_ preferenceList: PreferenceList) {
        //        updateInspectorIfNeeded(preferenceList)
        updatePopoverIfNeeded(preferenceList[PopoverPresentation.Key.self])
    }
    
    internal func transformDidChange() {
        switch activePresentation {
        case .popoverItem(_), .popover(_):
            guard let presentation = lastPopoverPresentation , let presentedVC = presentedVC else {
                return
            }
            guard let controller = presentedVC.popoverPresentationController else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.updateAnchor(presentation.targetAnchor, popoverPresentationController: controller)
            }
        case .inspector(_):
            _notImplemented()
        case .none:
            break
        }
    }
    
    internal func didDismissViewController() {
        if DanceUIFeature.gestureContainer.isEnable {
            guard !needsCancelDismissalAnimationCompletionReset else {
                RunLoop.performOnMainThread { // eliminates flickers of the newly presented view controller.
                    if let prefs = self.host?.viewGraph.hostPreferenceValues {
                        guard let prefsValues = DGGraphRef.withoutUpdate({
                            prefs.value
                        }) else {
                            return
                        }
                        self.updatePopover(prefsValues[PopoverPresentation.Key.self])
                    }
                }
                reset()
                return
            }
        }
        
        if activePresentation.isInspector {
            if let value = lastInspectorValues[activePresentation.viewID] {
                value.isPresented.wrappedValue = false
            }
        } else {
            if let presentation = lastPopoverPresentation {
                presentation.onDismiss()
            }
        }
        reset()
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didChangePlatformItemList: PlatformItemList) where ViewType : View {
        // no-operation
        _intentionallyLeftBlank()
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didChangePreferences: PreferenceList) where ViewType : View {
        if let colorScheme = didChangePreferences[PreferredColorSchemeKey.self].value {
            if hostingView.colorScheme != colorScheme {
                hostingView.colorScheme = colorScheme
            }
            if #available(iOS 12.0, *) {
                let style = colorScheme == .dark ? UIUserInterfaceStyle.dark : UIUserInterfaceStyle.light
                if #available(iOS 13.0, *) {
                    presentedVC?.overrideUserInterfaceStyle = style
                }
                presentedVC?.presentationController?.overrideTraitCollection = UITraitCollection(userInterfaceStyle: style)
            }
        }
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didMoveTo window: UIWindow?) where ViewType : View {
        DGGraphRef.withoutUpdate {
            if window != nil {
                hostingView.viewGraph.addPreference(PreferredColorSchemeKey.self)
            } else {
                hostingView.viewGraph.removePreference(PreferredColorSchemeKey.self)
            }
        }
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, willUpdate: inout EnvironmentValues) where ViewType : View {
        // no-operation
        _intentionallyLeftBlank()
    }
    
    internal func hostingView<ViewType>(_ hostingView: _UIHostingView<ViewType>, didUpdate: inout EnvironmentValues) where ViewType : View {
        // no-operation
        _intentionallyLeftBlank()
    }
    
    @objc
    internal func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        if let presentation = lastPopoverPresentation, !presentation.adaptivePresentationStyle {
            return .none
        }
        return  controller.presentationStyle
    }
    
    internal enum PresentationKind : Equatable {
        
        case popoverItem(AnyHashable)
        
        case popover(ViewIdentity)
        
        case inspector(ViewIdentity)
        
        case none
        
        internal var isInspector: Bool {
            switch self {
            case .inspector(_):
                return true
            default:
                return false
            }
        }
        
        internal var isPopover: Bool {
            switch self {
            case .popoverItem(_), .popover(_):
                return true
            default:
                return false
            }
        }
        
        internal var viewID: ViewIdentity {
            switch self {
            case .popover(let viewIdentity):
                return viewIdentity
            case .inspector(let viewIdentity):
                return viewIdentity
            default:
                return .zero
            }
        }
    }
}

@available(iOS 13.0, *)
internal struct InspectorAnchorPreferenceKey : HostPreferenceKey {
    
    internal typealias Value = [AnyHashable: Anchor<CGRect?>]
    
    @inline(__always)
    internal static var defaultValue: [AnyHashable: Anchor<CGRect?>] { [:] }
    
    internal static func reduce(value: inout [AnyHashable : Anchor<CGRect?>], nextValue: () -> [AnyHashable : Anchor<CGRect?>]) {
        value.merge(nextValue()) { lhs, rhs in
            return rhs
        }
    }
}

@available(iOS 13.0, *)
internal struct InspectorStorage {
    

    internal var isPresented: Binding<Bool>
    

    internal var isPresentedValue: Bool
    

    internal var dataID: AnyHashable?
    

    internal var content: AnyView?
    

    internal var environment: EnvironmentValues
    
    internal struct PreferenceKey : HostPreferenceKey {
        internal typealias Value = [ViewIdentity: InspectorStorage]

        @inline(__always)
        internal static var defaultValue: [ViewIdentity: InspectorStorage] { [:] }
        
        internal static func reduce(value: inout [ViewIdentity : InspectorStorage], nextValue: () -> [ViewIdentity : InspectorStorage]) {
            value.merge(nextValue()) { lhs, rhs in
                return rhs
            }
        }
    }
}

// MARK: popover Log
@available(iOS 13.0, *)
internal enum PopoverLogKeyword: String, LogKeyword {
    case preferencesDidChange
    case dimmingViewHitTest
    case presentedVCDisappear
    case bindingUpdate
    
    internal static var moduleName: String { "Popover" }
}

@available(iOS 13.0, *)
extension LogService.Module where K == PopoverLogKeyword {
    internal static let popover: Self = .init()
}
