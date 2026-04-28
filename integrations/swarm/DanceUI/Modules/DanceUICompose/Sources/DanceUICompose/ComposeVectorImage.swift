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
@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
internal final class ComposeVectorImage: NSObject, ComposeImageBitmap {
    
    internal let type: ComposeImageBitmapType = .vector
    
    internal lazy var canvas = ComposeCanvasImpl(idContainer)
  
    internal var idContainer: ComposeDisplayListIdentityContainer = .init()
    
    internal var width: Int
    
    internal var height: Int
    
    internal var colorSpace: CGColorSpace
    
    internal var hasAlpha: Bool
    
    internal var config: ComposeImageBitmapConfig
    
    internal init(width: Int,
         height: Int,
         colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(),
         hasAlpha: Bool = true,
         config: ComposeImageBitmapConfig = .ARGB8888) {
        self.width = width
        self.height = height
        self.colorSpace = colorSpace
        self.hasAlpha = hasAlpha
        self.config = config
    }
    
    internal func setup(with config: ComposeAnimatedImageConfig) { }
    
    internal func content() -> DisplayList.Item.Value? {
        Signpost.compose.tracePoi("VectorImage:content", []) {
            let displayList = canvas.currentResult
            
            guard displayList != .empty else {
                return nil
            }
               
            return .effect(.identity, displayList)
        }
    }
    
}
