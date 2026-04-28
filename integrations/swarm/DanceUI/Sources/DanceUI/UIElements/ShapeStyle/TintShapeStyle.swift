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

/// A style that reflects the current tint color.
///
/// You can set the tint color with the ``View/tint(_:)`` modifier. If no
/// explicit tint is set, the tint is derived from the app's accent color.
///
/// You can also use ``ShapeStyle/tint`` to construct this style.
@available(iOS 13.0, *)
public struct TintShapeStyle: ShapeStyle {
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        let environment = shape.environment
        let resolvedColor: Color = environment.tintColor ?? .accentColor
        resolvedColor._apply(to: &shape)
    }
    
    public init() {
        
    }
}

@available(iOS 13.0, *)
extension ShapeStyle where Self == TintShapeStyle {

    /// A style that reflects the current tint color.
    ///
    /// You can set the tint color with the `tint(_:)` modifier. If no explicit
    /// tint is set, the tint is derived from the app's accent color.
    @_alwaysEmitIntoClient
    public static var tint: TintShapeStyle {
        TintShapeStyle()
    }
}
