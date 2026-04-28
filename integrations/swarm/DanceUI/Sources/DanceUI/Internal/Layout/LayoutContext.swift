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
internal protocol _FinalPlacementContext {}

@available(iOS 13.0, *)
internal struct SizeAndSpacingContext {

    internal var context: AnyRuleContext
    
    @Attribute
    fileprivate var environment: EnvironmentValues
    
    internal init (_ context: AnyRuleContext,
                   environment: Attribute<EnvironmentValues>) {
        self.context = context
        self._environment = environment
    }
    
    internal init (environment: Attribute<EnvironmentValues>) {
        self.context = DanceUIGraph.AnyRuleContext(.current!)
        self._environment = environment
    }

    @inline(__always)
    internal func environmentValue<Member>(_ keyPath: KeyPath<EnvironmentValues, Member>) -> Member {
        return $environment.value(keyPath, self.context.attribute)
    }
    
}

@available(iOS 13.0, *)
internal struct PlacementContext: _FinalPlacementContext {
    
    internal var context: DanceUIGraph.AnyRuleContext

    @Attribute
    internal var environment: EnvironmentValues

    fileprivate let parentSize: ParentSize
    
    @inline(__always)
    internal var proposedSize: _ProposedSize {
        let _proposal: CGSize
        switch parentSize {
        case .eager(let size):
            _proposal = size._proposal
        case .lazy(let attribute):
            _proposal = context[attribute]._proposal
        }
        return _proposal.proposedSize
    }
    
    @inline(__always)
    internal var size: CGSize {
        switch parentSize {
        case .eager(let size):
            return size.value
        case .lazy(let attribute):
            return context[attribute].value
        }
    }
    
    fileprivate enum ParentSize {
        case eager(ViewSize)
        case lazy(Attribute<ViewSize>)
    }
    
    internal init(context: DanceUIGraph.AnyRuleContext,
                  environment: Attribute<EnvironmentValues>,
                  size: ViewSize) {
        self.context = context
        self._environment = environment
        self.parentSize = .eager(size)
    }
    
    @inline(__always)
    internal init(context: SizeAndSpacingContext, size: ViewSize) {
        self.init(context: context.context, environment: context.$environment, size: size)
    }
    
    @inline(__always)
    internal func environmentValue<Member>(_ keyPath: KeyPath<EnvironmentValues, Member>) -> Member {
        return $environment.value(keyPath, self.context.attribute)
    }
    
}

@available(iOS 13.0, *)
extension UnaryLayout where PlacementContextType == PlacementContext {
    
    internal static func makeViewImpl(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let animatable = makeAnimatable(value: modifier, inputs: inputs.base)
        let keypath = \EnvironmentValues.layoutDirection
        let layoutDirectionAttribute = inputs.environmentAttribute(keyPath: keypath)
        let layoutComputerAttribute = Attribute(UnaryLayoutComputer(layout: animatable, environment: inputs.environment))
        
        let geometryAttribute = Attribute(UnaryChildGeometry<Self>(parentSize: inputs.size, layoutDirection: layoutDirectionAttribute, parentLayoutComputer: layoutComputerAttribute))
        
        var newInputs = inputs
        
        newInputs.size = geometryAttribute.size()
        newInputs.position = Attribute(LayoutPositionQuery(parentPosition: inputs.position, localPosition: geometryAttribute.origin()))
        
        newInputs.enableLayouts = true
        
        var outputs = body(_Graph(), newInputs)
        layoutComputerAttribute.mutateBody(as: UnaryLayoutComputer<Self>.self, invalidating: true) { body in
            body.$childLayoutComputer = outputs.layout.attribute
        }
        
        geometryAttribute.mutateBody(as: UnaryChildGeometry<Self>.self, invalidating: true) { body in
            body.$childLayoutComputer = outputs.layout.attribute
        }
        outputs.setLayout(inputs) {
            layoutComputerAttribute
        }
        return outputs
    }
}
