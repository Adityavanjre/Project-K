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
extension Text: UnaryView {
    
    public typealias Body = Never
    
    public static func _makeView(view: _GraphValue<Text>, inputs: _ViewInputs) -> _ViewOutputs {
        var newInputs = inputs
        
        let requiresPlatformItemList = inputs.preferences.requiresPlatformItemList
        
        if requiresPlatformItemList {
            newInputs.preferences.requiresPlatformItemList = false
        }
        
        var outputs = makeCommonAttributes(view: view, inputs: newInputs)
        
        if requiresPlatformItemList && inputs.platformItemsListFlags.contains(.includesAccessibility) {
            let resolvedTextFilter = Attribute(ResolvedTextFilter(text: view.value,
                                                                  environment: inputs.environment,
                                                                  time: inputs.time,
                                                                  isArchived: inputs.isArchived,
                                                                  includeAccessibility: inputs.platformItemsListFlags.contains(.includesAccessibility)))
            outputs.makePreferenceWriter(inputs: inputs, key: PlatformItemList.Key.self, value: Attribute(PlatformRepresentation(text: resolvedTextFilter)))
        }
        
        return outputs
    }
    
    internal static func makeCommonAttributes(view: _GraphValue<Text>,
                                              inputs: _ViewInputs) -> _ViewOutputs {
        let resolvedTextFilter = ResolvedTextFilter(text: view.value,
                                                    environment: inputs.environment,
                                                    time: inputs.time,
                                                    includeDefaultAttributes: true,
                                                    isArchived: inputs.isArchived)
        func makeTextView() -> _ViewOutputs {
            let resolvedText = Attribute(resolvedTextFilter)
            let textChildQuery = TextChildQuery(resolvedText: resolvedText, unresolvedText: view.value)
            let textChild = Attribute(textChildQuery)
            // let shouldRecordTree = AGSubgraphShouldRecordTree()
            // if shouldRecordTree {
            //   AGSubgraphBeginTreeElement()
            // }
            // defer {
            //   if shouldRecordTree {
            //     AGSubgraphEndTreeElement()
            //   }
            // }
            return TextChildQuery.Value.makeDebuggableView(value: _GraphValue(textChild), inputs: inputs)
        }
        
        return makeTextView()
    }
    
    fileprivate struct PlatformRepresentation: Rule {
        
        fileprivate typealias Value = PlatformItemList
        
        @Attribute
        fileprivate var text: ResolvedStyledText
        
        fileprivate var value: Value {
            PlatformItemList(items: [PlatformItemList.Item(text: text)])
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct TextChildQuery: Rule {
    
    internal typealias Value = AccessibilityStyledTextContentView
    
    @Attribute
    internal var resolvedText: ResolvedStyledText
    
    @Attribute
    internal var unresolvedText: Text
    
    internal var value: Value {
        AccessibilityStyledTextContentView(text: resolvedText, unresolvedText: unresolvedText)
    }
}

@available(iOS 13.0, *)
internal struct AccessibilityStyledTextContentView: View {
    
    var text: ResolvedStyledText

    var unresolvedText: Text
    
    var body: some View {
        StyledTextContentView(text)
            .gestureContainer()
            .accessibilityLabel(unresolvedText)
            .accessibilityAddTraits(.isStaticText)
    }

}

@available(iOS 13.0, *)
internal struct StyledTextContentView: ContentResponder, ShapeStyledLeafView {
    
    internal var resolvedStyledText: ResolvedStyledText
    
    internal init(_ resolvedStyledText: ResolvedStyledText) {
        self.resolvedStyledText = resolvedStyledText
    }

    
    internal static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        var childInputs = inputs
        
        if inputs.preferences.requiresPlatformItemList {
            childInputs.preferences.requiresPlatformItemList = false
        }
        
        let resolvedForegroundStyle = childInputs.resolvedForegroundStyle(role: .stroke, mode: nil)
        
        var outputs = makeLeafView(view: view, inputs: childInputs, style: resolvedForegroundStyle)
        
        outputs.setLayout(inputs) {
            Attribute(StyledTextLayoutComputer(textView: view.value))
        }
        
        if !DanceUIFeature.gestureContainer.isEnable {
            if inputs.preferences.requiresViewResponders {
                let responder = StyledTextResponder(view: view.value, style: resolvedForegroundStyle, inputs: inputs, gestureRecognizer: nil)
                outputs.viewResponders = Attribute(StyledTextResponderFilter(responder: responder))
            }
        }
        
        return outputs
    }
    
    
    internal static var animatesSize: Bool {
        false
    }
    
    internal func shape(size: CGSize, edgeInsets: EdgeInsets) -> (ShapeStyle_RenderedShape.Shape, CGRect) {
        let positioningRect = CGRect(origin: .zero, size: size).inset(by: edgeInsets)
        let renderRect = CGRect(origin: .zero, size: positioningRect.size)
        let shape = ShapeStyle_RenderedShape.Shape(path: Path(renderRect), fillStyle: FillStyle())
        let rect = resolvedStyledText.frame(in: size)
        return (shape, rect.inset(by: edgeInsets))
    }
    
}

@available(iOS 13.0, *)
extension StyledTextContentView {
    
    fileprivate func gestureContainer() -> some View {
        modifier(StyledTextResponderGestureContainerModifier(shadowedView: self), require: DanceUIFeature.gestureContainer)
    }
    
}

@available(iOS 13.0, *)
private struct StyledTextResponderGestureContainerModifier: PrimitiveViewModifier {
    
    fileprivate var shadowedView: StyledTextContentView
    
    internal static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let child = StyledTextResponderGestureContainerChild(shadowedView: modifier.value.shadowedView).makeAttribute()
        
        return StyledTextResponderGestureContainerChild.Value._makeView(modifier: _GraphValue(child), inputs: inputs, body: body)
    }
    
}

@available(iOS 13.0, *)
private struct StyledTextResponderGestureContainerChild: Rule {
    
    @Attribute
    fileprivate var shadowedView: StyledTextContentView
    
    fileprivate var gestureRecognizer: UIGestureRecognizer?
    
    fileprivate var value: StyledTextResponderGestureContainerViewModifier {
        StyledTextResponderGestureContainerViewModifier(shadowedView: shadowedView, gestureRecognizer: gestureRecognizer)
    }
    
}

@available(iOS 13.0, *)
private struct StyledTextResponderGestureContainerViewModifier: MultiViewModifier, RendererEffect {
    
    fileprivate var shadowedView: StyledTextContentView
    
    fileprivate var gestureRecognizer: UIGestureRecognizer?
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        if let gestureRecognizer = gestureRecognizer {
            return .gestureRecognizers([gestureRecognizer])
        } else {
            return .identity
        }
    }
    
    internal static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        assert(DanceUIFeature.gestureContainer.isEnable)
        
        var bodyInputs = inputs
        bodyInputs.hitTestInsets = nil
        
        let resolvedForegroundStyle = inputs.resolvedForegroundStyle(role: .stroke, mode: nil)
        
        var outputs = makeRendererEffect(effect: modifier, inputs: inputs, body: body)
        
        if inputs.preferences.requiresViewResponders {
            let gestureRecognizer = UIKitResponderGestureRecognizer()
            modifier.value.mutateBody(as: StyledTextResponderGestureContainerChild.self, invalidating: false) { body in
                body.gestureRecognizer = gestureRecognizer
            }
            
            let responder = StyledTextResponder(view: modifier.value.shadowedView, style: resolvedForegroundStyle, inputs: inputs, gestureRecognizer: gestureRecognizer)
            outputs.viewResponders = Attribute(StyledTextResponderFilter(responder: responder))
        }
        
        return outputs
    }
    
    
    
}

@available(iOS 13.0, *)
private struct StyledTextLayoutComputer: StatefulRule {
    
    internal mutating func updateValue() {
        update(to: StyledTextLayoutEngine(text: textView.resolvedStyledText))
    }
    
    internal typealias Value = LayoutComputer
    
    @Attribute
    internal var textView: StyledTextContentView
}

@available(iOS 13.0, *)
private struct StyledTextResponderFilter: StatefulRule {
    
    fileprivate typealias Value = [ViewResponder]
    
    fileprivate let responder : StyledTextResponder
    
    fileprivate mutating func updateValue() {
        responder.update()
        guard !hasValue else {
            return
        }
        value = [responder]
    }
    
}

@available(iOS 13.0, *)
extension ResolvedStyledText {
    
    fileprivate func frame(in size: CGSize) -> CGRect {
        let metrics = self.metrics(requestedSize: size)
        let bounds = CGRect(
            x: -self.layoutProperties.bodyHeadOutdent,
            y: 0,
            width: metrics.size.width,
            height: metrics.size.height)
        let insets = self.layoutMargins - self.drawingMargins
        return bounds.inset(by: insets)
    }
    
}
