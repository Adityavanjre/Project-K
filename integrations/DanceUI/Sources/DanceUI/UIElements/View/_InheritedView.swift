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

@available(iOS 13.0, *)
internal final class _InheritedView: _UIGraphicsView {
    
    internal override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        guard isUserInteractionEnabled &&
                alpha > 0.01 &&
                !isHidden &&
                subviews.count > 0 else {
            return nil
        }
        
        for subview in subviews.reversed() {
            let convertPoint = convert(point, to: subview)
            if let view = subview.hitTest(convertPoint, with: event) {
                return view
            }
        }
        
        return nil
    }
}

internal final class _RenderNodeLayerView: _UIGraphicsView {
    
    internal override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        guard isUserInteractionEnabled &&
                alpha > 0.01 &&
                !isHidden &&
                subviews.count > 0 else {
            return nil
        }
        
        for subview in subviews.reversed() {
            let convertPoint = convert(point, to: subview)
            if let view = subview.hitTest(convertPoint, with: event) {
                return view
            }
        }
        
        return nil
    }
}
