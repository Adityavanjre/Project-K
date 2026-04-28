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

@frozen
@available(iOS 13.0, *)
public enum _VAlignment {
    
    case top
    
    case center
    
    case bottom
    
}

@frozen
@available(iOS 13.0, *)
public struct _AlignmentLayout: UnaryLayout, Animatable, MultiViewModifier, PrimitiveViewModifier {
    
    public typealias Body = Never
    
    public typealias AnimatableData = EmptyAnimatableData
    
    internal typealias PlacementContextType = PlacementContext
    
    internal var horizontal: TextAlignment?
    
    internal var vertical: _VAlignment?
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        guard horizontal != nil && vertical != nil,
              let width = proposedSize.width,
              let height = proposedSize.height else
        {
            let size = proposedSize
            
            let childFitSize = child.layoutComputer.engine.sizeThatFits(size)
            
            let width: CGFloat
            let height: CGFloat
            
            if let proposedWidth = proposedSize.width, horizontal != nil {
                width = proposedWidth
            } else {
                width = childFitSize.width
            }
            
            if let proposedHeight = proposedSize.height, vertical != nil {
                height = proposedHeight
            } else {
                height = childFitSize.height
            }
            
            return CGSize(width: width, height: height)
        }
        
        return CGSize(width: width, height: height)
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContext) -> _Placement {
        let proposed = context.size
        
        let anchorrH = horizontal.unit
        
        let anchorV = vertical.unit
        
        let parentSize = context.size
        
        let anchorPosition = CGPoint(x: parentSize.width * anchorrH, y: parentSize.height * anchorV)
        
        let retVal = _Placement(
            proposedSize: proposed,
            anchor: UnitPoint(x: anchorrH, y: anchorV),
            at: anchorPosition
        )
        
        return retVal
    }
    
    internal func spacing(in context: SizeAndSpacingContext, child: LayoutProxy) -> Spacing {
        child.layoutComputer.engine.spacing()
    }
    
}

@available(iOS 13.0, *)
extension Optional where Wrapped == TextAlignment {
    
    @inline(__always)
    internal var unit: CGFloat {
        switch self {
        case .leading:
            return 0
        case .center, .justified:
            return 0.5
        case .trailing:
            return 1
        case .none:
            return 0.5
        }
    }
    
}

@available(iOS 13.0, *)
extension Optional where Wrapped == _VAlignment {
    
    @inline(__always)
    internal var unit: CGFloat {
        switch self {
        case .top:
            return 0
        case .center:
            return 0.5
        case .bottom:
            return 1
        case .none:
            return 0.5
        }
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    @inline(__always)
    internal func alignment(horizontal: TextAlignment?, vertical: _VAlignment?) -> some View {
        modifier(_AlignmentLayout(horizontal: horizontal, vertical: vertical))
    }
    
}
