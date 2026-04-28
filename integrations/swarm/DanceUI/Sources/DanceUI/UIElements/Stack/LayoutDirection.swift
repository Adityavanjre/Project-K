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

@available(iOS 13.0, *)
public enum LayoutDirection : Hashable, CaseIterable, Encodable {
    
    public typealias Value = LayoutDirection
    
    /// A left-to-right layout direction.
    case leftToRight

    /// A right-to-left layout direction.
    case rightToLeft
    
}

#if os(iOS) || os(tvOS)

import UIKit

@available(iOS 13.0, *)
extension LayoutDirection {
    
    internal init(_ traitEnvironmentLayoutDirection: UITraitEnvironmentLayoutDirection) {
        switch traitEnvironmentLayoutDirection {
        case .rightToLeft:  self = .rightToLeft
        default:            self = .leftToRight
        }
    }
    
    internal init?(_ layoutDirection: UIUserInterfaceLayoutDirection) {
        switch layoutDirection {
        case .leftToRight:
            self = .leftToRight
        case .rightToLeft:
            self = .rightToLeft
        @unknown default:
            return nil
        }
    }
    
    internal var _semanticContentAttributes: UISemanticContentAttribute {
        switch self {
        case .leftToRight: return .forceLeftToRight
        case .rightToLeft: return .forceRightToLeft
        }
    }
    
}

@available(iOS 13.0, *)
extension UITraitEnvironmentLayoutDirection {
    
    internal init(_ layoutDirection: LayoutDirection) {
        switch layoutDirection {
        case .leftToRight:  self = .leftToRight
        case .rightToLeft:  self = .rightToLeft
        }
    }
    
}

#endif
