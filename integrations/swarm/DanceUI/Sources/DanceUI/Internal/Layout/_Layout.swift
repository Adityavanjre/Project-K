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
internal protocol _Layout: Animatable, _VariadicView_UnaryViewRoot {

    associatedtype PlacementContextType: _FinalPlacementContext

    func placement(of collection: LayoutProxyCollection,
                   in context: PlacementContext) -> [_Placement]


    func sizeThatFits(in size: _ProposedSize,
                      context: SizeAndSpacingContext,
                      children: LayoutProxyCollection) -> CGSize

    func updateLayoutComputer<Rule: StatefulRule>(rule: inout Rule,
                                                  layoutContext: SizeAndSpacingContext,
                                                  children: LayoutProxyCollection) where Rule.Value == LayoutComputer

    func layoutPriority(children: LayoutProxyCollection) -> Double

    static var layoutAxis: Axis? { get }

    static var isIdentityUnaryLayout: Bool { get }

    static func makeDynamicView(root: _GraphValue<Self>, inputs: _ViewInputs, list: Attribute<ViewList>) -> _ViewOutputs

    static func makeStaticView(root: _GraphValue<Self>, inputs: _ViewInputs, list: _ViewList_Elements) -> _ViewOutputs

}

@available(iOS 13.0, *)
extension _Layout {

    internal static var layoutAxis: Axis? { nil }

    internal func layoutPriority(children: LayoutProxyCollection) -> Double {
        0
    }

    public static func _makeView(root: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        makeView(root: root, inputs: inputs, body: body)
    }

    internal static func makeView(root: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        var newInputs = inputs
        if let axis = layoutAxis {
            newInputs.majorAxis = axis
            newInputs.hasMajorAxis = true
        } else {
            newInputs.hasMajorAxis = false
        }

        let listOutputs = body(_Graph(), newInputs)
        let output: _ViewOutputs
        switch listOutputs.views {
        case .staticList(let elements):
            output = makeStaticView(root: root, inputs: newInputs, list: elements)
        case .dynamicList(let listAttribute, let listModifier):
            var list = listAttribute
            if let listModifier = listModifier {
                list = Attribute(_ViewListOutputs.ApplyModifiers(base: list, modifier: listModifier))
            }
            output = makeDynamicView(root: root, inputs: newInputs, list: list)
        }
        return output
    }

    internal static func makeStaticView(root: _GraphValue<Self>, inputs: _ViewInputs, list: _ViewList_Elements) -> _ViewOutputs {

        let childCount = list.count

        if childCount == 1 && isIdentityUnaryLayout {
            let outputs = list.makeAllElements(inputs: inputs, indirectMap: nil) { inputs, makeOutputs in
                makeOutputs(inputs)
            }

            return outputs ?? _ViewOutputs()
        } else {

            let layoutComputerAttribute = Attribute(StaticLayoutComputer(layout: makeAnimatable(value: root, inputs: inputs.base), environment: inputs.environment, childAttributes: [] ))

            let viewGeometriesAttribute = Attribute(LayoutChildGeometries(parentSize: inputs.size, parentPosition: inputs.position, layoutComputer: layoutComputerAttribute))

            var index: Int = 0

            var childAttributes: [LayoutProxyAttributes] = []
            let outputs = list.makeAllElements(inputs: inputs, indirectMap: nil) { inputs, makeOutputs in
                let geometryAttribute = Attribute(LayoutChildGeometry(childGeometries: viewGeometriesAttribute, index: index))
                index &+= 1
                var newInputs = inputs
                newInputs.position = geometryAttribute.origin()
                newInputs.size = geometryAttribute.size()

                let output = makeOutputs(newInputs)
                childAttributes.append(LayoutProxyAttributes(_layoutComputer: output.layout, _traitsList: .init(nil)))
                return output
            }
            layoutComputerAttribute.mutateBody(as: StaticLayoutComputer<Self>.self, invalidating: true) { body in
                body.childAttributes = childAttributes
            }
            var result = _ViewOutputs(preferences: outputs?.preferences ?? PreferencesOutputs(), layout: outputs?.layout.attribute)
            result.setLayout(inputs) {
                layoutComputerAttribute
            }
            return result
        }
    }

    internal static func makeDynamicView(root: _GraphValue<Self>, inputs: _ViewInputs, list: Attribute<ViewList>) -> _ViewOutputs {

        let computer = DynamicLayoutComputer(
            layout: makeAnimatable(value: root, inputs: inputs.base),
            environment: inputs.environment,
            containerInfo: OptionalAttribute(nil),
            layoutComputerMap: DynamicLayoutMap(map: [], sortedArray: [], sortedSeed: 0x0)
        )
        let computerAttribute = Attribute(computer)
        let childGeometries = LayoutChildGeometries(parentSize: inputs.size, parentPosition: inputs.position, layoutComputer: computerAttribute)
        let childGeometriesAttribute = Attribute(childGeometries)

        func mapMutator(thunk: (inout DynamicLayoutMap) -> Void) {
            computerAttribute.mutateBody(as: DynamicLayoutComputer<Self>.self, invalidating: true) { computer in
                thunk(&computer.layoutComputerMap)
            }
        }

        let adaptor = DynamicLayoutViewAdaptor(
            item: list,
            childGeometries: OptionalAttribute(childGeometriesAttribute),
            mutateLayoutComputerMap: mapMutator
        )

        var newInputs = inputs
        newInputs.enableLayouts = false

        var (containerInfo, outputs) = DynamicContainer.makeContainer(adaptor: adaptor, inputs: newInputs)

        computerAttribute.mutateBody(as: DynamicLayoutComputer<Self>.self, invalidating: true) { computer in
            computer.$containerInfo = containerInfo
        }

        if inputs.preferences.requiresScrollable {

            let scrollablePreference = outputs.scrollable

            let scrollable = DynamicLayoutScrollable(
                list: WeakAttribute(list),
                childGeometries: WeakAttribute(childGeometriesAttribute),
                position: WeakAttribute(inputs.position),
                transform: WeakAttribute(inputs.transform),
                parent: WeakAttribute(inputs.scrollableView),
                children: WeakAttribute(scrollablePreference)
            )
            outputs.scrollable = Attribute(value: [scrollable])
        }
        outputs.setLayout(inputs) {
            computerAttribute
        }

        return outputs
    }

}

@available(iOS 13.0, *)
extension _Layout where PlacementContextType == PlacementContext {

    internal func updateLayoutComputer<Rule: StatefulRule>(rule: inout Rule, layoutContext: SizeAndSpacingContext, children: LayoutProxyCollection) where Rule.Value == LayoutComputer {
        rule.update(to: _LayoutEngine(layout: self, layoutContext: layoutContext, children: children))
    }
}

@available(iOS 13.0, *)
internal struct StaticLayoutComputer<Layout: _Layout>: StatefulRule {

    internal typealias Value = LayoutComputer

    @Attribute
    internal var layout: Layout

    @Attribute
    internal var environment: EnvironmentValues

    internal var childAttributes: [LayoutProxyAttributes]

    internal mutating func updateValue() {
        updateLayoutComputer(layout: layout,
                             environment: $environment,
                             layoutAttributes: childAttributes)
    }
}

@available(iOS 13.0, *)
internal struct LayoutChildGeometries: Rule {

    internal typealias Value = [ViewGeometry]

    @Attribute
    internal var parentSize: ViewSize

    @Attribute
    internal var parentPosition: ViewOrigin

    @Attribute
    internal var layoutComputer: LayoutComputer

    internal var value: [ViewGeometry] {
        return layoutComputer.engine.childGeometries(at: parentSize, origin: parentPosition.value)
    }
}

@available(iOS 13.0, *)
internal struct LayoutChildGeometry: Rule {

    internal typealias Value = ViewGeometry

    @Attribute
    internal var childGeometries: [ViewGeometry]

    internal let index: Swift.Int

    internal var value: ViewGeometry {
        childGeometries[index]
    }
}
