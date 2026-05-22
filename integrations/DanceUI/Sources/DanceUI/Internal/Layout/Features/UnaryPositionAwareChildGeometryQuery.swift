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
internal struct UnaryPositionAwareChildGeometry<LayoutType: UnaryLayout>: Rule {

    internal typealias Value = ViewGeometry

    @Attribute
    internal var layout: LayoutType

    @Attribute
    internal var layoutDirection: LayoutDirection

    @Attribute
    internal var parentSize: ViewSize

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var transform: ViewTransform

    @Attribute
    internal var environment: EnvironmentValues

    internal var childLayoutComputer: OptionalAttribute<LayoutComputer>

    internal var safeAreaInsets: OptionalAttribute<SafeAreaInsets>

    internal var value: ViewGeometry {
        let context = DanceUIGraph.AnyRuleContext.current
        let layoutContext = _PositionAwarePlacementContext(context: context,
                                                           size: $parentSize,
                                                           environment: $environment,
                                                           transform: $transform,
                                                           position: $position,
                                                           safeAreaInsets: safeAreaInsets)
        let layoutProxy = LayoutProxy(context: context,
                                      attributes: .init(_layoutComputer: childLayoutComputer,
                                                        _traitsList: .init(nil)))
        let placement = layout.placement(of: layoutProxy, in: layoutContext as! LayoutType.PlacementContextType)

        var geometry = layoutProxy.finallyPlaced(at: placement, in: parentSize.value, layoutDirection: layoutDirection)
        let position = self.position
        geometry.origin.apply(position.value)
        return geometry
    }

}
