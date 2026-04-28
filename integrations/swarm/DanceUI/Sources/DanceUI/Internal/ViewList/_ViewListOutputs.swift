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
#if SWIFT_PACKAGE
internal import DanceUIGraph
#else
internal import DanceUIGraph
#endif
@available(iOS 13.0, *)
public struct _ViewListOutputs {

    internal var views: Views

    internal var nextImplicitID: Int

    internal var staticCount: Int?

    internal enum Views {

        case staticList(_ViewList_Elements)

        case dynamicList(Attribute<ViewList>, ListModifier?)

        @inlinable
        internal var isStatic: Bool {
            if case .staticList = self { return true }
            return false
        }

    }

    internal class ListModifier {

        internal func apply(to viewList: inout ViewList) {
            _intentionallyLeftBlank()
        }
    }

    internal struct ApplyModifiers: Rule {

        internal typealias Value = ViewList

        @Attribute
        internal var base: ViewList

        internal let modifier: ListModifier

        internal var value: ViewList {
            var resultList = base
            modifier.apply(to: &resultList)
            return resultList
        }
    }

    internal func makeAttribute(inputs: _ViewListInputs) -> Attribute<ViewList> {
        switch views {
        case .staticList(let elements):
            return Attribute<ViewList>(value: BaseViewList(elements: elements, implicitID: inputs.implicitID, canTransition: inputs.canTransition, traitKeys: ViewTraitKeys(), traits: ViewTraitCollection()))
        case .dynamicList(let attribute, let modifier):
            if let modifier = modifier {
                return Attribute(ApplyModifiers(base: attribute, modifier: modifier))
            }
            return attribute
        }
    }

    internal mutating func multiModifier<Modifier: ViewModifier>(_ modifier: _GraphValue<Modifier>, inputs: _ViewListInputs) -> () {
        switch views {
        case .staticList(let elements):
            views = .staticList(ModifiedElements(base: elements, modifier: modifier, baseInputs: inputs.base))
        case .dynamicList(let attribute, let preModifier):
            views = .dynamicList(attribute, ModifiedViewList<Modifier>.ListModifier(pred: preModifier, modifier: modifier, inputs: inputs.base))
        }
    }

    internal static func unaryViewList<Content: View>(view: _GraphValue<Content>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let generator = TypedUnaryViewGenerator(view: view)
        let elements = UnaryElements(body: generator, baseInputs: inputs.base)
        return staticList(elements, inputs: inputs, staticCount: 1)
    }

    internal static func staticList(_ elements: _ViewList_Elements,
                                    inputs: _ViewListInputs,
                                    staticCount: Int) -> _ViewListOutputs {

        let nextImplicitID = inputs.implicitID &+ staticCount
        guard inputs.canTransition || inputs.$traits != nil else {
            return _ViewListOutputs(views: .staticList(elements),
                                    nextImplicitID: nextImplicitID,
                                    staticCount: staticCount)
        }

        let viewlist = BaseViewList.Init(elements: elements,
                                         implicitID: inputs.implicitID,
                                         canTransition: inputs.canTransition,
                                         traitKeys: inputs.traitKeys,
                                         traits: .init(inputs.$traits))
        return .init(views: .dynamicList(Attribute(viewlist), nil),
                     nextImplicitID: nextImplicitID,
                     staticCount: staticCount)
    }

    internal static func groupViewList<Parent: View, Footer: View>(parent: _GraphValue<Parent>,
                                                                   footer: _GraphValue<Footer>,
                                                                   inputs: _ViewListInputs,
                                                                   body: (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        var newInputs = inputs
        if !inputs.allowsNestedSections {
            newInputs.footerSectionedTrait = false
            newInputs.requiresSections = false
        }

        var headerInputs = newInputs
        if inputs.requiresDepthAndSections {
            headerInputs.$traits = .init(SectionedTrait(traits: .init(inputs.$traits)))
            headerInputs.traitKeys?.insert(IsSectionedTraitKey.self)
        }

        if inputs.footerSectionedTrait {
            headerInputs.hasParent = true
            headerInputs.$traits = .init(SectionHeaderTrait(traits: .init(headerInputs.$traits)))
            headerInputs.traitKeys?.insert(IsSectionHeaderTraitKey.self)
        }

        if inputs.headerStyleInput {
            headerInputs[StyleContextInput.self] = StyleContextInput.defaultValue
        }

        let headerOutputs = Parent._makeViewList(view: parent, inputs: headerInputs)

        var contentInputs = newInputs
        contentInputs.implicitID = headerOutputs.nextImplicitID
        if inputs.requiresDepthAndSections {
            contentInputs.$traits = .init(DepthTrait(traits: .init(inputs.$traits)))
            contentInputs.traitKeys?.insert(DepthTraitKey.self)
        }

        let contentOutputs = body(_Graph(), contentInputs)

        var footerInputs = newInputs
        footerInputs.implicitID = contentOutputs.nextImplicitID
        if inputs.footerSectionedTrait {
            footerInputs.$traits = .init(SectionFooterTrait(traits: .init(inputs.$traits)))
            footerInputs.traitKeys?.insert(SectionFooterTraitKey.self)
        }

        if inputs.footerStyleInput {
            footerInputs[StyleContextInput.self] = StyleContextInput.defaultValue
        }

        let footerOutputs = Footer._makeViewList(view: footer, inputs: footerInputs)

        if inputs.requiresSections {
            return .sectionListOutputs([headerOutputs, contentOutputs, footerOutputs], inputs: inputs)
        } else {
            return .concat([headerOutputs, contentOutputs, footerOutputs], inputs: inputs)
        }
    }

    internal static func sectionListOutputs(_ outputs: [_ViewListOutputs], inputs: _ViewListInputs) -> _ViewListOutputs {

        var viewLists: [Attribute<ViewList>] = []
        var staticCount: Int? = 0
        var nextImplicitID = inputs.implicitID
        for output in outputs {
            switch output.views {
            case .staticList(let elements):
                viewLists.append(.init(value: BaseViewList(elements: elements, implicitID: nextImplicitID, canTransition: inputs.canTransition, traitKeys: ViewTraitKeys(), traits: ViewTraitCollection())))
            case .dynamicList(let list, let modifier):
                if let modifier = modifier {
                    viewLists.append(Attribute(ApplyModifiers(base: list, modifier: modifier)))
                } else {
                    viewLists.append(list)
                }
            }

            nextImplicitID = output.nextImplicitID

            if let outputStaticCount = output.staticCount, staticCount != nil {
                staticCount! += outputStaticCount
            } else {
                staticCount = nil
            }
        }

        let sectionList = Attribute(MakeSection(lists: viewLists, traits: OptionalAttribute(inputs.$traits)))
        return _ViewListOutputs(views: .dynamicList(sectionList, nil), nextImplicitID: nextImplicitID, staticCount: staticCount)
    }

    internal static func concat(_ outputs: [_ViewListOutputs], inputs: _ViewListInputs) -> _ViewListOutputs {
        guard !outputs.isEmpty else {
            return .init(views: .staticList(EmptyViewListElements()), nextImplicitID: inputs.implicitID, staticCount: 0)
        }

        let copiedInputs = inputs

        var nextImplicitID: Int = copiedInputs.implicitID

        func mergeStatic(form beginIndex: Int, to endIndex: Int) -> _ViewListOutputs {
            let mergeCount = endIndex - beginIndex

            let element: _ViewList_Elements
            let staticCount: Int?
            switch mergeCount {
            case 0:
                element = EmptyViewListElements()
                staticCount = 0
            case 1:
                let output = outputs[beginIndex]
                guard case let .staticList(elements) = output.views else {
                    _danceuiPreconditionFailure()
                }
                element = elements
                staticCount = output.staticCount
            default:
                let mergedOutputs = Array(outputs[beginIndex..<endIndex])
                element = MergedElements(outputs: mergedOutputs)
                var newStaticCount: Int? = 0
                for output in mergedOutputs {
                    guard case .dynamicList = output.views else {
                        break
                    }
                    if case let .some(currentCount) = newStaticCount, let outputCount = output.staticCount {
                        newStaticCount = currentCount + outputCount
                    } else {
                        newStaticCount = nil
                    }
                }
                staticCount = newStaticCount
            }
            let list = BaseViewList(elements: element, implicitID: nextImplicitID, canTransition: copiedInputs.canTransition, traitKeys: copiedInputs.traitKeys, traits: ViewTraitCollection())
            let viewlistAttribute = Attribute<ViewList>(value: list)
            nextImplicitID = nextImplicitID &+ 1
            return .init(views: .dynamicList(viewlistAttribute, nil), nextImplicitID: nextImplicitID, staticCount: staticCount)
        }

        var dynamicLists: [Attribute<ViewList>] = []

        func appendDynamicList(_ outputs: _ViewListOutputs) {
            dynamicLists.append(outputs.makeAttribute(inputs: copiedInputs))
        }

        var mergedStaticEnd = 0
        var mergedStaticCount: Int? = nil
        for (index, output) in outputs.enumerated() {
            if let count = output.staticCount {
                mergedStaticCount = mergedStaticCount.map({$0 &+ count}) ?? count
            }
            guard case .dynamicList = output.views else {
                continue
            }
            let mergedOutputs: _ViewListOutputs!
            if mergedStaticEnd < index {
                mergedOutputs = mergeStatic(form: mergedStaticEnd, to: index)
                appendDynamicList(mergedOutputs)
            }
            dynamicLists.append(output.makeAttribute(inputs: copiedInputs))
            mergedStaticEnd = index &+ 1
        }

        if mergedStaticEnd < outputs.count {
            if mergedStaticEnd == 0 {
                if outputs.count == 1 {
                    return outputs[0]
                } else {
                    return .init(views: .staticList(MergedElements(outputs: outputs)), nextImplicitID: nextImplicitID, staticCount: mergedStaticCount)
                }
            } else {
                let mergedOutputs = mergeStatic(form: mergedStaticEnd, to: outputs.count)
                appendDynamicList(mergedOutputs)
            }
        }

        if dynamicLists.count == 0 {
            if copiedInputs.hasParent {
                return .nonEmptyParentViewList(inputs: copiedInputs)
            } else {
                return .staticList(EmptyViewListElements(), inputs: copiedInputs, staticCount: 0)
            }
        } else if dynamicLists.count == 1 {
            return .init(views: .dynamicList(dynamicLists[0], nil), nextImplicitID: nextImplicitID, staticCount: mergedStaticCount)
        } else {
            return .init(views: .dynamicList(Attribute(_ViewList_Group.Init(list: dynamicLists)), nil), nextImplicitID: nextImplicitID, staticCount: mergedStaticCount)
        }
    }

    internal static func nonEmptyParentViewList(inputs: _ViewListInputs) -> _ViewListOutputs {
        .staticList(EmptyViewListElements(), inputs: inputs, staticCount: 0)
    }
}

@available(iOS 13.0, *)
private struct MakeSection: Rule {

    internal typealias Value = ViewList

    internal var lists: [Attribute<ViewList>]

    @OptionalAttribute
    internal var traits: ViewTraitCollection?

    internal var value: ViewList {
        _ViewList_Section(id: DGAttribute.current!.rawValue, base: _ViewList_Group(lists: lists.map({($0.value, _GraphValue<ViewList>($0))})), traits: traits ?? ViewTraitCollection())
    }

}
