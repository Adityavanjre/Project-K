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
internal final class ComposeBlendModeColorFilter: NSObject, ComposeColorFilter {
    
    internal let color: UIColor
    
    internal let blendMode: CGBlendMode
    
    internal let type: ComposeColorFilterType = .tintColor
    
    internal init(color: UIColor, blendMode: CGBlendMode) {
        self.color = color
        self.blendMode = blendMode
    }
}

@available(iOS 13.0, *)
internal final class ComposeColorMatrixColorFilter: NSObject, ComposeColorFilter {
    
    internal let colorMatrix: _ColorMatrix
    
    internal let type: ComposeColorFilterType = .colorMatrix
    
    internal lazy var effect: DisplayList.Effect = .filter(.colorMatrix(colorMatrix))

    internal init(colorMatrix: _ColorMatrix) {
        self.colorMatrix = colorMatrix
    }
}

@available(iOS 13.0, *)
internal final class ComposeLightingColorFilter: NSObject, ComposeColorFilter {
    
    internal var multiplyColor: UIColor
    internal var addColor: UIColor
    
    internal let type: ComposeColorFilterType = .lighting
    
    internal lazy var effect: DisplayList.Effect = {
        let mulComponents = multiplyColor.cgColor.components ?? [1, 1, 1, 1]
        let addComponents = addColor.cgColor.components ?? [0, 0, 0, 0]
        let colorMatrix = _ColorMatrix(m11: Float(mulComponents[0]), m12: 0.0, m13: 0.0, m14: 0.0, m15: Float(addComponents[0]),
                                       m21: 0.0, m22: Float(mulComponents[1]), m23: 0.0, m24: 0.0, m25: Float(addComponents[1]),
                                       m31: 0.0, m32: 0.0, m33: Float(mulComponents[2]), m34: 0.0, m35: Float(addComponents[2]),
                                       m41: 0.0, m42: 0.0, m43: 0.0, m44: Float(mulComponents[3]), m45: Float(addComponents[3]))
        return .filter(.colorMatrix(colorMatrix))
    }()
    
    internal init(multiply: UIColor, add: UIColor) {
        self.multiplyColor = multiply
        self.addColor = add
    }
    
}
