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

import CoreGraphics
import CoreText
import Foundation
import MyShims



// MARK: - CGSize Hashable
#if swift(<5.10)
@available(iOS 13.0, *)
extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(height)
        hasher.combine(width)
    }
}
#else
extension CGSize: @retroactive Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(height)
        hasher.combine(width)
    }
}
#endif



@available(iOS 13.0, *)
extension CGSize {
    
    internal var isInfinite: Bool {
        width.isInfinite || height.isInfinite
    }
    
    internal var isNull: Bool {
        width.isZero && height.isZero
    }
}

@available(iOS 13.0, *)
public extension NSRange {
    
    @inline(__always)
    internal init(string: String, lowerBound: String.Index, upperBound: String.Index) {
        let utf16 = string.utf16
        
        let lowerBound = lowerBound.samePosition(in: utf16)!
        let location = utf16.distance(from: utf16.startIndex, to: lowerBound)
        let length = utf16.distance(from: lowerBound, to: upperBound.samePosition(in: utf16)!)
        
        self.init(location: location, length: length)
    }
    
    @inline(__always)
    internal init(range: Range<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
    
    @inline(__always)
    internal init(range: ClosedRange<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
    
}

@available(iOS 13.0, *)

extension NSStringDrawingContext {
    
    internal static func _createDefaultContext() -> NSStringDrawingContext {
        let context = NSStringDrawingContext()
        context.my_wrapsForTruncationMode = true
        context.my_wantsBaselineOffset = true
        context.my_wantsScaledLineHeight = true
        context.my_wantsScaledBaselineOffset = true
        context.my_cachesLayout = true
        return context
    }
    
    internal static var danceUIMainThreadInstance: NSStringDrawingContext = {
        let ctx = NSStringDrawingContext()
        ctx.my_wrapsForTruncationMode = true
        ctx.my_wantsBaselineOffset = true
        ctx.my_wantsScaledLineHeight = true
        ctx.my_wantsScaledBaselineOffset = true
        ctx.my_cachesLayout = true
        return ctx
    }()
    
    internal static func configuredForDanceUI(minScaleFactor: CGFloat,
                                              lineLimit: Int?,
                                              kitCache: AnyObject?) -> NSStringDrawingContext {
        if #available(iOS 13.0, *) {
            danceUIMainThreadInstance.minimumScaleFactor = (minScaleFactor < 1.0 && minScaleFactor >= 0) ? minScaleFactor : 0
            danceUIMainThreadInstance.my_scaledLineHeight = .zero
            danceUIMainThreadInstance.my_scaledBaselineOffset = .zero
            danceUIMainThreadInstance.my_maximumNumberOfLines = UInt(lineLimit ?? 0)
            danceUIMainThreadInstance.my_cachesLayout = true
            danceUIMainThreadInstance.my_layout = kitCache
            return danceUIMainThreadInstance
        } else {
            let context: NSStringDrawingContext = _createDefaultContext()
            context.minimumScaleFactor = (minScaleFactor < 1.0 && minScaleFactor >= 0) ? minScaleFactor : 0
            context.my_maximumNumberOfLines = UInt(lineLimit ?? 0)
            return context
        }
    }
}

@available(iOS 13.0, *)
extension NSAttributedString {
    
    @_spi(DanceUICompose)
    public struct Metrics {
        
        @_spi(DanceUICompose)
        public var size: CGSize
        
        @_spi(DanceUICompose)
        public let scale: CGFloat
        
        @_spi(DanceUICompose)
        public let firstBaseline: CGFloat
        
        @_spi(DanceUICompose)
        public let lastBaseline: CGFloat
        
        @_spi(DanceUICompose)
        public var baselineAdjustment: CGFloat
        
        @_spi(DanceUICompose)
        public var requestedWidth: CGFloat
        
        @_spi(DanceUICompose)
        public var drawingContext: NSStringDrawingContext? = nil
    }
    
    
    internal struct MetricsCache {
        internal var kitCache: AnyObject? = nil
        
        internal let string: NSAttributedString
        
        internal let lineLimit: Int?
        
        internal let minScaleFactor: CGFloat
        
        internal let bodyHeadOutdent: CGFloat
        
        internal let pixelLength: CGFloat
        
        internal let widthIsFlexible: Bool
        
        internal let drawWithRequestedWidth: Bool
        
        
        @inline(__always)
        internal init(_ string: NSAttributedString?,
                      scaleFactorOverride: CGFloat?,
                      lineLimit: Int?,
                      minScaleFactor: CGFloat,
                      bodyHeadOutdent: CGFloat,
                      pixelLength: CGFloat,
                      widthIsFlexible: Bool,
                      drawWithRequestedWidth: Bool) {
            self.lineLimit = lineLimit
            self.minScaleFactor = minScaleFactor
            self.bodyHeadOutdent = bodyHeadOutdent
            self.pixelLength = pixelLength
            self.widthIsFlexible = widthIsFlexible
            var attributedString = string ?? .emptyString
            if let scaleFactorOverride = scaleFactorOverride, scaleFactorOverride != 1.0 {
                attributedString = attributedString.scaled(by: scaleFactorOverride)
            }
            self.string = attributedString
            self.drawWithRequestedWidth = drawWithRequestedWidth
        }
        internal mutating func metrics(requestedSize: CGSize, fromDraw: Bool = false) -> Metrics {
            Signpost.resolvedText.traceInterval("metrics with requestedSize") {
                ResovledStyledTextCache.withCache { cache in
                    cache.measure(context: self) {
                        guard let metrics = cache.entries[self, requestedSize] else {
                            return Signpost.graphHost.traceInterval("metrics with requestedSize cache miss and measured") {
                                let metrics = string.measured(requestedSize: requestedSize,
                                                              lineLimit: lineLimit,
                                                              minScaleFactor: minScaleFactor,
                                                              bodyHeadOutdent: bodyHeadOutdent,
                                                              widthIsFlexible: widthIsFlexible,
                                                              kitCache: &kitCache)
                                
                                
                                var size = metrics.size
                                size.width.round(.up, toMultipleOf: pixelLength)
                                size.height.round(.up, toMultipleOf: pixelLength)
                                var firstBaseline = metrics.firstBaseline
                                firstBaseline.round(.toNearestOrAwayFromZero, toMultipleOf: pixelLength)
                                let firstBaselineOffset = firstBaseline - metrics.firstBaseline
                                var lastBaseline = metrics.lastBaseline + firstBaselineOffset
                                lastBaseline.round(.up, toMultipleOf: pixelLength)
                                let finalMetrics = Metrics(size: size,
                                                           scale: metrics.scale,
                                                           firstBaseline: firstBaseline,
                                                           lastBaseline: lastBaseline,
                                                           baselineAdjustment: firstBaseline - metrics.firstBaseline,
                                                           requestedWidth: metrics.requestedWidth)
                                
                                cache.entries[self, requestedSize] = finalMetrics
                                cache.entries[self, size] = finalMetrics
                                
                                cache.profileData.missCount &+= 1
                                
                                return finalMetrics
                            }
                        }
                        Signpost.resolvedText.traceInterval("metrics with requestedSize cache hit cache") {
                            cache.profileData.hitCount &+= 1
                        }
                        return metrics
                    }
                }
            }
        }
    }
    
    internal static let emptyString = NSAttributedString()
    internal func ui_attributedStringFromRange(_ range: NSRange,
                                               scaledBy scaleFactor: CGFloat) -> NSAttributedString {
        guard let string = self.attributedSubstring(from: range).mutableCopy() as? NSMutableAttributedString else {
            _danceuiFatalError("")
        }
        string.enumerateAttribute(.font, in: .init(location: 0, length: string.length), options: .init(rawValue: 0)) { (value, range, stop) in
            guard let font = value as? UIFont else {
                return
            }
            let size = (font.pointSize * scaleFactor * 4.0).rounded() * 0.25
            let newFont = UIFont(descriptor: font.fontDescriptor, size: size)
            string.addAttribute(.font, value: newFont, range: range)
        }
        return string
    }
    internal func maxFontMetrics() -> (capHeight: CGFloat, ascender: CGFloat, descender: CGFloat) {
        var capHeight: CGFloat = 0.0
        var ascender: CGFloat = 0.0
        var descender: CGFloat = 0.0
        
        self.enumerateAttribute(.font, in: .init(location: 0, length: length), options: .init(rawValue: 0x100000)) { (value, range, stop) in
            let font = value! as! CTFont
            capHeight = max(CTFontGetCapHeight(font), capHeight)
            ascender = max(CTFontGetAscent(font), ascender)
            descender = min(-CTFontGetDescent(font), descender)
        }
        return (capHeight, ascender, descender)
    }
    
    internal func scaled(by scaleFactor: CGFloat) -> NSAttributedString {
        guard scaleFactor != 1.0 else {
            return self
        }
        let length = self.length
        return self.ui_attributedStringFromRange(.init(location: 0, length: length),
                                                 scaledBy: scaleFactor)
    }
    
    internal static let characterSet: CharacterSet = MyCTFontCopySystemUIFontExcessiveLineHeightCharacterSet() as CharacterSet
    
    internal func allFonts(in range: Range<String.Index>) -> Set<UIFont> {
        var fonts = Set<UIFont>()
        let string = self.string
        let nsRange = NSRange(range: range, in: string)
        self.enumerateAttribute(.font, in: nsRange, options: .init()) { (value, range, stop) in
            guard let font = value as? UIFont else {
                return
            }
            fonts.insert(font)
        }
        return fonts
    }
    
    internal var drawingMargins: EdgeInsets {
        let string = self.string
        var edgeInsets = EdgeInsets()
        guard let range = string.rangeOfCharacter(from: NSAttributedString.characterSet, options: .caseInsensitive, range: .init(uncheckedBounds: (string.startIndex, string.endIndex))) else {
            return edgeInsets
        }
        let fonts = self.allFonts(in: range)
        for font in fonts {
            var leading: CGFloat = 0
            var top: CGFloat = 0
            var trailing: CGFloat = 0
            var bottom: CGFloat = 0
            guard MyCTFontGetLanguageAwareOutsets(font as CTFont, &leading, &top, &trailing, &bottom) else { // BDCOV_EXCL_BLOCK
                continue
            }
            edgeInsets.top = max(edgeInsets.top, top)
            edgeInsets.leading = max(edgeInsets.leading, leading)
            edgeInsets.bottom = max(edgeInsets.bottom, bottom)
            edgeInsets.trailing = max(edgeInsets.trailing, trailing)
        }
        return edgeInsets
    }
    private func measured(requestedSize: CGSize,
                          lineLimit: Int?,
                          minScaleFactor: CGFloat,
                          bodyHeadOutdent: CGFloat,
                          widthIsFlexible: Bool,
                          kitCache: inout AnyObject?) -> Metrics {
        Signpost.resolvedText.tracePoi("nsattributedString measured string: %@ ;requestedSize: %f %f;", [self.string, requestedSize.width, requestedSize.height]) {
            let shouldCacheContext: Bool
            if #available(iOS 13, *) {
                shouldCacheContext = false
            } else {
                shouldCacheContext = true
            }
            
            let drawingContext = NSStringDrawingContext.configuredForDanceUI(minScaleFactor: minScaleFactor,
                                                                             lineLimit: lineLimit,
                                                                             kitCache: kitCache)
            if bodyHeadOutdent > 0 { // BDCOV_EXCL_BLOCK
                drawingContext.my_wantsNumberOfLineFragments = true
            }
            if #available(iOS 15, *) {
                drawingContext.my_activeRenderers = .zero
            }
            if #available(iOS 13, *) {
                drawingContext.my_cachesLayout = true
            }
            let formalizedRequestedSize: CGSize = CGSize(width: requestedSize.width.formalize(),
                                                         height: requestedSize.height.formalize())
            var boundingRect = Signpost.resolvedText.traceInterval("nsattributedString boundingRect hasCache: %@", [kitCache == nil ? "false" : "true"]) {
                return self.boundingRect(with: formalizedRequestedSize,
                                         options: .danceUIOptions,
                                         context: drawingContext)
            }
            
            if #available(iOS 13, *) {
                if let layout = drawingContext.my_layout {
                    kitCache = layout as AnyObject
                } else {
                    kitCache = nil
                }
                drawingContext.my_layout = nil // objc_retainAutoreleasedReturnValue
            }
            
            let contextScaledLineHeight = drawingContext.my_scaledLineHeight
            if contextScaledLineHeight != 0.0 && !contextScaledLineHeight.isNaN {
                boundingRect.size.height = contextScaledLineHeight
            }
            
            if bodyHeadOutdent > 0 { // BDCOV_EXCL_BLOCK
                // copy from 13.0 FIXME
                let numberOfLineFragments = Int(drawingContext.my_numberOfLineFragments)
                if numberOfLineFragments == 1 || self.string.components(separatedBy: .newlines).count == lineLimit {
                    let newWidth: CGFloat = boundingRect.size.width + bodyHeadOutdent
                    boundingRect.size.width = .minimum(newWidth, formalizedRequestedSize.width)
                }
            }
            
            var metricsSizeWidth = requestedSize.width
            
            if !widthIsFlexible {
                if boundingRect.size.width == .leastNonzeroMagnitude {
                    metricsSizeWidth = 0
                } else {
                    metricsSizeWidth = boundingRect.size.width
                }
            }
            
            let lastBaseline: CGFloat
            if contextScaledLineHeight == 0.0 {
                boundingRect.size.height = boundingRect.size.height == .leastNonzeroMagnitude ? 0 : boundingRect.size.height
                lastBaseline = drawingContext.my_baselineOffset
            } else {
                lastBaseline = drawingContext.my_scaledBaselineOffset
            }
            
            return Metrics(size: CGSize(width: metricsSizeWidth,
                                        height: boundingRect.size.height),
                           scale: drawingContext.actualScaleFactor,
                           firstBaseline: drawingContext.my_firstBaselineOffset,
                           lastBaseline: lastBaseline,
                           baselineAdjustment: 0,
                           requestedWidth: requestedSize.width,
                           drawingContext: shouldCacheContext ? drawingContext : nil)
        }
    }
    
    internal var hasLinkAttributes: Bool {
        var flag = false
        enumerateAttribute(NSAttributedString.Key.danceUILink, in: range) { value, subrange, shouldStop in
            guard URL(urlValue: value) != nil else {
                return
            }
            flag = true
            shouldStop.pointee = true
        }
        return flag
    }
    
    internal var hasTextInteractionAttributes: Bool {
        var flag = false
        enumerateAttributes(in: range) { attributes, subrange, shouldStop in
            if URL(urlValue: attributes[NSAttributedString.Key.danceUILink]) != nil {
                flag = true
                shouldStop.pointee = true
            }
            if attributes[NSAttributedString.Key.danceUI.textOnTapAction] is TextOnTapAction {
                flag = true
                shouldStop.pointee = true
            }
        }
        return flag
    }
    
}

@available(iOS 13.0, *)
extension NSAttributedString {
    
    internal func lineHeightScalingAdjustment(lineHeightMultiple: CGFloat, maximumLineHeight: CGFloat, minimumLineHeight: CGFloat) -> CGFloat {
        guard (lineHeightMultiple < 1) && (lineHeightMultiple != 0) ||
                maximumLineHeight != 0 ||
                minimumLineHeight != 0
        else {
            return 0
        }
        let (_, ascender, descender) = self.maxFontMetrics()
        let scender = ascender - descender
        let ascenderedLineHeightMutiple = (lineHeightMultiple == 0 ? 1 : lineHeightMultiple) * scender
        let newMaximumLineHeight = min((maximumLineHeight.isZero ? ascenderedLineHeightMutiple : maximumLineHeight), ascenderedLineHeightMutiple)
        let alignmentedMaximumLineHeight = ascenderedLineHeightMutiple >= minimumLineHeight ? newMaximumLineHeight : minimumLineHeight
        if scender > alignmentedMaximumLineHeight {
            return scender - alignmentedMaximumLineHeight
        }
        return 0
    }
}

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public final class ResolvedStyledText {
    
    public private(set) var string: NSAttributedString?

    // DanceUI Compose addition: stores the original string before any color updates
    private var originalString: NSAttributedString?
    
    internal private(set) var truncationMode: Text.TruncationMode
    
    internal private(set) var lineLimit: Int?
    
    internal private(set) var minScaleFactor: CGFloat
    
    internal private(set) var lineSpacing: CGFloat
    
    internal private(set) var lineHeightMultiple: CGFloat
    
    internal private(set) var maximumLineHeight: CGFloat
    
    internal private(set) var minimumLineHeight: CGFloat
    
    internal private(set) var hyphenationFactor: Float
    
    // internal private(set) var alignment: CTTextAlignment
    
    internal private(set) var multilineTextAlignment: TextAlignment
    
    internal private(set) var layoutDirection: LayoutDirection
    
    internal private(set) var bodyHeadOutdent: CGFloat
    
    internal private(set) var resolvableConfiguration: ResolvableAttributeConfiguration
    
    internal private(set) var pixelLength: CGFloat
    
    private var cache: NSAttributedString.MetricsCache
    
    internal private(set) var dynamicRendering: Bool
    
    internal let features: Text.ResolvedProperties.Features
    
    internal var scaleFactorOverride: CGFloat? = nil {
        didSet {
            self.cache = newCache()
        }
    }
    
    internal lazy var pixelMargins: EdgeInsets = {
        guard let string = string else {
            return .init()
        }
        var drawingMargins = string.drawingMargins
        drawingMargins.top += string.lineHeightScalingAdjustment(lineHeightMultiple: lineHeightMultiple, maximumLineHeight: maximumLineHeight, minimumLineHeight: minimumLineHeight)
        return drawingMargins.rounded(.up, toMultipleOf: cache.pixelLength)
    }()
    
    @_spi(DanceUICompose)
    public var drawingMargins: EdgeInsets {
        pixelMargins
    }
    
    @_spi(DanceUICompose)
    public var layoutMargins: EdgeInsets

    @_spi(DanceUICompose)
    public var _composeAlignFix = false
    
    @inline(__always)
    @_spi(DanceUICompose)
    public func metrics(requestedSize size: CGSize) -> NSAttributedString.Metrics {
        cache.metrics(requestedSize: size)
    }
    
    private func newCache() -> NSAttributedString.MetricsCache {
        var cache: NSAttributedString.MetricsCache
        cache = NSAttributedString.MetricsCache(string,
                                                scaleFactorOverride: scaleFactorOverride,
                                                lineLimit: lineLimit,
                                                minScaleFactor: minScaleFactor,
                                                bodyHeadOutdent: bodyHeadOutdent,
                                                pixelLength: pixelLength,
                                                widthIsFlexible: resolvableConfiguration.widthIsFlexible(dynamicRendering),
                                                drawWithRequestedWidth: hyphenationFactor != 0)
        return cache
    }
    
    @_spi(DanceUICompose)
    public init(string: NSAttributedString?,
                environment: EnvironmentValues,
                dynamicRendering: Bool,
                features: Text.ResolvedProperties.Features) {
        let id = Signpost.resolvedText.makeIntervalTraceID()
        Signpost.resolvedText.traceIntervalBegin(id: id, "init", [])
        if let string = string {
            self.string = string.scaled(by: 1.0)
            self.resolvableConfiguration = string.resolvableConfiguration()
        } else {
            self.string = .emptyString
            self.resolvableConfiguration = .none
        }
        self.truncationMode = environment.truncationMode
        self.lineLimit = environment.lineLimit
        self.minScaleFactor = environment.minimumScaleFactor
        self.lineSpacing = environment.lineSpacing
        self.lineHeightMultiple = environment.lineHeightMultiple
        self.maximumLineHeight = environment.maximumLineHeight
        self.minimumLineHeight = environment.minimumLineHeight
        self.hyphenationFactor = environment.hyphenationFactor
        self.bodyHeadOutdent = environment.bodyHeadOutdent
        self.pixelLength = environment.pixelLength
        let widthIsFlexible = resolvableConfiguration.widthIsFlexible(dynamicRendering)
        self.multilineTextAlignment = environment.multilineTextAlignment
        self.layoutDirection = environment.layoutDirection
        self.layoutMargins = .zero
        
        self.cache = .init(self.string,
                           scaleFactorOverride: scaleFactorOverride,
                           lineLimit: self.lineLimit,
                           minScaleFactor: minScaleFactor,
                           bodyHeadOutdent: bodyHeadOutdent,
                           pixelLength: pixelLength,
                           widthIsFlexible: widthIsFlexible,
                           drawWithRequestedWidth: hyphenationFactor != 0) // Fix me
        self.dynamicRendering = dynamicRendering
        self.features = features
        Signpost.resolvedText.traceIntervalEnd(id: id, "init", [])
    }
    
    internal var isEmpty: Bool {
        string?.length == 0
    }
    internal func spacing() -> Spacing {
        guard let string = string else {
            return .zero
        }
        let (capHeight, ascender, descender) = string.maxFontMetrics()
        let offset = (ascender - descender)
        var roundedOffset = offset * 0.1
        
        roundedOffset.round(.up, toMultipleOf: 4.0) // 4
        
        let aboveTextSpacing = offset + roundedOffset - ascender
        
        let belowTextSpacing = max(offset + roundedOffset - capHeight,
                                   roundedOffset - descender)
        
        let spacing = Spacing(minima: [
            .init(category: .textToText, edge: .top): 0,
            .init(category: .textToText, edge: .bottom): 0,
            .init(category: .edgeAboveText, edge: .top): aboveTextSpacing,
            .init(category: .edgeBelowText, edge: .bottom): belowTextSpacing,
        ])
        return spacing
    }
    internal func draw(in rect: CGRect, with size: CGSize) {
        Signpost.resolvedText.traceInterval("draw") {
            Signpost.resolvedText.tracePoi("draw string: %@; rect: %f %f %f %f, size: %f %f;", [string?.string ?? "", rect.origin.x,
                                                                                                rect.origin.y, rect.width, rect.height,
                                                                                                size.width, size.height]) {
                guard let string = string else {
                    return
                }
                
                let pixelMargins = self.pixelMargins
                
                let metrics = self.cache.metrics(requestedSize: size,fromDraw: true)
                
                var scale: CGFloat = 1.0
                
                if let scaleFactorOverride = scaleFactorOverride {
                    scale = scaleFactorOverride
                } else if minScaleFactor != 1.0 {
                    scale = metrics.scale
                } else {
                    scale = 1
                }
                
                var kitCache: AnyObject? = nil
                if scale == 1 && !resolvableConfiguration.containsResolvable {
                    kitCache = cache.kitCache
                }
                
                let sizeWidthWithOffset: CGFloat
                var originWidthWithOffset: CGFloat = rect.origin.x + pixelMargins.leading
                if _composeAlignFix {
                    sizeWidthWithOffset = metrics.requestedWidth
                } else if cache.drawWithRequestedWidth && metrics.requestedWidth < CGFloat.infinity {
                    sizeWidthWithOffset = metrics.requestedWidth
                    switch CTTextAlignment(textAlignment: layoutProperties.multilineTextAlignment, layoutDirection: layoutProperties.layoutDirection) {
                    case .left:
                        originWidthWithOffset += 0
                    case .right:
                        originWidthWithOffset += bodyHeadOutdent - metrics.requestedWidth
                    case .center:
                        originWidthWithOffset += (bodyHeadOutdent - metrics.requestedWidth) / 2.0
                    case .justified:
                        originWidthWithOffset += 0
                    case .natural:
                        assertionFailure("Fatal error: string = \(string.string) multilineTextAlignment = \(layoutProperties.multilineTextAlignment) layoutDirection = \(layoutProperties.layoutDirection)")
                    @unknown default:
                        break
                    }
                } else {
                    sizeWidthWithOffset = metrics.size.width + bodyHeadOutdent
                }
                let scaledString = string.scaled(by: scale)
                let drawingContext = NSStringDrawingContext.configuredForDanceUI(minScaleFactor: 1.0,
                                                                                 lineLimit: lineLimit,
                                                                                 kitCache: kitCache)
                drawingContext.my_wantsNumberOfLineFragments = false
                if #available(iOS 15.0, *) {
                    drawingContext.my_activeRenderers = (scaledString.hasLinkAttributes ? 1 : 0) << 3
                }
                let originHeight = pixelMargins.top + metrics.baselineAdjustment + rect.origin.y
                let sizeHeight = metrics.size.height
                let drawRect = CGRect(origin: CGPoint(x: originWidthWithOffset,
                                                      y: originHeight),
                                      size: CGSize(width: sizeWidthWithOffset,
                                                   height: sizeHeight))
                
                Signpost.resolvedText.tracePoi("draw inner drawRect: %f %f %f %f", [drawRect.origin.x, drawRect.origin.y, drawRect.width, drawRect.height]) {
                    scaledString.format().draw(with: drawRect,
                                               options: .danceUIOptions,
                                               context: drawingContext)
                }
            }
        }
        return
    }
    
    internal func nextUpdate(after time: Time) -> Time {
        guard resolvableConfiguration.isUpdateStrategyDelay else {
            return .distantFuture
        }
        switch resolvableConfiguration.updateStrategy {
        case .never:
            return .distantFuture
        case .time(let delay):
            return time.advanced(by: delay)
        }
    }
    
    internal func resolvedContent() -> NSAttributedString? {
        guard let string = string else {
            return nil
        }
        
        guard resolvableConfiguration.containsResolvable else {
            return string
        }
        
        guard case .time = resolvableConfiguration.updateStrategy else {
            return string
        }
        
        guard dynamicRendering else {
            return string
        }
        
        guard let mutableString = string.mutableCopy() as? NSMutableAttributedString else {
            return nil
        }
        
        // FIXME: mutableString.resolveAttributes()
        
        return mutableString
    }
    
    
#warning("Not support update asynchronously.")
    internal var updatesAsynchronously: Bool {
        false
    }
    
    internal func linkURL(at point: CGPoint, in size: CGSize) -> URL? {
        guard let string = string else {
            return nil
        }
        
        return NSLayoutManager.with(string,
                                    drawingScale: scaleFactor(for: size),
                                    size: size,
                                    layoutProperties: layoutProperties) { layoutManager, textContainer -> URL? in
            let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            guard index != NSNotFound else {
                return nil
            }
            let characterSearchRange = NSRange(location: index, length: 1)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: characterSearchRange, actualCharacterRange: nil)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            
            guard boundingRect.contains(point) else {
                return nil
            }
            
            var link = string.attribute(.danceUILink, at: index, effectiveRange: nil)
            link = link ?? string.attribute(.link, at: index, effectiveRange: nil)
            return URL(urlValue: link)
        }
    }
    
    internal func interactionItemList(at point: CGPoint, in size: CGSize, hitTestInsets: EdgeInsets?) -> TextInteractionItemList? {
        guard let string = string else { return nil }
        
        var itemList = TextInteractionItemList(items: [])
        
        let hasIteractionItems = NSLayoutManager.with(string,
                                                      drawingScale: scaleFactor(for: size),
                                                      size: size,
                                                      layoutProperties: layoutProperties) { layoutManager, textContainer -> Bool in
            
            func hitTestInLaidTexts(_ derivedPoint: CGPoint) -> (characterIndex: Int, boundingRect: CGRect)? {
                let index = layoutManager.characterIndex(for: derivedPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
                guard index != NSNotFound else {
                    return nil
                }
                
                let characterSearchRange = NSRange(location: index, length: 1)
                var actualCharacterSearchRange = characterSearchRange
                let glyphRange = layoutManager.glyphRange(forCharacterRange: characterSearchRange, actualCharacterRange: &actualCharacterSearchRange)
                let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                
                guard boundingRect.contains(derivedPoint) else {
                    return nil
                }
                
                return (characterIndex: index, boundingRect: boundingRect)
            }
            
            func findItemsForCharacter(at index: Int, boundingRect: CGRect) -> [TextInteractionItem]? {
                var items = [TextInteractionItem]()
                
                var actionRange = NSRange(location: index, length: 1)
                if let anyAction = string.attribute(.danceUI.textOnTapAction, at: index, effectiveRange: &actionRange),
                   let action = anyAction as? TextOnTapAction {
                    items.append(.onTapAction(action, string, actionRange, boundingRect, action.info))
                }
                
                var link = string.attribute(.danceUILink, at: index, effectiveRange: nil)
                link = link ?? string.attribute(.link, at: index, effectiveRange: nil)
                
                if let link = link, let url = URL(urlValue: link) {
                    items.append(.url(url))
                }
                
                if items.isEmpty {
                    return nil
                }
                
                return items
            }
            
            let (points, weights, _) = hitTestInsets.map({ hitPoints(point, hitTestInsets: $0) })
            ?? hitPoints(point: point, radius: 20, derivesOutmostOnly: true)
            
            struct WeighedHitResult {
                let point: CGPoint
                var weight: CGFloat
                let index: Int
                let items: [TextInteractionItem]
            }
            
            let sortedWeighedHitResults: [WeighedHitResult] = zip(points, weights).lazy.reduce([WeighedHitResult]()) { partialResult, weighedPoint in
                var nextResult = partialResult
                
                let (point, weight) = weighedPoint
                
                guard let (index, boundingRect) = hitTestInLaidTexts(point) else {
                    return nextResult
                }
                
                if let items = findItemsForCharacter(at: index, boundingRect: boundingRect) {
                    nextResult.append(WeighedHitResult(point: point, weight: weight, index: index, items: items))
                }
                
                return nextResult
            }.sorted { lhs, rhs in
                lhs.index < rhs.index
            }
            
            var previousIndex: Int?
            let summedWeighedHitResults = sortedWeighedHitResults.reduce([WeighedHitResult]()) { partialResults, result in
                var nextResults = partialResults
                if let oldPreviousIndex = previousIndex {
                    if oldPreviousIndex == result.index {
                        nextResults[nextResults.count - 1].weight += result.weight
                    } else {
                        previousIndex = result.index
                        nextResults.append(result)
                    }
                    return nextResults
                } else {
                    previousIndex = result.index
                    nextResults.append(result)
                    return nextResults
                }
            }.sorted { lhs, rhs in
                lhs.weight > rhs.weight
            }
            
            if let result = summedWeighedHitResults.first {
                itemList.items = result.items
            }
            
            return itemList.items.count > 0
        }
        
        if !hasIteractionItems {
            return nil
        }
        
        return itemList
    }
    
    @inline(__always)
    @_spi(DanceUICompose)
    public var layoutProperties: TextLayoutProperties {
        TextLayoutProperties(lineLimit: lineLimit,
                             truncationMode: truncationMode,
                             multilineTextAlignment: multilineTextAlignment,
                             layoutDirection: layoutDirection,
                             minScaleFactor: minScaleFactor,
                             lineSpacing: lineSpacing,
                             lineHeightMultiple: lineHeightMultiple,
                             maximumLineHeight: maximumLineHeight,
                             minimumLineHeight: minimumLineHeight,
                             hyphenationFactor: CGFloat(hyphenationFactor),
                             bodyHeadOutdent: bodyHeadOutdent,
                             pixelLength: pixelLength)
    }
    
    @inline(__always)
    internal func scaleFactor(for size: CGSize) -> CGFloat {
        let metrics = cache.metrics(requestedSize: size)
        
        if let scaleFactorOverride = scaleFactorOverride {
            return scaleFactorOverride
        }
        if minScaleFactor != 1 {
            return metrics.scale
        }
        return minScaleFactor
    }
    
    
    internal var needsStyledRendering: Bool {
        features.contains(.styledText)
    }
    
    @_spi(DanceUICompose)
    public func update(color: UIColor, shadow: NSShadow?) {
        guard let string else {
            return
        }
        let mutable = NSMutableAttributedString(attributedString: string)

        var hasAnyForegroundColor = false
        mutable.enumerateAttribute(.foregroundColor, in: mutable.range, options: []) { value, _, _ in
            if value != nil {
                hasAnyForegroundColor = true
            }
        }

        if !hasAnyForegroundColor {
            mutable.addAttribute(.foregroundColor, value: color, range: mutable.range)
        }

        if let shadow {
            mutable.addAttribute(.shadow, value: shadow, range: mutable.range)
        }
        self.string = mutable
        self.cache.kitCache = nil
    }
}

@available(iOS 13.0, *)
extension ResolvedStyledText: CustomStringConvertible {
    
    public var description: String {
        string?.string ?? ""
    }
}

@available(iOS 13.0, *)
internal struct ResolvableAttributeConfiguration: Codable, Equatable {
    
    internal var containsResolvable: Bool = false
    
    internal var updateStrategy: ResolvableAttributeUpdateStrategy = .never
    
    internal static let none: Self = ResolvableAttributeConfiguration()
    
    @inline(__always)
    internal init() {
        
    }
    
    @inline(__always)
    internal func widthIsFlexible(_ dynamicRendering: Bool) -> Bool {
        guard !containsResolvable else {
            return false
        }
        switch updateStrategy {
        case .time:
            return dynamicRendering
        case .never:
            return false
        }
    }
}

@available(iOS 13.0, *)
internal enum ResolvableAttributeUpdateStrategy: Codable, Equatable {
    
    case time(delay: Double)
    
    case never
    
}

@available(iOS 13.0, *)
extension NSAttributedString.Key {
    
    @inline(__always)
    internal static var resolvableAttributeConfiguration: NSAttributedString.Key {
        NSAttributedString.Key(rawValue: "resolvableAttributeConfiguration")
    }
    
    @inline(__always)
    @_spi(DanceUICompose)
    public static var languageIdentifierForDanceUI: NSAttributedString.Key {
        NSAttributedString.Key(rawValue: "NSLanguage")
    }
}

@available(iOS 13.0, *)
extension NSAttributedString {
    
    @inline(__always)
    internal func resolvableConfiguration() -> ResolvableAttributeConfiguration {
        let key: NSAttributedString.Key = .resolvableAttributeConfiguration
        guard let attribute = firstAttribute(ResolvableAttributeConfiguration.self, name: key) else {
            return .none
        }
        return attribute
    }
    
    @inline(__always)
    internal func firstAttribute<Attribute>(_ attributeType: Attribute.Type,
                                            name: NSAttributedString.Key) -> Attribute? {
        var attribute: Attribute?
        self.enumerateAttribute(name, in: range, options: .init(rawValue: 0)) { (attr, subrange, flagPtr) in
            guard let resultAttribute = attr as? Attribute else {
                return
            }
            attribute = resultAttribute
        }
        return attribute
    }
    
    @inline(__always)
    @_spi(DanceUICompose)
    public var range: NSRange {
        NSRange(0..<length)
    }
}

@available(iOS 13.0, *)
extension NSMutableAttributedString {
    
    // TODO: internal func resolveAttributes()
    
}

@available(iOS 13.0, *)
extension ResolvableAttributeConfiguration {
    
    @inline(__always)
    internal var isUpdateStrategyDelay: Bool {
        containsResolvable && updateStrategy != .never
    }
}

@available(iOS 13.0, *)

extension NSAttributedString {
    
    internal convenience init(format: NSAttributedString, locale: Locale , arguments: CVaListPointer) {
        let attributes = format.attributes(at: 0, effectiveRange: nil)
        let nsstr = NSString.init(format: format.string, locale: locale, arguments: arguments)
        self.init(string: nsstr as String, attributes: attributes)
    }
    
    internal var isStyled: Bool {
        var result = false
        enumerateAttributes(in: range, options: .init()) { attributes, attributesRange, stop in
            let checkAttributeNil: (NSAttributedString.Key) -> Bool = { key in
                guard attributes[key] == nil else {
                    result = true
                    stop.pointee = true
                    return false
                }
                return true
            }
            let attributesUnderCheck: [NSAttributedString.Key] = [.font, .foregroundColor, .backgroundColor, .strikethroughStyle, .underlineStyle, .kern, .baselineOffset, .strikethroughColor, .inlinePresentationIntent, .link]
            for key in attributesUnderCheck {
                guard checkAttributeNil(key) else { return }
            }
            if #available(iOS 14.0, *) {
                guard checkAttributeNil(.tracking) else { return }
            }
        }
        return result
    }
    
    @available(iOS 15.0, *)
    internal convenience init(markdown string: String) {
        do {
            self.init(try AttributedString(markdown: string))
        } catch {
            _danceuiFatalError("Error in translating '\(string)' to AttributedString.")
        }
    }
}

@available(iOS 13.0, *)
extension NSStringDrawingOptions {
    
    @inline(__always)
    internal static var danceUIOptions: NSStringDrawingOptions {
        NSStringDrawingOptions(rawValue: 0x100001)
    }
    
}

@available(iOS 13.0, *)
private final class ResovledStyledTextCache {
    
    fileprivate struct MetricsKey: Hashable {
        
        private let proposalSzie: CGSize
        
        private let lineLimit: Int?
        
        private let minScaleFactor: CGFloat
        
        private let bodyHeadOutdent: CGFloat
        
        private let pixelLength: CGFloat
        
        private let widthIsFlexible: Bool
        
        private let drawWithRequestedWidth: Bool
        
        @inline(__always)
        fileprivate init(cache: NSAttributedString.MetricsCache,
                         proposalSzie: CGSize) {
            self.proposalSzie = proposalSzie
            self.lineLimit = cache.lineLimit
            self.minScaleFactor = cache.minScaleFactor
            self.bodyHeadOutdent = cache.bodyHeadOutdent
            self.pixelLength = cache.pixelLength
            self.widthIsFlexible = cache.widthIsFlexible
            self.drawWithRequestedWidth = cache.drawWithRequestedWidth
        }
    }
    
    fileprivate struct Store {
        
        fileprivate var entries: [MetricsKey : NSAttributedString.Metrics]
        
        @inline(__always)
        fileprivate init() {
            entries = [:]
        }
        
    }
    
    fileprivate struct Entries {
        
        private unowned let cache: LRUCache<NSAttributedString, Store>
        
        @inline(__always)
        fileprivate init(cache: LRUCache<NSAttributedString, Store>) {
            self.cache = cache
        }
        
        @inline(__always)
        fileprivate subscript(cache: NSAttributedString.MetricsCache, requestedSize: CGSize) -> NSAttributedString.Metrics? {
            get {
                let key = MetricsKey(cache: cache, proposalSzie: requestedSize)
                return self.cache[cache.string, Store()].entries[key]
            }
            nonmutating _modify {
                let key = MetricsKey(cache: cache, proposalSzie: requestedSize)
                yield &self.cache[cache.string, Store()].entries[key]
            }
        }
        
    }
    
    fileprivate static let shared = ResovledStyledTextCache()
    
    fileprivate static let async = AsyncCache(ResovledStyledTextCache())
    
    private let cache: LRUCache<NSAttributedString, Store>
    
    @inline(__always)
    private init() {
        self.cache = LRUCache(totalWeight: 1000)
    }
    
    fileprivate var entries: Entries {
        Entries(cache: cache)
    }
    
    fileprivate func measure<R>(context: NSAttributedString.MetricsCache,
                                _ body: () -> R) -> R {
        return profileData.measure(context: context, body)
    }
    
    
    fileprivate struct ProfileData: CustomStringConvertible {
        
        
        private let frequency: Double
        
        private let startTimeBase: UInt64
        
        fileprivate var missCount: Int = 0
        
        fileprivate var hitCount: Int = 0
        
        init() {
            var previousTime = mach_absolute_time()
            var startTime: UInt64 = 0
            let loopCount = UInt64(10)
            for _ in 0..<loopCount {
                let currentTime = mach_absolute_time()
                let delta = currentTime - previousTime
                startTime += delta
                previousTime = currentTime
            }
            startTime /= loopCount
            self.startTimeBase = startTime
            
            var info: mach_timebase_info = .init()
            if mach_timebase_info(&info) != KERN_SUCCESS {
                frequency = 0
                return
            }
            
            frequency = Double(1.0e9) * (Double(info.denom) / Double(info.numer))
        }
        
        
        fileprivate mutating func measure<R>(context: NSAttributedString.MetricsCache,
                                             _ body: () -> R) -> R {
            return body()
        }
        
        var description: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            
            let total = missCount + hitCount
            let missRate = Double(missCount) / Double(total)
            let hitRate = Double(hitCount) / Double(total)
            var result = "[\(Self.self)] total = \(total)\n"
            result += "[\(Self.self)] miss-count = \(missCount); miss-rate = \(formatter.string(from: missRate as NSNumber)!)\n"
            
            result += "[\(Self.self)] hit-count = \(hitCount); hit-rate = \(formatter.string(from: hitRate as NSNumber)!)\n"
            
            
            return result
        }
    }
    
    fileprivate var profileData: ProfileData = .init()
    
    fileprivate func printStatistics() {
        guard EnvValue.isTextCacheStatisticsEnabled else {
            return
        }
        logger.debug(.init(stringLiteral: profileData.description))
    }
    
    @inline(__always)
    internal static func withCache<R>(_ body: (ResovledStyledTextCache) -> R) -> R {
        guard DanceUIFeature.hostingConfigurationReaderAsyncComputerSize.isEnable else {
            return body(ResovledStyledTextCache.shared)
        }
        if Thread.isMainThread {
            return body(ResovledStyledTextCache.shared)
        } else {
            return ResovledStyledTextCache.async.withContent { cache in
                body(cache)
            }
        }
    }
}

#if DANCE_UI_INHOUSE || DEBUG
@_silgen_name("_MyPrintTextCacheStatistics")
@available(iOS 13.0, *)
public func _MyPrintTextCacheStatistics() {
    ResovledStyledTextCache.shared.printStatistics()
}
#endif

@available(iOS 13.0, *)
extension EnvValue where K == Key {
    
    private static let textCacheStatisticsEnabledValue: Self = .init()
    
    fileprivate static var isTextCacheStatisticsEnabled: Bool {
        textCacheStatisticsEnabledValue.value
    }
}

@available(iOS 13.0, *)
private struct Key: DefaultFalseBoolEnvKey {
    
    fileprivate static var raw: String {
        "DANCEUI_TEXT_CACHE_STATISTICS"
    }
    
}



// MARK: - iOS 15.2 Types for Offset Calibration
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public struct TextLayoutProperties {
    
    internal var lineLimit: Int?
    
    internal var truncationMode: Text.TruncationMode
    
    internal var multilineTextAlignment: TextAlignment
    
    internal var layoutDirection: LayoutDirection
    
    internal var minScaleFactor: CGFloat
    
    internal var lineSpacing: CGFloat
    
    internal var lineHeightMultiple: CGFloat
    
    internal var maximumLineHeight: CGFloat
    
    internal var minimumLineHeight: CGFloat
    
    internal var hyphenationFactor: CGFloat
    
    @_spi(DanceUICompose)
    public let bodyHeadOutdent: CGFloat
    
    internal let pixelLength: CGFloat
    
}

@available(iOS 13.0, *)
extension Text {
    
    @_spi(DanceUICompose)
    public struct ResolvedProperties {
        
        @_spi(DanceUICompose)
        public struct Features: OptionSet {
            
            @_spi(DanceUICompose)
            public let rawValue: UInt8
            
            @_spi(DanceUICompose)
            public init(rawValue: UInt8) {
                self.rawValue = rawValue
            }
            
            internal static let empty: Features = .init()
            
            internal static let styledText: Features = .init(rawValue: 0x1)
        }
        
        internal var insets: EdgeInsets
        
        internal var features: Features
        
    }
    
}

@available(iOS 13.0, *)
internal enum ResolvableAttributeConfiguration2 {
    
    case resolvable(updateDelay: Double?)
    
    case none
    
}

@available(iOS 13.0, *)
extension NSAttributedString {
    
    internal struct MetricsCache2 {
        
        internal var kitCache: AnyObject?
        
        internal let string: NSAttributedString
        
        internal let lineLimit: Int?
        
        internal let minScaleFactor: CGFloat
        
        internal let bodyHeadOutdent: CGFloat
        
        internal let pixelLength: CGFloat
        
        internal let widthIsFlexible: Bool
        
        internal let drawWithRequestedWidth: Bool
        
        internal let isCollapsible: Bool
        
        internal let layoutMargins: EdgeInsets
        
        internal var entries: ArrayWith3Inline<(CGSize, Metrics2)>
        
    }
    
    internal struct Metrics2 {
        
        internal var size: CGSize
        
        internal let scale: CGFloat
        
        internal var firstBaseline: CGFloat
        
        internal var lastBaseline: CGFloat
        
        internal var baselineAdjustment: CGFloat
        
        internal var requestedWidth: CGFloat
        
    }
    
    internal func format() -> NSAttributedString {
        if #available(iOS 15.0, *) {
            return self
        } else {
            var keysToRemove: Set<NSAttributedString.Key> = Set([.danceUI.textOnTapAction, .languageIdentifierForDanceUI])
            var mutableScaledString: NSMutableAttributedString = .init(attributedString: self)
            mutableScaledString.enumerateAttributes(in: NSRange(location: 0, length: mutableScaledString.length)) { attributes, _, _ in
                attributes.keys.forEach { key in
                    if !(key.rawValue.starts(with: "CT") || key.rawValue.starts(with: "NS")) {
                        keysToRemove.insert(key)
                    }
                }
            }
            for key in keysToRemove {
                mutableScaledString.removeAttribute(key, range: NSRange(location: 0, length: mutableScaledString.length))
            }
            return NSAttributedString(attributedString: mutableScaledString)
        }
    }
    
}

@available(iOS 13.0, *)
private func hitPoints(_ point: CGPoint, hitTestInsets: EdgeInsets) -> ([CGPoint], [Double], [Bool]) {
    var points = [CGPoint]()
    points.append(point)
    var weights = [Double]()
    weights.append(1.0)
    var isDerived = [Bool]()
    isDerived.append(false)
    
    var needsTopLeading = 0
    var needsTopTrailing = 0
    var needsBottomLeading = 0
    var needsBottomTrailing = 0
    
    let maxTotalPoints = 8.0
    let derivedPointWeight = 1 / maxTotalPoints
    
    if hitTestInsets.top != 0 {
        points.append(point + CGPoint(x: 0, y: -hitTestInsets.top))
        weights.append(derivedPointWeight)
        isDerived.append(true)
        needsTopLeading += 1
        needsTopTrailing += 1
    }
    
    if hitTestInsets.leading != 0 {
        points.append(point + CGPoint(x: -hitTestInsets.leading, y: 0))
        weights.append(derivedPointWeight)
        isDerived.append(true)
        needsTopLeading += 1
        needsBottomLeading += 1
    }
    
    if hitTestInsets.bottom != 0 {
        points.append(point + CGPoint(x: 0, y: hitTestInsets.bottom))
        weights.append(derivedPointWeight)
        isDerived.append(true)
        needsBottomLeading += 1
        needsBottomTrailing += 1
    }
    
    if hitTestInsets.trailing != 0 {
        points.append(point + CGPoint(x: hitTestInsets.trailing, y: 0))
        weights.append(derivedPointWeight)
        isDerived.append(true)
        needsBottomTrailing += 1
        needsTopTrailing += 1
    }
    
    if needsTopLeading == 2 {
        points.append(point + CGPoint(x: -hitTestInsets.leading, y: -hitTestInsets.top))
        weights.append(derivedPointWeight)
        isDerived.append(true)
    }
    
    if needsTopTrailing == 2 {
        points.append(point + CGPoint(x: hitTestInsets.trailing, y: -hitTestInsets.top))
        weights.append(derivedPointWeight)
        isDerived.append(true)
    }
    
    if needsBottomLeading == 2 {
        points.append(point + CGPoint(x: -hitTestInsets.leading, y: hitTestInsets.bottom))
        weights.append(derivedPointWeight)
        isDerived.append(true)
    }
    
    if needsBottomTrailing == 2 {
        points.append(point + CGPoint(x: hitTestInsets.trailing, y: hitTestInsets.bottom))
        weights.append(derivedPointWeight)
        isDerived.append(true)
    }
    
    return (points, weights, isDerived)
}
