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
extension StackLayout {
    
    internal struct Header {
        
        internal var minorAxisAlignment: AlignmentKey
        
        internal var uniformSpacing: CGFloat?
        
        internal var majorAxis: Axis
        
        internal var internalSpacing: CGFloat
        
        internal var lastProposedSize: _ProposedSize?
        
        internal var stackSize: CGSize
        
        internal var lazyPreferredSpacing: Spacing?
        
        internal var proxies: LayoutSubviews
        
        internal var resizeChildrenWithTrailingOverflow: Bool
        
        internal var dimensionsCache: Cache3<_ProposedSize, CGSize>
        
        internal var lastFittingSizeInfo: (proposal: _ProposedSize, size: CGSize)? = nil
        
        internal var count: Int {
            proxies.count
        }
        
        internal init(proxies: LayoutSubviews,
                      majorAxis: Axis,
                      internalSpacing: CGFloat,
                      minorAxisAlignment: AlignmentKey,
                      uniformSpacing: CGFloat?,
                      resizeChildrenWithTrailingOverflow: Bool) {
            self.minorAxisAlignment = minorAxisAlignment
            self.uniformSpacing = uniformSpacing
            self.majorAxis = majorAxis
            self.internalSpacing = internalSpacing
            self.lastProposedSize = nil
            self.stackSize = .zero
            self.lazyPreferredSpacing = nil
            self.proxies = proxies
            self.resizeChildrenWithTrailingOverflow = resizeChildrenWithTrailingOverflow
            self.dimensionsCache = .init()
        }
        
        internal mutating func preferredSpacing() -> Spacing {
            if let spacing = lazyPreferredSpacing {
                return spacing
            }
            
            var spacing: Spacing = count == 0 ? .zero : Spacing(minima: [:])
            
            var edgeSets: [Edge.Set] = []
            for (index, proxy) in proxies.enumerated() {
                if majorAxis == .horizontal {
                    edgeSets = [.init(.top), .init(.bottom)]
                } else {
                    edgeSets = [.init(.leading), .init(.trailing)]
                }
                var edgeSet: Edge.Set
                if index == 0 {
                    edgeSet = majorAxis == .horizontal ? .init(.leading) : .init(.top)
                } else {
                    edgeSet = Edge.Set(rawValue: 0)
                }
                edgeSets.append(edgeSet)
                if index != proxies.count - 1 {
                    edgeSets.append(Edge.Set(rawValue: 0))
                } else {
                    let set: Edge.Set = majorAxis == .horizontal ? .init(.trailing) : .init(.bottom)
                    edgeSets.append(set)
                }
                let currentSpacing: Spacing = proxy.spacing.spacing
                spacing.incorporate(.init(edgeSets), of: currentSpacing)
            }
            lazyPreferredSpacing = spacing
            return spacing
        }
        
        @usableFromInline
        internal mutating func cacheFittingSizeInfo(_ proposal: _ProposedSize, fittingSize: CGSize) {
            let dimension: CGFloat = proposal.value(for: majorAxis) ?? 0
            if dimension > 0, dimension < .infinity, (proposal.width != nil || proposal.height != nil) {
                lastFittingSizeInfo = (proposal, fittingSize)
            } else {
                lastFittingSizeInfo = nil
            }
        }
        
        @usableFromInline
        internal func findFittingSize(_ size: _ProposedSize) -> CGSize? {
            guard let fittingSizeInfo = lastFittingSizeInfo else {
                return nil
            }
            let size = size.size
            guard !size.isInfinite,
                  !size.width.isZero,
                  !size.height.isZero else {
                return nil
            }
            let epsilon: CGFloat = 0.4
            let oldPorposal = fittingSizeInfo.proposal.size
            let widthDiff = size.width - oldPorposal.width
            let heightDiff = size.height - oldPorposal.height
            
            guard widthDiff < epsilon && heightDiff < epsilon else {
                // oversize?
                return nil
            }
            
            guard widthDiff < -epsilon || heightDiff < -epsilon else {
                return fittingSizeInfo.size
            }
            
            let fittingWidthDiff = fittingSizeInfo.size.width - size.width
            let fittingHeightDiff = fittingSizeInfo.size.height - size.height
            
            if fittingWidthDiff > epsilon || fittingHeightDiff > epsilon {
                return nil
            } else {
                return fittingSizeInfo.size
            }
        }
        
        @usableFromInline
        internal func minMajorAxisRange(for child: Child, index: Int, proposedSize: _ProposedSize) -> CGFloat {
            _danceuiPrecondition(index < count)
            var proposal: _ProposedSize = proposedSize
            proposal.setValue(0, for: majorAxis)
            if let range: CGFloat = child.majorAxisRangeCache.min {
                return range
            } else {
                return proxies[index].lengthThatFits(proposal, in: majorAxis)
            }
        }
        
        @usableFromInline
        internal func maxMajorAxisRange(for child: Child, index: Int, proposedSize: _ProposedSize) -> CGFloat {
            _danceuiPrecondition(index < count)
            var proposal: _ProposedSize = proposedSize
            proposal.setValue(.infinity, for: majorAxis)
            if let range: CGFloat = child.majorAxisRangeCache.max {
                return range
            } else {
                return proxies[index].lengthThatFits(proposal, in: majorAxis)
            }
        }
    }
}
