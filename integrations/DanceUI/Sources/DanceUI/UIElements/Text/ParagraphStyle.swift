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

@available(iOS 13.0, *)
extension NSTextAlignment {
    @_transparent
    internal init(_ textAlignment: TextAlignment) {
        switch textAlignment {
        case .center:
            self = .center
        case .leading:
            self = .left
        case .trailing:
            self = .right
        case .justified:
            self = .justified
        }
    }
}

@available(iOS 13.0, *)
extension NSLineBreakMode {
    
    @_transparent
    internal init(_ truncationMode: Text.TruncationMode) {
        switch truncationMode {
        case .head:
            self = .byTruncatingHead
        case .middle:
            self = .byTruncatingMiddle
        case .tail:
            self = .byTruncatingTail
        case .clipping:
            self = .byClipping
        case .charWrapping:
            self = .byCharWrapping
        case .wordWrapping:
            self = .byWordWrapping
        }
    }
}

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func makeParagraphStyle(environment: EnvironmentValues) -> NSMutableParagraphStyle {
    let paragraphStyle = NSMutableParagraphStyle()
    let layoutDirection = environment.layoutDirection
    let multilineTextAlignment = environment.multilineTextAlignment
    
    let textAlignment: NSTextAlignment = .init(textAlignment: multilineTextAlignment, layoutDirection: layoutDirection)
    paragraphStyle.alignment = textAlignment
    paragraphStyle.lineBreakMode = .init(environment.truncationMode)
    paragraphStyle.lineSpacing = environment.lineSpacing
    if #available(iOS 14.0, *) {
        paragraphStyle.lineBreakStrategy = .standard
    }
    paragraphStyle.lineHeightMultiple = environment.lineHeightMultiple
    paragraphStyle.maximumLineHeight = environment.maximumLineHeight
    paragraphStyle.minimumLineHeight = environment.minimumLineHeight
    paragraphStyle.hyphenationFactor = environment.hyphenationFactor
    paragraphStyle.firstLineHeadIndent = environment.bodyHeadOutdent
    paragraphStyle.headIndent = environment.restBodyHeadOutdent
    paragraphStyle.allowsDefaultTighteningForTruncation = environment.allowsTightening
    
    return paragraphStyle
}
