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
internal struct SecondaryLayerGeometryQuery: Rule {

    internal typealias Value = ViewGeometry
    
    @OptionalAttribute
    internal var alignment: Alignment?
    
    @Attribute
    internal var layoutDirection: LayoutDirection
    
    @Attribute
    internal var primaryPosition: ViewOrigin
    
    @Attribute
    internal var primarySize: ViewSize
    
    @OptionalAttribute
    internal var primaryLayoutComputer: LayoutComputer?
    
    @OptionalAttribute
    internal var secondaryLayoutComputer: LayoutComputer?
    
    internal var value: ViewGeometry {
        let primaryLayoutComputer = self.primaryLayoutComputer ?? .defaultValue
        let alignment = self.alignment ?? .center
        let primarySize = primarySize
        let primaryDimension = ViewDimensions(guideComputer: primaryLayoutComputer, size: primarySize)
        let primaryHAlignment: CGFloat = primaryDimension[alignment.horizontal]
        let primaryVAlignment: CGFloat = primaryDimension[alignment.vertical]
        
        let secondaryLayoutComputer = self.secondaryLayoutComputer ?? .defaultValue
        let proposal = _ProposedSize(size: primarySize.value)
        let fittingSize = secondaryLayoutComputer.engine.sizeThatFits(proposal)
        
        let secondaryDimension = ViewDimensions(guideComputer: secondaryLayoutComputer, size: ViewSize(value: fittingSize, _proposal: primarySize.value))
        let secondaryHAlignment: CGFloat = secondaryDimension[alignment.horizontal]
        let secondaryVAlignment: CGFloat = secondaryDimension[alignment.vertical]
        
        var position = primaryPosition
        
        var x: CGFloat = primaryHAlignment + position.value.x - secondaryHAlignment
        let y: CGFloat = primaryVAlignment + position.value.y - secondaryVAlignment
        
        if layoutDirection == .rightToLeft {
            let primaryHAlignmentCenter = primaryDimension[HorizontalAlignment.center]
            let secondaryHExplicitAlignmentCenter = secondaryDimension[HorizontalAlignment.center]
            x = (primaryHAlignmentCenter + position.value.x - secondaryHExplicitAlignmentCenter) * 2 - x
        }
        
        position.value.x = x
        position.value.y = y
        return  ViewGeometry(origin: ViewOrigin(value: CGPoint(x: x, y: y)),
                             dimensions: ViewDimensions(guideComputer: secondaryLayoutComputer, size: ViewSize(value: fittingSize, _proposal: primarySize.value)))
    }
}
