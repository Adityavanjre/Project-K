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
internal class DanceUINavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            self.navigationBar.standardAppearance.backgroundImage = UIImage()
            self.navigationBar.standardAppearance.shadowImage = UIImage()
        } else {
            self.navigationBar.shadowImage = UIImage()
            self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        }
    }

}

@available(iOS 13.0, *)
internal class SplitViewNavigationController: DanceUINavigationController {

    internal func replaceRoot<Root: View>(root: Root, in environment: EnvironmentValues) {
        self.update(with: root, in: environment)
    }

    internal func applyStyleContextModifier<A: View>(to: A) -> AnyView {
        AnyView(to)
    }
    
}

@available(iOS 13.0, *)
internal final class StyleContextSplitViewNavigationController<A: StyleContext>: SplitViewNavigationController {

    internal init<Content: View>(rootView: Content) {
        let styledView = rootView.modifier(Self.defaultModifier)
        let hostingController = UIHostingController(rootView: styledView)
        super.init(rootViewController: hostingController)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }

    internal override init(navigationBarClass: AnyObject.Type?, toolbarClass: AnyObject.Type?) {
        _unimplementedInitializer(className: "DanceUI.StyleContextSplitViewNavigationController")
    }

    internal override init(nibName: String?, bundle: Bundle?) {
        _unimplementedInitializer(className: "DanceUI.StyleContextSplitViewNavigationController")
    }
    
    fileprivate static var defaultModifier: StyleContextWriter<A> {
        return StyleContextWriter()
    }

    internal override func applyStyleContextModifier<Content: View>(to view: Content) -> AnyView {
        let styledView = view.modifier(Self.defaultModifier)
        return AnyView(styledView)
    }
    
    override func replaceRoot<Root>(root: Root, in environment: EnvironmentValues) where Root : View {
        let styledRoot = root.modifier(Self.defaultModifier)
        super.replaceRoot(root: styledRoot, in: environment)
    }
    
}
