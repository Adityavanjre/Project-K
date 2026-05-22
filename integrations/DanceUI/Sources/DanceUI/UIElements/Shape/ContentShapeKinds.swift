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

/// A kind for the content shape of a view.
///
/// The kind is used by the system to influence various effects, hit-testing,
/// and more.
@available(iOS 13.0, *)
public struct ContentShapeKinds: OptionSet {
    
    public typealias ArrayLiteralElement = ContentShapeKinds
    
    public typealias Element = ContentShapeKinds
    
    public typealias RawValue = Int
    
    /// The corresponding value of the raw type.
    public var rawValue: Int
    
    /// Creates a content shape kind.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// The kind for hit-testing and accessibility.
    ///
    /// Setting a content shape with this kind causes the view to hit-test
    /// using the specified shape.
    public static let interaction: ContentShapeKinds = ContentShapeKinds(rawValue: 0x1)
    
    /// The kind for drag and drop previews.
    ///
    /// When using this kind, only the preview shape is affected. To control the
    /// shape used to hit-test and start the drag preview, use the `interaction`
    /// kind.
    public static let dragPreview: ContentShapeKinds = ContentShapeKinds(rawValue: 0x2)
    
    /// The kind for context menu previews.
    ///
    /// When using this kind, only the preview shape will be affected. To
    /// control the shape used to hit-test and start the context menu
    /// presentation, use the `.interaction` kind.
    public static let contextMenuPreview: ContentShapeKinds = ContentShapeKinds(rawValue: 0x4)
     
    /// The kind for hover effects.
    ///
    /// When using this kind, only the preview shape is affected. To control
    /// the shape used to hit-test and start the effect, use the `interaction`
    /// kind.
    ///
    /// This kind does not affect the `onHover` modifier.

    public static let hoverEffect: ContentShapeKinds = ContentShapeKinds(rawValue: 0x8)
    
    public static let focusEffect: ContentShapeKinds = ContentShapeKinds(rawValue: 0x10)
}
