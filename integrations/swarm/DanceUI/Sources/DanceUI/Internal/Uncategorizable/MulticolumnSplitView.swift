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

import Foundation
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct MulticolumnSplitViewRepresentable<A: View, B: View, C: View>: UIViewControllerRepresentable {
    
    internal final class Coordinator: PlatformViewCoordinator, UISplitViewControllerDelegate {
        
        internal var secondaryController: SplitViewNavigationController
        
        internal var supplementaryController: SplitViewNavigationController?
        
        internal var secondaryPlaceholderHost: ObjectIdentifier
        
        internal var supplementaryPlaceholderHost: ObjectIdentifier?
        
        fileprivate var bridgedState: WeakAttribute<BridgedState>?
        
        fileprivate var previousState: BridgedState

        internal override init() {
            _unimplementedInitializer(className: "DanceUI.Coordinator")
        }
        
        internal init<Root: View>(secondaryRoot: Root) {
            supplementaryController = nil
            supplementaryPlaceholderHost = nil
            bridgedState = nil
            previousState = BridgedState()
            secondaryController = StyleContextSplitViewNavigationController<NoStyleContext>(rootView: secondaryRoot)
            secondaryPlaceholderHost = ObjectIdentifier(secondaryController.topViewController!)
            super.init()
        }
        
        internal func addSupplementaryView<Supplementary: View>(_ supplementaryView: Supplementary) {
            supplementaryController = StyleContextSplitViewNavigationController<ContentListStyleContext>(rootView: supplementaryView)
            supplementaryPlaceholderHost = ObjectIdentifier(supplementaryController!.topViewController!)
        }
        
        internal func updateSecondaryPlaceholder(_ secondary: C,
                                                 for splitController: UISplitViewController,
                                                 in environment: EnvironmentValues) {
            let secondaryController = self.secondaryController
            guard let topViewController = secondaryController.topViewController,
                  ObjectIdentifier(topViewController) == secondaryPlaceholderHost else {
                      return
                  }
            
            secondaryController.replaceRoot(root: secondary, in: environment)
        }
        
        internal func updateSupplementaryPlaceholder(_ supplementary: B,
                                                     for splitController: UISplitViewController,
                                                     in environment: EnvironmentValues) {
            guard let supplementaryController = supplementaryController,
                  let topViewController = supplementaryController.topViewController,
                  let supplementaryPlaceholderHost = supplementaryPlaceholderHost,
                  ObjectIdentifier(topViewController) == supplementaryPlaceholderHost,
                  let supplementaryController = self.supplementaryController else {
                return
            }
            
            supplementaryController.replaceRoot(root: supplementary, in: environment)
        }
        
        // MARK: UISplitViewControllerDelegate
        @available(iOS 14.0, *)
        internal func splitViewController(_ svc: UISplitViewController,
                                          topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
            guard let navVC = svc[proposedTopColumn] as? UINavigationController,
                  let topViewController = navVC.topViewController,
                  ObjectIdentifier(topViewController) == secondaryPlaceholderHost else {
                      return proposedTopColumn
                  }
            
            return self.supplementaryController == nil ? .primary : .supplementary
        }
        
        internal func splitViewControllerDidExpand(_ svc: UISplitViewController) {
            recomputeBridgedState(from: svc, displayMode: nil)
        }
        
        internal func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
            self.splitViewControllerDidExpand(svc)
        }
        
        internal func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
            recomputeBridgedState(from: svc, displayMode: displayMode)
        }
        
        fileprivate func recomputeBridgedState(from svc: UISplitViewController, displayMode: UISplitViewController.DisplayMode?) {
            let displayMode = displayMode ?? svc.displayMode
            let isCollapsed = svc.isCollapsed
            
            guard previousState.displayMode != displayMode ||
                  previousState.isCollapsed != isCollapsed else {
                      return
                  }
            
            previousState.commit(to: bridgedState)
            previousState = BridgedState(isCollapsed: isCollapsed, displayMode: displayMode)
        }
    }
    
    internal typealias UIViewControllerType = NotifyingMulticolumnSplitViewController

    internal var primary: A

    internal var _supplementary: B?

    internal var secondary: C

    fileprivate var bridgedState: WeakAttribute<BridgedState>
    
    fileprivate init(configuration: MulticolumnSplitView<A, B, C>.Configuration,
                     bridgedState: WeakAttribute<BridgedState>) {
        self.primary = configuration.primary
        self._supplementary = configuration.supplementary
        self.secondary = configuration.secondary
        self.bridgedState = bridgedState
    }
    
    internal var hasSupplementary: Bool {
        _supplementary != nil
    }
    
    internal var supplementary: B {
        return _supplementary!
    }
    
    @available(iOS 14.0, *)
    fileprivate var style: UISplitViewController.Style {
        hasSupplementary ? .tripleColumn : .doubleColumn
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(secondaryRoot: secondary)
        
        if hasSupplementary {
            coordinator.addSupplementaryView(self.supplementary)
        }
        
        coordinator.bridgedState = bridgedState
        return coordinator
    }
    
    internal func makeUIViewController(context: Context) -> NotifyingMulticolumnSplitViewController {
        
        if #available(iOS 14.0, *) {
            let coordinator = context.coordinator
            let notifyingMulticolumnVC = NotifyingMulticolumnSplitViewController(style: self.style)
            notifyingMulticolumnVC.delegate = coordinator
            
            let splitVC = StyleContextSplitViewNavigationController<SidebarStyleContext>(rootView: self.primary)
            notifyingMulticolumnVC.primaryViewController = splitVC
            notifyingMulticolumnVC.secondaryViewController = coordinator.secondaryController
            
            if hasSupplementary {
                notifyingMulticolumnVC.supplementaryViewController = coordinator.supplementaryController
            }
            return notifyingMulticolumnVC
            
        } else {
            runtimeIssue(type: .error, "this logic branch should never be reached")
            return NotifyingMulticolumnSplitViewController()
        }
    }
    
    internal func updateUIViewController(_ uiViewController: NotifyingMulticolumnSplitViewController, context: Context) {
        let environment = context.environment
        let coordinator = context.coordinator
        
        let primaryVC = uiViewController.primaryViewController! as! SplitViewNavigationController
        primaryVC.replaceRoot(root: self.primary, in: environment)

        coordinator.updateSecondaryPlaceholder(self.secondary, for: uiViewController, in: environment)
        
        if hasSupplementary {
            coordinator.updateSupplementaryPlaceholder(self.supplementary, for: uiViewController, in: environment)
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct BridgedState {
    
    var isCollapsed: Bool
    
    var displayMode: UISplitViewController.DisplayMode?
    
    internal init() {
        isCollapsed = false
        displayMode = nil
    }
    
    internal init(isCollapsed: Bool, displayMode: UISplitViewController.DisplayMode?) {
        self.isCollapsed = isCollapsed
        self.displayMode = displayMode
    }
    
    internal func commit(to: WeakAttribute<BridgedState>?) {
        guard let to = to, var attr = to.attribute else {
            return
        }
        
        let graphHost = attr.graph.graphHost()
        let mutation = CustomGraphMutation {
            guard var attr = to.attribute else {
                return
            }
            attr.value = self
        }
        graphHost.asyncTransaction(Transaction(), mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
    }
    
}

@available(iOS 13.0, *)
internal struct MulticolumnSplitView<A: View, B: View, C: View>: PrimitiveView, UnaryView {
    
    internal struct Configuration {

        internal var primary: A

        internal var supplementary: B?

        internal var secondary: C

    }
    
    fileprivate struct EnvironmentTransform: Rule {
        
        @Attribute
        internal var environment: EnvironmentValues
        
        @Attribute
        fileprivate var bridgedState: BridgedState
        
        internal static var initialValue: EnvironmentValues? {
            nil
        }
        
        internal var value: EnvironmentValues {
            var environment = self.environment
            let bridgedState = self.bridgedState
            
            environment.isSplitViewExpended = bridgedState.isCollapsed
            environment.displayMode = bridgedState.displayMode
            
            return environment
        }
        
    }
    
    internal struct Container: View {

        internal var configuration: Configuration

        fileprivate var bridgedState: WeakAttribute<BridgedState>
        
        fileprivate init(configuration: Configuration, bridgedState: WeakAttribute<BridgedState>) {
            self.configuration = configuration
            self.bridgedState = bridgedState
        }
        
        internal var body: some View {
            let viewRepresentable = MulticolumnSplitViewRepresentable(configuration: configuration, bridgedState: bridgedState)
            viewRepresentable.ignoresSafeArea().preference(key: HostingStatusBarContentKey.self, value: true)
        }
        
    }
    
    internal struct Child: Rule {
        
        @Attribute
        internal var multicolumnSplitView: MulticolumnSplitView<A, B, C>
        
        @Attribute
        fileprivate var bridgedState: BridgedState
        
        internal static var initialValue: Container? {
            nil
        }
        
        internal var value: MulticolumnSplitView<A, B, C>.Container {
            Container(configuration: multicolumnSplitView.configuration,
                      bridgedState: WeakAttribute<BridgedState>(_bridgedState))
        }
        
    }
    
    var configuration: Configuration
    
    internal static func _makeView(view: _GraphValue<MulticolumnSplitView<A, B, C>>, inputs: _ViewInputs) -> _ViewOutputs {
        let state = BridgedState()
        let bridgedStateAttr = Attribute(value: state)
        
        let transform = EnvironmentTransform(environment: inputs.environment, bridgedState: bridgedStateAttr)
        let environmentAttr = Attribute(transform)
        let cachedEnvironment = CachedEnvironment(environmentAttr)
        
        let child = Child(multicolumnSplitView: view.value, bridgedState: bridgedStateAttr)
        let newGraphValue = _GraphValue(child)
        
        var newInputs = inputs
        newInputs.updateCachedEnvironment(MutableBox(cachedEnvironment))
        return Container.makeDebuggableView(value: newGraphValue, inputs: newInputs)
    }
    
}
