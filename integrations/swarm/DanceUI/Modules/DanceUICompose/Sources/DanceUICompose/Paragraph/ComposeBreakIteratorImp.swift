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

final class ComposeBreakIteratorImp: NSObject, ComposeBreakIterator {
    enum Style {
        case char
    }
    
    private var locale: String?
    
    private var style: Style = .char
    
    private var text: NSString?
    
    private var currentPosition: Int32 = 0
    
    static func makeCharacterInstance(locale: String?) -> Self {
        let iterator = Self()
        iterator.locale = locale
        iterator.style = .char
        return iterator
    }

    func setText(_ string: String) {
        text = string as NSString
        currentPosition = 0 
    }

    func isBoundary(offset: Int32) -> Bool {
        guard let text else { return false }
        
        let offset = Int(offset)
        
        if offset == 0 { return true }
        
        if offset > text.length { return false }
        if offset == text.length { return true }
        
        let range = text.rangeOfComposedCharacterSequence(at: offset)
        return range.location == offset
    }
    
    func preceding(offset: Int32) -> Int32 {
        guard let text else { return -1 }

        let offset = Int(offset)

        if offset <= 0 { return -1 }

        if offset > text.length { return Int32(text.length) }
        
        var scalarBoundary = offset
        if offset < text.length {
            let codeUnit = text.character(at: offset)
            if 0xDC00 <= codeUnit && codeUnit <= 0xDFFF {
                scalarBoundary = offset - 1
            }
        }

        if scalarBoundary <= 0 { return -1 }

        let precedingRange = text.rangeOfComposedCharacterSequence(at: scalarBoundary - 1)
        return Int32(precedingRange.location)
    }
    
    func following(offset: Int32) -> Int32 {
        guard let text else { return -1 }
        
        let offset = Int(offset)
        
        if offset >= text.length { return -1 }
        
        let currentRange = text.rangeOfComposedCharacterSequence(at: offset)
        
        let nextBoundary = currentRange.location + currentRange.length
        
        if nextBoundary >= text.length {
            return Int32(text.length)
        }
        
        return Int32(nextBoundary)
    }
    
    func current() -> Int32 {
        return currentPosition
    }
    
    func next() -> Int32 {
        guard let text else { return -1 }
        
        let nextBoundary = following(offset: currentPosition)
        
        if nextBoundary != -1 {
            currentPosition = nextBoundary
        } else {
            currentPosition = Int32(text.length)
        }
        
        return currentPosition
    }
    
    func next(index: Int32) -> Int32 {
        guard let text else { return -1 }
        
        if index == 0 {
            return currentPosition
        }
        
        if index > 0 {
            for _ in 0..<index {
                let nextBoundary = following(offset: currentPosition)
                if nextBoundary == -1 {
                    currentPosition = Int32(text.length)
                    break
                }
                currentPosition = nextBoundary
            }
        } else {
            let steps = abs(index)
            for _ in 0..<steps {
                let prevBoundary = preceding(offset: currentPosition)
                if prevBoundary == -1 {
                    currentPosition = 0
                    break
                }
                currentPosition = prevBoundary
            }
        }
        
        return currentPosition
    }
}
