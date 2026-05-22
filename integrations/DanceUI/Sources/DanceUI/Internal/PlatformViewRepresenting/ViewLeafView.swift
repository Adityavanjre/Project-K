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

@available(iOS 13.0, *)
internal struct ViewLeafView<Content: PlatformViewRepresentable>: RendererLeafView, PlatformViewFactory {
    
    internal typealias PlatformViewProvider = Content.PlatformViewProvider
    
    internal let content: Content
    
    internal var platformView: PlatformViewHost<Content>
    
    internal var coordinator: Content.Coordinator
    
    internal static func _makeView(view: _GraphValue<ViewLeafView<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        var outputs = _makeLeafView(view: view, inputs: inputs)
        outputs.setLayout(inputs) {
            let signal = Attribute(value: Void())
            let weakSignal = WeakAttribute(signal)
            let layoutComputer =  Attribute(InvalidatableLeafLayoutComputer<Content>(view: view.value,
                                                                                                  rendererHost: ViewGraph.viewRendererHost,
                                                                                                  invalidationSignal: weakSignal))
            
            layoutComputer.addInput(signal, options: .sentinel, token: 0)
            return layoutComputer
        }
        return outputs
    }
    
    internal var representedViewProvider: PlatformViewProvider {
        platformView.representedViewProvider!
    }
    
    internal func layoutTraits() -> _LayoutTraits {
        var traits = content.intrinsicLayoutTraits(for: platformView)
        
        content.overrideLayoutTraits(&traits, for: representedViewProvider)
        
        return traits
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize) -> CGSize {
        let traits = layoutTraits()
        
        let width = proposedSize.width ?? traits.width.ideal
        
        let height = proposedSize.height ?? traits.height.ideal
        
        _danceuiPrecondition(traits.width.min <= traits.width.max)
        _danceuiPrecondition(traits.height.min <= traits.height.max)
        
        var size = CGSize(width: max(min(traits.width.max, width), traits.width.min),
                          height: max(min(traits.height.max, height), traits.height.min))
        
        let values = PlatformViewRepresentableValues(preferenceBridge: platformView.host?.viewGraph.preferenceBridge,
                                                     transaction: Transaction.current,
                                                     environment: platformView.environment)
        let context = PlatformViewRepresentableContext<Content>(values: values,
                                                                coordinator: coordinator)
        
        content.overrideSizeThatFits(&size, in: proposedSize, platformView: representedViewProvider, context: context)
        
        return size
    }
    
    // MARK: PlatformViewFactory
    
    internal func makePlatformView() -> UIView {
        platformView
    }
    
    internal func updatePlatformView(_ view: inout UIView) {
        view = platformView
    }
    
    internal func renderPlatformView(in graphicsContext: GraphicsContext, size: CGSize, renderer: DisplayList.GraphicsRenderer) {
        renderer.renderPlatformView(platformView, in: graphicsContext, size: size, viewType: Content.self)
    }
    
}

@available(iOS 13.0, *)
private struct InvalidatableLeafLayoutComputer<View: PlatformViewRepresentable>: StatefulRule {
    
    fileprivate typealias Value = LayoutComputer
    
    @Attribute
    fileprivate var view: ViewLeafView<View>
    
    fileprivate weak var rendererHost: ViewRendererHost?
    
    fileprivate let invalidationSignal: WeakAttribute<Void>
    
    fileprivate mutating func updateValue() {
        let leafView = view
        if leafView.platformView.layoutInvalidator == nil {
            let invalidationSignal = self.invalidationSignal
            leafView.platformView.layoutInvalidator = { [weak rendererHost] in
                guard let rendererHost = rendererHost else {
                    return
                }
                rendererHost.viewGraph.asyncTransaction(Transaction(),
                                                        mutation: InvalidatingGraphMutation(attribute: invalidationSignal),
                                                        style: .ignoresFlush,
                                                        mayDeferUpdate: true)
            }
        }
        update(to: LeafLayoutEngine(view: leafView,
                                    cache: Cache3<_ProposedSize, CGSize>()))
    }
}
