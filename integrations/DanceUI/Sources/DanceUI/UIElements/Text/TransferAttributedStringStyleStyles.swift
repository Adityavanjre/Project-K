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
extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    
    internal mutating func transferAttributedStringStyles(to style: inout Text.Style) {

        translateToDanceUIAttributes()
        
        if let inlinePresentationIntentType = self[.inlinePresentationIntent] as? InlinePresentationIntent {
            if inlinePresentationIntentType.hasType(.emphasized) {
                style.addFontModifier(type: Font.ItalicModifier.self)
            }
            if inlinePresentationIntentType.hasType(.stronglyEmphasized) {
                style.addFontModifier(type: Font.BoldModifier.self)
            }
            if inlinePresentationIntentType.hasType(.code) {
                if #available(iOS 13.0, *) {
                    style.addFontModifier(type: Font.MonospacedModifier.self)
                }
            }
            if inlinePresentationIntentType.hasType(.strikethrough) {
                StrikethroughTextModifier().modify(style: &style)
            }
        }
        
    }
    
    internal mutating func translateToDanceUIAttributes() {
        let inlinePresentationIntentKey = NSAttributedString.Key(rawValue: "NSInlinePresentationIntent")

        if let nsInlinePresentationIntentFromNSPresentationIndent = self[inlinePresentationIntentKey] as? Int {
            self[.inlinePresentationIntent] = InlinePresentationIntent(rawValue: nsInlinePresentationIntentFromNSPresentationIndent)
            self[inlinePresentationIntentKey] = nil
        }
    }
}
