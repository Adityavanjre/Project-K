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

@available(iOS 13.0, *)
public protocol NavigationViewStyle {
    
    associatedtype _Body : View
    
    @ViewBuilder
    func _body(configuration: _NavigationViewStyleConfiguration) -> Self._Body
    
}

@available(iOS 13.0, *)
extension NavigationViewStyle where Self == ColumnNavigationViewStyle {
    
    /// A navigation view style represented by a series of views in columns.
    @_alwaysEmitIntoClient
    public static var columns: ColumnNavigationViewStyle {
        .init()
    }
}

@available(iOS 13.0, *)
extension NavigationViewStyle where Self == DefaultNavigationViewStyle {
    
    /// The default navigation view style in the current context of the view
    /// being styled.
    @_alwaysEmitIntoClient
    public static var automatic: DefaultNavigationViewStyle {
        .init()
    }
}

@available(macOS, unavailable)
@available(iOS 13.0, *)
extension NavigationViewStyle where Self == StackNavigationViewStyle {
    
    /// A navigation view style represented by a view stack that only shows a
    /// single top view at a time.
    @_alwaysEmitIntoClient
    public static var stack: StackNavigationViewStyle {
        .init()
    }
}

@available(iOS 13.0, *)
public struct _NavigationViewStyleConfiguration {
    
    public struct Content : ViewAlias, PrimitiveView {
        
        public typealias Body = Never
        
        internal init() {
            _intentionallyLeftBlank()
        }
    }
    
    public let content: _NavigationViewStyleConfiguration.Content
    
    internal init() {
        self.content = Content()
    }
    
}

/// A navigation view style represented by a primary view stack that
/// navigates to a detail view.
@available(iOS 13.0, *)
public struct DoubleColumnNavigationViewStyle: NavigationViewStyle {
    
    internal static let willShowDetailNotification = Notification.Name("DanceUI.NotificationSendingSplitViewController")
    
    public init() {
        _intentionallyLeftBlank()
    }
    
    /*
     typealias _Body = FeatureConditional<_VariadicView.Tree<DoubleColumnNavigationView, _NavigationViewStyleConfiguration.Content>, _VariadicView.Tree<ColumnNavigationView, _NavigationViewStyleConfiguration.Content>, BothFeatures<Semantics.IOSMultiColumnFeature, IOSSidebarListStyleFeature>>
     */
    
    // Same split as ColumnNavigationViewStyle below
    // From analysis, since iOS 14 this decides between ColumnNavigationView or DoubleColumnNavigationView based on feature flag
    // And eventually reaches ColumnNavigationView logic
    // But on iOS 13 this is hardcoded to DoubleColumnNavigationView, so lower versions also use this approach
    // Returns fixed type, so cannot use if #available, must put logic in custom IOS14Above feature
    public func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        StaticIf(IOS14Above.self) {
            let root = ColumnNavigationView(isSidebarEnabled: false) 
            _VariadicView.Tree(root: root, content: _NavigationViewStyleConfiguration.Content())
        } else: {
            let root = DoubleColumnNavigationView() 
            _VariadicView.Tree(root: root, content: _NavigationViewStyleConfiguration.Content())
        }
    }
    
}

@available(iOS 13.0, *)
internal struct DoubleColumnNavigationView: _VariadicView_UnaryViewRoot {
    
    /*
     internal typealias Body = ModifiedContent<ModifiedContent<BridgedSplitView<_VariadicView_Children.Element, Group<_ConditionalContent<_VariadicView_Children.Element, _UnaryViewAdaptor<EmptyView>>>>, _SafeAreaRegionsIgnoringLayout>, _PreferenceWritingModifier<HostingStatusBarContentKey>>
     */
    
    internal struct BodyContent: View {
        
        internal var children: _VariadicView.Children
        
        @_transparent
        @ViewBuilder
        var body: some View {
            if children.distance(from: 0, to: children.list.count) >= 2 {
                children.last!
            } else {
                _UnaryViewAdaptor(EmptyView())
            }
        }
    }
    
    @ViewBuilder
    public func body(children: _VariadicView.Children) -> some View {
        let placeholder = Group(content: BodyContent(children: children))
        if let first = children.first  {
            BridgedSplitView(master: first, placeholder: placeholder)
                .ignoresSafeArea()
                .preference(key: HostingStatusBarContentKey.self, value: true)
        } else {
            BridgedSplitView(master: EmptyView(), placeholder: placeholder)
                .ignoresSafeArea()
                .preference(key: HostingStatusBarContentKey.self, value: true)
        }
    }
}

@available(iOS 13.0, *)
internal struct BridgedSplitView<A: View, B: View>: UIViewControllerRepresentable {
    
    internal let master: A
    
    internal let placeholder: B
    
    internal final class Coordinator: PlatformViewCoordinator, UISplitViewControllerDelegate {
        
        internal var placeholderNavController: UINavigationController
        
        internal var placeholderHost: UIHostingController<B> {
            let firstViewController = placeholderNavController.viewControllers[0]
            return firstViewController as! UIHostingController<B>
        }
        
        internal override init() {
            _unimplementedInitializer(className: "DwiftUI.Coordinator")
        }
        
        internal init(placeholderNavController: UINavigationController) {
            self.placeholderNavController = placeholderNavController
            super.init()
        }
        
        internal func splitViewController(_ splitViewController: UISplitViewController,
                                          collapseSecondary: UIViewController,
                                          onto: UIViewController) -> Bool {
            placeholderNavController == collapseSecondary
        }
        
        internal func splitViewController(_ splitViewController: UISplitViewController,
                                          separateSecondaryFrom: UIViewController) -> UIViewController? {
            guard let navViewController = separateSecondaryFrom as? UINavigationController else {
                return nil
            }
            
            guard let topViewController = navViewController.topViewController else {
                return placeholderNavController
            }
            
            if topViewController is UINavigationController {
                return nil
            }
            return placeholderNavController
        }
    }
    
    internal func makeCoordinator() -> Coordinator {
        let hostingController = UIHostingController(rootView: self.placeholder)
        // Original implementation was UINavigationController, customized to force transparent navigation bar
        let navController = DanceUINavigationController(rootViewController: hostingController)
        return Coordinator(placeholderNavController: navController)
    }
    
    internal func makeUIViewController(context: Context) -> NotificationSendingSplitViewController {
        let hostingController = UIHostingController(rootView: self.master)
        hostingController.host.updatePreferences()
        // Original implementation was UINavigationController, customized to force transparent navigation bar
        let navController = DanceUINavigationController(rootViewController: hostingController)
        
        let splitViewController = NotificationSendingSplitViewController(nibName: nil, bundle: nil)
        splitViewController.delegate = context.coordinator
        splitViewController.viewControllers = [navController, context.coordinator.placeholderNavController]
        splitViewController.preferredDisplayMode = .automatic
        context.coordinator.placeholderHost.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        return splitViewController
    }
    
    internal func updateUIViewController(_ uiViewController: NotificationSendingSplitViewController, context: Context) {
        let firstViewController = uiViewController.viewControllers.first!
        let firstNavigationController = firstViewController as! UINavigationController
        firstNavigationController.update(with: self.master, in: context.environment)
        context.coordinator.placeholderHost.rootView = self.placeholder
    }
    
} 
@available(iOS 13.0, *)
internal struct ColumnNavigationView: _VariadicView_UnaryViewRoot {
    
    internal struct BodyContent: View {
        
        internal var isSidebarEnabled: Bool
        
        internal var children: _VariadicView_Children
        
        // Reference iOS15 optimization, fixed crash bug when children is empty (e.g. NavigationView {}) based on iOS14
        @ViewBuilder
        internal var body: some View {
            let distance = self.children.distance(from: 0, to: self.children.list.count)
            let emptyView = EmptyView()
            let emptyViewAdaptor = _UnaryViewAdaptor(emptyView)
            switch distance {
            case 0:
                let config = MulticolumnSplitView<_UnaryViewAdaptor<EmptyView>, Never, _UnaryViewAdaptor<EmptyView>>.Configuration(primary: emptyViewAdaptor, supplementary: nil, secondary: emptyViewAdaptor)
                MulticolumnSplitView(configuration: config)
            case 1:
                let config = MulticolumnSplitView<_VariadicView_Children.Element, Never, _UnaryViewAdaptor<EmptyView>>.Configuration(primary: self.children[0], supplementary: nil, secondary: emptyViewAdaptor)
                MulticolumnSplitView(configuration: config)
            case 2:
                let config = MulticolumnSplitView<_VariadicView_Children.Element, Never, _VariadicView_Children.Element>.Configuration(primary: self.children[0], supplementary: nil, secondary: self.children[1])
                MulticolumnSplitView(configuration: config)
            default:
                let secondary = HStack(alignment: .center, spacing: 0, content: {
                    ForEach(children[2...]) {
                        $0
                    }
                })
                let config = MulticolumnSplitView.Configuration(primary: self.children[0],
                                                                supplementary: self.children[1],
                                                                secondary: secondary)
                MulticolumnSplitView(configuration: config)
            }
        }
    }
    
    internal typealias Body = BodyContent
    
    internal var isSidebarEnabled: Swift.Bool
    
    internal func body(children: _VariadicView.Children) -> BodyContent {
        return BodyContent(isSidebarEnabled: self.isSidebarEnabled, children: children)
    }
    
}

/// A navigation view style represented by a series of views in columns.
///
/// You can also use ``NavigationViewStyle/columns`` to construct this style.
@available(iOS 13.0, *)
public struct ColumnNavigationViewStyle: NavigationViewStyle {
    
    internal var isSidebarEnabled: Bool
    
    internal static let willShowDetailNotification = Notification.Name("DanceUI.NotificationSendingSplitViewController")
    
    // introduced in iOS 15
    public init() {
        isSidebarEnabled = true
    }
    
    // This is the result after splitting FeatureConditional, original definition before split:
    //FeatureConditional<_VariadicView.Tree<DoubleColumnNavigationView, _NavigationViewStyleConfiguration.Content>, _VariadicView.Tree<ColumnNavigationView, _NavigationViewStyleConfiguration.Content>, BothFeatures<Semantics.IOSMultiColumnFeature, IOSSidebarListStyleFeature>>
    // Since IOSMultiColumnFeature and IOSSidebarListStyleFeature are both enabled, directly use _VariadicView.Tree<ColumnNavigationView, _NavigationViewStyleConfiguration.Content>
    public func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        // From analysis, since iOS 14 this decides between ColumnNavigationView or DoubleColumnNavigationView based on feature flag
        // And eventually reaches ColumnNavigationView logic
        // But on iOS 13 this is hardcoded to DoubleColumnNavigationView, so lower versions also use this approach
        // Returns fixed type, so cannot use if #available, must put logic in custom IOS14Above feature
        StaticIf(IOS14Above.self) {
            let root = ColumnNavigationView(isSidebarEnabled: false) 
            _VariadicView.Tree(root: root, content: _NavigationViewStyleConfiguration.Content())
        } else: {
            let root = DoubleColumnNavigationView() 
            _VariadicView.Tree(root: root, content: _NavigationViewStyleConfiguration.Content())
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct PassthroughNavigationView: _VariadicView_UnaryViewRoot, _VariadicView_ViewRoot {
    
    internal func body(children: _VariadicView.Children) -> some View {
        children
    }
}

@available(iOS 13.0, *)
internal struct PassthroughNavigationViewStyle: NavigationViewStyle {
    
    func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        _VariadicView.Tree(root: PassthroughNavigationView(), content: _NavigationViewStyleConfiguration.Content())
    }
}

/// The default navigation view style.
///
/// You can also use ``NavigationViewStyle/automatic`` to construct this style.
@available(iOS 13.0, *)
public struct DefaultNavigationViewStyle : NavigationViewStyle {
    
    /*
     public typealias _Body =
     ModifiedContent<
     ModifiedContent<
     ModifiedContent<
     ResolvedNavigationViewStyle,
     ViewInputDependency<
     StyleContextPredicate<SheetStyleContext>,
     NavigationViewStyleModifier<StackNavigationViewStyle>
     >
     >,
     ViewInputDependency<
     StyleContextPredicate<DocumentStyleContext>,
     NavigationViewStyleModifier<PassthroughNavigationViewStyle>
     >
     >,
     NavigationViewStyleModifier<ColumnNavigationViewStyle>
     >
     */
    
    public init() {
        _intentionallyLeftBlank()
    }
    
    public func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        ResolvedNavigationViewStyle().defaultBody()
    }
    
}
