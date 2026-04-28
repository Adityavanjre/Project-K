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

@frozen
@available(iOS 13.0, *)
public struct TextOnTapAction {
    
    public typealias Callback = (_ string: NSAttributedString, _ subrange: NSRange, _ bounds: CGRect, _ info: Any?) -> Void
    
    public let info: Any?
    
    public let action: Callback
    
    @inlinable
    public init(info: Any? = nil, action: @escaping Callback) {
        self.info = info
        self.action = action
    }
    
    @inlinable
    public func callAsFunction(_ string: NSAttributedString,
                               _ subrange: NSRange,
                               _ bounds: CGRect,
                               _ info: Any?) {
        action(string, subrange, bounds, info)
    }
    
}

@available(iOS 13.0, *)
extension ExtensionWrapper where Wrapped == NSAttributedString.Key {
    
    public static let textOnTapAction = NSAttributedString.Key("com.ByteDance.DanceUI.TextOnTapAction")
    
}

@available(iOS 13.0, *)
extension ExtensionWrapper where Wrapped: NSAttributedString {
    
    public func textOnTapAction(at location: Int) -> TextOnTapAction? {
        wrapped.attribute(.danceUI.textOnTapAction, at: location, effectiveRange: nil) as? TextOnTapAction
    }
    
}

@available(iOS 13.0, *)
extension ExtensionWrapper where Wrapped: NSMutableAttributedString {
    
    public func setTextOnTapAction(_ action: TextOnTapAction?, for subrange: NSRange) {
        if let action {
            wrapped.addAttribute(.danceUI.textOnTapAction, value: action, range: subrange)
        } else {
            wrapped.removeAttribute(.danceUI.textOnTapAction, range: subrange)
        }
    }

    public func setTextOnTapAction(_ action: TextOnTapAction?) {
        setTextOnTapAction(action, for: wrapped.range)
    }
    
}
