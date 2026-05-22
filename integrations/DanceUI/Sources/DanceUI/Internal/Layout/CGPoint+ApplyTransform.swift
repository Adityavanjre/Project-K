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

@available(iOS 13.0, *)
extension CGPoint {
    
    internal mutating func applyTransform(item: ViewTransform.Item) {
        switch item {
        case .translation(let size):
            x += size.width
            y += size.height
        case .affineTransform(var affineTransform, let inverse):
            if inverse {
                affineTransform = affineTransform.inverted()
            }
            self = applying(affineTransform)
        case .projectionTransform(let projectionTransform, let inverse):
            if inverse {
                self = unapplying(projectionTransform)
            } else {
                self = applying(projectionTransform)
            }
        case .coordinateSpace, .sizedSpace, .scrollLayout:
            break
        }
    }
    
    internal func unapplying(_ transform : ProjectionTransform) -> CGPoint {
        let value = transform.m11 * transform.m22 + self.x * (transform.m23 * transform.m12 - transform.m22 * transform.m13) + (self.y * transform.m13 - transform.m12) * transform.m21 - self.y * transform.m11 * transform.m23

        guard value != 0 else {
            return self
        }
        
        let x = ((self.y * transform.m23 - transform.m22) * transform.m31 + self.x * (transform.m22 * transform.m33 - transform.m32 * transform.m23) + transform.m21 * transform.m32 - self.y * transform.m21 * transform.m33) / value
        let y = ((self.y * transform.m13 - transform.m12) * transform.m31 + self.x * (transform.m33 * transform.m12 - transform.m13 * transform.m32) + transform.m11 * transform.m32 - self.y * transform.m33 * transform.m11) / -value
        return CGPoint(x: x, y: y)
    }
    
    internal func applying(_ transform: ProjectionTransform) -> CGPoint {
        let value: CGFloat = self.x * transform.m13 + self.y * transform.m23 + transform.m33
        guard value > 0 else {
            return CGPoint(x: CGFloat.infinity, y: CGFloat.infinity)
        }
        
        let x = (self.x * transform.m11 + self.y * transform.m21 + transform.m31) / value
        let y = (self.x * transform.m12 + self.y * transform.m22 + transform.m32) / value

        return CGPoint(x: x, y: y)
    }
}

@available(iOS 13.0, *)
extension Array where Element == CGPoint {
    
    internal mutating func applyTransform(item: ViewTransform.Item) {
        for i in indices {
            self[i].applyTransform(item: item)
        }
    }
    
}
