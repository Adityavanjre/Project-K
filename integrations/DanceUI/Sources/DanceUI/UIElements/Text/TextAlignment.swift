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

/// Aligns the child view within its bounds given anchor types
///
/// Child sizing: Respects the child's preferred size on the aligned axes. The child fills the context bounds on unaligned axes.
///
/// Preferred size: Child's preferred size
/// An alignment in the horizontal axis.
@frozen
@available(iOS 13.0, *)
public enum TextAlignment : Hashable, CaseIterable, Encodable {

    case leading

    case center

    case trailing

    case justified
}

@available(iOS 13.0, *)
extension NSTextAlignment {
    
    internal init(textAlignment: TextAlignment, layoutDirection: LayoutDirection) {
        switch (textAlignment, layoutDirection) {
        case (.center, _):
            self = .center
        case (.leading, .leftToRight):
            self = .left
        case (.trailing, .leftToRight):
            self = .right
        case (.leading, .rightToLeft):
            self = .right
        case (.trailing, .rightToLeft):
            self = .left
        case (.justified, _):
            self = .justified
        }
    }
    
    internal init(in environment: EnvironmentValues) {
        self.init(textAlignment: environment.multilineTextAlignment,
             layoutDirection: environment.layoutDirection)
    }
    
}

@available(iOS 13.0, *)
extension CTTextAlignment {
    
    @inline(__always)
    internal init(textAlignment: TextAlignment, layoutDirection: LayoutDirection) {
        switch (layoutDirection, textAlignment) {
        case (LayoutDirection.leftToRight, .leading):
            self = .left
        case (LayoutDirection.leftToRight, .center):
            self = .center
        case (LayoutDirection.leftToRight, .trailing):
            self = .right
        case (LayoutDirection.rightToLeft, .leading):
            self = .right
        case (LayoutDirection.rightToLeft, .center):
            self = .center
        case (LayoutDirection.rightToLeft, .trailing):
            self = .left
        case (_, .justified):
            self = .justified
        }
    }
}
