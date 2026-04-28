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
internal struct SheetStyleContext: StyleContext {
    
}

@available(iOS 13.0, *)
internal struct DocumentStyleContext: StyleContext {
    
}

@available(iOS 13.0, *)
fileprivate struct BridgedNavigationView: UIViewControllerRepresentable {

    internal var children: _VariadicView_Children

    // Original implementation was UINavigationController, customized to force transparent navigation bar
    internal func makeUIViewController(context: Context) -> UINavigationController {
        guard let first = children.first else {
            return DanceUINavigationController()
        }
        let hostingController = UIHostingController(rootView: first)
        return DanceUINavigationController(rootViewController: hostingController)
    }
    
    internal func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        guard let first = children.first else {
            return
        }
        
        uiViewController.update(with: first, in: context.environment)
    }
    
    public func _identifiedViewTree(in uiViewController: UINavigationController) -> _IdentifiedViewTree {
        .empty
    }
}

@available(iOS 13.0, *)
fileprivate struct StackNavigationView: _VariadicView_UnaryViewRoot, _VariadicView_ViewRoot {

    internal func body(children: _VariadicView.Children) -> some View {
        return BridgedNavigationView(children: children)
            .ignoresSafeArea()
            .preference(key: HostingStatusBarContentKey.self, value: true)
    }
    
}

/// A navigation view style represented by a view stack that only shows a
/// single top view at a time.
///
/// You can also use ``NavigationViewStyle/stack`` to construct this style.
@available(macOS, unavailable)
@available(iOS 13.0, *)
public struct StackNavigationViewStyle: NavigationViewStyle {
    
    public init() {
        _intentionallyLeftBlank()
    }
    
    public func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        _VariadicView.Tree(root: StackNavigationView(), content: _NavigationViewStyleConfiguration.Content())
    }
    
}

@available(iOS 13.0, *)
internal struct ResolvedNavigationViewStyle: StyleableView {
    
    /*
    internal typealias DefaultBody =
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
                NavigationViewStyleModifier<PassthroughNavigationViewStyle>>
            >,
        NavigationViewStyleModifier<ColumnNavigationViewStyle>
    >
     */
    
    internal func defaultBody() -> some View {
        self
            .modifier(NavigationViewStyleModifier(style: StackNavigationViewStyle()).requiring(SheetStyleContext()))
            .modifier(NavigationViewStyleModifier(style: PassthroughNavigationViewStyle()).requiring(DocumentStyleContext()))
            .modifier(NavigationViewStyleModifier(style: ColumnNavigationViewStyle()))
        
    }
}
