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

import UIKit

@available(iOS 13.0, *)
extension UIView {
    
    internal func adoptEnvironment(_ environment: EnvironmentValues, hostedSubview: UIView) {
        let currentIsEnabled = environment.isEnabled
        
        if isUserInteractionEnabled != currentIsEnabled {
            isUserInteractionEnabled = currentIsEnabled
        }
        
        let currentSemanticContentAttribute = environment.layoutDirection._semanticContentAttributes
        
        if hostedSubview.semanticContentAttribute != currentSemanticContentAttribute {
            hostedSubview.semanticContentAttribute = currentSemanticContentAttribute
        }
        
        if let accentColor = environment.accentColor {
            let resolvedColor = accentColor._box.resolve(in: environment)
            
            let uiColor = resolvedColor.uiColor
            
            if tintColor !== uiColor {
                tintColor = uiColor
            }
        }
        
        if let selfAsUIControl = hostedSubview as? UIControl {
            if selfAsUIControl.isEnabled != currentIsEnabled {
                selfAsUIControl.isEnabled = currentIsEnabled
            }
        }
    }
    
}
