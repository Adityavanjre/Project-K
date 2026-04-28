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
internal struct PlatformViewRepresentableAdaptor<ViewType: UIViewRepresentable>: PlatformViewRepresentable, View {
    
    internal typealias Body = ViewType.Body
    
    internal typealias Coordinator = ViewType.Coordinator
    
    internal typealias PlatformViewProvider = ViewType.UIViewType
    
    internal typealias Context = UIViewRepresentableContext<ViewType>
    
    typealias PlatformView = ViewType
    
    internal var base: ViewType
    
    internal var body: Body {
        Update.syncMainWithoutUpdate {
            base.body
        }
    }
    
    internal static func platformView(for view: ViewType.UIViewType) -> UIView {
        view
    }
    
    internal func _identifiedViewTree(in provider: PlatformViewProvider) -> _IdentifiedViewTree { // Implementation must be wrapped in Update.syncMainWithoutUpdate to prevent async height calculation from being triggered asynchronously
        base._identifiedViewTree(in: provider)
    }

    internal func makeViewProvider(context: PlatformViewRepresentableContext<Self>) -> PlatformViewProvider {
        Update.syncMainWithoutUpdate {
            let platformContext = UIViewRepresentableContext<ViewType>(
                coordinator: context.coordinator,
                transaction: context.values.transaction,
                environment: context.values.environment,
                preferenceBridge: context.values.preferenceBridge
            )
            
            return base.makeUIView(context: platformContext)
        }
    }

    internal func updateViewProvider(_ platformView: PlatformViewProvider, context: PlatformViewRepresentableContext<Self>) {
        Update.syncMainWithoutUpdate {
            let platformContext = UIViewRepresentableContext<ViewType>(
                coordinator: context.coordinator,
                transaction: context.values.transaction,
                environment: context.values.environment,
                preferenceBridge: context.values.preferenceBridge
            )
            
            base.updateUIView(platformView, context: platformContext)
        }
    }
    
    internal func makeCoordinator() -> Coordinator {
        Update.syncMainWithoutUpdate {
            base.makeCoordinator()
        }
    }

    internal func overrideLayoutTraits(_ layoutTraits: inout _LayoutTraits, for platformView: PlatformViewProvider) {
        Update.syncMainWithoutUpdate {
            base._overrideLayoutTraits(&layoutTraits, for: platformView)
        }
    }

    internal func overrideSizeThatFits(_ size: inout CGSize, in proposedSize: _ProposedSize, platformView: PlatformViewProvider, context: PlatformViewRepresentableContext<Self>) {
        Update.syncMainWithoutUpdate {
            let platformContext = UIViewRepresentableContext<ViewType>(
                coordinator: context.coordinator,
                transaction: context.values.transaction,
                environment: context.values.environment,
                preferenceBridge: context.values.preferenceBridge
            )
            if let fittingSize = base.sizeThatFits(ProposedViewSize(proposedSize), uiView: platformView, context: platformContext) {
                size = fittingSize
            } else {
                base._overrideSizeThatFits(&size, in: proposedSize, uiView: platformView)
            }
        }
    }
    
    internal static func dismantleViewProvider(_ platformView: PlatformViewProvider, coordinator: Coordinator) {
        Update.syncMainWithoutUpdate {
            ViewType.dismantleUIView(platformView, coordinator: coordinator)
        }
    }
    
    internal static func dynamicProperties() -> DynamicPropertyCache.Fields {
        DynamicPropertyCache.fields(of: ViewType.self)
    }
    
    internal static var isViewController: Bool {
        return false
    }
    
    internal func specializationContext(for context: PlatformViewRepresentableContext<Self>) -> UIViewRepresentableContext<ViewType> {
        UIViewRepresentableContext(
            coordinator: context.coordinator,
            transaction: context.values.transaction,
            environment: context.values.environment,
            preferenceBridge: context.values.preferenceBridge
        )
    }
    
}
