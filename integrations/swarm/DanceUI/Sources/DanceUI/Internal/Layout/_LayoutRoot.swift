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

@frozen
@available(iOS 13.0, *)
public struct _LayoutRoot<LayoutType: Layout>: _VariadicView_UnaryViewRoot, _Layout {
    
    public typealias Body = Never
    
    public typealias AnimatableData = LayoutType.AnimatableData
    
    public var animatableData: LayoutType.AnimatableData {
        get {
            layout.animatableData
        }
        
        set {
            layout.animatableData = newValue
        }
    }
    
    internal static var isIdentityUnaryLayout: Bool {
        false
    }
    
    internal typealias PlacementContextType = PlacementContext
    
    @usableFromInline
    internal var layout: LayoutType
    
    @inlinable
    public init(layout: LayoutType) {
        self.layout = layout
    }
    
    internal static var layoutAxis: Axis? {
        guard let orientation = LayoutType.layoutProperties.stackOrientation else {
            return nil
        }
        return orientation == .vertical ? .vertical : .horizontal
    }
    
    internal func placement(of collection: LayoutProxyCollection, in context: PlacementContext) -> [_Placement] {
        _abstractFunction()
    }
    
    internal func sizeThatFits(in size: _ProposedSize, context: SizeAndSpacingContext, children: LayoutProxyCollection) -> CGSize {
        _abstractFunction()
    }
    
    internal func updateLayoutComputer<Rule: StatefulRule>(rule: inout Rule, layoutContext: SizeAndSpacingContext, children: LayoutProxyCollection) where Rule.Value == LayoutComputer {
        
        LayoutEngineBox<ViewLayoutEngine<LayoutType>>.update(&rule, inPlace: { (engineDelegate) in
            let engine = ViewLayoutEngine(layout: self.layout, layoutContext: layoutContext, proxies: children, layoutDirection: layoutContext.environmentValue(\.layoutDirection), cache: engineDelegate.engine.cache)
            engineDelegate.engine = engine
        }) { () -> LayoutEngineBox<ViewLayoutEngine<LayoutType>> in
            let engine = ViewLayoutEngine(layout: self.layout, layoutContext: layoutContext, proxies: children, layoutDirection: layoutContext.environmentValue(\.layoutDirection))
            return LayoutEngineBox(engine: engine)
        }
        
    }
}

@available(iOS 13.0, *)
fileprivate struct ViewLayoutEngine<LayoutType: Layout>: LayoutEngine {
    
    internal var layout: LayoutType
    
    internal var cache: LayoutType.Cache
    
    internal var proxies: LayoutProxyCollection
    
    internal var layoutDirection: LayoutDirection
    
    internal var sizeCache: Cache3<_ProposedSize, CGSize>
    
    internal var cachedAlignmentSize: ViewSize
    
    internal var cachedAlignmentGeometry: [ViewGeometry]
    
    internal var cachedAlignment: Cache3<ObjectIdentifier, CGFloat?>
    
    internal var preferredSpacing: Spacing?
    
    internal init(layout: LayoutType,
                  layoutContext: SizeAndSpacingContext,
                  proxies: LayoutProxyCollection,
                  layoutDirection: LayoutDirection,
                  cache: LayoutType.Cache? = nil) {
        self.layout = layout
        if var cache = cache {
            let subviews = LayoutSubviews(layoutDirection: layoutDirection, storage: LayoutSubviews.Storage.direct(proxies.attributes), context: proxies.context)
            layout.updateCache(&cache, subviews: subviews)
            self.cache = cache
        } else {
            self.cache = layout.makeCache(subviews: LayoutSubviews(layoutDirection: layoutDirection, storage: LayoutSubviews.Storage.direct(proxies.attributes), context: layoutContext.context))
        }
        self.proxies = proxies
        self.layoutDirection = layoutDirection
        self.sizeCache = .init()
        self.cachedAlignmentSize = .zero
        self.cachedAlignmentGeometry = []
        self.cachedAlignment = .init()
        self.preferredSpacing = nil
    }
    
    internal mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        
        if let dimensions = sizeCache[size] {
            return dimensions
        }
        let subviews = LayoutSubviews(layoutDirection: layoutDirection, storage: LayoutSubviews.Storage.direct(proxies.attributes), context: proxies.context)
        let fitSize = self.layout.sizeThatFits(proposal: ProposedViewSize(size), subviews: subviews, cache: &cache)
        sizeCache[size] = fitSize
        return fitSize
    }
    
    internal mutating func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        let subviews = LayoutSubviews(layoutDirection: layoutDirection, storage: LayoutSubviews.Storage.direct(proxies.attributes), context: proxies.context)
        switch key.bits {
        case .horizontal:
            return self.layout.explicitAlignment(of: HorizontalAlignment(key.id), in: .init(origin: .zero, size: size.value), proposal: ProposedViewSize(size.proposalWhenPlacing(by: .horizontal)), subviews: subviews, cache: &cache)
        case .vertical:
            return self.layout.explicitAlignment(of: VerticalAlignment(key.id), in: .init(origin: .zero, size: size.value), proposal: ProposedViewSize(size.proposalWhenPlacing(by: .vertical)), subviews: subviews, cache: &cache)
        }
    }
    
    internal func layoutPriority() -> Double {
        0
    }
    
    internal mutating func childGeometries(at size: ViewSize, origin: CGPoint) -> [ViewGeometry] {
        let subviews = LayoutSubviews(layoutDirection: layoutDirection, storage: LayoutSubviews.Storage.direct(proxies.attributes), context: proxies.context)
        return withLayoutData(LayoutData(at: size, origin: origin, subviews: subviews)) {
            self.layout.placeSubviews(in: CGRect(origin: origin, size: size.value), proposal: ProposedViewSize(size._proposal), subviews: subviews, cache: &cache)
            let geometries = LayoutData.current.geometries ?? []
            guard geometries.isEmpty else {
                return geometries
            }
            let placement = LayoutData.current.placement
            return placement.enumerated().map { (index, placement) in
                subviews[index].finallyPlaced(at: placement, in: size.value, layoutDirection: subviews.layoutDirection)
            }
        }
    }
    
    
    
    internal func requiresSpacingProjection() -> Bool {
        false
    }
    
    internal mutating func spacing() -> Spacing {
        if let spacing = preferredSpacing {
            return spacing
        }
        let subviews = LayoutSubviews(layoutDirection: layoutDirection, storage: LayoutSubviews.Storage.direct(proxies.attributes), context: proxies.context)
        let spacing = layout.spacing(subviews: subviews, cache: &cache)
        preferredSpacing = spacing.spacing
        return spacing.spacing
    }
}
