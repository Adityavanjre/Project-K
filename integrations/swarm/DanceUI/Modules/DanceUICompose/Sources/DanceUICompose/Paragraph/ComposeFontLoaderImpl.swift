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
import UIKit
@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
internal final class ComposeFontLoaderImpl: NSObject, ComposeFontLoader {

    internal func load(withFontFamily fontFamily: String?, fontSize: CGFloat, fontWeight: UIFont.Weight, fontStyle: ComposeFontStyle) -> UIFont {
        Signpost.compose.tracePoi("FontLoader:load", []) {
            
            let size = fontSize.px2pt
            
            var font = if let fontFamily, let design = Self.detectFontDesign(from: fontFamily) {
                Font.system(size: size, weight: .init(rawWeight: fontWeight.rawValue), design: design)
            } else if let fontFamily {
                Font.custom(fontFamily, size: size)
                    .weight(.init(rawWeight: fontWeight.rawValue))
            } else {
                Font.system(size: size, weight: .init(rawWeight: fontWeight.rawValue))
            }
            if fontStyle == .italic {
                font = font.italic()
            }
            return UIFont(font)
        }
    }
    
    private static func detectFontDesign(from fontFamily: String) -> Font.Design? {
        let monospacedNames = [".AppleSystemUIFontMonospaced", "Menlo", "Courier"]
        if monospacedNames.contains(fontFamily) {
            return .monospaced
        }

        let serifNames = [".AppleSystemUIFontSerif", "Times", "Times New Roman"]
        if serifNames.contains(fontFamily) {
            return .serif
        }

        let defaultNames = [".AppleSystemUIFont", "Helvetica Neue", "Helvetica"]
        if defaultNames.contains(fontFamily) {
            return .default
        }

        return nil
    }
}
