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
internal struct NavigationDestination<Content: View>: ViewModifier {

    @Namespace
    internal var namespace

    @Binding
    internal var isPresented: Bool

    internal var isDetail: Bool

    internal var navigationContent: Content

    internal init(isPresented: Binding<Bool>,
                  updateSeed: Binding<UInt32>?,
                  isDetail: Bool,
                  navigationContent: Content) {
        self._namespace = Namespace()
        self._isPresented = isPresented
        self.isDetail = isDetail
        self.navigationContent = navigationContent
    }
    
    @ViewBuilder
    internal func body(content: Self.Content) -> some View {
        let base = self.base(content, environment: nil, updateSeed: nil)

        base.accessibilityLinkedGroup(id: "navigationLink", in: self.namespace)
    }
    
    internal func base(_ content: Self.Content, environment: EnvironmentValues?, updateSeed: UInt32?) -> some View {
        content.transactionalPreferenceTransform(key: NavigationDestinationsKey.self) { value, transaction in
            guard self.isPresented else {
                value.removeValue(forKey: self.namespace)
                return
            }
            
            let destinationContent = NavigationDestinationContent(id: self.namespace,
                                                                  content: self.navigationContent,
                                                                  isDetail: self.isDetail,
                                                                  transaction: transaction,
                                                                  environment: environment,
                                                                  updateSeed: updateSeed) {
                self.dismiss()
            }
            
            value[self.namespace] = destinationContent
        }
    }
    
    fileprivate func dismiss() {
        self.isPresented = false
    }
}

@available(iOS 13.0, *)
internal struct NavigationDestinationContent {

    internal var id: Namespace.ID

    internal var isDetail: Bool

    internal var onDismiss: () -> ()

    internal var transaction: Transaction

    internal var tag: Any?

    internal var generateContent: (Bool) -> AnyView
    
    internal init<ContentView: View>(id: Namespace.ID,
                                     content: ContentView,
                                     isDetail: Bool,
                                     transaction: Transaction,
                                     environment: EnvironmentValues?,
                                     updateSeed: UInt32?,
                                     onDismiss: @escaping () -> ()) {
        self.id = id
        self.isDetail = isDetail
        self.onDismiss = onDismiss
        self.transaction = transaction
        self.tag = nil
        self.generateContent = { hasStyle in
            let view = content.accessibilityLinkedGroup(id: "navigationLink", in: id)
            guard hasStyle else {
                return AnyView(view)
            }
            
            let styledView = view.styleContext(NoStyleContext())
            return AnyView(styledView)
        }
    }
    
}

@available(iOS 13.0, *)
internal struct NavigationDestinationsKey: HostPreferenceKey {
    
    internal typealias Value = [Namespace.ID: NavigationDestinationContent]
    
    internal static var defaultValue: Value {
        Value()
    }
    
    internal static func reduce(value: inout Value,
                                nextValue: () -> Value) {
        value.merge(nextValue()) { lhs, rhs in
            return rhs
        }
    }
    
}
