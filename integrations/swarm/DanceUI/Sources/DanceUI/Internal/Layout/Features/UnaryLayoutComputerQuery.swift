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
internal struct UnaryLayoutComputer<LayoutType: UnaryLayout>: StatefulRule where LayoutType.PlacementContextType == PlacementContext {

    internal typealias Value = LayoutComputer

    @Attribute
    internal var layout: LayoutType

    @Attribute
    internal var environment: EnvironmentValues

    @OptionalAttribute
    internal var childLayoutComputer: LayoutComputer?

    internal mutating func updateValue() {
        let context = SizeAndSpacingContext(environment: $environment)
        let engine = UnaryLayoutEngine(layout: layout,
                                       layoutContext: context,
                                       child: LayoutProxy(context: context.context, attributes: LayoutProxyAttributes(_layoutComputer: _childLayoutComputer, _traitsList: .init(nil))),
                                       dimensionsCache: .init(),
                                       placementCache: .init())
        update(to: engine)
    }

}
