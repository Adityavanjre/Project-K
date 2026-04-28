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
internal struct EffectiveLabelStyle: Equatable {

    internal var baseType: Any.Type

    internal static var titleAndIcon: EffectiveLabelStyle {
        get {
            return EffectiveLabelStyle(baseType: TitleAndIconLabelStyle.Type.self)
        }
    }
    
    internal static var titleOnly: EffectiveLabelStyle {
        get {
            return EffectiveLabelStyle(baseType: TitleOnlyLabelStyle.Type.self)
        }
    }
    
    internal static var iconOnly: EffectiveLabelStyle {
        get {
            return EffectiveLabelStyle(baseType: IconOnlyLabelStyle.Type.self)
        }
    }
    
    internal static func == (lhs: Self, rhs: Self) -> Bool {
        // 0x3465b4 iOS15.2
        return lhs.baseType == rhs.baseType
    }
}




