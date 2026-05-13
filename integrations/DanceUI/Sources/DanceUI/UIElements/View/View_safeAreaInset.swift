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
import Foundation

@available(iOS 13.0, *)
extension View {

    /// Shows the specified content above or below the modified view.
    ///
    /// The `content` view is anchored to the specified
    /// vertical edge in the parent view, aligning its horizontal axis
    /// to the specified alignment guide. The modified view is inset by
    /// the height of `content`, from `edge`, with its safe area
    /// increased by the same amount.
    ///
    ///     struct ScrollableViewWithBottomBar: View {
    ///         var body: some View {
    ///             ScrollView {
    ///                 ScrolledContent()
    ///             }
    ///             .safeAreaInset(edge: .bottom, spacing: 0) {
    ///                 BottomBarContent()
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - edge: The vertical edge of the view to inset by the height of
    ///    `content`, to make space for `content`.
    ///   - spacing: Extra distance placed between the two views, or
    ///     nil to use the default amount of spacing.
    ///   - alignment: The alignment guide used to position `content`
    ///     horizontally.
    ///   - content: A view builder function providing the view to
    ///     display in the inset space of the modified view.
    ///
    /// - Returns: A new view that displays both `content` above or below the
    ///   modified view,
    ///   making space for the `content` view by vertically insetting
    ///   the modified view, adjusting the safe area of the result to match.
    //@inlinable
    public func safeAreaInset<V: View>(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View {
        var verticalEdge: Edge
        switch edge {
        case .top:
            verticalEdge = .top
        case .bottom:
            verticalEdge = .bottom
        }
        let insetViewModifier = _InsetViewModifier<V>(content: content(),
                                                      edge: verticalEdge,
                                                      regions: .container,
                                                      spacing: spacing,
                                                      alignmentKey: alignment.key)
        return self.modifier(insetViewModifier)
    }


    /// Shows the specified content beside the modified view.
    ///
    /// The `content` view is anchored to the specified
    /// horizontal edge in the parent view, aligning its vertical axis
    /// to the specified alignment guide. The modified view is inset by
    /// the width of `content`, from `edge`, with its safe area
    /// increased by the same amount.
    ///
    ///     struct ScrollableViewWithSideBar: View {
    ///         var body: some View {
    ///             ScrollView {
    ///                 ScrolledContent()
    ///             }
    ///             .safeAreaInset(edge: .leading, spacing: 0) {
    ///                 SideBarContent()
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - edge: The horizontal edge of the view to inset by the width of
    ///    `content`, to make space for `content`.
    ///   - spacing: Extra distance placed between the two views, or
    ///     nil to use the default amount of spacing.
    ///   - alignment: The alignment guide used to position `content`
    ///     vertically.
    ///   - content: A view builder function providing the view to
    ///     display in the inset space of the modified view.
    ///
    /// - Returns: A new view that displays `content` beside the modified view,
    ///   making space for the `content` view by horizontally insetting
    ///   the modified view.
    //@inlinable
    public func safeAreaInset<V: View>(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View {
        var horizontalEdge: Edge
        switch edge {
        case .leading:
            horizontalEdge = .leading
        case .trailing:
            horizontalEdge = .trailing
        }
        let insetViewModifier = _InsetViewModifier<V>(content: content(),
                                                      edge: horizontalEdge,
                                                      regions: .container,
                                                      spacing: spacing,
                                                      alignmentKey: alignment.key)
        return self.modifier(insetViewModifier)
    }
}

@available(iOS 13.0, *)
public struct _InsetViewModifier<Content: View>: MultiViewModifier, PrimitiveViewModifier {

    @usableFromInline
    internal var content: Content

    @usableFromInline
    internal var properties: (regions: SafeAreaRegions, spacing: CGFloat?, edge: Edge, alignmentKey: AlignmentKey)

    internal init(content: Content, edge: Edge, regions: SafeAreaRegions, spacing: CGFloat?, alignmentKey: AlignmentKey) {
        self.content = content
        self.properties = (regions, spacing, edge, alignmentKey)
    }
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var insetChildGeometryAttribute: Attribute<InsetChildGeometry.Value>?
        var insetPrimarySafeAreasAttribute: Attribute<InsetPrimarySafeAreas.Value>?
        var insetLayoutComputerAttribute: Attribute<InsetLayoutComputer.Value>?
        var modifiedInputs = _ViewInputs(inputs)
        var contentModifiedInputs = _ViewInputs(inputs)
        let props = modifier[{.of(&$0.properties)}]
        let layoutDirection = inputs.environmentAttribute(keyPath: \.layoutDirection)
        let insetViewLayout = InsetViewLayout(parentPosition: inputs.position,
                                              parentSize: inputs.size,
                                              props: props.value,
                                              layoutDirection: layoutDirection)
        if inputs.needReposition {
            let uniqueID = UniqueID()
            let insetChildGeometry = InsetChildGeometry(layout: insetViewLayout)
            insetChildGeometryAttribute = Attribute(insetChildGeometry)
            modifiedInputs.position = insetChildGeometryAttribute!.0.origin()
            modifiedInputs.size = insetChildGeometryAttribute!.0.size()
            contentModifiedInputs.position = insetChildGeometryAttribute!.1.origin()
            contentModifiedInputs.size = insetChildGeometryAttribute!.1.size()
            let insetPrimarySafeAreas = InsetPrimarySafeAreas(layout: insetViewLayout,
                                                              safeAreaInsets: inputs.safeAreaInsets,
                                                              uniqueID: uniqueID)
            insetPrimarySafeAreasAttribute = Attribute(insetPrimarySafeAreas)
            modifiedInputs.safeAreaInsets = OptionalAttribute(insetPrimarySafeAreasAttribute)
            let insetPrimaryTransform = InsetPrimaryTransform(position: inputs.position,
                                                              size: inputs.size,
                                                              transform: inputs.transform,
                                                              uniqueID: uniqueID)
            let insetPrimaryTransformAttribute = Attribute(insetPrimaryTransform)
            modifiedInputs.transform = insetPrimaryTransformAttribute
        }
        if inputs.enableLayouts {
            let insetLayoutComputer = InsetLayoutComputer(layout: insetViewLayout)
            insetLayoutComputerAttribute = Attribute(insetLayoutComputer)
        }

        let outputs = body(_Graph(), modifiedInputs)
        let view = modifier[{.of(&$0.content)}]
        // AGSubgraphShouldRecordTree skip some logic
        contentModifiedInputs.implicitRootType = _ZStackLayout.self
        let contentOutputs = Content._makeView(view: view, inputs: contentModifiedInputs)
        if inputs.needReposition {
            insetChildGeometryAttribute!.mutateBody(as: InsetChildGeometry.self, invalidating: true) { body in
                body.layout.$primaryLayoutComputer = outputs.layout.attribute
                body.layout.$secondaryLayoutComputer = contentOutputs.layout.attribute
            }
            insetPrimarySafeAreasAttribute!.mutateBody(as: InsetPrimarySafeAreas.self, invalidating: true) { body in
                body.layout.$primaryLayoutComputer = outputs.layout.attribute
                body.layout.$secondaryLayoutComputer = contentOutputs.layout.attribute
            }
        }
        
        if inputs.enableLayouts {
            insetLayoutComputerAttribute!.mutateBody(as: InsetLayoutComputer.self, invalidating: true) { body in
                body.layout.$primaryLayoutComputer = outputs.layout.attribute
                body.layout.$secondaryLayoutComputer = contentOutputs.layout.attribute
            }
        }
        var visitor = PairwisePreferenceCombinerVisitor(outputs: (outputs, contentOutputs),
                                                        result: _ViewOutputs())
        for key in inputs.preferences.keys {
            key.visitKey(&visitor)
        }
        visitor.result.overrideLayout(OptionalAttribute(inputs.enableLayouts ? insetLayoutComputerAttribute : nil))
        return visitor.result
    }


}

@available(iOS 13.0, *)
private struct InsetPrimarySafeAreas: AsyncAttribute, Rule {
    
    internal init(layout: InsetViewLayout, safeAreaInsets: OptionalAttribute<SafeAreaInsets>, uniqueID: UniqueID) {
        self.layout = layout
        self._safeAreaInsets = safeAreaInsets
        self.uniqueID = uniqueID
    }
    
    
    fileprivate typealias Value = SafeAreaInsets

    fileprivate var layout: InsetViewLayout

    @OptionalAttribute
    fileprivate var safeAreaInsets: SafeAreaInsets?

    fileprivate let uniqueID: UniqueID

    fileprivate var value: SafeAreaInsets {
        let safeAreaInsetsElement = layout.primarySafeAreaInsets()
        let next: SafeAreaInsets.OptionalValue = self.safeAreaInsets.map({ .insets($0) }) ?? .empty
        return SafeAreaInsets(space: uniqueID,
                              elements: [safeAreaInsetsElement],
                              next: next)
    }
}

@available(iOS 13.0, *)
private struct InsetViewLayout {

    @Attribute
    fileprivate var parentPosition: ViewOrigin

    @Attribute
    fileprivate var parentSize: ViewSize

    @Attribute
    fileprivate var props: (regions: SafeAreaRegions, spacing: CGFloat?, edge: Edge, alignmentKey: AlignmentKey)

    @Attribute
    fileprivate var layoutDirection: LayoutDirection

    @OptionalAttribute
    fileprivate var primaryLayoutComputer: LayoutComputer?
    
    @OptionalAttribute
    fileprivate var secondaryLayoutComputer: LayoutComputer?
    
    fileprivate func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        let spacing = spacing()
        let secondaryProposedSize = secondaryProposal(parentProposal: size, spacing: spacing)
        let secondaryComputerEngine = self.secondaryLayoutComputer?.engine ?? LayoutComputer().engine
        let secondaryFittingSize = secondaryComputerEngine.sizeThatFits(secondaryProposedSize)
        let proposedSize: _ProposedSize
        let edge = self.props.edge
        switch edge {
        case .top, .bottom:
            if let height = size.height {
                var length = height - (secondaryFittingSize.height + spacing)
                length = .maximum(0, length)
                proposedSize = _ProposedSize(width: size.width, height: length)
            } else {
                proposedSize = _ProposedSize(width: size.width, height: nil)
            }
        case .leading, .trailing:
            if let width = size.width {
                var length = width - (secondaryFittingSize.width + spacing)
                length = .maximum(0, length)
                proposedSize = _ProposedSize(width: length, height: size.height)
            } else {
                proposedSize = _ProposedSize(width: nil, height: size.height)
            }
        }
        let primaryComputerEngine = self.primaryLayoutComputer?.engine ?? LayoutComputer().engine
        let primaryFittingSize = primaryComputerEngine.sizeThatFits(proposedSize)
        let width: CGFloat
        let height: CGFloat
        switch edge {
        case .top, .bottom:
            width = CGFloat.maximum(secondaryFittingSize.width, primaryFittingSize.width)
            height = primaryFittingSize.height + spacing + secondaryFittingSize.height
        case .leading, .trailing:
            width = primaryFittingSize.width + spacing + secondaryFittingSize.width
            height = CGFloat.maximum(secondaryFittingSize.height, primaryFittingSize.height)
        }
        return CGSize(width: width, height: height)
    }

    fileprivate func childGeometry() -> (ViewGeometry, ViewGeometry) {
        let spacing = self.spacing()
        let edge = self.props.edge
        let parentSize = self.parentSize
        let parentSizeProposal = parentSize._proposal
        let parentSizeValue = parentSize.value
        var widthCandidate: CGFloat = parentSizeProposal.width

        var widthValid = !parentSizeProposal.width.isNaN
        var width = widthValid ? parentSizeProposal.width : nil

        let heightValid = !parentSizeProposal.height.isNaN
        var height = heightValid ? parentSizeProposal.height : nil
        switch self.props.edge {
        case .top, .bottom:
            widthCandidate = widthValid ? parentSizeProposal.width : parentSizeProposal.height
            widthValid = true
        case .leading, .trailing:
            break
        }

        let proposedSize = _ProposedSize(width: width, height: height)
        let proposedSizeForSecondaryComputer = secondaryProposal(parentProposal: proposedSize, spacing: spacing)
        let secondaryComputer = self.secondaryLayoutComputer ?? LayoutComputer()
        let secondaryFittingSize = secondaryComputer.engine.sizeThatFits(proposedSizeForSecondaryComputer)

        height = proposedSize.height
        var length: CGFloat
        switch edge {
        case .top, .bottom:
            if let h = proposedSize.height {   // proposedSize.height 不为空
                length = h - (spacing + secondaryFittingSize.height)
                width = CGFloat.maximum(0, length)
                height = CGFloat.maximum(0, length)
            } else {
                height = nil
            }
            width = widthValid ? widthCandidate : nil
           
        case .leading, .trailing:
           
            if widthValid {
                length = widthCandidate - (spacing + secondaryFittingSize.width)
                width = CGFloat.maximum(0, length)
            } else {
                width = nil
            }
            if !heightValid {
                height = nil
            }
        }

        let primaryComputer = self.primaryLayoutComputer ?? LayoutComputer()

        let proposedSizeForPrimaryComputer = _ProposedSize(width: width, height: height)
        let primaryFittingSize = primaryComputer.engine.sizeThatFits(proposedSizeForPrimaryComputer)
        let secondaryProposalSize = _ProposedSize(width: proposedSizeForSecondaryComputer.width, height: proposedSizeForSecondaryComputer.height)
        
        var factorPoint = CGPoint()
        switch edge {
        case .top:
            factorPoint.x = 0.5
            factorPoint.y = 1.0
        case .leading:
            factorPoint.x = 1.0
            factorPoint.y = 0.5
        case .bottom:
            factorPoint.x = 0.5
            factorPoint.y = 0.0
        case .trailing:
            factorPoint.x = 0.0
            factorPoint.y = 0.5
        }

        var primaryVGOriginOffsetX = (parentSizeValue.width - primaryFittingSize.width) * factorPoint.x
        let primaryVGOriginOffsetY = (parentSizeValue.height - primaryFittingSize.height) * factorPoint.y

        let primaryViewDimensions = ViewDimensions(guideComputer: primaryComputer,
                                            size: ViewSize(value: primaryFittingSize,
                                                           proposal: proposedSizeForPrimaryComputer))
        let primaryAlignmentValue = primaryViewDimensions[props.alignmentKey]
        let secondaryViewDimensions = ViewDimensions(guideComputer: secondaryComputer,
                                             size: ViewSize(value: secondaryFittingSize,
                                                            proposal: secondaryProposalSize))
        let secondaryAlignmentValue = secondaryViewDimensions[props.alignmentKey]
        let originX = primaryAlignmentValue + primaryVGOriginOffsetX - secondaryAlignmentValue
        let originY = primaryAlignmentValue + primaryVGOriginOffsetY - secondaryAlignmentValue

        var secondaryVGOriginOffsetX: CGFloat
        let secondaryVGOriginOffsetY: CGFloat

        let secondaryOriginX: CGFloat
        let secondaryOriginY: CGFloat
        switch edge {
        case .top:
            secondaryOriginX = originX
            secondaryOriginY = 0
        case .leading:
            secondaryOriginY = originY
            secondaryOriginX = 0
        case .bottom:
            secondaryOriginX = originX
            secondaryOriginY = (parentSizeValue.height - secondaryFittingSize.height)
        case .trailing:
            secondaryOriginY = originY
            secondaryOriginX = (parentSizeValue.width - secondaryFittingSize.width)
        }
        secondaryVGOriginOffsetX = secondaryOriginX
        secondaryVGOriginOffsetY = secondaryOriginY
        switch self.layoutDirection {
        case .leftToRight:
            break
        case .rightToLeft:
            let primaryOriginX = (parentSizeValue.width - primaryFittingSize.width) * factorPoint.x
            let primaryOriginY = (parentSizeValue.height - primaryFittingSize.height) * factorPoint.y

            let primaryMaxX = CGRect(origin: CGPoint(x: primaryOriginX, y: primaryOriginY), size: primaryFittingSize).maxX
            primaryVGOriginOffsetX = parentSizeValue.width - primaryMaxX

            let secondaryMaxX = CGRect(origin: CGPoint(x: secondaryOriginX, y: secondaryOriginY), size: secondaryFittingSize).maxX
            secondaryVGOriginOffsetX = parentSizeValue.width - secondaryMaxX
        }
        
        let parentPosition = self.parentPosition.value
        let primaryVGOriginX = primaryVGOriginOffsetX + parentPosition.x
        let primaryVGOriginY = primaryVGOriginOffsetY + parentPosition.y
        let primaryVGOrigin = CGPoint(x: primaryVGOriginX, y: primaryVGOriginY)
        
        let secondaryVGOriginX = parentPosition.x + secondaryVGOriginOffsetX
        let secondaryVGOriginY = parentPosition.y + secondaryVGOriginOffsetY
        let secondaryVGOrigin = CGPoint(x: secondaryVGOriginX, y: secondaryVGOriginY)
        let primaryViewGeometry = ViewGeometry(origin: ViewOrigin(value: primaryVGOrigin),
                                               dimensions: ViewDimensions(guideComputer: primaryComputer,
                                                                          size: ViewSize(value: primaryFittingSize,
                                                                                         proposal: proposedSizeForPrimaryComputer)))

        let secondaryViewGeometry = ViewGeometry(origin: ViewOrigin(value: secondaryVGOrigin),
                                                 dimensions: ViewDimensions(guideComputer: secondaryComputer,
                                                                            size: ViewSize(value: secondaryFittingSize,
                                                                                           proposal:secondaryProposalSize)))
        return (primaryViewGeometry, secondaryViewGeometry)
    }

    fileprivate func spacing() -> CGFloat {
        
        let prop = self.props
        if let spacing = prop.spacing {
            return spacing
        }
        let primaryComputerEngine = self.primaryLayoutComputer?.engine ?? LayoutEngineBox(engine: LayoutComputer.DefaultEngine())
        let secondaryComputerEngine = self.secondaryLayoutComputer?.engine ?? LayoutComputer().engine
        
        let primarySpacing = primaryComputerEngine.spacing()
        let secondarySpacing = secondaryComputerEngine.spacing()
        let axis: Axis
        switch prop.edge {
        case .top, .bottom:
            axis = .vertical
        case .leading, .trailing:
            axis = .horizontal
        }
        return primarySpacing.distanceToSuccessorView(along: axis, preferring: secondarySpacing) ?? 8.0
    }
    
    fileprivate func primarySafeAreaInsets() -> SafeAreaInsets.Element {

        let prop = self.props
        var spacing = self.spacing()
        
        let proposedSize = _ProposedSize(size: self.parentSize.value)
        let secondaryProposedSize = secondaryProposal(parentProposal: proposedSize, spacing: spacing)
        let engine = self.secondaryLayoutComputer?.engine ?? LayoutEngineBox(engine: LayoutComputer.DefaultEngine())
        let fittingSize = engine.sizeThatFits(secondaryProposedSize)
        let length: CGFloat
        
        switch prop.edge {
        case .top, .bottom:
            length = fittingSize.height
        case .leading, .trailing:
            length = fittingSize.width
        }
        spacing += length
        
        let edgeInsets = EdgeInsets(spacing, edges: Edge.Set(prop.edge))
        return SafeAreaInsets.Element(regions: prop.regions, insets: edgeInsets)
    }
    
    fileprivate func secondaryProposal(parentProposal: _ProposedSize, spacing: CGFloat) -> _ProposedSize {

        let calculateValue: CGFloat
        switch self.props.edge {
        case .top, .bottom:
            if let height = parentProposal.height {
                calculateValue = height
            } else {
                return _ProposedSize(width: parentProposal.width, height: nil)
            }
        case .leading, .trailing:
            if let width = parentProposal.width {
                calculateValue = width
            } else {
                return _ProposedSize(width: nil, height: parentProposal.height)
            }
        }
        let lengthWithoutSpacing = calculateValue - spacing
        var length: CGFloat = 0
        if lengthWithoutSpacing >= 0 {
            length = lengthWithoutSpacing
        }
        
        var proposedSize: _ProposedSize
        switch self.props.edge {
        case .top, .bottom:
            proposedSize = _ProposedSize(width: parentProposal.width, height: length)
        case .leading, .trailing:
            proposedSize = _ProposedSize(width: length, height: parentProposal.height)
        }
                
        let primaryMin = primaryMinimum(parentProposalWithoutSpacing: proposedSize)
        length -= primaryMin
        
        if length < 0 {
            length = 0
        }
        
        switch self.props.edge {
        case .top, .bottom:
            return _ProposedSize(width: parentProposal.width, height: length)
        case .leading, .trailing:
            return _ProposedSize(width: length, height: parentProposal.height)
        }
    }
    
    fileprivate func primaryMinimum(parentProposalWithoutSpacing: _ProposedSize) -> CGFloat {
        
        let engine = self.primaryLayoutComputer?.engine ?? LayoutComputer().engine
        
        switch self.props.edge {
        case .top, .bottom:
            let proposedSize = _ProposedSize(width: parentProposalWithoutSpacing.width, height: 0)
            return engine.sizeThatFits(proposedSize).height
        case .leading, .trailing:
            let proposedSize = _ProposedSize(width: 0, height: parentProposalWithoutSpacing.height)
            return engine.sizeThatFits(proposedSize).width
        }
    }
}

@available(iOS 13.0, *)
private struct InsetChildGeometry: AsyncAttribute, Rule {
    
    fileprivate var value: (ViewGeometry, ViewGeometry) {
        layout.childGeometry()
    }
    
    fileprivate typealias Value = (ViewGeometry, ViewGeometry)
    
    fileprivate var layout: InsetViewLayout

}

@available(iOS 13.0, *)
private struct InsetPrimaryTransform: AsyncAttribute, Rule {
        
    fileprivate typealias Value = ViewTransform

    @Attribute
    fileprivate var position: ViewOrigin

    @Attribute
    fileprivate var size: ViewSize
    
    @Attribute
    fileprivate var transform: ViewTransform

    fileprivate let uniqueID: UniqueID
    
    fileprivate var value: ViewTransform {
        var transform = self.transform
        transform.appendViewOrigin(self.position)
        transform.appendSizedSpace(name: self.uniqueID, size: self.size.value)
        return transform
    }
    
}

@available(iOS 13.0, *)

private struct InsetLayoutComputer: AsyncAttribute, StatefulRule {
    
    fileprivate var layout: InsetViewLayout

    fileprivate typealias Value = LayoutComputer
    
    fileprivate mutating func updateValue() {
        let engine = Engine(layout: self.layout,
                            context: AnyRuleContext.current,
                            dimensionsCache: (Cache3<_ProposedSize, CGSize>.init()))
        self.update(to: engine)
    }
    
    fileprivate struct Engine: LayoutEngine {
        
        fileprivate var layout: InsetViewLayout

        fileprivate var context: AnyRuleContext

        fileprivate var dimensionsCache: Cache3<_ProposedSize, CGSize>

        fileprivate mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {
            
            if let dimensions = dimensionsCache[size] {
                return dimensions
            }
            var fitSize: CGSize?
            context.update {
                fitSize = self.layout.sizeThatFits(size)
            }
            dimensionsCache[size] = fitSize
            return fitSize!
        }
    }
}
