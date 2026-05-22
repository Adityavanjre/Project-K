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
internal protocol ContentResponder {
    
    func contains(points: [CGPoint], size: CGSize, edgeInsets: EdgeInsets) -> BitVector64
    
    func contentPath(size: CGSize, edgeInsets: EdgeInsets) -> Path
    
    func contentPath(size: CGSize, edgeInsets: EdgeInsets, kind: ContentShapeKinds) -> Path
    
}

@available(iOS 13.0, *)
extension ContentResponder {
    
    internal func contains(points: [CGPoint], size: CGSize, edgeInsets: EdgeInsets) -> BitVector64 {
        let insetRect = CGRect(origin: .zero, size: size).inset(by: edgeInsets)
        return BitVector64().contained(points: points) { point in
            insetRect.has(point)
        }
    }
    
    internal func contentPath(size: CGSize, edgeInsets: EdgeInsets) -> Path {
        Path(CGRect(origin: .zero, size: size).inset(by: edgeInsets))
    }
    
    internal func contentPath(size: CGSize, edgeInsets: EdgeInsets, kind: ContentShapeKinds) -> Path {
        contentPath(size: size, edgeInsets: edgeInsets)
    }
}
