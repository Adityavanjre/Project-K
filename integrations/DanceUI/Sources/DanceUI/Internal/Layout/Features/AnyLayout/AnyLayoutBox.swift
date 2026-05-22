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

@usableFromInline
@available(iOS 13.0, *)
internal class AnyLayoutBox {
    
    internal func makeCache(subviews: LayoutSubviews) -> AnyLayout.Cache {
        _abstractFunction()
    }
    
    internal func updateCache(_ cache: inout AnyLayout.Cache, subviews: LayoutSubviews) {
        _abstractFunction()
    }
    
    internal func spacing(subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> ViewSpacing {
        _abstractFunction()
    }
    
    internal func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> CGSize {
        _abstractFunction()
    }
    
    internal func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) {
        _abstractFunction()
        
    }
    
    internal func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> CGFloat? {
        _abstractFunction()
    }
    
    internal func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> CGFloat? {
        _abstractFunction()
    }
}

@available(iOS 13.0, *)
internal final class _AnyLayoutBox<L: Layout>: AnyLayoutBox {
    
    internal var layout : L
    
    internal init(layout: L) {
        self.layout = layout
    }
    
    internal override func makeCache(subviews: LayoutSubviews) -> AnyLayout.Cache {
        AnyLayout.Cache(type: L.self, value: layout.makeCache(subviews: subviews))
    }
    
    internal override func updateCache(_ cache: inout AnyLayout.Cache, subviews: LayoutSubviews) {
        if cache.type == L.self {
            withLayoutCache(&cache) { layoutCache in
                layout.updateCache(&layoutCache, subviews: subviews)
            }
        } else {
            cache = makeCache(subviews: subviews)
        }
    }
    
    internal override func spacing(subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> ViewSpacing {
        withLayoutCache(&cache) { layoutCache in
            layout.spacing(subviews: subviews, cache: &layoutCache)
        }
    }
    
    internal override func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> CGSize {
        withLayoutCache(&cache) { layoutCache in
            layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &layoutCache)
        }
    }
    
    internal override func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) {
        withLayoutCache(&cache) { layoutCache in
            layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &layoutCache)
        }
    }
    
    internal override func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> CGFloat? {
        withLayoutCache(&cache) { layoutCache in
            layout.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &layoutCache)
        }
    }
    
    internal override func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout AnyLayout.Cache) -> CGFloat? {
        withLayoutCache(&cache) { layoutCache in
            layout.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &layoutCache)
        }
    }
    
    @inline(__always)
    private func withLayoutCache<R>(_ cache: inout AnyLayout.Cache, body: (inout L.Cache) -> R) -> R {
        var layoutCache = cache.value as! L.Cache
        let result = body(&layoutCache)
        cache.value = layoutCache
        return result
    }
}
