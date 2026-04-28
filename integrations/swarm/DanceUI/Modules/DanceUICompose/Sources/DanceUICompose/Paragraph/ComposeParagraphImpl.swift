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

@_spi(DanceUICompose) import DanceUI

private struct Constraints {
    fileprivate var minWidth: Int
    fileprivate var maxWidth: Int
    fileprivate var minHeight: Int
    fileprivate var maxHeight: Int
}

/// Line metrics following Skia's LineMetrics pattern.
/// All dimension values (ascent, descent, height, width, left, baseline) are in points.
private struct ComposeLineMetric {
    let startIndex: Int
    let endIndex: Int
    let endExcludingWhitespaces: Int
    let endIncludingNewline: Int
    let isHardBreak: Bool
    let ascent: CGFloat
    let descent: CGFloat
    let height: CGFloat
    let width: CGFloat
    let left: CGFloat
    let baseline: CGFloat
    let lineNumber: Int
}

@available(iOS 13, *)
internal final class ComposeParagraphImpl: NSObject, ComposeParagraph {
    internal init(
        intrinsics: any ComposeParagraphIntrinsics,
        minWidth: Int, maxWidth: Int, minHeight: Int, maxHeight: Int,
        maxLines: Int, ellipsis: Bool
    ) {
        let signpostId = Signpost.compose.tracePoiBegin("Paragraph:init", [])
        let intervalId = Signpost.compose.makeIntervalTraceID()
        Signpost.compose.traceIntervalBegin(id: intervalId, "Paragraph:init", [])
        let intrinsics = intrinsics as! ComposeParagraphIntrinsicsImpl
        self.intrinsics = intrinsics
        self.constraints = Constraints(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight)
        composePrint(.paragraph, message:"Paragraph:init - constraints: minWidth=\(minWidth), maxWidth=\(maxWidth), minHeight=\(minHeight), maxHeight=\(maxHeight)")

        self.resolvedStyledText = intrinsics.resolvedText(maxLines: maxLines, ellipsis: ellipsis)
        self.ellipsis = ellipsis
        composePrint(.paragraph, message:"Paragraph:init - resolvedStyledText.string.length: \(resolvedStyledText.string?.length ?? -1)")

        self.metrics = resolvedStyledText.metrics(requestedSize: CGSize(
            width: CGFloat(maxWidth).px2pt,
            height: CGFloat(maxHeight).px2pt
        ))

        let bounds = CGRect(
            x: -resolvedStyledText.layoutProperties.bodyHeadOutdent,
            y: 0,
            width: metrics.size.width,
            height: metrics.size.height)
        composePrint(.paragraph, message:"Paragraph:init - bounds before inset(pt): \(bounds)")

        let insets = resolvedStyledText.layoutMargins - resolvedStyledText.drawingMargins
        composePrint(.paragraph, message:"Paragraph:init - insets: \(insets)")

        self.bounds = bounds.inset(by: insets)

        if let placeholderRanges = intrinsics.placeholderRanges {
            let placeholderIndices = placeholderRanges.map { $0.range.location }
            let rects = intrinsics.getPlaceholderRects(attributedString: intrinsics.string, constraintWidth: metrics.requestedWidth, constraintHeight: bounds.size.height, placeholderIndices: placeholderIndices)
            self.placeholderRects = rects.map { NSValue(cgRect: $0.pt2px) }
        }

        composePrint(.paragraph, message: "Resolve paragraph to size: \(metrics.size)")
        Signpost.compose.traceIntervalEnd(id: intervalId, "Paragraph:init", [])
        Signpost.compose.tracePoiEnd(id: signpostId, "Paragraph:init", [])

    }

    internal let intrinsics: ComposeParagraphIntrinsicsImpl

    private let constraints: Constraints

    internal let resolvedStyledText: ResolvedStyledText

    internal let metrics: NSAttributedString.Metrics

    // Unit in pt
    internal let bounds: CGRect

    /// Whether ellipsis was requested for truncation
    private let ellipsis: Bool

    internal var width: CGFloat { CGFloat(constraints.maxWidth) }

    internal var height: CGFloat { metrics.size.height.pt2px }

    internal var minIntrinsicWidth: CGFloat { intrinsics.minIntrinsicWidth }

    internal var maxIntrinsicWidth: CGFloat { intrinsics.maxIntrinsicWidth }

    internal var firstBaseline: CGFloat { metrics.firstBaseline.pt2px }

    internal var lastBaseline: CGFloat { metrics.lastBaseline.pt2px }

    private var maxLines: Int { intrinsics.maxLines }

    /// Indicates whether the paragraph exceeds the maximum number of lines.
    /// Following Android logic:
    /// - When lineCount < maxLines: false (actual line count guaranteed not to exceed maxLines)
    /// - When lineCount >= maxLines: check if ellipsis is applied or text is truncated
    internal var didExceedMaxLines: Bool {
        guard let attributedString = resolvedStyledText.string else { return false }

        let actualLineCount = lineCount

        // When lineCount is less than maxLines, actual line count is guaranteed not to exceed maxLines
        if actualLineCount < maxLines {
            return false
        }

        // When lineCount >= maxLines, check if:
        // 1. Ellipsis is applied (line is truncated with ellipsis)
        // 2. Text is truncated (lineEnd of last line != charSequence.length)
        let lastLineIndex = min(actualLineCount, maxLines) - 1

        // Check if last line is ellipsized
        if isLineEllipsized(withLineIndex: lastLineIndex) {
            return true
        }

        // Check if text is truncated (last line doesn't end at the full text length)
        let lastLineEnd = getLineEnd(withLineIndex: lastLineIndex, visibleEnd: false)
        return lastLineEnd != attributedString.length
    }

    internal var placeholderRects: [NSValue] = []
    
    internal func paint(with canvas: any ComposeCanvas, paint: (any ComposePaint)?, color: UIColor, shadow: NSShadow?) {
        Signpost.compose.traceInterval("Paragraph:paint", []) {
            guard let canvas = canvas as? ComposeCanvasImpl else {
                return
            }
            canvas
                .drawParagraph(
                    self,
                    width: width.px2pt,
                    color: color,
                    shadow: shadow
                )
        }
    }

    // MARK: - Helper Properties

    /// Cached CTFrame for CoreText operations
    private lazy var ctFrame: CTFrame = {
        guard let string = resolvedStyledText.string else {
            fatalError("ResolvedStyledText.string is nil")
        }
        // Override lineBreakMode to .byCharWrapping so CTFrame wraps text
        // at character boundaries (matching Skia behavior). The original string
        // may have .byTruncatingTail which makes CTFrame produce only 1 line.
        let mutable = NSMutableAttributedString(attributedString: string)
        mutable.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: mutable.length)) { value, range, _ in
            let style = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            style.lineBreakMode = .byCharWrapping
            mutable.addAttribute(.paragraphStyle, value: style, range: range)
        }
        let framesetter = CTFramesetterCreateWithAttributedString(mutable)
        let path = CGPath(
            rect: CGRect(
                x: .zero,
                y: .zero,
                // Fix alignmet center issue
                width: CGFloat(constraints.maxWidth).px2pt,
                height: Double.greatestFiniteMagnitude
            ),
            transform: nil
        )
        return CTFramesetterCreateFrame(
            framesetter,
            CFRangeMake(0, mutable.length),
            path,
            nil
        )
    }()

    /// Cached CTLine array from ctFrame
    private lazy var ctLines: [CTLine] = {
        CTFrameGetLines(ctFrame) as! [CTLine]
    }()

    /// Line metrics tuple (ascent, descent, leading, width) for each line
    private lazy var ctLineMetrics: [(ascent: CGFloat, descent: CGFloat, leading: CGFloat, width: CGFloat)] = {
        ctLines.map { line in
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            return (ascent, descent, leading, width)
        }
    }()

    /// Cached line top positions (in points, accumulated from top)
    private lazy var ctLineTops: [CGFloat] = {
        var tops: [CGFloat] = []
        var currentTop: CGFloat = 0
        for metrics in ctLineMetrics {
            tops.append(currentTop)
            currentTop += metrics.ascent + metrics.descent + metrics.leading
        }
        return tops
    }()

    /// Cached line origins from CTFrame (accounts for text alignment)
    /// The x component reflects left/center/right alignment
    private lazy var ctLineOrigins: [CGPoint] = {
        var origins = [CGPoint](repeating: .zero, count: ctLines.count)
        CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, ctLines.count), &origins)
        composePrint(.paragraph, message:"ctLineOrigins: \(origins)")
        return origins
    }()

    /// Default font metrics extracted from the attributed string's font attribute
    /// Used for empty strings where no CTLines exist
    private lazy var defaultFontMetrics: (ascent: CGFloat, descent: CGFloat, leading: CGFloat)? = {
        guard let attributedString = resolvedStyledText.string else { return nil }
        guard let font = intrinsics.style.attributes[.font] as? UIFont else { return nil }
        let ctFont = font as CTFont
        let ascent = CTFontGetAscent(ctFont)
        let descent = CTFontGetDescent(ctFont)
        let leading = CTFontGetLeading(ctFont)
        composePrint(.paragraph, message:"defaultFontMetrics: ascent=\(ascent), descent=\(descent), leading=\(leading)")
        return (ascent, descent, leading)
    }()

    /// Cached line metrics array following Skia's LineMetrics pattern
    private lazy var lineMetrics: [ComposeLineMetric] = {
        buildLineMetrics()
    }()

    private func buildLineMetrics() -> [ComposeLineMetric] {
        let nsString = resolvedStyledText.string?.string as NSString?

        if ctLines.isEmpty {
            // For empty text, create a single line metric using default font metrics
            if let fm = defaultFontMetrics {
                return [ComposeLineMetric(
                    startIndex: 0,
                    endIndex: 0,
                    endExcludingWhitespaces: 0,
                    endIncludingNewline: 0,
                    isHardBreak: false,
                    ascent: fm.ascent,
                    descent: fm.descent,
                    height: fm.ascent + fm.descent + fm.leading,
                    width: 0,
                    left: 0,
                    baseline: fm.ascent,
                    lineNumber: 0
                )]
            }
            return []
        }

        var result: [ComposeLineMetric] = []

        for i in 0..<ctLines.count {
            let line = ctLines[i]
            let range = CTLineGetStringRange(line)
            let startIdx = range.location
            let endInclNewline = range.location + range.length

            // Determine if this is a hard break (ends with \n)
            var hardBreak = false
            if let str = nsString, endInclNewline > startIdx {
                let lastChar = str.character(at: endInclNewline - 1)
                hardBreak = (lastChar == 0x0A)
            }

            // endIndex: end excluding trailing newline for hard breaks
            let endIdx = hardBreak ? (endInclNewline - 1) : endInclNewline

            // endExcludingWhitespaces: trim trailing whitespace
            var endExcWhite = endIdx
            if let str = nsString {
                while endExcWhite > startIdx {
                    let ch = str.character(at: endExcWhite - 1)
                    if let scalar = UnicodeScalar(ch),
                       !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                        break
                    }
                    endExcWhite -= 1
                }
            }

            let m = ctLineMetrics[i]
            let lineTopPt = ctLineTops[i]
            let baselinePt = lineTopPt + m.ascent

            result.append(ComposeLineMetric(
                startIndex: startIdx,
                endIndex: endIdx,
                endExcludingWhitespaces: endExcWhite,
                endIncludingNewline: endInclNewline,
                isHardBreak: hardBreak,
                ascent: m.ascent,
                descent: m.descent,
                height: m.ascent + m.descent + m.leading,
                width: m.width,
                left: ctLineOrigins[i].x,
                baseline: baselinePt,
                lineNumber: i
            ))
        }

        // Add virtual empty line for trailing newline (following Skia behavior)
        if let last = result.last, last.isHardBreak {
            let prevM = ctLineMetrics[result.count - 1]
            let prevTop = ctLineTops[result.count - 1]
            let virtualTopPt = prevTop + prevM.ascent + prevM.descent + prevM.leading

            let virtualAscent: CGFloat
            let virtualDescent: CGFloat
            let virtualLeading: CGFloat
            if let fm = defaultFontMetrics {
                virtualAscent = fm.ascent
                virtualDescent = fm.descent
                virtualLeading = fm.leading
            } else {
                virtualAscent = last.ascent
                virtualDescent = last.descent
                virtualLeading = 0
            }

            result.append(ComposeLineMetric(
                startIndex: last.endIncludingNewline,
                endIndex: last.endIncludingNewline,
                endExcludingWhitespaces: last.endIncludingNewline,
                endIncludingNewline: last.endIncludingNewline,
                isHardBreak: false,
                ascent: virtualAscent,
                descent: virtualDescent,
                height: virtualAscent + virtualDescent + virtualLeading,
                width: 0,
                left: 0,
                baseline: virtualTopPt + virtualAscent,
                lineNumber: result.count
            ))
        }

        return result
    }

    /// Find line metrics for the given character offset using binary search.
    /// Following Skia's lineMetricsForOffset pattern.
    private func lineMetricsForOffset(_ offset: Int) -> ComposeLineMetric? {
        return lineMetrics.binarySearchFirstMatchingOrLast { offset < $0.endIncludingNewline }
    }

    /// Number of lines in the paragraph
    internal var lineCount: Int {
        return max(ctLines.count, 1) // At least 1 line even for empty text
    }

    // MARK: - Cursor and Position APIs

    /// Returns the cursor rectangle at the given character offset.
    /// Following Skia's getCursorRect pattern:
    /// - Uses baseline-based positioning (baseline - ascent for top, baseline + descent for bottom)
    /// - Includes workaround for new empty lines to avoid oversized cursors
    internal func getCursorRect(withOffset offset: Int) -> CGRect {
        guard let attributedString = resolvedStyledText.string else {
            return .zero
        }

        // Validate offset
        guard offset >= 0 && offset <= attributedString.length else {
            composePrint(.paragraph, message: "[ERROR] getCursorRect: offset \(offset) out of bounds [0, \(attributedString.length)]")
            return .zero
        }

        let horizontal = getHorizontalPosition(withOffset: offset, usePrimaryDirection: true)
        guard let line = lineMetricsForOffset(offset) else { return .zero }

        // Workaround for new empty line at end of text (following Skia pattern):
        // When cursor is on a new empty line, constrain ascent/descent to default font metrics
        // to avoid an oversized cursor.
        // See: https://bugs.chromium.org/p/skia/issues/detail?id=11321
        let isNewEmptyLine = (offset - 1 == line.startIndex) && (offset == attributedString.length)

        var asc = line.ascent
        var desc = line.descent

        if isNewEmptyLine, let fm = defaultFontMetrics {
            asc = min(asc, fm.ascent)
            desc = min(desc, fm.descent)
        }

        let top = (line.baseline - asc + bounds.origin.y).pt2px
        let bottom = (line.baseline + desc + bounds.origin.y).pt2px

        return CGRect(
            x: horizontal,
            y: top,
            width: 0,
            height: bottom - top
        )
    }

    /// Returns the character offset at the given screen position
    /// - Parameter position: Touch/click position (x, y) in pixels (includes bounds.origin offset)
    /// - Returns: Character offset closest to the position
    internal func getOffsetForPosition(_ position: CGPoint) -> Int {
        guard let attributedString = resolvedStyledText.string else { return 0 }

        // Convert from pixels to points and subtract bounds.origin offset
        let pointPt = CGPoint(
            x: position.x.px2pt - bounds.origin.x,
            y: position.y.px2pt - bounds.origin.y
        )

        // Find the line at this vertical position
        let lineIndex = getLineForVerticalPosition(position.y)
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return attributedString.length
        }

        let line = ctLines[lineIndex]
        let lineRange = CTLineGetStringRange(line)

        // Get the character index at the x position within this line
        let index = CTLineGetStringIndexForPosition(line, CGPoint(x: pointPt.x, y: 0))

        // CTLineGetStringIndexForPosition returns kCFNotFound (-1) if position is outside
        if index == kCFNotFound {
            // If x is before line start, return line start; if after, return line end
            if pointPt.x < 0 {
                return lineRange.location
            } else {
                return lineRange.location + lineRange.length
            }
        }

        return index
    }

    /// Returns the horizontal X position for the cursor at the given offset
    /// Following Skia implementation: uses CTLineGetOffsetForStringIndex for character positions
    /// - Parameters:
    ///   - offset: Character offset (0 to text.length inclusive)
    ///   - usePrimaryDirection: Whether to use primary text direction (for BiDi handling)
    /// - Returns: X coordinate in pixels (includes bounds.origin offset)
    internal func getHorizontalPosition(withOffset offset: Int, usePrimaryDirection: Bool) -> CGFloat {
        guard let attributedString = resolvedStyledText.string else {
            return bounds.origin.x.pt2px
        }

        // Handle empty text - cursor at origin
        if attributedString.length == 0 {
            return bounds.origin.x.pt2px
        }

        // Get the line containing the offset
        // Don't clamp offset here - getLineForOffset handles offset == text.length
        // and detects virtual empty lines after trailing newlines
        let lineIndex = getLineForOffset(offset)

        // Handle virtual empty line (e.g., cursor after trailing newline "aaa\n")
        // lineIndex == ctLines.count means we're on a virtual line, cursor at line start
        if lineIndex >= ctLines.count {
            return bounds.origin.x.pt2px
        }

        guard lineIndex >= 0 else {
            return bounds.origin.x.pt2px
        }

        let line = ctLines[lineIndex]
        let lineRange = CTLineGetStringRange(line)

        // For CTLineGetOffsetForStringIndex, clamp offset to the line's range
        let effectiveOffset = min(offset, lineRange.location + lineRange.length)

        // Use CTLineGetOffsetForStringIndex for precise cursor positioning
        var secondaryOffset: CGFloat = 0
        let xOffsetPt: CGFloat

        // CTLineGetOffsetForStringIndex handles offset at line end correctly
        var primaryOffset = CTLineGetOffsetForStringIndex(line, effectiveOffset, &secondaryOffset)

        // Workaround for CoreText returning 0 for low surrogates (odd index in surrogate pair)
        // When CTLineGetOffsetForStringIndex returns 0 for a non-zero offset within the line,
        // it's likely a low surrogate - use the previous offset's position instead
        // Example: 🇨🇳🌍 + offset 5
        if primaryOffset == 0 && effectiveOffset > 0 {
            if effectiveOffset > lineRange.location {
                // Try the previous offset - if it returns a valid position, use that
                var prevSecondary: CGFloat = 0
                let prevOffset = CTLineGetOffsetForStringIndex(line, effectiveOffset - 1, &prevSecondary)
                if prevOffset > 0 {
                    primaryOffset = prevOffset
                    secondaryOffset = prevSecondary
                }
            }
        }

        // Use primary or secondary offset based on usePrimaryDirection (for BiDi handling)
        xOffsetPt = usePrimaryDirection ? primaryOffset : secondaryOffset

        // Get line origin which accounts for text alignment (left/center/right)
        let lineOriginX = ctLineOrigins[lineIndex].x

        // Add line origin (for alignment) and bounds.origin offset, then convert to pixels
        return (xOffsetPt + lineOriginX + bounds.origin.x).pt2px
    }

    /// Returns the bounding box for the character at the given offset
    /// - Parameter offset: Character offset
    /// - Returns: Rectangle enclosing the character
    internal func getBoundingBox(withOffset offset: Int) -> CGRect {
        composePrint(.paragraph, message:"getBoundingBox called - offset: \(offset)")
        guard let attributedString = resolvedStyledText.string else {
            composePrint(.paragraph, message:"getBoundingBox - no string, returning .zero")
            return .zero
        }
        composePrint(.paragraph, message:"getBoundingBox - string.length: \(attributedString.length)")
        guard offset >= 0 && offset < attributedString.length else {
            composePrint(.paragraph, message:"getBoundingBox - offset out of bounds, returning .zero")
            return .zero
        }

        // Find the line containing this offset
        let lineIndex = getLineForOffset(offset)
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            composePrint(.paragraph, message:"getBoundingBox - lineIndex out of bounds, returning .zero")
            return .zero
        }

        let line = ctLines[lineIndex]
        let lineRange = CTLineGetStringRange(line)

        // Get the x offset for this character within the same line
        // Must use CTLine directly to ensure both offsets are calculated on the same line
        var secondaryOffset: CGFloat = 0
        let xOffset = CTLineGetOffsetForStringIndex(line, offset, &secondaryOffset)
        composePrint(.paragraph, message:"getBoundingBox - xOffset(pt): \(xOffset)")

        // Get the x offset for the next character to calculate width (within same line)
        let nextOffset = offset + 1
        let nextXOffset: CGFloat
        if nextOffset <= lineRange.location + lineRange.length {
            nextXOffset = CTLineGetOffsetForStringIndex(line, nextOffset, nil)
        } else {
            // At end of line, use line width
            nextXOffset = CGFloat(ctLineMetrics[lineIndex].width)
        }
        let charWidth = abs(nextXOffset - xOffset)
        composePrint(.paragraph, message:"getBoundingBox - nextXOffset(pt): \(nextXOffset), charWidth(pt): \(charWidth)")

        // Get line top and height using line APIs (these are already in px)
        let lineTop = getLineTop(withLineIndex: lineIndex)
        let lineHeight = getLineHeight(withLineIndex: lineIndex)

        // Get line origin which accounts for text alignment (left/center/right)
        let lineOriginX = ctLineOrigins[lineIndex].x

        // x and width need to be converted from pt to px
        // Add line origin (for alignment) and bounds.origin offset
        let result = CGRect(
            x: (xOffset + lineOriginX + bounds.origin.x).pt2px,
            y: lineTop,
            width: charWidth.pt2px,
            height: lineHeight
        )
        composePrint(.paragraph, message:"getBoundingBox - result(px): \(result)")
        return result
    }

    /// Returns rectangles covering the text range for selection highlighting
    /// Following Skia's approach: getRectsForRange(start, end, RectHeightMode.MAX, RectWidthMode.TIGHT)
    /// RectHeightMode.MAX means we use the maximum line height across all lines for consistent selection
    /// - Parameters:
    ///   - start: Start character offset (inclusive)
    ///   - end: End character offset (exclusive)
    /// - Returns: Array of CGRect values covering the range
    internal func getRectsForRange(withStart start: Int, end: Int) -> [NSValue] {
        composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange called: start=\(start), end=\(end)")

        guard start < end else {
            composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: early return (start >= end)")
            return []
        }

        guard resolvedStyledText.string != nil else {
            composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: no string, returning empty")
            return []
        }

        var rects: [NSValue] = []

        let startLine = getLineForOffset(start)
        let endLine = getLineForOffset(end - 1)
        composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: startLine=\(startLine), endLine=\(endLine)")

        // Calculate max line height across all lines in the range (emulating RectHeightMode.MAX)
        var maxLineHeight: CGFloat = 0
        for lineIndex in startLine...endLine {
            let lineHeight = getLineHeight(withLineIndex: lineIndex)
            maxLineHeight = max(maxLineHeight, lineHeight)
        }
        composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: maxLineHeight=\(maxLineHeight)")

        for lineIndex in startLine...endLine {
            let lineStart = getLineStart(withLineIndex: lineIndex)
            let lineEnd = getLineEnd(withLineIndex: lineIndex, visibleEnd: false)
            composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: lineIndex=\(lineIndex), lineStart=\(lineStart), lineEnd=\(lineEnd)")

            let rangeStart = max(start, lineStart)
            let rangeEnd = min(end, lineEnd)
            composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: rangeStart=\(rangeStart), rangeEnd=\(rangeEnd)")

            if rangeStart < rangeEnd {
                let leftBox = getBoundingBox(withOffset: rangeStart)
                let left = leftBox.minX

                let rightBox = getBoundingBox(withOffset: rangeEnd - 1)
                let right = rightBox.maxX
                composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: left=\(left), right=\(right)")

                // Use maxLineHeight for consistent selection height (RectHeightMode.MAX)
                let top = getLineTop(withLineIndex: lineIndex)
                let bottom = top + maxLineHeight
                composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: top=\(top), bottom=\(bottom) (using maxLineHeight)")

                let rect = CGRect(
                    x: min(left, right),
                    y: top,
                    width: abs(right - left),
                    height: maxLineHeight
                )
                composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: adding rect=\(rect)")
                rects.append(NSValue(cgRect: rect))
            }
        }

        composePrint(.paragraph, message:"[DanceUI][Swift] getRectsForRange: returning \(rects.count) rects")
        return rects
    }

    // MARK: - Line APIs

    /// Returns the line index containing the given character offset
    /// - Parameter offset: Character offset
    /// - Returns: Zero-based line index (can return ctLines.count for virtual empty line after trailing newline)
    internal func getLineForOffset(_ offset: Int) -> Int {
        guard let attributedString = resolvedStyledText.string else { return 0 }
        guard offset >= 0 && offset <= attributedString.length else {
            return 0
        }

        // Check if offset is at end of text after a trailing newline (virtual empty line)
        // This handles the case where "aaa\n" should show cursor on line 1, not line 0
        if offset == attributedString.length && offset > 0 && !ctLines.isEmpty {
            let nsString = attributedString.string as NSString
            let prevChar = nsString.character(at: offset - 1)
            if prevChar == 0x0A { // newline '\n'
                // Return virtual line index (one past the last CTLine)
                return ctLines.count
            }
        }

        for i in 0..<ctLines.count {
            let line = ctLines[i]
            let range = CTLineGetStringRange(line)
            // Check if offset is within this line's range
            if offset >= range.location && offset < range.location + range.length {
                return i
            }
            // Handle the case where offset is at the end of text (without trailing newline)
            if i == ctLines.count - 1 && offset == range.location + range.length {
                return i
            }
        }

        return max(ctLines.count - 1, 0)
    }

    /// Returns the line index at the given Y coordinate
    /// - Parameter vertical: Y coordinate in pixels
    /// - Returns: Zero-based line index
    internal func getLineForVerticalPosition(_ vertical: CGFloat) -> Int {
        let verticalPt = vertical.px2pt

        for i in 0..<ctLines.count {
            let lineTop = ctLineTops[i]
            let metrics = ctLineMetrics[i]
            let lineBottom = lineTop + metrics.ascent + metrics.descent + metrics.leading

            if verticalPt >= lineTop && verticalPt <= lineBottom {
                return i
            }
        }
        return max(ctLines.count - 1, 0)
    }

    /// Returns the Y coordinate of the top of the specified line
    /// - Parameter lineIndex: Zero-based line index (can be ctLines.count for virtual empty line)
    /// - Returns: Y coordinate in pixels
    internal func getLineTop(withLineIndex lineIndex: Int) -> CGFloat {
        // Handle empty text - return origin
        if ctLines.isEmpty && lineIndex == 0 {
            return bounds.origin.y.pt2px
        }

        // Handle virtual empty line after trailing newline (lineIndex == ctLines.count)
        // The top of the virtual line is the bottom of the last real line
        if lineIndex == ctLines.count && !ctLines.isEmpty {
            return getLineBottom(withLineIndex: ctLines.count - 1)
        }

        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        let lineTopPt = ctLineTops[lineIndex]

        // Add bounds.origin offset since paragraph is drawn at bounds.origin
        let result = (lineTopPt + bounds.origin.y).pt2px
        composePrint(.paragraph, message:"getLineTop lineIndex=\(lineIndex) result=\(result)")
        return result
    }

    /// Returns the Y coordinate of the bottom of the specified line
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: Y coordinate in pixels
    internal func getLineBottom(withLineIndex lineIndex: Int) -> CGFloat {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return height
        }

        let metrics = ctLineMetrics[lineIndex]
        let lineTopPt = ctLineTops[lineIndex]
        let lineBottomPt = lineTopPt + metrics.ascent + metrics.descent + metrics.leading

        // Add bounds.origin offset since paragraph is drawn at bounds.origin
        let result = (lineBottomPt + bounds.origin.y).pt2px
        composePrint(.paragraph, message:"getLineBottom lineIndex=\(lineIndex) result=\(result)")
        return result
    }

    /// Returns the height of the specified line
    /// - Parameter lineIndex: Zero-based line index (can be ctLines.count for virtual empty line)
    /// - Returns: Height in pixels
    internal func getLineHeight(withLineIndex lineIndex: Int) -> CGFloat {
        // Handle empty text - use font metrics to calculate line height
        if ctLines.isEmpty && lineIndex == 0 {
            if let fontMetrics = defaultFontMetrics {
                return (fontMetrics.ascent + fontMetrics.descent + fontMetrics.leading).pt2px
            }
            return height
        }

        // Handle virtual empty line after trailing newline (lineIndex == ctLines.count)
        // Use the height of the first line (consistent with how empty lines are handled)
        if lineIndex == ctLines.count && !ctLines.isEmpty {
            let metrics = ctLineMetrics[0]
            return (metrics.ascent + metrics.descent + metrics.leading).pt2px
        }

        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        let metrics = ctLineMetrics[lineIndex]
        return (metrics.ascent + metrics.descent + metrics.leading).pt2px
    }

    /// Returns the ascent of the specified line (negative value, distance from baseline to top)
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: Negative ascent in pixels
    private func getLineAscent(withLineIndex lineIndex: Int) -> CGFloat {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        let metrics = ctLineMetrics[lineIndex]
        return -metrics.ascent.pt2px
    }

    /// Returns the baseline Y position of the specified line
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: Baseline Y position in pixels
    private func getLineBaseline(withLineIndex lineIndex: Int) -> CGFloat {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        let metrics = ctLineMetrics[lineIndex]
        let lineTopPt = ctLineTops[lineIndex]
        let baselinePt = lineTopPt + metrics.ascent

        return (baselinePt + bounds.origin.y).pt2px
    }

    /// Returns the descent of the specified line (distance from baseline to bottom, excluding leading)
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: Descent in pixels
    private func getLineDescent(withLineIndex lineIndex: Int) -> CGFloat {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        let metrics = ctLineMetrics[lineIndex]
        return metrics.descent.pt2px
    }

    /// Returns the left edge X coordinate of the line's content
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: X coordinate in pixels
    internal func getLineLeft(withLineIndex lineIndex: Int) -> CGFloat {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        // Get line origin which accounts for text alignment (left/center/right)
        let lineOriginX = ctLineOrigins[lineIndex].x

        // Add line origin (for alignment) and bounds.origin offset
        return (lineOriginX + bounds.origin.x).pt2px
    }

    /// Returns the right edge X coordinate of the line's content
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: X coordinate in pixels
    internal func getLineRight(withLineIndex lineIndex: Int) -> CGFloat {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return width
        }

        let metrics = ctLineMetrics[lineIndex]
        // Get line origin which accounts for text alignment (left/center/right)
        let lineOriginX = ctLineOrigins[lineIndex].x

        // Right = lineOrigin.x + lineWidth + bounds.origin.x
        return (lineOriginX + metrics.width + bounds.origin.x).pt2px
    }

    /// Returns the width of the line's content
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: Width in pixels
    internal func getLineWidth(withLineIndex lineIndex: Int) -> CGFloat {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        let metrics = ctLineMetrics[lineIndex]
        return metrics.width.pt2px
    }

    /// Returns the character offset of the first character in the line
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: Character offset
    internal func getLineStart(withLineIndex lineIndex: Int) -> Int {
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return 0
        }

        let line = ctLines[lineIndex]
        let range = CTLineGetStringRange(line)
        return range.location
    }

    /// Returns the character offset of the last character in the line
    /// - Parameters:
    ///   - lineIndex: Zero-based line index
    ///   - visibleEnd: If true, excludes trailing whitespace
    /// - Returns: Character offset
    internal func getLineEnd(withLineIndex lineIndex: Int, visibleEnd: Bool) -> Int {
        guard let attributedString = resolvedStyledText.string else { return 0 }
        guard lineIndex >= 0 && lineIndex < ctLines.count else {
            return attributedString.length
        }

        let line = ctLines[lineIndex]
        let range = CTLineGetStringRange(line)
        var lineEnd = range.location + range.length

        // Trim trailing whitespace if requested
        if visibleEnd {
            let nsString = attributedString.string as NSString
            while lineEnd > range.location {
                let charIndex = lineEnd - 1
                guard charIndex < nsString.length else { break }
                let char = nsString.character(at: charIndex)
                // Check for whitespace (space, tab, newline, etc.)
                let isWhitespace = CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(char) ?? UnicodeScalar(0))
                if !isWhitespace {
                    break
                }
                lineEnd -= 1
            }
        }

        return lineEnd
    }
    /// Checks if the line is truncated with ellipsis
    /// Following Android implementation: isLineEllipsized returns true when getEllipsisCount > 0
    /// For iOS, we check if the line doesn't cover the full text when ellipsis is enabled
    /// - Parameter lineIndex: Zero-based line index
    /// - Returns: True if the line is truncated with ellipsis
    internal func isLineEllipsized(withLineIndex lineIndex: Int) -> Bool {
        // Ellipsis can only be applied when the ellipsis flag is enabled
        guard ellipsis else { return false }

        guard lineIndex >= 0 && lineIndex < ctLines.count else { return false }

        // Only the last visible line can have ellipsis
        // When maxLines is applied, the last line (at index maxLines-1) may be ellipsized
        let isLastLine = (lineIndex == ctLines.count - 1)
        if !isLastLine {
            return false
        }

        // If we haven't reached maxLines, no ellipsis is needed
        if ctLines.count < maxLines {
            return false
        }

        // Get the original text length from intrinsics
        let originalTextLength = intrinsics.originalTextLength

        // Check if the last line's range doesn't cover the full original text
        // This indicates the text was truncated with ellipsis
        let line = ctLines[lineIndex]
        let range = CTLineGetStringRange(line)
        let lineEnd = range.location + range.length

        // If the line doesn't end at the original text length, it's ellipsized
        return lineEnd < originalTextLength
    }

    // MARK: - Word Boundary

    /// Check if the given offset is in valid range
    @inline(__always)
    private func checkOffsetIsValid(_ offset: Int, length: Int) {
        assert(offset >= 0 && offset <= length, "Invalid offset: \(offset). Valid range is [0, \(length)]")
    }

    /// Returns the word boundary containing the given offset using CFStringTokenizer
    /// - Parameter offset: Character offset
    /// - Returns: TextRange with start and end of the word
    internal func wordBoundary(with offset: Int) -> ComposeTextRange {
        guard let attributedString = resolvedStyledText.string else { return ComposeTextRange(start: 0, end: 0) }
        let string = attributedString.string as NSString

        checkOffsetIsValid(offset, length: string.length)

        // To match Skia/Android implementation:
        // - Return empty range if offset is between spaces
        // - Return previous word if offset is right after that word (at whitespace)
        func isWhitespace(_ offset: Int) -> Bool {
            guard let scalar = Unicode.Scalar(string.character(at: offset)) else { return false }
            return CharacterSet.whitespacesAndNewlines.contains(scalar)
        }
        
        // Check if we're at whitespace or end of text
        if (offset < string.length && isWhitespace(offset)) || offset == string.length {
            // Check if previous character is not whitespace
            if offset > 0, !isWhitespace(offset - 1) {
                return getParagraphWordBoundary(string, offset - 1)
            } else {
                // Between spaces or at start, return empty range
                return ComposeTextRange(start: offset, end: offset)
            }
        }
        return getParagraphWordBoundary(string, offset)
    }
    
    private func getParagraphWordBoundary(_ string: NSString, _ offset: Int) -> ComposeTextRange {
        // Use CFStringTokenizer for proper word boundary detection
        let cfString = string as CFString
        let locale = CFLocaleCopyCurrent()
        let tokenizer = CFStringTokenizerCreate(
            nil,
            cfString,
            CFRangeMake(0, string.length),
            kCFStringTokenizerUnitWord,
            locale
        )

        CFStringTokenizerGoToTokenAtIndex(tokenizer, offset)
        let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)

        if range.location == kCFNotFound {
            return ComposeTextRange(start: offset, end: offset)
        }

        return ComposeTextRange(start: range.location, end: range.location + range.length)
    }

    // MARK: - Text Direction (BiDi Support)

    /// Returns the paragraph-level text direction
    /// - Parameter offset: Character offset
    /// - Returns: Text direction
    internal func paragraphDirection(with offset: Int) -> ComposeTextDirection {
        guard let attributedString = resolvedStyledText.string else { return .leftToRight }
        guard offset >= 0 && offset < attributedString.length else {
            return .leftToRight
        }

        if let direction = attributedString.attribute(
            .writingDirection,
            at: offset,
            effectiveRange: nil
        ) as? NSWritingDirection {
            return direction == .rightToLeft ? .rightToLeft : .leftToRight
        }

        return .leftToRight
    }

    /// Returns the BiDi run direction at the given offset
    /// - Parameter offset: Character offset
    /// - Returns: Text direction of the BiDi run
    internal func bidiRunDirection(with offset: Int) -> ComposeTextDirection {
        guard let attributedString = resolvedStyledText.string else { return .leftToRight }
        if attributedString.length == 0 {
            return .leftToRight
        }
        if offset < 0 {
            return .leftToRight
        }
        let safeOffset = min(offset, attributedString.length - 1)
        let lineIndex = getLineForOffset(safeOffset)
        if lineIndex < 0 || lineIndex >= ctLines.count {
            return paragraphDirection(with: safeOffset)
        }
        let line = ctLines[lineIndex]
        let runs = CTLineGetGlyphRuns(line) as NSArray
        for case let run as CTRun in runs {
            let range = CTRunGetStringRange(run)
            let runEnd = range.location + range.length
            if safeOffset >= range.location && safeOffset < runEnd {
                let status = CTRunGetStatus(run)
                return status.contains(.rightToLeft) ? .rightToLeft : .leftToRight
            }
        }
        return paragraphDirection(with: safeOffset)
    }
}

/// Returns the first item satisfying `predicate`, or the last item in the array if none satisfy it.
/// Returns `nil` if the array is empty.
/// Following Skia's binarySearchFirstMatchingOrLast pattern.
extension Array {
    fileprivate func binarySearchFirstMatchingOrLast(_ predicate: (Element) -> Bool) -> Element? {
        guard !isEmpty else { return nil }
        var low = 0
        var high = count
        while low < high {
            let mid = low + (high - low) / 2
            if predicate(self[mid]) {
                high = mid
            } else {
                low = mid + 1
            }
        }
        return self[Swift.min(low, count - 1)]
    }
}
