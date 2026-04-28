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
internal struct AutomaticPaddingViewModifier: PrimitiveViewModifier, MultiViewModifier {
    
    internal var padding: EdgeInsets?
    
    internal static func _makeView(modifier: _GraphValue<AutomaticPaddingViewModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        guard inputs.base.enableLayouts || inputs.base.reposition else {
            return body(_Graph(), inputs)
        }
        let modifiedModifier = Attribute(PaddingLayout(modifier: modifier.value,
                                                       environment: inputs.environment,
                                                       childLayoutComputer: .init(nil)))
        return ModifiedContent<PaddingLayout.WrappedLayout, _SafeAreaInsetsModifier>._makeView(modifier: .init(modifiedModifier), inputs: inputs) { graph, childInputs in
            let outputs = body(graph, childInputs)
            modifiedModifier.mutateBody(as: PaddingLayout.self, invalidating: true) { body in
                body.childLayoutComputer = outputs.layout
            }
            return outputs
        }
    }
    
    internal struct PaddingLayout: Rule {
        
        internal typealias Value = ModifiedContent<WrappedLayout, _SafeAreaInsetsModifier>
        
        @Attribute
        internal var modifier: AutomaticPaddingViewModifier

        @Attribute
        internal var environment: EnvironmentValues

        internal var childLayoutComputer: OptionalAttribute<LayoutComputer>
        
        internal var value: Value {
            let childLayoutComputer = self.childLayoutComputer.value
            let insets: EdgeInsets
            if childLayoutComputer == nil || !childLayoutComputer!.engine.ignoresAutomaticPadding() {
                if let padding = modifier.padding {
                    insets = padding
                } else {
                    insets = environment.defaultPadding
                }
            } else {
                insets = .zero
            }
            return .init(content: .init(base: _PaddingLayout(edges: .all, insets: insets)), modifier: .init(elements: [], nextInsets: nil))
        }
        
    }
    
}

@available(iOS 13.0, *)
extension AutomaticPaddingViewModifier.PaddingLayout {
    
    internal struct WrappedLayout: PrimitiveViewModifier, MultiViewModifier, Animatable, UnaryLayout {
        
        internal typealias PlacementContextType = PlacementContext
        
        internal typealias Body = Never
        
        internal typealias AnimatableData = EmptyAnimatableData
        
        internal var base: _PaddingLayout
        
        func placement(of child: LayoutProxy, in context: PlacementContext) -> _Placement {
            base.placement(of: child, in: context)
        }
        
        func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
            base.sizeThatFits(in: proposedSize, context: context, child: child)
        }
        
        static func _viewListCount(inputs: _ViewListCountInputs, body: @escaping (_ViewListCountInputs) -> Int?) -> Int? {
            body(inputs)
        }
    }
}

@available(iOS 13.0, *)
extension View {
    
    public func _automaticPadding(_ edgeInsets: EdgeInsets? = nil) -> some View {
        modifier(AutomaticPaddingViewModifier(padding: edgeInsets))
    }
}
