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
import UIKit
@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
internal class ComposeSpanStyleImpl: NSObject, ComposeSpanStyle {

    internal var textForegroundColor: UIColor?
    
    internal var textFont: UIFont?
    
    internal var letterSpacing: CGFloat
    
    internal var baselineShift: CGFloat
    
    internal var localeList: [String]?
    
    internal var backgroundColor: UIColor?
    
    internal var textDecoration: ComposeTextDecoration
    
    internal var shadow: NSShadow?
    
    internal var drawStyle: (any ComposeDrawStyle)?
    
    internal init(
        textForegroundColor: UIColor? = nil,
        textFont: UIFont? = nil,
        letterSpacing: CGFloat = 0,
        baselineShift: CGFloat = 0,
        localeList: [String]? = nil,
        backgroundColor: UIColor? = nil,
        textDecoration: ComposeTextDecoration = [],
        shadow: NSShadow? = nil,
        drawStyle: (any ComposeDrawStyle)? = nil
    ) {
        self.textForegroundColor = textForegroundColor
        self.textFont = textFont
        self.letterSpacing = letterSpacing
        self.baselineShift = baselineShift
        self.localeList = localeList
        self.backgroundColor = backgroundColor
        self.textDecoration = textDecoration
        self.shadow = shadow
    }
}

extension ComposeTextDecoration {
    internal var attributes: [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        guard self != [] else {
            return attributes
        }
        if contains(.underline) {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if contains(.lineThrough) {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        return attributes
    }
}

@available(iOS 13, *)
extension ComposeSpanStyle {
    internal var attributes: [NSAttributedString.Key: Any] {
        Signpost.compose.traceInterval("SpanStyle:attributes", []) {
            guard let spanStyle = self as? ComposeSpanStyleImpl else {
                return [:]
            }
            var attributes: [NSAttributedString.Key: Any] = [:]
            if let color = spanStyle.textForegroundColor {
                attributes[.foregroundColor] = color
            }
            if let font = spanStyle.textFont {
                attributes[.font] = font
            }
            if spanStyle.letterSpacing != 0 {
                attributes[.kern] = spanStyle.letterSpacing.px2pt
            }
            if spanStyle.baselineShift != 0 {
                attributes[.baselineOffset] = spanStyle.baselineShift.px2pt
            }
            if let locale = spanStyle.localeList?.first {
                attributes[.languageIdentifierForDanceUI] = locale
            }
            if let backgroundColor = spanStyle.backgroundColor {
                attributes[.backgroundColor] = backgroundColor
            }
            let decorationAttributes = spanStyle.textDecoration.attributes
            attributes.merge(decorationAttributes) { _, second in second }
            if let shadow = spanStyle.shadow {
                // TODO: Consider using DanceUI.ShadowEffect for better shadow effect support
                attributes[.shadow] = shadow
            }
            if let drawStyle = spanStyle.drawStyle {
                if let _ = drawStyle as? ComposeFill {
                } else if let strokeStyle = drawStyle as? ComposeStroke {
                    attributes[.strokeWidth] = strokeStyle.width.px2pt
                    attributes[.strokeColor] = attributes[.foregroundColor]
                    // FIXME: cap, join, pathEffect is not implemented yet
                }
            }
            return attributes
        }
    }
}
