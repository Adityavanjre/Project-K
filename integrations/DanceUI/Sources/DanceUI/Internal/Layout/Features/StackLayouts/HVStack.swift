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
internal protocol HVStack: _Layout, Layout where Cache == _StackLayoutCache {

    associatedtype MinorAxisAlignment: AlignmentGuide

    var spacing: CGFloat? { get }

    var alignment: MinorAxisAlignment { get }

    static var majorAxis: Axis { get }

    static var resizeChildrenWithTrailingOverflow: Bool { get }

}

@available(iOS 13.0, *)
extension HVStack {

    internal static var layoutAxis: Axis? {
        layoutProperties.stackOrientation
    }

    internal static var resizeChildrenWithTrailingOverflow: Bool {
        true
    }

    internal func placement(of collection: LayoutProxyCollection, in context: PlacementContext) -> [_Placement] {
        _abstractFunction()
    }

    internal func sizeThatFits(in size: _ProposedSize, context: SizeAndSpacingContext, children: LayoutProxyCollection) -> CGSize {
        _abstractFunction()
    }

    @inlinable
    internal func updateLayoutComputer<Rule>(rule: inout Rule, layoutContext: SizeAndSpacingContext, children: LayoutProxyCollection) where Rule : StatefulRule, Rule.Value == LayoutComputer {
        let subviews = LayoutSubviews(layoutDirection: layoutContext.environmentValue(\.layoutDirection), storage: .direct(children.attributes), context: layoutContext.context)
        LayoutEngineBox<StackLayout>.update(&rule) { box in
            box.engine = StackLayout(proxies: subviews, majorAxis: Self.majorAxis, minorAxisAlignment: self.alignment.key, uniformSpacing: self.spacing, resizeChildrenWithTrailingOverflow: Self.resizeChildrenWithTrailingOverflow)
        } create: {
            return LayoutEngineBox(engine: StackLayout(proxies: subviews, majorAxis: Self.majorAxis, minorAxisAlignment: self.alignment.key, uniformSpacing: self.spacing, resizeChildrenWithTrailingOverflow: Self.resizeChildrenWithTrailingOverflow))
        }
    }
}

@available(iOS 13.0, *)
public struct _StackLayoutCache {

    internal var stack : StackLayout

}

@available(iOS 13.0, *)
extension HVStack {

    public static var layoutProperties: LayoutProperties {
        LayoutProperties(Self.majorAxis)
    }

    public func makeCache(subviews: LayoutSubviews) -> Cache {
        _StackLayoutCache(stack: StackLayout(proxies: subviews,
                                             majorAxis: Self.majorAxis,
                                             minorAxisAlignment: self.alignment.key,
                                             uniformSpacing: self.spacing,
                                             resizeChildrenWithTrailingOverflow: Self.resizeChildrenWithTrailingOverflow))
    }

    public func updateCache(_ cache: inout _StackLayoutCache, subviews: LayoutSubviews) {
        guard cache.stack.header.proxies != subviews else {
            return
        }
        cache.stack = StackLayout(proxies: subviews,
                                  majorAxis: Self.majorAxis,
                                  minorAxisAlignment: self.alignment.key,
                                  uniformSpacing: self.spacing,
                                  resizeChildrenWithTrailingOverflow: Self.resizeChildrenWithTrailingOverflow)
    }

    public func spacing(subviews: LayoutSubviews, cache: inout _StackLayoutCache) -> ViewSpacing {
        updateCache(&cache, subviews: subviews)
        return ViewSpacing(spacing: cache.stack.spacing())
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout _StackLayoutCache) -> CGSize {
        updateCache(&cache, subviews: subviews)
        return cache.stack.sizeThatFits(proposal.proposal)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout _StackLayoutCache) {
        updateCache(&cache, subviews: subviews)
        let geometries = cache.stack.childGeometries(at: ViewSize(value: bounds.size, proposal: proposal.proposal), origin: bounds.origin)
        for (index, subview) in subviews.enumerated() {
            guard index < geometries.count else {
                continue
            }
            subview.place(at: geometries[index])
        }
    }

    public func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Self.Cache) -> CGFloat? {
        updateCache(&cache, subviews: subviews)
        return cache.stack.explicitAlignment(guide.key, at: ViewSize(value: bounds.size, proposal: proposal.proposal))
    }

    public func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout Self.Cache) -> CGFloat? {
        updateCache(&cache, subviews: subviews)
        return cache.stack.explicitAlignment(guide.key, at: ViewSize(value: bounds.size, proposal: proposal.proposal))
    }

}
