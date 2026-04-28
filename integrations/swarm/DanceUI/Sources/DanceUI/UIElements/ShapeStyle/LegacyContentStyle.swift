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
internal struct LegacyContentStyle: ShapeStyle {
    
    internal var id: ContentStyle.ID

    internal var color: Color
    
    internal static var sharedPrimary: AnyShapeStyle {
        AnyShapeStyle(LegacyContentStyle(id: .primary,
                                         color: .primary))
    }
    
    internal func _apply(to shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .prepare,
             .resolveStyle,
             .fallbackColor,
             .multiLevel:
            apply(to: &shape)
        case .primaryStyle:
            shape.result = .style(LegacyContentStyle.sharedPrimary)
        }
    }
    
    @inline(__always)
    private func apply(to shape: inout _ShapeStyle_Shape) {
        let systemColorsStyle = SystemColorsStyle()
        if id == .primary {
            systemColorsStyle._apply(to: &shape)
        } else {
            let offsetStyle = OffsetShapeStyle(base: systemColorsStyle, offset: Int(id.rawValue))
            offsetStyle._apply(to: &shape)
        }
    }
}

// TODO: _notImplemented EnvironmentValues.backgroundMaterial unused
//extension EnvironmentValues {
//    
//    @inline(__always)
//    internal var backgroundMaterial: Material? {
//        get {
//            self[BackgroundMaterialKey.self]
//        }
//        
//        set {
//            self[BackgroundMaterialKey.self] = newValue
//        }
//    }
//}
//
//private struct BackgroundMaterialKey: EnvironmentKey {
//    
//    fileprivate typealias Value = Material?
//    
//    fileprivate static var defaultValue: Material? {
//        nil
//    }
//}
