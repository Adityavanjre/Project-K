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
import Foundation

@available(iOS 13.0, *)
internal struct AnimatedShape<S: Shape>: ShapeStyledLeafView {
    
    internal var shape: S
    
    internal var fillStyle: FillStyle
    
    internal func shape(size: CGSize, edgeInsets: EdgeInsets) -> (ShapeStyle_RenderedShape.Shape, CGRect) {
        let positioningRect = CGRect(origin: .zero, size: size).inset(by: edgeInsets)
        let renderRect = CGRect(origin: .zero, size: positioningRect.size)
        let path = self.shape.path(in: renderRect)
        let shapeRect = positioningRect.flushNullToZero()
        let renderedShape = ShapeStyle_RenderedShape.Shape(path: path,
                                                           fillStyle: self.fillStyle)
        return (renderedShape, shapeRect)
    }
    
    internal struct Init: Rule {
        
        internal typealias Value = AnimatedShape<S>
        
        @Attribute
        internal var shape: S
        
        @Attribute
        internal var fillStyle: FillStyle
        
        internal var value: AnimatedShape<S> {
            .init(shape: self.shape, fillStyle: self.fillStyle)
        }
    }
}
