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

#if DEBUG
@available(iOS 13.0, *)
internal var StyledTextLayoutDelegate_sizeThatFitsCounter = 0
#endif
@available(iOS 13.0, *)
internal struct StyledTextLayoutEngine: LayoutEngine, CustomDebugStringConvertible {
    
    internal var text: ResolvedStyledText
    
    var debugDescription: String {
        "\(Self.self)<text: \(text.string?.string ?? "")>"
    }
    
    internal init(text: ResolvedStyledText) {
        self.text = text
    }
    
    internal func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        let requestedSize = CGSize(width: size.width ?? .infinity, height: size.height ?? .infinity)
        let metrics = text.metrics(requestedSize: requestedSize)
        return metrics.size
    }
    
    internal func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        let size = size.value
        if key == VerticalAlignment.lastTextBaseline.key {
            let metrics = text.metrics(requestedSize: size)
            return metrics.lastBaseline
        } else if key == VerticalAlignment.firstTextBaseline.key {
            let metrics = text.metrics(requestedSize: size)
            return metrics.firstBaseline
        } else if key == VerticalAlignment.firstTextLineCenter.key {
            let metrics = text.metrics(requestedSize: size)
            let value = text.string?.maxFontMetrics()
            var height: CGFloat = value?.capHeight ?? 0
            height *= 0.5
            height += metrics.firstBaseline
            return height
        }
        return nil
    }
    
    
    internal func spacing() -> Spacing {
        text.spacing()
    }
    
    internal func lengthThatFits(_ proposedSize: _ProposedSize,
                                          in axis: Axis) -> CGFloat {
        switch axis {
        case .horizontal:
            if proposedSize.value(for: axis) == 0 {
                return 0
            }
            fallthrough
        case .vertical:
            return sizeThatFits(proposedSize).value(for: axis)
        }
    }
    
}
