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
internal final class UnderlineTextModifier: AnyTextModifier {
    
    internal let lineStyle: Text.LineStyle?
    
    @inline(__always)
    internal override init() {
        self.lineStyle = nil
        super.init()
    }
    
    @inline(__always)
    internal init(_ isActive: Bool = true, _ nsUnderlineStyle: NSUnderlineStyle = .single, color: Color? = nil) {
        self.lineStyle = isActive ? Text.LineStyle(nsUnderlineStyle: nsUnderlineStyle, color: color) : nil
        super.init()
    }
    
    internal override func modify(style: inout Text.Style) {
        guard let lineStyle = lineStyle else {
            style.underline = .implicit
            return
        }
        style.underline = .explicit(lineStyle)
    }
    
    internal override func isEqual(to: AnyTextModifier) -> Bool {
        guard let value = to as? UnderlineTextModifier else {
            return false
        }
        return value.lineStyle == lineStyle
    }
}
