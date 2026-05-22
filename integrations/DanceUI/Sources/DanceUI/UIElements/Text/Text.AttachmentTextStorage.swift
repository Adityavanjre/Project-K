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
extension Text {
    
    @usableFromInline
    internal final class AttachmentTextStorage: AnyTextStorage {
        
        internal var image: Image
        
        @usableFromInline
        internal init(image: Image) {
            self.image = image
        }
        
        internal override func resolve(into resolved: inout Text.Resolved, in environment: EnvironmentValues, options: ResolveOptions) {
            let resolvedImage = image.provider.resolve(in: environment, style: resolved.style)
            if let label = resolvedImage.label, options.contains(.showLabel), !resolvedImage.decorative {
                resolved.append(label, in: environment)
            }
            resolved.append(resolvedImage, in: environment)
        }
        
        internal override func resolvesToEmpty(in: EnvironmentValues, with: ResolveOptions) -> Bool {
            return false
        }
        
        internal override func isEqual(to instance: AnyTextStorage) -> Bool {
            guard let instance = instance as? AttachmentTextStorage else {
                return false
            }
            return self.image == instance.image
        }
        
        internal override func isStyled(options: Text.ResolveOptions) -> Bool {
            return true
        }
    }
}
