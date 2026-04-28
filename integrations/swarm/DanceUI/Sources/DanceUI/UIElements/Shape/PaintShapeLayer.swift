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
internal final class PaintShapeLayer: CALayer {
    
    internal var path: Path

    internal var origin: CGPoint

    internal var paint: AnyResolvedPaint?

    internal var paintBounds: CGRect
 
    internal var fillStyle: FillStyle
    
    internal override init() {
        self.path = .init()
        self.origin = .zero
        self.paint = .init()
        self.paintBounds = .zero
        self.fillStyle = .init()
        super.init()
    }
    
    internal override init(layer: Any) {
        self.path = .init()
        self.origin = .zero
        self.paint = .init()
        self.paintBounds = .zero
        self.fillStyle = .init()
        super.init(layer: layer)
    }
    
    internal required init?(coder: NSCoder) {
        self.path = .init()
        self.origin = .zero
        self.paint = .init()
        self.paintBounds = .zero
        self.fillStyle = .init()
        super.init(coder: coder)
    }
    
    internal override func draw(in context: CGContext) {
        
        GraphicsContext.renderingTo(cgContext: context, environment: EnvironmentValues()) { graphicsContext in
            
            graphicsContext.translateBy(x: -origin.x, y: -origin.y)
            
            guard let resolvedPaint = paint else {
                _danceuiFatalError("AnyResolvedPaint in PaintShapeLayer is empty.")
            }
            
            let rect = paintBounds.offsetBy(dx: origin.x, dy: origin.y)
            
            resolvedPaint.fill(path, style: fillStyle, in: graphicsContext, bounds: rect)
        }
    }
}
