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
public enum ContentSizeCategory : Hashable, CaseIterable {

    case extraSmall

    case small

    case medium
    
    case large
    
    case extraLarge

    case extraExtraLarge

    case extraExtraExtraLarge

    case accessibilityMedium

    case accessibilityLarge

    case accessibilityExtraLarge

    case accessibilityExtraExtraLarge
    // 0xb
    case accessibilityExtraExtraExtraLarge

    /// A Boolean value indicating whether the content size category is one that
    /// is associated with accessibility.
    public var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium,
             .accessibilityLarge,
             .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
    
    internal var ctTextSize: CFString {
        let textCategory: UIContentSizeCategory
        switch self {
        case .extraSmall:
            textCategory = .extraSmall
        case .small:
            textCategory = .small
        case .medium:
            textCategory = .medium
        case .large:
            textCategory = .large
        case .extraLarge:
            textCategory = .extraLarge
        case .extraExtraLarge:
            textCategory = .extraExtraLarge
        case .extraExtraExtraLarge:
            textCategory = .extraExtraExtraLarge
        case .accessibilityMedium:
            textCategory = .accessibilityMedium
        case .accessibilityLarge:
            textCategory = .accessibilityLarge
        case .accessibilityExtraLarge:
            textCategory = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:
            textCategory = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:
            textCategory = .accessibilityExtraExtraExtraLarge
        }
        
        return textCategory.rawValue as CFString
    }
}

@available(iOS 13.0, *)
extension ContentSizeCategory {
    public static func < (lhs: ContentSizeCategory, rhs: ContentSizeCategory) -> Bool {
        func comparisonValue(for sizeCategory: Self) -> Int {
            switch sizeCategory {
            case .extraSmall: return 0
            case .small: return 1
            case .medium: return 2
            case .large: return 3
            case .extraLarge: return 4
            case .extraExtraLarge: return 5
            case .extraExtraExtraLarge: return 6
            case .accessibilityMedium: return 7
            case .accessibilityLarge: return 8
            case .accessibilityExtraLarge: return 9
            case .accessibilityExtraExtraLarge: return 10
            case .accessibilityExtraExtraExtraLarge: return 11
            @unknown default: return 3
            }
        }
        return comparisonValue(for: lhs) < comparisonValue(for: rhs)
    }
    
    public static func <= (lhs: ContentSizeCategory, rhs: ContentSizeCategory) -> Bool {
        !(rhs < lhs)
    }
    
    public static func > (lhs: ContentSizeCategory, rhs: ContentSizeCategory) -> Bool {
        rhs < lhs
    }
    
    public static func >= (lhs: ContentSizeCategory, rhs: ContentSizeCategory) -> Bool {
        !(lhs < rhs)
    }
}


#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 13.0, *)
extension ContentSizeCategory {
    init?(_ uiContentSizeCategory: UIContentSizeCategory) {
        switch uiContentSizeCategory {
        case .extraSmall:                           self = .extraSmall
        case .small:                                self = .small
        case .medium:                               self = .medium
        case .large:                                self = .large
        case .extraLarge:                           self = .extraLarge
        case .extraExtraLarge:                      self = .extraExtraLarge
        case .extraExtraExtraLarge:                 self = .extraExtraExtraLarge
        case .accessibilityMedium:                  self = .accessibilityMedium
        case .accessibilityLarge:                   self = .accessibilityLarge
        case .accessibilityExtraLarge:              self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:         self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:    self = .accessibilityExtraExtraExtraLarge
        default:                                    return nil
        }
    }
}

@available(iOS 13.0, *)
extension UIContentSizeCategory {
    
    init(_ contentSizeCategory: ContentSizeCategory) {
        switch contentSizeCategory {
        case .extraSmall:                           self = .extraSmall
        case .small:                                self = .small
        case .medium:                               self = .medium
        case .large:                                self = .large
        case .extraLarge:                           self = .extraLarge
        case .extraExtraLarge:                      self = .extraExtraLarge
        case .extraExtraExtraLarge:                 self = .extraExtraExtraLarge
        case .accessibilityMedium:                  self = .accessibilityMedium
        case .accessibilityLarge:                   self = .accessibilityLarge
        case .accessibilityExtraLarge:              self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:         self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:    self = .accessibilityExtraExtraExtraLarge
        }
    }
    
}

#endif
