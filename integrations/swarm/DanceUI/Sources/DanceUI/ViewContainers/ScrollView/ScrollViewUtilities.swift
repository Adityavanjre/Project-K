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
internal struct ScrollViewUtilities {
    
    internal static func contentFrame(in size: CGSize, contentComputer: LayoutComputer?, axes: Axis.Set) -> ViewFrame {
        
        let contentSize = contentSizeThatFits(in: .init(size: size),
                                              contentComputer: contentComputer,
                                              axes: axes) ?? size
        let containsHorizontal = axes.contains(.horizontal)
        let containsVertical = axes.contains(.vertical)

        let x = axes == .all || !containsHorizontal ? max(size.width - contentSize.width, 0) * 0.5 : 0
        let y = axes == .all || !containsVertical ? max(size.height - contentSize.height, 0) * 0.5 : 0
        let proposedSize = _ProposedSize(width: containsHorizontal ? .nan : size.width, height: containsVertical ? .nan : size.height)
        return ViewFrame(origin: ViewOrigin(value: CGPoint(x: x, y: y)),
                         size: ViewSize(value: contentSize, proposal: proposedSize))
    }
    
    internal static func sizeThatFits(in proposed: _ProposedSize, contentComputer: LayoutComputer?, axes: Axis.Set) -> CGSize? {
        guard axes != .empty else {
            return nil
        }
        
        let height = axes.contains(.vertical) ? nil : proposed.height
        let width = axes.contains(.horizontal) ? nil : proposed.width
        
        let size: CGSize
        if let contentComputer = contentComputer {
            size = contentComputer.engine.sizeThatFits(_ProposedSize(width: width, height: height))
        } else {
            size = .init(width: width ?? 10.0, height: height ?? 10.0)
        }
        
        return CGSize(
            width: axes.contains(.horizontal) ? (proposed.width ?? size.width) : size.width,
            height: axes.contains(.vertical) ? (proposed.height ?? size.height) : size.height
        )
    }
    
    internal static func animationOffset(for rect: CGRect, anchor: UnitPoint?, bounds: CGRect, contentSize: CGSize) -> CGPoint {
        if let anchor = anchor {
            return CGPoint(
                x: max(min((rect.width * anchor.x + rect.origin.x) - bounds.width * anchor.x, contentSize.width), 0),
                y: max(min((rect.height * anchor.y + rect.origin.y) - bounds.height * anchor.y, contentSize.height), 0)
            )
        }
        if bounds.contains(rect) {
            return CGPoint(
                x: max(min(bounds.origin.x, contentSize.width), 0),
                y: max(min(bounds.origin.y, contentSize.height), 0)
            )
        }
        
        let x: CGFloat
        if rect.maxX >= bounds.maxX {
            x = rect.maxX - bounds.width
        } else {
            if bounds.minX <= rect.minX {
                x = bounds.origin.x
            } else {
                x = rect.minX
            }
        }
        
        let y: CGFloat
        if rect.maxY >= bounds.maxY {
            y = rect.maxY - bounds.height
        } else {
            if bounds.minY <= rect.minY {
                y = bounds.origin.y
            } else {
                y = rect.minY
            }
        }
        
        return CGPoint(
            x: max(min(x, contentSize.width), 0),
            y: max(min(y, contentSize.height), 0)
        )
    }
    
    internal static func contentSizeThatFits(in proposed: _ProposedSize, contentComputer: LayoutComputer?, axes: Axis.Set) -> CGSize? {
        guard axes != .empty else {
            return nil
        }
        
        let width = axes.contains(.horizontal) ? nil : proposed.width
        let height = axes.contains(.vertical) ? nil : proposed.height
        
        if let contentComputer = contentComputer {
            return contentComputer.engine.sizeThatFits(_ProposedSize(width: width, height: height))
        } else {
            return CGSize(width: width ?? 10.0, height: height ?? 10.0)
        }
    }

}
