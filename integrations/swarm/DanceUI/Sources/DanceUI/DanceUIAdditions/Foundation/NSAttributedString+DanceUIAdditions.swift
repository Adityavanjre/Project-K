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
extension NSAttributedString {
    
    internal func replacingLineBreakModes(_ lineBreakMode: NSLineBreakMode) -> NSAttributedString {
        var result: NSMutableAttributedString?
        let closure = { (value: Any?, subrange: NSRange, shouldStop: UnsafeMutablePointer<ObjCBool>) in
            guard let paragraphStyle = value as? NSParagraphStyle else {
                return
            }
            if self.shouldReplaceLineBreakMode(paragraphStyle.lineBreakMode, with: lineBreakMode) {
                let mutableParagraphStyle = paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                mutableParagraphStyle.lineBreakMode = lineBreakMode
                let replacedString = result ?? self.mutableCopy() as! NSMutableAttributedString
                result = replacedString
                replacedString.addAttribute(.paragraphStyle,
                                            value: mutableParagraphStyle.copy(),
                                            range: subrange)
            }
        }
        withoutActuallyEscaping(closure) { escapingClosure in
            enumerateAttribute(.paragraphStyle, in: range, using: escapingClosure)
        }
        return (result?.copy() as? NSAttributedString) ?? self
    }
    
    private func shouldReplaceLineBreakMode(_ replacedLineBreakMode: NSLineBreakMode, with targetLineBreakMode: NSLineBreakMode) -> Bool {
        return replacedLineBreakMode.semantics != targetLineBreakMode.semantics
    }
    
}

extension NSLineBreakMode {
    
    fileprivate enum Semantics {
        case singleLine
        case multiLine
    }
    
    @inline(__always)
    fileprivate var semantics: Semantics? {
        switch self {
        case .byWordWrapping, .byCharWrapping, .byClipping:
            return .multiLine
        case .byTruncatingHead, .byTruncatingTail, .byTruncatingMiddle:
            return .singleLine
        @unknown default:
            return nil
        }
    }
    
}
