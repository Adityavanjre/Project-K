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
internal struct AnchoredResolvedPaint<PaintType: ResolvedPaint>: ResolvedPaint {
    
    internal typealias AnimatableData = AnimatablePair<PaintType.AnimatableData, AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>>
    
    internal var paint: PaintType

    internal var bounds: CGRect
    
    internal var animatableData: AnimatableData {
        get {
            AnimatableData(paint.animatableData, bounds.animatableData)
        }
        
        set {
            paint.animatableData = newValue.first
            bounds.animatableData = newValue.second
        }
    }
    
    internal func fill(_ path: Path, style: FillStyle, in context: GraphicsContext, bounds: CGRect?) {
        var paintBounds: CGRect
        
        if let boundsValue = bounds {
            paintBounds = boundsValue
        } else {
            paintBounds = path.boundingRect
        }
        
        let newOrigin = self.bounds.origin.addPoint(paintBounds.origin)
        
        let newBounds = CGRect(origin: newOrigin, size: self.bounds.size)
        
        paint.fill(path, style: style, in: context, bounds: newBounds)
    }

    internal var isOpaque: Bool {
        paint.isOpaque
    }
    
    internal var isClear: Bool {
        paint.isClear
    }
}
