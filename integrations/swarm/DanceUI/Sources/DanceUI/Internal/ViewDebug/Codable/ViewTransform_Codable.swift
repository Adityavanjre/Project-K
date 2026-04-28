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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
extension ViewTransform: Encodable {
    
    private enum CodingKeys: CodingKey, Hashable {
        case items
        case positionAdjustment
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var items = [Item]()
        forEach(inverted: true) { item, _ in
            items.append(item)
        }
        try? container.encode(items, forKey: .items)
        try? container.encode(positionAdjustment, forKey: .positionAdjustment)
    }
}

@available(iOS 13.0, *)
extension ViewTransform.Item: Encodable {
    
    private enum CodingKeys: CodingKey, Hashable {
        
        case translation
        case affineTransform
        case projectionTransform
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .translation(let size):
            try? container.encode(size, forKey: .translation)
        case .affineTransform(let affineTransform, let inverse):
            var transform3D = CATransform3DMakeAffineTransform(affineTransform)
            if inverse {
                transform3D = CATransform3DInvert(transform3D)
            }
            try? container.encode(transform3D.elements, forKey: .affineTransform)
        case .projectionTransform(let projectionTransform, let inverse):
            var transform3D = projectionTransform.transform3DValue
            if inverse {
                transform3D = CATransform3DInvert(transform3D)
            }
            try? container.encode(transform3D.elements, forKey: .projectionTransform)
        case .coordinateSpace(_), .sizedSpace(_, _), .scrollLayout(_):
            break
        }
    }
}

extension CATransform3D {
    var elements: [CGFloat] {
        [m11, m12, m13, m14,
         m21, m22, m23, m24,
         m31, m32, m33, m34,
         m41, m42, m43, m44]
    }
}

#endif
