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

@usableFromInline
@available(iOS 13.0, *)
internal struct StrokedPath: Equatable {
    
    internal let path: Path
    
    internal let style: StrokeStyle
    
    @DestroyableBox
    internal var cachedPath: UnsafeAtomicLazy<Path.PathBox>
    
    public init(path: Path, style: StrokeStyle) {
        self.path = path
        self.style = style
        _cachedPath = DestroyableBox(wrappedValue: UnsafeAtomicLazy<Path.PathBox>(cache: nil))
    }
    
    @usableFromInline
    internal static func == (lhs: StrokedPath, rhs: StrokedPath) -> Bool {
        lhs.path == rhs.path && lhs.style == rhs.style
    }
    
}

@available(iOS 13.0, *)
extension StrokedPath: PathValuable {
    
    internal var cgPath: CGPath {
        
        guard let pathBox = cachedPath.cache else {
            let newBox = box
            cachedPath.cache = newBox
            return newBox.cgPath
        }
        
        return pathBox.cgPath
    }
    
    fileprivate var box: Path.PathBox {
        
        var strokedPath = path.cgPath
        
        if !style.dash.isEmpty {
            strokedPath = strokedPath.copy(dashingWithPhase: style.dashPhase, lengths: style.dash)
        }
        
        strokedPath = strokedPath.copy(strokingWithWidth: style.lineWidth,
                                       lineCap: style.lineCap,
                                       lineJoin: style.lineJoin,
                                       miterLimit: style.miterLimit)
        return Path.PathBox(strokedPath)
    }
}
