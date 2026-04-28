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

import CoreFoundation

@available(iOS 13.0, *)
internal struct DanceUICTAttributeName: RawRepresentable {
    
    internal typealias RawValue = CFString
    
    internal let rawValue: RawValue
    
    @inline(__always)
    internal init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    @inline(__always)
    private init(static staticKey: NSAttributedString.Key) {
        rawValue = staticKey.rawValue.withCString { cString in
            CFStringCreateWithCStringNoCopy(nil, cString, CFStringBuiltInEncodings.nonLossyASCII.rawValue, kCFAllocatorNull)
        }
    }
    
    @inline(__always)
    internal init(rawValue: () -> CFString) {
        self.init(rawValue: rawValue())
    }
    
    internal static let font = DanceUICTAttributeName(static: .font)

    /// NSParagraphStyle, default defaultParagraphStyle
    internal static let paragraphStyle = DanceUICTAttributeName(static: .paragraphStyle)

    /// UIColor, default blackColor
    internal static let foregroundColor = DanceUICTAttributeName(static: .foregroundColor)

    /// UIColor, default nil: no background
    internal static let backgroundColor = DanceUICTAttributeName(static: .backgroundColor)

    /// NSNumber containing integer, default 1: default ligatures, 0: no ligatures
    internal static let ligature = DanceUICTAttributeName(static: .ligature)

    /// NSNumber containing floating point value, in points; amount to modify default kerning. 0 means kerning is disabled.
    internal static let kern = DanceUICTAttributeName(static: .kern)

    /// NSNumber containing floating point value, in points; amount to modify default tracking. 0 means tracking is disabled.
    internal static let tracking = DanceUICTAttributeName {
        if #available(iOS 14.0, *) {
            return NSAttributedString.Key.tracking.rawValue as CFString
        } else {
            return kCTTrackingAttributeName
        }
    }

    /// NSNumber containing integer, default 0: no strikethrough
    internal static let strikethroughStyle = DanceUICTAttributeName(static: .strikethroughStyle)

    /// NSNumber containing integer, default 0: no underline
    internal static let underlineStyle = DanceUICTAttributeName(static: .underlineStyle)

    /// UIColor, default nil: same as foreground color
    internal static let strokeColor = DanceUICTAttributeName(static: .strokeColor)

    /// NSNumber containing floating point value, in percent of font point size, default 0: no stroke; positive for stroke alone, negative for stroke and fill (a typical value for outlined text would be 3.0)
    internal static let strokeWidth = DanceUICTAttributeName(static: .strokeWidth)

    /// NSShadow, default nil: no shadow
    internal static let shadow = DanceUICTAttributeName(static: .shadow)

    /// NSString, default nil: no text effect
    internal static let textEffect = DanceUICTAttributeName(static: .textEffect)

    /// NSTextAttachment, default nil
    internal static let attachment = DanceUICTAttributeName(static: .attachment)

    /// NSURL (preferred) or NSString
    internal static let link = DanceUICTAttributeName(static: .link)

    /// NSNumber containing floating point value, in points; offset from baseline, default 0
    internal static let baselineOffset = DanceUICTAttributeName(static: .baselineOffset)

    /// UIColor, default nil: same as foreground color
    internal static let underlineColor = DanceUICTAttributeName(static: .underlineColor)

    /// UIColor, default nil: same as foreground color
    internal static let strikethroughColor = DanceUICTAttributeName(static: .strikethroughColor)

    /// NSNumber containing floating point value; skew to be applied to glyphs, default 0: no skew
    internal static let obliqueness = DanceUICTAttributeName(static: .obliqueness)

    /// NSNumber containing floating point value; log of expansion factor to be applied to glyphs, default 0: no expansion
    internal static let expansion = DanceUICTAttributeName(static: .expansion)

    /// NSArray of NSNumbers representing the nested levels of writing direction overrides as defined by Unicode LRE, RLE, LRO, and RLO characters.  The control characters can be obtained by masking NSWritingDirection and NSWritingDirectionFormatType values.  LRE: NSWritingDirectionLeftToRight|NSWritingDirectionEmbedding, RLE: NSWritingDirectionRightToLeft|NSWritingDirectionEmbedding, LRO: NSWritingDirectionLeftToRight|NSWritingDirectionOverride, RLO: NSWritingDirectionRightToLeft|NSWritingDirectionOverride,
    internal static let writingDirection = DanceUICTAttributeName(static: .writingDirection)

    /// An NSNumber containing an integer value.  0 means horizontal text.  1 indicates vertical text.  If not specified, it could follow higher-level vertical orientation settings.  Currently on iOS, it's always horizontal.  The behavior for any other value is undefined.
    internal static let verticalGlyphForm = DanceUICTAttributeName(static: .verticalGlyphForm)
    
    internal static let inlinePresentationIntent = DanceUICTAttributeName(static: .inlinePresentationIntent)
    
    internal static let presentationIntent = DanceUICTAttributeName(static: .presentationIntentAttributeName)
    
}
