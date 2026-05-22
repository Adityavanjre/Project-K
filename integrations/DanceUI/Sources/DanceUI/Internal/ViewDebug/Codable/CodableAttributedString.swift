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
internal struct CodableAttributedString: Encodable {

    internal var base: NSAttributedString

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(base.string, forKey: .string)
        var attributes: [CodableAttributes] = []
        base.applyRanges { range in
            attributes.append(CodableAttributes(range: range))
        }
        if !attributes.isEmpty {
            try container.encode(attributes, forKey: .attributes)
        }
    }
    
    private enum CodingKeys: CodingKey, Hashable {
        
        case string
        
        case attributes
    }
    
    internal struct Range {
        
        var start : Int
        
        var count : Int
        
        var attributes : [NSAttributedString.Key: Any]
    }
}

@available(iOS 13.0, *)
private struct CodableAttributes: Encodable {
    
    internal var range: CodableAttributedString.Range
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if range.start != 0 {
            try container.encode(range.start, forKey: .start)
        }
        if range.count < .max - range.start {
            try container.encode(range.count, forKey: .count)
        }
        let attributes = range.attributes
        try attributes.forEach { (key: NSAttributedString.Key, value: Any) in
            switch key {
            case .foregroundColor:
                if let uiColor = value as? UIColor {
                    let color = Color.Resolved(uiColor)
                    try container.encode(color, forKey: .foregroundColor)
                }
            case .paragraphStyle:
                if let paragraphStyle = value as? NSParagraphStyle {
                    try container.encode(paragraphStyle.codable, forKey: .paragraphStyle)
                }
            case .font:
                if let font = value as? UIFont {
                    try container.encode(font.codable, forKey: .font)
                }
            case .attachment:
                if let attachment = value as? NSTextAttachment {
                    try container.encode(attachment.codable, forKey: .attachment)
                }
            case .baselineOffset:
                if let baselineOffset = value as? Float {
                    try container.encode(baselineOffset, forKey: .baselineOffset)
                }
            case .strikethroughStyle:
                if let strikethroughStyle = value as? Int {
                    try container.encode(strikethroughStyle, forKey: .strikethroughStyle)
                }
            case .strikethroughColor:
                if let uiColor = value as? UIColor {
                    let color = Color.Resolved(uiColor)
                    try container.encode(color, forKey: .strikethroughColor)
                }
            case .underlineStyle:
                if let underlineStyle = value as? Int {
                    try container.encode(underlineStyle, forKey: .underlineStyle)
                }
            case .underlineColor:
                if let uiColor = value as? UIColor {
                    let color = Color.Resolved(uiColor)
                    try container.encode(color, forKey: .underlineColor)
                }
            case .shadow:
                if let shadow = value as? NSShadow {
                    let shadowStyle = ResolvedShadowStyle(shadow)
                    try container.encode(shadowStyle, forKey: .shadow)
                }
            default:
                break
            }
        }
    }
    
    internal enum CodingKeys: CodingKey, Hashable {
        
        case start
        
        case count
        
        case font
        
        case foregroundColor
        
        case paragraphStyle
        
        case attachment
        
        case baselineOffset
        
        case kerning
        
        case tracking
        
        case strikethroughStyle
        
        case strikethroughColor
        
        case underlineStyle
        
        case underlineColor
        
        case shadow
        
        case resolvableDateInterval
        
        case resolvableAbsoluteDate
        
        case resolvableCurrentDate
    }
}

@available(iOS 13.0, *)
extension NSAttributedString {
    
    @inline(__always)
    internal var codable: CodableAttributedString {
        .init(base: self)
    }
    
    internal func applyRanges(to action: (CodableAttributedString.Range) -> Void) {
        let length = self.length
        let nsRange = NSRange(0..<length)
        enumerateAttributes(in: nsRange) { attrs, range, _ in
            let lowerBound = range.lowerBound
            let upperBound = range.upperBound
            if lowerBound <= upperBound {
                var count = length
                let start = lowerBound
                
                count = (count ^ upperBound) | (start ^ 0)
                count = (count != 0) ? upperBound : .max
                count = count - start

                action(.init(start: start, count: count, attributes: attrs))
            }
        }
    }
}

@available(iOS 13.0, *)
private struct CodableNSParagraphStyle: Encodable {
    
    var base: NSParagraphStyle
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let alignment = base.alignment
        if alignment != .left {
            try container.encode(CTTextAlignment(alignment).rawValue, forKey: .alignment)
        }
        let lineBreakMode = base.lineBreakMode
        if lineBreakMode != .byTruncatingTail {
            try container.encode(lineBreakMode.rawValue, forKey: .lineBreakMode)
        }
        let lineSpacing = base.lineSpacing
        if lineSpacing != 0.0 {
            try container.encode(lineSpacing, forKey: .lineSpacing)
        }
        let lineHeightMultiple = base.lineHeightMultiple
        if lineHeightMultiple != 1.0 {
            try container.encode(lineHeightMultiple, forKey: .lineHeightMultiple)
        }
        let maximumLineHeight = base.maximumLineHeight
        if maximumLineHeight != MaximumLineHeightKey.defaultValue {
            try container.encode(maximumLineHeight, forKey: .maximumLineHeight)
        }
        let minimumLineHeight = base.minimumLineHeight
        if minimumLineHeight != MinimumLineHeightKey.defaultValue {
            try container.encode(minimumLineHeight, forKey: .minimumLineHeight)
        }
        let hyphenationFactor = base.hyphenationFactor
        if hyphenationFactor != 0.0 {
            try container.encode(hyphenationFactor, forKey: .hyphenationFactor)
        }
        let allowsTightening = base.allowsDefaultTighteningForTruncation
        if allowsTightening {
            try container.encode(allowsTightening, forKey: .allowsTightening)
        }
        let baseWritingDirection = base.baseWritingDirection
        if baseWritingDirection != .natural {
            try container.encode(baseWritingDirection.rawValue, forKey: .baseWritingDirection)
        }
    }
    
    internal enum CodingKeys: CodingKey, Hashable {
        
        case alignment
        
        case lineBreakMode
        
        case lineSpacing
        
        case lineHeightMultiple
        
        case maximumLineHeight
        
        case minimumLineHeight
        
        case hyphenationFactor
        
        case allowsTightening
        
        case baseWritingDirection
    }
}

@available(iOS 13.0, *)
extension NSParagraphStyle {
    
    @inline(__always)
    fileprivate var codable: CodableNSParagraphStyle {
        .init(base: self)
    }
}

private struct CodablePlatformFont: Encodable {
    
    var base: UIFont
    
    internal func encode(to encoder: Encoder) throws {
    }
    
    internal enum CodingKeys: CodingKey, Hashable {
        
        case data
        
        case url
        
        case name
        
        case options
        
        case textStyle
        
        case sizeCategory
        
        case size
        
        case traits
        
        case featureSettings
        
        case variations
    }
    
    enum Error: Swift.Error, Hashable {
        
        case invalidFont
    }
}

extension UIFont {
    
    @inline(__always)
    fileprivate var codable: CodablePlatformFont {
        .init(base: self)
    }
}

@available(iOS 13.0, *)
private struct CodableTextAttachment: Encodable {
    
    var base: NSTextAttachment
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let image = base.image {
            try container.encode(CodingKind.image.rawValue, forKey: .kind)
            try container.encode(image.codable, forKey: .value)
        }
    }
    
    internal enum CodingKeys: CodingKey, Hashable {
        
        case kind
        
        case value
    }
    
    internal enum CodingKind: UInt8 {
        
        case image
    }
    
    internal enum Error: Swift.Error, Hashable {
        
        case invalidAttachment
    }
}

@available(iOS 13.0, *)
extension NSTextAttachment {
    
    @inline(__always)
    fileprivate var codable: CodableTextAttachment {
        .init(base: self)
    }
}

@available(iOS 13.0, *)
extension ResolvedShadowStyle {
    init(_ shadow: NSShadow) {
        self.offset = shadow.shadowOffset
        self.radius = shadow.shadowBlurRadius
        if let color = shadow.shadowColor as? UIColor, let resolved = Color.Resolved.init(color) {
            self.color = resolved
        } else {
            self.color = .empty
        }
    }
}

@available(iOS 13.0, *)
internal struct CodablePlatformImage: Encodable {
    
    var base: UIImage
    
    internal func encode(to encoder: Encoder) throws {
        if let image = base.cgImage {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(CodableCGImage(base: image), forKey: .data)
            try container.encode(base.scale, forKey: .scale)
            try container.encode(base.imageOrientation.rawValue, forKey: .orientation)
            if let baselineOffset = base.baselineOffsetFromBottom {
                try container.encode(baselineOffset, forKey: .baselineOffset)
            }
            let mode = base.renderingMode
            if mode == .alwaysTemplate {
                try container.encode(true, forKey: .template)
            }
        }
    }
    
    private enum CodingKeys: CodingKey, Hashable {
        
        case data
        
        case scale
        
        case orientation
        
        case baselineOffset
        
        case template
    }
    
    private enum Error: Swift.Error, Hashable {
        
        case invalidImage
    }
}

@available(iOS 13.0, *)
extension UIImage {
    @inline(__always)
    internal var codable: CodablePlatformImage {
        .init(base: self)
    }
}

#endif
