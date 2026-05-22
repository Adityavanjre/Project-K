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
internal final class BoldTextModifier: AnyTextModifier {
    
    internal let isActive : Bool
    
    internal init(isActive: Bool) {
        self.isActive = isActive
    }
    
    internal override func modify(style: inout Text.Style) {
        if isActive {
            style.addFontModifier(type: Font.BoldModifier.self)
        } else {
            style.removeFontModifier(type: Font.BoldModifier.self)
        }
    }
    
    internal override func isEqual(to: AnyTextModifier) -> Bool {
        guard let value = to as? BoldTextModifier else {
            return false
        }
        return value.isActive == isActive
    }
    
}

@available(iOS 13.0, *)
internal final class ItalicTextModifier: AnyTextModifier {
    
    internal let isActive : Bool
    
    internal init(isActive: Bool) {
        self.isActive = isActive
    }
    
    internal override func modify(style: inout Text.Style) {
        if isActive {
            style.addFontModifier(type: Font.ItalicModifier.self)
        } else {
            style.removeFontModifier(type: Font.ItalicModifier.self)
        }
    }
    
    internal override func isEqual(to: AnyTextModifier) -> Bool {
        guard let value = to as? ItalicTextModifier else {
            return false
        }
        return value.isActive == isActive
    }
    
}
