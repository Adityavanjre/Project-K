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

internal import DanceUIGraph
internal import DanceUIRuntime

/// A type-erased ShapeStyle value.
@frozen
@available(iOS 13.0, *)
public struct AnyShapeStyle: ShapeStyle {
    
    internal var storage: Storage
    
    @usableFromInline
    @frozen
    internal struct Storage: Equatable {
        
        internal var box: AnyShapeStyleBox
        
        @usableFromInline
        internal static func == (lhs: Storage, rhs: Storage) -> Bool{
            if lhs.box === rhs.box {
                return true
            } else {
                return lhs.box.isEqual(to: rhs.box)
            }
        }
    }
    
    /// Create an instance from `style`.
    public init<S>(_ style: S) where S :ShapeStyle {
        self.storage = .init(box: ShapeStyleBox(value: style))
    }
    
    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        type.result = .bool(true)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        self.storage.box.apply(to: &shape)
    }
}


@usableFromInline
@available(iOS 13.0, *)
internal class AnyShapeStyleBox {
    
    @objc
    @usableFromInline
    deinit {
        
    }
    
    internal func apply(to: inout _ShapeStyle_Shape) {
    }
    
    internal func isEqual(to: AnyShapeStyleBox) -> Bool {
        false
    }
}

@available(iOS 13.0, *)
private final class ShapeStyleBox<A: ShapeStyle>: AnyShapeStyleBox {
    
    fileprivate let base: A
    
    fileprivate init(value: A) {
        self.base = value
    }
    
    fileprivate override func apply(to: inout _ShapeStyle_Shape) {
        self.base._apply(to: &to)
    }
    
    fileprivate override func isEqual(to: AnyShapeStyleBox) -> Bool {
        guard let rhsBox = to as? ShapeStyleBox else {
            return false
        }
        
        let isEqual = DGCompareValues(lhs: base, rhs: rhsBox.base)
        return isEqual
    }
}
