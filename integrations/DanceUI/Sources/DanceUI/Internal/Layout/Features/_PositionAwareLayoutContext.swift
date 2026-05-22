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
internal struct _PositionAwarePlacementContext: _FinalPlacementContext {

    private var context: AnyRuleContext

    private var _size: Attribute<ViewSize>

    private var _environment: Attribute<EnvironmentValues>

    private var _transform: Attribute<ViewTransform>

    private var _position: Attribute<ViewOrigin>

    private var _safeAreaInsets: OptionalAttribute<SafeAreaInsets>

    internal init(context: AnyRuleContext,
                  size: Attribute<ViewSize>,
                  environment: Attribute<EnvironmentValues>,
                  transform: Attribute<ViewTransform>,
                  position: Attribute<ViewOrigin>,
                  safeAreaInsets: OptionalAttribute<SafeAreaInsets> = .init()) {
        self.context = context
        self._size = size
        self._environment = environment
        self._transform = transform
        self._position = position
        self._safeAreaInsets = safeAreaInsets
    }

    @inlinable
    internal var size: CGSize {
        context[_size].value
    }

    @inlinable
    internal var proposedSize: _ProposedSize {
        context[_size]._proposal.proposedSize
    }

    @inlinable
    internal var environment: EnvironmentValues {
        context[_environment]
    }

    @inlinable
    internal var position: ViewOrigin {
        context[_position]
    }

    @inlinable
    internal var transform: ViewTransform {
        var newTransform = context[_transform]
        let position: ViewOrigin = position
        let positionValue = position.value

        let translationWidth = positionValue.x - newTransform.positionAdjustment.width
        let translationHeight = positionValue.y - newTransform.positionAdjustment.height
        let translation = CGSize(width: -translationWidth, height: -translationHeight)
        newTransform.appendTranslation(translation)

        newTransform.applyPositionAdjustment(CGSize(width: positionValue.x, height: positionValue.y))
        return newTransform
    }

    @inlinable
    internal func safeAreaInsets(matching regions: SafeAreaRegions) -> EdgeInsets {
        guard let safeAreaInsets = context[_safeAreaInsets] else {
            return .zero
        }
        return safeAreaInsets.resolve(regions: regions, in: self)
    }
}

@available(iOS 13.0, *)
extension UnaryLayout where PlacementContextType == _PositionAwarePlacementContext {

    static internal func makeViewImpl(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {

        let childGeometry = UnaryPositionAwareChildGeometry(layout: modifier.value, layoutDirection: inputs.environmentAttribute(keyPath: \EnvironmentValues.layoutDirection), parentSize: inputs.size, position: inputs.position, transform: inputs.transform, environment: inputs.environment, childLayoutComputer: OptionalAttribute<LayoutComputer>(), safeAreaInsets: inputs.safeAreaInsets)

        let childGeometryAttribute = Attribute(childGeometry)

        var newInputs = inputs
        newInputs.position = childGeometryAttribute.origin()
        newInputs.size = childGeometryAttribute.size()
        newInputs.enableLayouts = true
        var outputs = body(_Graph(), newInputs)

        childGeometryAttribute.mutateBody(as: UnaryPositionAwareChildGeometry<Self>.self, invalidating: true) { body in
            body.childLayoutComputer = outputs.layout
        }
        let childLayoutComputer = outputs.layout
        outputs.setLayout(inputs) {
            Attribute(UnaryPositionAwareLayoutComputer(layout: modifier.value, environment: inputs.environment, childLayoutComputer: childLayoutComputer))
        }

        return outputs
    }

}
