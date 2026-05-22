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
internal struct __GridLayout {

    internal var itemSize: CGSize
    
    internal var itemSpacing: Spacing
    
    internal var lineSpacing: Spacing
    
    internal var fillDirection: FillDirection
    
//    internal init(itemSize: CGSize, itemSpacing: CGFloat, lineSpacing: CGFloat, fillDirection: FillDirection) {
//        _notImplemented()
//    }
//
//    internal init(itemSize: CGSize, itemSpacing: Spacing, lineSpacing: Spacing, fillDirection: FillDirection) {
//        _notImplemented()
//    }
//
//    private func counts(fillDirection: FillDirection, size: CGSize, itemSpacing: Spacing, itemCount: Int) -> (xCount: Int, yCount: Int) {
//        _notImplemented()
//    }
//
//    private func framesForViews(_: LayoutProxyCollection, fillDirection: FillDirection, size: CGSize, itemSize: CGSize, itemCount: Int) -> [CGRect] {
//        _notImplemented()
//    }
//
//    private func spacing(_: Spacing, inDimension: CGFloat, count: Int, itemDimension: CGFloat) -> CGFloat {
//        _notImplemented()
//    }
    
}

@available(iOS 13.0, *)
extension __GridLayout {
    
    internal struct Spacing {
        
        internal var min: CGFloat
        
        internal var max: CGFloat?
        
//        internal init(fixed: CGFloat) {
//            _notImplemented()
//        }
//
//        internal init(min: CGFloat, max: CGFloat?) {
//            _notImplemented()
//        }
    }
    
}

@available(iOS 13.0, *)
extension __GridLayout {
    
    internal enum FillDirection: Equatable, Hashable {
        
        case horizontal
        
        case vertical
        
    }
    
}

//extension __GridLayout: _Layout {
//
//    internal typealias PlacementContextType = PlacementContext
//
//    internal typealias AnimatableData = EmptyAnimatableData
//
//    internal typealias Body = Never
//
//    internal static var majorAxis: Axis? {
//        _notImplemented()
//    }
//
//    internal func placement(of collection: LayoutProxyCollection, in context: PlacementContext) -> [_Placement] {
//        _notImplemented()
//    }
//
//    internal func sizeThatFits(in size: _ProposedSize, context: SizeAndSpacingContext, children: LayoutProxyCollection) -> CGSize {
//        _notImplemented()
//    }
//}
