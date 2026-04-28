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
extension NSLayoutManager {
    
    internal static func with<Result>(
        _ string: NSAttributedString,
        drawingScale: CGFloat,
        size: CGSize,
        layoutProperties: TextLayoutProperties,
        _ body: (NSLayoutManager, NSTextContainer) -> Result
    ) -> Result {
        let string2 = (layoutProperties.lineLimit == 1) ? string : string.replacingLineBreakModes(.byWordWrapping)
        let string3 = string2.scaled(by: drawingScale)
        
        let textStorage: NSTextStorage = NSTextStorage()
        
        let layoutManager = NSLayoutManager()
        layoutManager.my_allowsOriginalFontMetricsOverride = true
        
        textStorage.addLayoutManager(layoutManager)
        
        if #available(iOS 15.0, *) {
            textStorage.my__setShouldSetOriginalFontAttribute(true)
        }
        textStorage.setAttributedString(string3)
        
        let safeSize = CGSize(width: max(size.width, 0), height: max(size.height + 2, 0))
        
        let textContainer = NSTextContainer(size: safeSize)
        
        textContainer.lineFragmentPadding = 0
        
        textContainer.maximumNumberOfLines = layoutProperties.safeLineLimit
        
        textContainer.lineBreakMode = NSLineBreakMode(layoutProperties.truncationMode)
        
        layoutManager.addTextContainer(textContainer)
        
        return body(layoutManager, textContainer)
    }
    
}

@available(iOS 13.0, *)
extension TextLayoutProperties {
    
    @inline(__always)
    fileprivate var safeLineLimit: Int {
        guard let lineLimit = self.lineLimit else {
            return 0
        }
        return max(lineLimit, 1)
    }
    
}
