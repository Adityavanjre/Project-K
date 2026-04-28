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

@available(iOS 13.0, *)
internal struct Spacing: Equatable {

    internal static let zeroHorizontal: Spacing = Spacing(minima: Dictionary.init(dictionaryLiteral: (Key(category: nil, edge: .leading), 0), (Key(category: nil, edge: .trailing), 0)))

    internal static let zeroVertical: Spacing = Spacing(minima: Dictionary.init(dictionaryLiteral: (Key(category: nil, edge: .top), 0), (Key(category: nil, edge: .bottom), 0)))

    internal static let zero: Spacing = .init(minima: Dictionary.init(dictionaryLiteral: (Key(category: nil, edge: .top), 0), (Key(category: nil, edge: .bottom), 0), (Key(category: nil, edge: .leading), 0), (Key(category: nil, edge: .trailing), 0)))

    internal static let zeroText: Spacing = Spacing(minima: [Key(category: .edgeBelowText, edge: .top) : 0,
                                                    Key(category: .edgeAboveText, edge: .bottom) : 0])

    internal var minima: [Key: CGFloat]

    internal struct Category: Hashable, CustomStringConvertible, CustomDebugStringConvertible {

        internal let id: ObjectIdentifier

        private struct EdgeAboveText {
        }

        private struct EdgeBelowText {
        }

        private struct TextToText {
        }

        internal static let edgeAboveText: Category = .init(id: .init(EdgeAboveText.self))

        internal static let edgeBelowText: Category = .init(id: .init(EdgeBelowText.self))

        internal static let textToText: Category = .init(id: .init(TextToText.self))

        internal var description: String { // BDCOV_EXCL_BLOCK
            return "\(unsafeBitCast(id, to: Any.Type.self))"
        }

        internal var debugDescription: String { // BDCOV_EXCL_BLOCK
            return "<\(type(of: self)): \(unsafeBitCast(id, to: Any.Type.self))>"
        }

    }

    internal struct Key: Hashable {
        let category: Category?
        let edge: Edge
    }

    internal mutating func reset(_ edges: Edge.Set) {
        guard !edges.isEmpty else {
            return
        }

        var newMinima: [Key: CGFloat] = minima.filter({!edges.contains($0.key.edge)})

        if edges.contains(.top) {
            newMinima[Key(category: .edgeBelowText, edge: .top)] = 0
        }

        if edges.contains(.bottom) {
            newMinima[Key(category: .edgeAboveText, edge: .bottom)] = 0
        }
        self.minima = newMinima
    }

    internal mutating func incorporate(_ edges: Edge.Set, of spacing: Spacing) {
        guard !edges.isEmpty else {
            return
        }

        var needMergeSpacingValue: [(Key, CGFloat)] = []
        for (key, value) in spacing.minima {
            guard edges.contains(key.edge) else {
                continue
            }
            needMergeSpacingValue.append((key, value))
        }
        minima.merge(needMergeSpacingValue, uniquingKeysWith: { .maximum($0, $1) })
    }

    internal func distanceToSuccessorView(along axis: Axis, preferring preferredSpacing: Spacing) -> CGFloat? {
        let trailingOrBottomEdge: Edge = Edge(rawValue: Int8((axis.rawValue & 0x1) ^ 0x3))!
        let leadingOrTopEdge: Edge = Edge(rawValue: Int8((axis.rawValue & 0x1) ^ 0x1))!

        let fromEdge: Edge
        let toEdge: Edge
        let largerSpacing: Spacing
        let smallerSpacing: Spacing

        if minima.count >= preferredSpacing.minima.count {
            fromEdge = leadingOrTopEdge
            toEdge = trailingOrBottomEdge
            largerSpacing = self
            smallerSpacing = preferredSpacing
        } else {
            fromEdge = trailingOrBottomEdge
            toEdge = leadingOrTopEdge
            largerSpacing = preferredSpacing
            smallerSpacing = self
        }

        return smallerSpacing._distance(
            from: fromEdge,
            to: toEdge,
            ofViewPreferring: largerSpacing
        )
    }

    internal func _distance(from fromEdge: Edge, to toEdge: Edge, ofViewPreferring preferredSpacing: Spacing) -> CGFloat? {
        typealias Value = (hasNoPreferredSpacing: Bool, preferredDistance: CGFloat)

        let (hasNoPreferredSpacing, maxPreferredDistance) = minima.reduce((true, 0)) { (result, keyValuePair) -> Value in
            let (previouslyHasNoPreferredSpacing, previousMaxPreferredSpacing) = result
            let (fromEdgeKey, currentSpacing) = keyValuePair

            guard fromEdgeKey.category != nil && fromEdgeKey.edge == fromEdge else {
                return result
            }

            let toEdgeKey = Key(category: fromEdgeKey.category, edge: toEdge)

            guard let matchedPreferredSpacing = preferredSpacing.minima[toEdgeKey] else {
                return result
            }

            let baseValue = previouslyHasNoPreferredSpacing
                ? -CGFloat.infinity
                : previousMaxPreferredSpacing

            let spacingSum = currentSpacing + matchedPreferredSpacing

            return (false, max(baseValue, spacingSum))
        }

        guard hasNoPreferredSpacing else {
            return maxPreferredDistance
        }

        let fromEdgeKeyWithoutCategory = Key(category: nil, edge: fromEdge)

        let fromEdgeSpaceWithoutCategoryOrZero = minima[fromEdgeKeyWithoutCategory]

        let toEdgeKeyWithoutCategory = Key(category: nil, edge: toEdge)

        let toEdgeSpaceWithoutCategoryOrNil = preferredSpacing.minima[toEdgeKeyWithoutCategory]

        let fromEdgeSpaceWithoutCategory: CGFloat, toEdgeSpaceWithoutCategory: CGFloat

        switch (fromEdgeSpaceWithoutCategoryOrZero, toEdgeSpaceWithoutCategoryOrNil) {
        case let (.some(lhs), .some(rhs)):
            fromEdgeSpaceWithoutCategory = lhs
            toEdgeSpaceWithoutCategory = rhs
        case let (.some(lhs), .none):
            fromEdgeSpaceWithoutCategory = lhs
            toEdgeSpaceWithoutCategory = -.infinity
        case let (.none, .some(rhs)):
            fromEdgeSpaceWithoutCategory = -.infinity
            toEdgeSpaceWithoutCategory = rhs
        default:
            return nil
        }

        return max(fromEdgeSpaceWithoutCategory, toEdgeSpaceWithoutCategory)
    }

    @inline(__always)
    internal mutating func clear(_ edge: Edge.Set) {
        minima = minima.filter({ !edge.contains(Edge.Set($0.key.edge)) })
    }

}
