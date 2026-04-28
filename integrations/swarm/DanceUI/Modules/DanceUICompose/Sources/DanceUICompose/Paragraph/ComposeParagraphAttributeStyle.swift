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

@available(iOS 13.0, *)
internal final class ComposeParagraphAttributeStyle {
    internal init(
        spanStyleRanges: [any ComposeAnnotatedStringRangeWithSpanStyle] = [],
        textStyle: ComposeTextStyleImpl = .init(),
        attributes: [NSAttributedString.Key: Any] = [:]
    ) {
        self.spanStyleRanges = spanStyleRanges
        self.textStyle = textStyle
        self.attributes = attributes
        updateAttributes()
    }

    internal var spanStyleRanges: [any ComposeAnnotatedStringRangeWithSpanStyle]
    
    internal var textStyle: ComposeTextStyleImpl {
        didSet {
            updateAttributes()
        }
    }

    internal private(set) var attributes: [NSAttributedString.Key: Any] = [:]

    internal private(set) var environment = EnvironmentValues()

    private func updateAttributes() {
        Signpost.compose.tracePoi("ParagraphAttributeStyle:updateAttributes", []) {
            updateAttributes(spanStyle: textStyle.spanStyle)
            updateAttributes(paragraphStyle: textStyle.paragraphStyle)
            attributes[.paragraphStyle] = makeParagraphStyle(environment: environment)
        }
    }
    
    private func updateAttributes(spanStyle: some ComposeSpanStyle) {
        attributes.merge(spanStyle.attributes) { _, second in second }
    }
    
    private func updateAttributes(paragraphStyle: some ComposeParagraphStyle) {
        Signpost.compose.tracePoi("ParagraphAttributeStyle:updateAttributesWithStyle", []) {
            if let multilineTextAlignment = textStyle.paragraphStyle.textAlign.multilineTextAlignment(environment) {
                environment.multilineTextAlignment = multilineTextAlignment
            }
            if let layoutDirection = textStyle.paragraphStyle.textDirection.layoutDirection {
                environment.layoutDirection = layoutDirection
            }
            let indent = textStyle.paragraphStyle.textIndent
            environment.bodyHeadOutdent = indent.firstLine
            environment.restBodyHeadOutdent = indent.restLine
        }
    }
    
    func update(maxLines: Int, ellipsis: Bool) {
        environment.lineLimit = maxLines == 0 ? nil : maxLines
        // [Paragraph] Compose default behavior should be clipping
        environment.truncationMode = ellipsis ? .tail : .clipping
    }
}
