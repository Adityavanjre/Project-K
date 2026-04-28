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

@available(iOS 13.0, *)
internal struct PlatformViewControllerRepresentableAdaptor<ViewControllerType: UIViewControllerRepresentable>: PlatformViewRepresentable {
    
    internal typealias Body = ViewControllerType.Body
    
    internal typealias Coordinator = ViewControllerType.Coordinator
    
    internal typealias PlatformViewProvider = ViewControllerType.UIViewControllerType
    
    internal typealias PlatformView = ViewControllerType
    
    internal typealias Context = UIViewControllerRepresentableContext<ViewControllerType>
    
    internal var base: ViewControllerType
    
    internal var body: Body {
        Update.syncMainWithoutUpdate {
            base.body
        }
    }
    
    internal static func platformView(for provider: PlatformViewProvider) -> UIView {
        Update.syncMainWithoutUpdate {
            provider.view
        }
    }
    
    internal func _identifiedViewTree(in provider: PlatformViewProvider) -> _IdentifiedViewTree { // Implementation must be wrapped in Update.syncMainWithoutUpdate to prevent async height calculation from being triggered asynchronously
        base._identifiedViewTree(in: provider)
    }
    
    internal func makeViewProvider(context: PlatformViewRepresentableContext<Self>) -> PlatformViewProvider {
        Update.syncMainWithoutUpdate {
            let platformContext = specializationContext(for: context)
            return base.makeUIViewController(context: platformContext)
        }
    }
    
    internal func updateViewProvider(_ platformView: PlatformViewProvider, context: PlatformViewRepresentableContext<Self>) {
        Update.syncMainWithoutUpdate {
            let platformContext = specializationContext(for: context)
            base.updateUIViewController(platformView, context: platformContext)
        }
    }
    
    internal func makeCoordinator() -> Coordinator {
        Update.syncMainWithoutUpdate {
            base.makeCoordinator()
        }
    }
    
    internal func overrideLayoutTraits(_ layoutTraits: inout _LayoutTraits, for platformView: PlatformViewProvider) {
        let size = platformView.preferredContentSize
        if size.width > 0 {
            layoutTraits.width.ideal = size.width
        }
        if size.height > 0 {
            layoutTraits.height.ideal = size.height
        }
    }
    
    internal func overrideSizeThatFits(_ size: inout CGSize, in proposedSize: _ProposedSize, platformView: PlatformViewProvider, context: PlatformViewRepresentableContext<Self>) {
        Update.syncMainWithoutUpdate {
            let platformContext = UIViewControllerRepresentableContext<ViewControllerType>(
                coordinator: context.coordinator,
                transaction: context.values.transaction,
                environment: context.values.environment,
                preferenceBridge: context.values.preferenceBridge
            )
            if let fittingSize = base.sizeThatFits(ProposedViewSize(proposedSize), uiViewController: platformView, context: platformContext) {
                size = fittingSize
            }
        }
    }
    
    internal static func dismantleViewProvider(_ provider: PlatformViewProvider, coordinator: Coordinator) {
        Update.syncMainWithoutUpdate {
            ViewControllerType.dismantleUIViewController(provider, coordinator: coordinator)
        }
    }
    
    internal static func dynamicProperties() -> DynamicPropertyCache.Fields {
        DynamicPropertyCache.fields(of: ViewControllerType.self)
    }
    
    internal static var isViewController: Bool {
        return true
    }
    
    internal func specializationContext(for context: PlatformViewRepresentableContext<Self>) -> UIViewControllerRepresentableContext<ViewControllerType> {
        UIViewControllerRepresentableContext(
            coordinator: context.coordinator,
            transaction: context.values.transaction,
            environment: context.values.environment,
            preferenceBridge: context.values.preferenceBridge
        )
    }
    
}
