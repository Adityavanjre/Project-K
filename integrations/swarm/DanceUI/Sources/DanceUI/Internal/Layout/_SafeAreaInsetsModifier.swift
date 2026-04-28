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
internal struct _SafeAreaInsetsModifier: PrimitiveViewModifier, MultiViewModifier {

    internal struct Transform: Rule {

        internal typealias Value = ViewTransform

        internal let space: UniqueID

        @Attribute
        internal var transform: ViewTransform

        @Attribute
        internal var position: ViewOrigin

        @Attribute
        internal var size: ViewSize

        internal var value: ViewTransform {
            var transform = self.transform
            let position = self.position
            let translationX = position.value.x - transform.positionAdjustment.width
            let translationY = position.value.y - transform.positionAdjustment.height
            if translationX <= 0 || translationY <= 0 {
                transform.appendTranslation(CGSize(width: abs(translationX), height: abs(translationY)))
            }
            transform.appendSizedSpace(name: space, size: size.value)
            transform.positionAdjustment = CGSize(width: position.value.x, height: position.value.y)
            return transform
        }
    }

    internal struct Insets: Rule {

        internal typealias Value = SafeAreaInsets

        internal let space: UniqueID

        @Attribute
        internal var modifier: _SafeAreaInsetsModifier

        @OptionalAttribute
        internal var next: SafeAreaInsets?

        internal var value: SafeAreaInsets {
            var nextInsets: SafeAreaInsets.OptionalValue!
            let modifier = self.modifier
            if let next = modifier.nextInsets {
                nextInsets = next
            } else {
                if let selfNext = self.next {
                    nextInsets = .insets(selfNext)
                } else {
                    nextInsets = .empty
                }
            }
            return SafeAreaInsets(space: space, elements: modifier.elements, next: nextInsets)
        }

    }

    internal var elements: [SafeAreaInsets.Element]

    internal var nextInsets: SafeAreaInsets.OptionalValue?

    internal var insets: EdgeInsets {
        elements.reduce(.zero, {$0 + $1.insets})
    }

    internal init(elements: [SafeAreaInsets.Element], nextInsets: SafeAreaInsets.OptionalValue?) {
        self.elements = elements
        self.nextInsets = nextInsets
    }

    static func _makeView(modifier: _GraphValue<_SafeAreaInsetsModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let animatedPosition = inputs.animatedPosition
        let animatedSize = inputs.animatedSize
        let space = UniqueID()
        let transform = Transform(
            space: space,
            transform: inputs.transform,
            position: animatedPosition,
            size: animatedSize)

        let insets = Insets(space: space, modifier: modifier.value, next: inputs.safeAreaInsets)
        var newInputs = inputs
        newInputs.transform = Attribute(transform)
        newInputs.safeAreaInsets = OptionalAttribute(Attribute(insets))

        return body(_Graph(), newInputs)
    }
}

@available(iOS 13.0, *)
internal struct SafeAreaInsets {

    internal struct Element {

        internal var regions: SafeAreaRegions

        internal var insets: EdgeInsets

    }

    internal enum OptionalValue {

        indirect case insets(SafeAreaInsets)

        case empty

    }

    internal var space: UniqueID

    internal var elements: [Element]

    internal var next: SafeAreaInsets.OptionalValue

    internal func mergedInsets(regions: SafeAreaRegions) -> (selected: EdgeInsets, total: EdgeInsets) {
        guard !elements.isEmpty else {
            return (.zero, .zero)
        }
        var selected: EdgeInsets = .zero
        var total: EdgeInsets = .zero
        var edgeSet: Edge.Set = .all
        for element in elements.reversed() {
            if element.regions.intersection(regions).isEmpty {
                if element.insets.trailing != 0 {
                    edgeSet.remove(.trailing)
                }
                if element.insets.bottom != 0 {
                    edgeSet.remove(.bottom)
                }
                if element.insets.top != 0 {
                    edgeSet.remove(.top)
                }
                if element.insets.leading != 0 {
                    edgeSet.remove(.leading)
                }
            } else {
                if edgeSet.contains(.top) {
                    selected.top += element.insets.top
                }
                if edgeSet.contains(.leading) {
                    selected.leading += element.insets.leading
                }
                if edgeSet.contains(.trailing) {
                    selected.trailing += element.insets.trailing
                }
                if edgeSet.contains(.bottom) {
                    selected.bottom += element.insets.bottom
                }
            }
            total = total + element.insets
        }
        return (selected, total)
    }

    internal func resolve(regions: SafeAreaRegions, in context: _PositionAwarePlacementContext) -> EdgeInsets {
        let size = context.size
        var adjustRect = CGRect(origin: .zero, size: size)
        adjust(&adjustRect, from: regions, to: context)

        var nextSafeAreaInsets: SafeAreaInsets? = nil
        if case let .insets(safeAreaInset) = next {
            nextSafeAreaInsets = safeAreaInset
        }
        while let currentSafeAreaInsets = nextSafeAreaInsets {
            currentSafeAreaInsets.adjust(&adjustRect, from: regions, to: context)
            if case let .insets(safeAreaInset) = currentSafeAreaInsets.next {
                nextSafeAreaInsets = safeAreaInset
            } else {
                nextSafeAreaInsets = nil
            }
        }

        let dimensionsRect = CGRect(origin: .zero, size: size)
        var insets: EdgeInsets = .zero
        insets.leading = dimensionsRect.minX - adjustRect.minX
        insets.trailing = adjustRect.maxX - dimensionsRect.maxX
        insets.top = dimensionsRect.minY - adjustRect.minY
        insets.bottom = adjustRect.maxY - dimensionsRect.maxY
        return insets
    }

    internal func adjust(_ rect: inout CGRect, from regions: SafeAreaRegions, to context: _PositionAwarePlacementContext) {
        let mergedInsets = self.mergedInsets(regions: regions)
        guard mergedInsets.selected != .zero || mergedInsets.total != .zero else {
            return
        }
        let transform = context.transform

        var blockBool = false
        var cornerPoints: [CGPoint] = []
        let coordinateSpace: CoordinateSpace = .named(space)
        transform.convert(.fromGlobal, space: coordinateSpace) { item in
            if case let .sizedSpace(name, size) = item {
                if case let .named(spaceName) = coordinateSpace, spaceName == name {
                    var selectedRect = CGRect(origin: .zero, size: size)
                    selectedRect = selectedRect._inset(by: mergedInsets.total)
                    let insetSelectedRect = selectedRect._inset(by: EdgeInsets(top: -mergedInsets.selected.top, leading: -mergedInsets.selected.leading, bottom: -mergedInsets.selected.bottom, trailing: -mergedInsets.selected.trailing))
                    var insetCornerPoints = selectedRect.cornerPoints
                    insetCornerPoints.append(contentsOf: insetSelectedRect.cornerPoints)
                    cornerPoints = insetCornerPoints
                }
                return
            }

            switch item {
            case .affineTransform(let affineTransform, _):
                if !affineTransform.isRectilinear {
                    blockBool = true
                }
            case .projectionTransform(let projectionTransform, _):
                if projectionTransform.isAffine {
                    let affineTransform = projectionTransform.affineTransformValue
                    if !affineTransform.isRectilinear {
                        blockBool = true
                    }
                }
            default:
                break
            }
            if !blockBool {
                cornerPoints.applyTransform(item: item)
            }
        }

        guard !blockBool else {
            return
        }

        let rect1 = CGRect(cornerPoints: cornerPoints[0..<4])
        let rect2 = CGRect(cornerPoints: cornerPoints[4..<8])
        let rect1MinX = rect1.minX
        let rect1MaxX = rect1.maxX
        let rect1MinY = rect1.minY
        let rect1MaxY = rect1.maxY

        let rect2MinX = rect2.minX
        let rect2MaxX = rect2.maxX
        let rect2MinY = rect2.minY
        let rect2MaxY = rect2.maxY

        let rectMinX = rect.minX
        let rectMaxX = rect.maxX
        let rectMinY = rect.minY
        let rectMaxY = rect.maxY

        if rect1MinY > (rectMinY - 0.1) && (rectMinY + 0.1) > rect2MinY {
            let value = rectMinY - rect2MinY
            rect.origin.y -= value
            rect.size.height += value
        }

        if (rectMaxY + 0.1) > rect1MaxY && rect2MaxY > (rectMaxY - 0.1) {
            rect.size.height += (rect2MaxY - rectMaxY)
        }

        if rect1MinX > (rectMinX - 0.1) && (rectMinX + 0.1) > rect2MinX {
            let value = rectMinX - rect2MinX
            rect.origin.x -= value
            rect.size.width += value
        }

        if (rectMaxX + 0.1) > rect1MaxX && rect2MaxX > (rectMaxX - 0.1) {
            rect.size.width += (rect2MaxX - rectMaxX)
        }
    }

}
