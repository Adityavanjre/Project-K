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
internal import Resolver
@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
public final class ComposeResourceFactoryImpl: NSObject, ComposeResourceFactory {
    
    @objc
    public static let sharedInstance = ComposeResourceFactoryImpl()
    
    private lazy var decoder = Resolver.services.optional(ImageDecoder.self)
    
    public func makeImageBitmap(with data: Data) -> any ComposeImageBitmap {
        Signpost.compose.tracePoi("ComposeResourceFactory:makeImageBitmapWithData", []) {
            let uiImage = if let decoder {
                decoder.decodedImage(with: data)
            } else {
                UIImage(data: data)
            }
            
            guard let sourceImage = uiImage else {
                _danceuiRuntimeIssue(type: .warning, "ComposeImageBitmap decode from data error")
                return ComposeImage(UIImage())
            }
            return ComposeImage(sourceImage)
        }
    }
    
    public func makeImageBitmap(withFilePath path: String) -> ComposeImageBitmap {
        Signpost.compose.tracePoi("ComposeResourceFactory:makeImageBitmapWithFilePath", []) {
            let uiImage = if let decoder {
                decoder.decodedImage(with: path)
            } else {
                UIImage(contentsOfFile: path)
            }
            guard let sourceImage = uiImage else {
                _danceuiRuntimeIssue(type: .warning, "ComposeImageBitmap decode from path error")
                return ComposeImage(UIImage())
            }
            return ComposeImage(sourceImage)
        }
    }
    
    public func makeVectorImageBitmap(withWidth width: Int, height: Int, config: ComposeImageBitmapConfig, hasAlpha: Bool, colorSpace: CGColorSpace) -> any ComposeImageBitmap {
        return ComposeVectorImage(width: width, height: height, colorSpace: colorSpace, hasAlpha: hasAlpha, config: config)
    }
    
    public func makeImageLoadConfig() -> any ComposeImageLoadConfig {
        return ComposeAsyncImageLoadConfig()
    }
    
    public func makeAnimatedImageConfig() -> any ComposeAnimatedImageConfig {
        return ComposeAnimatedImageConfiguration()
    }
    
    public func makeDisplayListIdentity() -> UInt {
        UInt(DisplayList.Identity.make().value)
    }
    
    public func makeLinearGradient(from: CGPoint, to: CGPoint, colors: [UIColor], colorStops: [NSNumber]?, tileMode: ComposeTileMode) -> any ComposeShader {
        ComposeLinearGradient(from: from.px2pt, to: to.px2pt, colors: colors, stops: colorStops?.map(\.doubleValue.px2pt), tileMode: tileMode)
    }
    
    public func makeRadialGradient(withCenter center: CGPoint, radius: CGFloat, colors: [UIColor], colorStops: [NSNumber]?, tileMode: ComposeTileMode) -> any ComposeShader {
        ComposeRadialGradient(center: center.px2pt, radius: radius.px2pt, colors: colors, stops: colorStops?.map(\.doubleValue.px2pt), tileMode: tileMode)
    }
    
    public func makeSweepGradient(withCenter center: CGPoint, colors: [UIColor], colorStops: [NSNumber]?) -> any ComposeShader {
        ComposeSweepGradient(center: center.px2pt, colors: colors, stops: colorStops?.map(\.doubleValue.px2pt))
    }
    
    public func makeTint(with color: UIColor, blendMode: CGBlendMode) -> any ComposeColorFilter {
        ComposeBlendModeColorFilter(color: color, blendMode: blendMode)
    }
    
    public func makeColorMatrix(with colorMatrix: ComposeColorMatrix) -> any ComposeColorFilter {
        ComposeColorMatrixColorFilter(colorMatrix: _ColorMatrix(colorMatrix: colorMatrix))
    }
    
    public func makeLighting(withMultiply multiply: UIColor, add: UIColor) -> any ComposeColorFilter {
        ComposeLightingColorFilter(multiply: multiply, add: add)
    }
    
    public func makeDashPathEffect(withIntervals intervals: [NSNumber], phase: CGFloat) -> any ComposePathEffect {
        DashPathEffect(intervals: intervals.map({ CGFloat($0.doubleValue.px2pt) }), phase: phase.px2pt)
    }
    
    public func makeComposeGraphicsLayerScope() -> any ComposeGraphicsLayerScope {
        ComposeGraphicsLayerScopeImpl()
    }
    
    public func makeTextStyle(with spanStyle: any ComposeSpanStyle, paragraphStyle: any ComposeParagraphStyle) -> any ComposeTextStyle {
        ComposeTextStyleImpl(spanStyle: spanStyle, paragraphStyle: paragraphStyle)
    }
    
    public func makeSpanStyle(
        withTextForegroundColor textForegroundColor: UIColor?,
        textFont: UIFont?,
        letterSpacing: CGFloat,
        baselineShift: CGFloat,
        localeList: [String]?,
        backgroundColor: UIColor?,
        textDecoration: ComposeTextDecoration,
        shadow: NSShadow?,
        drawStyle: (any ComposeDrawStyle)?
    ) -> any ComposeSpanStyle {
        ComposeSpanStyleImpl(
            textForegroundColor: textForegroundColor,
            textFont: textFont,
            letterSpacing: letterSpacing,
            baselineShift: baselineShift,
            localeList: localeList,
            backgroundColor: backgroundColor,
            textDecoration: textDecoration,
            shadow: shadow,
            drawStyle: drawStyle
        )
    }

    public func makeParagraphStyle(
        with textAlign: ComposeTextAlign,
        textDirection: ComposeTextDirection,
        textIndent: ComposeTextIndent
    ) -> any ComposeParagraphStyle {
        ComposeParagraphStyleImpl(
            textAlign: textAlign,
            textDirection: textDirection,
            textIndent: textIndent
        )
    }
    
    public func makeCATransform3D(with matrix: ComposeRenderNodeLayerMatrix) -> CATransform3D {
        matrix.transform
    }
    
    // MARK: - DrawStyle
    
    public func makeFillDrawStyle() -> any ComposeFill {
        ComposeFillImpl()
    }
    
    public func makeStrokeDrawStyle(withWidth width: CGFloat, miter: CGFloat, cap: ComposeStrokeCap, join: ComposeStrokeJoin, pathEffect: (any ComposePathEffect)?) -> any ComposeStroke {
        ComposeStrokeImpl(width: width, miter: miter, cap: cap, join: join, pathEffect: pathEffect)
    }
    
    // MARK: - AnnotatedString Range
    public func makeAnnotatedStringRangeWithSpanStyle(with range: NSRange, spanStyle: any ComposeSpanStyle) -> any ComposeAnnotatedStringRangeWithSpanStyle {
        ComposeAnnotatedStringRangeWithSpanStyleImpl(range: range, spanStyle: spanStyle)
    }
    
    public func makeBreakIteratorCharacterInstance() -> any ComposeBreakIterator {
        ComposeBreakIteratorImp.makeCharacterInstance(locale: nil)
    }
    
    public func makeParagraphPlaceholder(withWidth width: CGFloat, height: CGFloat, alignment: Int32) -> any ComposeParagraphPlaceholder {
        ComposeParagraphPlaceholderImpl(width: width, height: height, alignment: alignment)
    }
    
    public func makeAnnotatedStringRangeWithPlaceHolder(with range: NSRange, placeHolder: any ComposeParagraphPlaceholder) -> any ComposeAnnotatedStringRangeWithPlaceholder {
        ComposeAnnotatedStringRangeWithPlaceHolderImpl(range: range, placeholder: placeHolder)
    }
}

@available(iOS 13.0, *)
extension _ColorMatrix {
    internal init(colorMatrix: ComposeColorMatrix) {
        self.init(m11: colorMatrix.m11,
                  m12: colorMatrix.m12,
                  m13: colorMatrix.m13,
                  m14: colorMatrix.m14,
                  m15: colorMatrix.m15 / 255.0,
                  m21: colorMatrix.m21,
                  m22: colorMatrix.m22,
                  m23: colorMatrix.m23,
                  m24: colorMatrix.m24,
                  m25: colorMatrix.m25 / 255.0,
                  m31: colorMatrix.m31,
                  m32: colorMatrix.m32,
                  m33: colorMatrix.m33,
                  m34: colorMatrix.m34,
                  m35: colorMatrix.m35 / 255.0,
                  m41: colorMatrix.m41,
                  m42: colorMatrix.m42,
                  m43: colorMatrix.m43,
                  m44: colorMatrix.m44,
                  m45: colorMatrix.m45 / 255.0)
    }
}
