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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
extension ResolvedStyledText: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(string?.codable, forKey: .string)
        let margins = pixelMargins
        if margins != .zero {
            try container.encodeIfPresent(margins.codingProxy, forKey: .stylePadding)
        }
        if resolvableConfiguration != .none {
            try container.encode(resolvableConfiguration, forKey: .resolvableConfiguration)
        }
        try layoutProperties.encode(to: &container)
    }
    
    internal enum CodingKeys: CodingKey, Hashable {

      case string

      case stylePadding

      case truncationMode

      case lineLimit

      case minimumScaleFactor

      case lineSpacing

      case lineHeightMultiple

      case maximumLineHeight

      case minimumLineHeight

      case hyphenationFactor

      case bodyHeadOutdent

      case pixelLength

      case resolvableConfiguration

      case multilineTextAlignment

      case layoutDirection

      case layoutMargins
    }

}

@available(iOS 13.0, *)
extension TextLayoutProperties {
    fileprivate func encode(to container: inout KeyedEncodingContainer<ResolvedStyledText.CodingKeys>) throws {
        if truncationMode != .tail {
            try container.encode(truncationMode, forKey: .truncationMode)
        }
        if lineLimit != nil {
            try container.encode(lineLimit, forKey: .lineLimit)
        }
        if minScaleFactor != 1.0 {
            try container.encode(minScaleFactor, forKey: .minimumScaleFactor)
        }
        if lineSpacing != 0.0 {
            try container.encode(lineSpacing, forKey: .lineSpacing)
        }
        if lineHeightMultiple != 0.0 {
            try container.encode(lineHeightMultiple, forKey: .lineHeightMultiple)
        }
        if maximumLineHeight != MaximumLineHeightKey.defaultValue {
            try container.encode(maximumLineHeight, forKey: .maximumLineHeight)
        }
        if minimumLineHeight != MinimumLineHeightKey.defaultValue {
            try container.encode(minimumLineHeight, forKey: .minimumLineHeight)
        }
        if hyphenationFactor != 0.0 {
            try container.encode(hyphenationFactor, forKey: .hyphenationFactor)
        }
        if bodyHeadOutdent != 0.0 {
            try container.encode(bodyHeadOutdent, forKey: .bodyHeadOutdent)
        }
        if pixelLength != 1.0 {
            try container.encode(pixelLength, forKey: .pixelLength)
        }
        if multilineTextAlignment != .leading {
            try container.encode(multilineTextAlignment, forKey: .multilineTextAlignment)
        }
        if layoutDirection != .leftToRight {
            try container.encode(layoutDirection, forKey: .layoutDirection)
        }
    }
}

#endif
