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
@_spi(DanceUICompose) import DanceUI

@available(iOS 13, *)
internal final class ComposeParagraphIntrinsicsImpl: NSObject, ComposeParagraphIntrinsics {
    internal init(_ text: String,
                  style: ComposeParagraphAttributeStyle,
                  placeholderRanges: [any ComposeAnnotatedStringRangeWithPlaceholder],
                  maxLines: Int = 0,
                  ellipsis: Bool = false) {
        let id = Signpost.compose.tracePoiBegin("ParagraphIntrinsics:init", [])
        let intervalId = Signpost.compose.makeIntervalTraceID()
        Signpost.compose.traceIntervalBegin(id: intervalId, "ParagraphIntrinsics:init", [])
        self.maxLines = maxLines
        self.ellipsis = ellipsis
        self.style = style
        self.style.update(maxLines: maxLines, ellipsis: ellipsis)
        let mutable = NSMutableAttributedString(
            string: text,
            attributes: style.attributes
        )
        let parahraphStyle = makeParagraphStyle(environment: style.environment)
        mutable.addAttribute(.paragraphStyle, value: parahraphStyle, range: mutable.range)
        for spanStyleRange in style.spanStyleRanges {
            mutable.addAttributes(spanStyleRange.spanStyle.attributes, range: spanStyleRange.range)
        }
        var string = NSAttributedString(attributedString: mutable)
        self.placeholderRanges = placeholderRanges
        if !placeholderRanges.isEmpty {
            string = ComposeParagraphIntrinsicsImpl.buildAttributedString(text: string, placeholders: placeholderRanges)
        }
        self.string = string
        
        resolvedText = ResolvedStyledText(
            string: string,
            environment: style.environment,
            dynamicRendering: false,
            features: []
        )
        let metrics = resolvedText.metrics(requestedSize: CGSize(width: Double.infinity, height: Double.infinity))
        composePrint(.paragraph, message: "\(#function) resolved metrics \(metrics) for \(string)")
        maxIntrinsicWidth = metrics.size.width.pt2px

        Signpost.compose.tracePoiEnd(id: id, "ParagraphIntrinsics:init", [])
        Signpost.compose.traceIntervalEnd(id: intervalId, "ParagraphIntrinsics:init", [])
    }
    
    internal let string: NSAttributedString

    /// The length of the original text (before any truncation)
    internal var originalTextLength: Int { string.length }

    internal let style: ComposeParagraphAttributeStyle

    // NOTE: Use lazy var to avoid the overhead on non TextField necessary scene. Most Text scene will not call this API.
    // This optimization can avoid the extra 2~3% CPU usage on ScrollView with Text scene.
    /// Calculate minIntrinsicWidth as the width of the longest word
    /// This matches Android/Skia behavior where minIntrinsicWidth is the minimum width
    private(set) lazy var minIntrinsicWidth: CGFloat = Self.calculateMinIntrinsicWidth(string: string, style: style)
    
    /// 文本在单行显示时的最大宽度
    internal private(set) var maxIntrinsicWidth: CGFloat = .zero

    internal var hasStaleResolvedFonts: Bool {
        false
    }
    
    internal var placeholderRanges: [any ComposeAnnotatedStringRangeWithPlaceholder]? = nil
    
    internal var maxLines: Int
    
    private var ellipsis: Bool
    
    private var resolvedText: ResolvedStyledText
    
    internal func resolvedText(maxLines: Int, ellipsis: Bool) -> ResolvedStyledText {
        Signpost.compose.traceInterval("ParagraphIntrinsics:resolvedText", []) {
            guard maxLines != self.maxLines || ellipsis != self.ellipsis else {
                return resolvedText
            }
            return Signpost.compose.traceInterval("ParagraphIntrinsics:resolvedText:miss cache", []) {
                style.update(maxLines: maxLines, ellipsis: ellipsis)
                let mutable = NSMutableAttributedString(attributedString: string)
                let parahraphStyle = makeParagraphStyle(environment: style.environment)
                mutable.addAttribute(.paragraphStyle, value: parahraphStyle, range: mutable.range)
                return ResolvedStyledText(
                    string: NSAttributedString(attributedString: mutable),
                    environment: style.environment,
                    dynamicRendering: false,
                    features: []
                )
            }
        }
    }
    
    // 创建一个空的 attachment，只占空间不渲染
    internal static func createPlaceholderAttachment(width: CGFloat, height: CGFloat,
                                                     alignment: PlaceholderVerticalAlign) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage()
        attachment.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        return NSAttributedString(attachment: attachment)
    }
    
    //构建 AttributedString 时插入 Placeholder
    internal static func buildAttributedString(text: NSAttributedString,
                                               placeholders: [any ComposeAnnotatedStringRangeWithPlaceholder]) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: text)
        // 从后往前替换，避免 range 偏移问题
        for value in placeholders.sorted(by: { $0.range.location > $1.range.location }) {
            guard let placeholder = value.placeholder as? ComposeParagraphPlaceholderImpl else {
                continue
            }
            let attachmentString = createPlaceholderAttachment(
                width: placeholder.width.px2pt,
                height: placeholder.height.px2pt,
                alignment: placeholder.alignment
            )
            result.replaceCharacters(in: value.range, with: attachmentString)
        }
        
        return result
    }
    
    func getPlaceholderRects(
        attributedString: NSAttributedString,
        constraintWidth: CGFloat,
        constraintHeight: CGFloat,
        placeholderIndices: [Int]
    ) -> [CGRect] {
        var rects: [CGRect] = []
        
        let mutableAttr = NSMutableAttributedString(attributedString: attributedString)
        mutableAttr.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: mutableAttr.length)) { value, range, _ in
            guard let style = value as? NSParagraphStyle,
                  let mutableStyle = style.mutableCopy() as? NSMutableParagraphStyle else { return }
            mutableStyle.lineBreakMode = .byWordWrapping
            mutableAttr.addAttribute(.paragraphStyle, value: mutableStyle, range: range)
        }
        let attributedString = mutableAttr
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let framePath = CGPath(rect: CGRect(x: 0, y: 0, width: constraintWidth, height: constraintHeight), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), framePath, nil)
        
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        
        for (placeholderIdx, charIndex) in placeholderIndices.enumerated() {
            for (lineIndex, line) in lines.enumerated() {
                let lineRange = CTLineGetStringRange(line)
                
                if charIndex >= lineRange.location &&
                    charIndex < lineRange.location + lineRange.length {
                    
                    let xOffset = CTLineGetOffsetForStringIndex(line, charIndex, nil)
                    
                    guard let placeholderRanges = self.placeholderRanges,
                          placeholderIdx < placeholderRanges.count,
                          let placeholder = placeholderRanges[placeholderIdx].placeholder as? ComposeParagraphPlaceholderImpl else {
                        break
                    }
                    
                    let placeholderWidth = placeholder.width.px2pt
                    let placeholderHeight = placeholder.height.px2pt
                    let alignment = placeholder.alignment
                    
                    // 获取行的排版信息
                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    CTLineGetTypographicBounds(line, &ascent, &descent, nil)
                    
                    let lineOrigin = lineOrigins[lineIndex]
                    
                    let baselineY = constraintHeight - lineOrigin.y
                    
                    // 获取 placeholder 前一个字符的属性
                    let prevCharIndex = max(0, charIndex - 1)
                    let prevCharAttributes = attributedString.attributes(at: prevCharIndex, effectiveRange: nil)
                    let prevFont = prevCharAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 17)
                    
                    let textAscent = prevFont.ascender
                    let textDescent = -prevFont.descender  // descender 是负值
                    
                    
                    let y: CGFloat
                    switch alignment {
                    case .top:
                        // placeholder 顶部 = 行顶部 = 0
                        y = baselineY - ascent
                    case .bottom:
                        y = baselineY + descent - placeholderHeight
                    case .center:
                        let lineCenterY = baselineY - ascent + (ascent + descent) / 2
                        y = lineCenterY - placeholderHeight / 2
                    case .aboveBaseline:
                        y = baselineY - placeholderHeight
                    case .textTop:
                        y = baselineY - textAscent
                    case .textBottom:
                        y = baselineY + textDescent - placeholderHeight
                    case .textCenter:
                        y = baselineY - textAscent + (textAscent + textDescent - placeholderHeight) / 2
                    }
                    
                    let rect = CGRect(
                        x: lineOrigin.x + xOffset,
                        y: y,
                        width: placeholderWidth,
                        height: placeholderHeight
                    )
                    rects.append(rect)
                    break
                }
            }
        }
        
        return rects
    }

    /// Cache for `calculateMinIntrinsicWidth` results keyed by attributed string.
    /// `ObjectCache` is thread-safe and automatically constructs values on cache miss.
    private static let minIntrinsicWidthCache = ObjectCache<NSAttributedString, CGFloat> { string in
        let text = string.string
        guard !text.isEmpty else { return .zero }

        var maxWordWidth: CGFloat = .zero

        // Use a single CTTypesetter for all word measurements.
        // This is much cheaper than creating a ResolvedStyledText per word,
        // as the typesetter caches internal font/glyph data.
        let typesetter = CTTypesetterCreateWithAttributedString(string)

        // Use word boundary enumeration to find all words
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byWords) { word, range, _, _ in
            guard let word = word, !word.isEmpty else { return }
            let nsRange = NSRange(range, in: text)
            // Create a lightweight CTLine for just this word's range
            let line = CTTypesetterCreateLine(typesetter, CFRange(location: nsRange.location, length: nsRange.length))
            let width = CTLineGetTypographicBounds(line, nil, nil, nil)
            maxWordWidth = max(maxWordWidth, width)
        }

        // Also account for placeholder (NSTextAttachment) widths,
        // since word enumeration skips over attachment characters (\u{FFFC})
        string.enumerateAttribute(.attachment, in: NSRange(location: 0, length: string.length)) { value, _, _ in
            if let attachment = value as? NSTextAttachment {
                maxWordWidth = max(maxWordWidth, attachment.bounds.width)
            }
        }

        return maxWordWidth.pt2px
    }

    /// Calculate the minimum intrinsic width as the width of the longest word.
    /// This matches Android/Skia behavior where minIntrinsicWidth is the minimum width
    /// needed to display the text without breaking words.
    private static func calculateMinIntrinsicWidth(string: NSAttributedString, style: ComposeParagraphAttributeStyle) -> CGFloat {
        minIntrinsicWidthCache[string]
    }
}
