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
internal final class ImageProviderBox<BaseImageProviderType: _ImageProvider>: AnyImageProviderBox {
    
    internal var base: BaseImageProviderType
    
    internal init(_ base: BaseImageProviderType) {
        self.base = base
    }
    
    internal override func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
        base.resolve(in: environment, style: style)
    }
    
    internal override var staticImage: UIImage? {
        base.staticImage
    }
    
    internal override func isEqual(to rhs: AnyImageProviderBox) -> Bool {
        base == (rhs as? ImageProviderBox<BaseImageProviderType>)?.base
    }
    
}

@usableFromInline
@available(iOS 13.0, *)
internal class AnyImageProviderBox: _ImageProvider {
    
    internal init() {
    }
    
    internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
        _abstract(self.self)
    }
    
    internal var staticImage: UIImage? {
        _abstract(self.self)
    }
    
    internal func isEqual(to rhs: AnyImageProviderBox) -> Bool {
        _abstract(self.self)
    }
    
    @usableFromInline
    internal static func == (lhs: AnyImageProviderBox, rhs: AnyImageProviderBox) -> Bool {
        false
    }
    
}
