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
internal final class ComposeFillImpl: NSObject, ComposeFill {}

@available(iOS 13.0, *)
internal final class ComposeStrokeImpl: NSObject, ComposeStroke {
    internal var width: CGFloat
    
    internal var miter: CGFloat
    
    internal var cap: ComposeStrokeCap
    
    internal var join: ComposeStrokeJoin
    
    internal var pathEffect: (any ComposePathEffect)?
    
    internal init(
        width: CGFloat,
        miter: CGFloat,
        cap: ComposeStrokeCap = .butt,
        join: ComposeStrokeJoin = .miter,
        pathEffect: (any ComposePathEffect)? = nil
    ) {
        self.width = width
        self.miter = miter
        self.cap = cap
        self.join = join
        self.pathEffect = pathEffect
    }
}
