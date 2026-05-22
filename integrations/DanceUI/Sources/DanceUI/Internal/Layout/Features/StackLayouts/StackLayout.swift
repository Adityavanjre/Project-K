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
internal struct StackLayout {
    
    internal var header: Header
    
    internal var children: [Child]
    
    internal init(proxies: LayoutSubviews,
                  majorAxis: Axis,
                  minorAxisAlignment: AlignmentKey,
                  uniformSpacing: CGFloat?,
                  resizeChildrenWithTrailingOverflow: Bool) {
        var internalSpacing: CGFloat = 0
        var children: [Child] = []
        for (index, proxy) in proxies.enumerated() {
            var accumulatedSpacing: CGFloat = 0
            if index == 0 {
                accumulatedSpacing = 0
            } else if let spacing = uniformSpacing {
                accumulatedSpacing = spacing
            } else {
                let previousProxy = proxies[index - 1]
                accumulatedSpacing = previousProxy.proxy.distance(toSuccessor: proxy.proxy, along: majorAxis)
            }
            let layoutPriority = proxy.priority
            var childGeometry = ViewGeometry.invalidValue
            childGeometry.dimensions.size._proposal = .zero
            let child = Child(layoutPriority: layoutPriority, majorAxisRangeCache: .init(min: nil, max: nil), distanceToPrevious: accumulatedSpacing, fittingOrder: index, offer: .zero, geometry: childGeometry)
            children.append(child)
            internalSpacing += accumulatedSpacing
        }
        self.header = Header(proxies: proxies, majorAxis: majorAxis, internalSpacing: internalSpacing, minorAxisAlignment: minorAxisAlignment, uniformSpacing: uniformSpacing, resizeChildrenWithTrailingOverflow: resizeChildrenWithTrailingOverflow)
        self.children = children
    }
}

@available(iOS 13.0, *)
extension StackLayout: LayoutEngine {
    
    internal mutating func spacing() -> Spacing {
        header.preferredSpacing()
    }
    
    internal mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        if let fittingSize = header.findFittingSize(size) {
            return fittingSize
        }
        if let value = header.dimensionsCache[size] {
            return value
        }
        withUnmanagedImplementation { impl in
            impl.placeChildren(in: size)
        }
        let fittingSize: CGSize = header.stackSize
        header.dimensionsCache[size] = fittingSize
        
        return fittingSize
    }

    
    internal mutating func childGeometries(at size: ViewSize, origin: CGPoint) -> [ViewGeometry] {
        
        let lastProposedSize = header.lastProposedSize
        withUnmanagedImplementation { impl in
            let proposal = impl.proposalWhenPlacing(in: size)
            if proposal.width != lastProposedSize?.width ||
                proposal.height != lastProposedSize?.height {
                impl.placeChildren(in: proposal)
            }
        }
        
        var origin = origin
        let majorAxis = self.header.majorAxis
        guard !children.isEmpty else {
            return []
        }
        let childGeometries: [ViewGeometry]
        let layoutDirection = header.proxies.layoutDirection
        if majorAxis == .horizontal {
            switch layoutDirection {
            case .leftToRight:
                break
            case .rightToLeft:
                origin.x += size.value.width
            }
            childGeometries = children.enumerated().map { (index, child) -> ViewGeometry in
                var childGeometry: ViewGeometry = child.geometry
                var childOrigin = origin
                switch layoutDirection {
                case .leftToRight:
                    childOrigin.x += child.distanceToPrevious
                    if childOrigin.x > .infinity {
                        childOrigin.x = childGeometry.origin.value.x
                    }
                case .rightToLeft:
                    childOrigin.x -= (child.distanceToPrevious + childGeometry.sizeValue(for: majorAxis))
                    if childOrigin.x > .infinity {
                        childOrigin.x = childGeometry.origin.value.x
                    }
                }
                childGeometry.origin.value.x = childOrigin.x
                childGeometry.origin.value.y = childGeometry.origin.value.y + childOrigin.y
                switch layoutDirection {
                case .leftToRight:
                    childOrigin.x += childGeometry.sizeValue(for: majorAxis)
                case .rightToLeft:
                    break
                }
                guard child.geometry.sizeValue(for: majorAxis) > 0 ||
                        child.geometry.sizeValue(for: majorAxis.minor) > 0 else {
                    // ignore child major axis dimension is zero
                    return childGeometry
                }
                origin = childOrigin
                return childGeometry
            }
        } else {
            childGeometries = children.enumerated().map { (index, child) -> ViewGeometry in
                var childOrigin = origin
                var childGeometry: ViewGeometry = child.geometry
                var x = childGeometry.origin.value.x
                childOrigin.y += child.distanceToPrevious
                if childOrigin.y > .infinity {
                    childOrigin.y = childGeometry.origin.value.y
                }
                switch layoutDirection {
                case .leftToRight:
                    break
                case .rightToLeft:
                    x = size.value.width - CGRect(x: childGeometry.origin.value.x, y: childOrigin.y, width: childGeometry.dimensions.width, height: childGeometry.dimensions.height).maxX
                }
                childGeometry.origin.value.x = x + childOrigin.x
                childGeometry.origin.value.y = childOrigin.y
                childOrigin.y += childGeometry.sizeValue(for: majorAxis)
                guard child.geometry.sizeValue(for: majorAxis) > 0 ||
                        child.geometry.sizeValue(for: majorAxis.minor) > 0 else {
                    // ignore child major axis dimension is zero
                    return childGeometry
                }
                origin = childOrigin
                return childGeometry
            }
        }
        return childGeometries
    }
    
    internal mutating func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        let stackSize = header.stackSize
        withUnmanagedImplementation { impl in
            let proposal = impl.proposalWhenPlacing(in: size)
            if proposal.size != stackSize {
                impl.placeChildren(in: proposal)
            }
        }
        var alignment: CGFloat? = nil
        let alignmentID: AlignmentID.Type = key.id
        var seed: Int = 0
        for (index, child) in children.enumerated() {
            let layoutComputer: LayoutComputer = header.proxies[index].proxy.layoutComputer
            let offer = child.offer
            let fittingSize: CGSize = header.proxies[index].sizeThatFits(ProposedViewSize(child.offer))
            let dimension = ViewDimensions(guideComputer: layoutComputer, size: ViewSize(value: fittingSize, proposal: offer))
            if let explicitAlignment: CGFloat = dimension[explicit: key] {
                var childValue: CGFloat = child.geometry.originValue(for: key)
                childValue += explicitAlignment
                alignmentID._combineExplicit(childValue: childValue, seed, into: &alignment)
                seed += 1
            }
        }
        return alignment
    }
    
    internal func layoutPriority() -> Double {
        children.count == 0 ? -.infinity : 0
    }
    
    @inline(__always)
    internal mutating func withUnmanagedImplementation<R>(_ body: (UnmanagedImplementation) -> R) -> R {
        var copySelf = self
        let result = withUnsafeMutablePointer(to: &copySelf) { p1 in
            p1.pointee.children.withUnsafeMutableBufferPointer { p2 in
                let impl = UnmanagedImplementation(layout: p1,
                                                   children: p2)
                return body(impl)
            }
        }
        self = copySelf
        return result
    }
}
