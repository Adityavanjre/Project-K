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

import CoreGraphics

@available(iOS 13.0, *)
// [ x']   [ x ] [  a   b  0  ]   [ ax + cy + tx ]
// [ y'] = [ y ] [  c   d  0  ] = [ bx + dy + ty ]
// [ 1 ]   [ 1 ] [  tx  ty 1  ]   [      1       ]

extension CGAffineTransform {
    
    @inlinable
    internal var isRectilinear: Bool {
        guard b != 0 || c != 0 else {
            return true
        }
        guard a == 0 else {
            return false
        }
        return d == 0
    }

}

@available(iOS 13.0, *)
extension CGAffineTransform {
    
    internal init(orientation: Image.Orientation, in size: CGSize) {
        switch orientation {
        case .up: /// ok
            self = .identity
        case .down: /// ok
            self = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: size.width, ty: size.height)
        case .left: /// ok
            self = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: size.height)
        case .right: /// ok
            self = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: size.width, ty: 0)
        case .upMirrored:
            self = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: size.width, ty: 0)
        case .downMirrored:
            self = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        case .leftMirrored: /// ok
            self = CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0)
        case .rightMirrored: /// ok
            self = CGAffineTransform(a: 0, b: -1, c: -1, d: 0, tx: 0, ty: 0).translatedBy(x: -size.height, y: -size.width)
        }
    }
}
