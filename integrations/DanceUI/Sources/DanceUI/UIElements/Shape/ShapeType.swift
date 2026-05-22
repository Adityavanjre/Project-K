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

@usableFromInline
@available(iOS 13.0, *)
internal enum ShapeType {
    
    case rect(_ rect: CGRect, radius: CGFloat, style: RoundedCornerStyle)
    case rectBorder(_ rect: CGRect, radius: CGFloat, style: RoundedCornerStyle, lineWidth: CGFloat)
    case strokedPath(_ path: Path, start: CGFloat, end: CGFloat, style: StrokeStyle)
    case empty
    case other
    
    @usableFromInline
    internal init(_ path: Path) {
        switch path.storage {
        case .rect(let rect):
            self = .rect(rect, radius: 0, style: .circular)
        case .ellipse(let rect):
            if rect.size.width != rect.size.height {
                self = .empty
            } else {
                self = .rect(rect, radius: rect.size.width * 0.5, style: .circular)
            }
        case .roundedRect(let fixedRoundedRect):
            if fixedRoundedRect.cornerSize.width != fixedRoundedRect.cornerSize.height {
                self = .empty
            } else {
                var radius: CGFloat = .minimum(fixedRoundedRect.rect.size.width, fixedRoundedRect.rect.size.height)
                radius *= 0.5
                radius = .minimum(radius, fixedRoundedRect.cornerSize.width)
                self = .rect(fixedRoundedRect.rect, radius: radius, style: fixedRoundedRect.style)
            }
        case .stroked(let strokePath):
            guard strokePath.style.dash.isEmpty else {
                self = .empty
                return
            }
            let style = strokePath.style
            switch strokePath.path.storage {
            case .rect(let rect):
                if style.lineJoin != .miter || style.miterLimit <= CGFloat(2).squareRoot() {
                    self = .strokedPath(strokePath.path, start: 0, end: 1, style: strokePath.style)
                } else {
                    let radius = style.lineWidth * -0.5
                    let insetedRect = rect.insetBy(dx: radius, dy: radius)
                    self = .rectBorder(insetedRect, radius: 0, style: .circular, lineWidth: style.lineWidth)
                }
            case .ellipse(let rect):
                if rect.size.width != rect.size.height {
                    self = .strokedPath(strokePath.path, start: 0, end: 1, style: strokePath.style)
                } else {
                    let insetValue = style.lineWidth * -0.5
                    let insetedRect = rect.insetBy(dx: insetValue, dy: insetValue)
                    let radiusValue = rect.size.width * 0.5 + style.lineWidth * 0.5
                    let radius = max(0, radiusValue)
                    self = .rectBorder(insetedRect, radius: radius, style: .circular, lineWidth: style.lineWidth)
                }
            case .roundedRect(let fixedRounedRect):
                if fixedRounedRect.cornerSize.width != fixedRounedRect.cornerSize.height {
                    self = .strokedPath(strokePath.path, start: 0, end: 1, style: strokePath.style)
                } else {
                    let cornerRadius = fixedRounedRect.cornerSize.width
                    let minValue = min(fixedRounedRect.rect.size.width, fixedRounedRect.rect.size.height) * 0.5
                    let minRadius = min(cornerRadius, minValue)
                    let radius = max(0, style.lineWidth * 0.5 + minRadius)
                    let insetValue = style.lineWidth * -0.5
                    let insetedRect = fixedRounedRect.rect.insetBy(dx: insetValue, dy: insetValue)
                    self = .rectBorder(insetedRect, radius: radius, style: fixedRounedRect.style, lineWidth: style.lineWidth)
                }
            case .stroked:
                self = .strokedPath(strokePath.path, start: 0, end: 1, style: strokePath.style)
            case .trimmed(let trimmedPath):
                self = .strokedPath(trimmedPath.path, start: trimmedPath.start, end: trimmedPath.end, style: strokePath.style)
            case .path:
                self = .strokedPath(strokePath.path, start: 0, end: 1, style: strokePath.style)
            case .empty:
                self = .empty
            }
        default:
            self = .empty
        }
    }
}
