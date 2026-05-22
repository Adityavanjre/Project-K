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

/// An opaque value derived from an anchor source and a particular view.
///
/// You can convert the anchor to a `Value` in the coordinate space of a target
/// view by using a ``GeometryProxy`` to specify the target view.
@frozen
@available(iOS 13.0, *)
public struct Anchor<Value> {
    
    /// A type-erased geometry value that produces an anchored value of a given type.
    @frozen
    public struct Source {
        
        private var box: AnchorBoxBase<Value>
        
        internal init(box: AnchorBoxBase<Value>) {
            self.box = box
        }
        
        internal func prepare(size: CGSize, transform: ViewTransform) -> Anchor<Value> {
            .init(box: self.box, size: size, transform: transform)
        }
    }
    
    internal let box: AnchorValueBoxBase<Value>
    
    internal var defaultValue: Value {
        box.defaultValue
    }
    
    internal init(box: AnchorBoxBase<Value>, size: CGSize, transform: ViewTransform) {
        self.box = box.prepare(size: size, transform: transform)
    }
    
    internal func `in`(context: _PositionAwarePlacementContext) -> Value {
        return self.box.convert(to: context.transform)
    }
}

@available(iOS 13.0, *)
extension Anchor: Equatable where Value: Equatable {
    
    public static func == (lhs: Anchor<Value>, rhs: Anchor<Value>) -> Bool {
        lhs.box.isEqual(to: rhs.box)
    }
}

@available(iOS 13.0, *)
extension Anchor : Hashable where Value : Hashable {

    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// Implement this method to conform to the `Hashable` protocol. The
    /// components used for hashing must be the same as the components compared
    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
    /// with each of these components.
    ///
    /// - Important: Never call `finalize()` on `hasher`. Doing so may become a
    ///   compile-time error in the future.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
    public func hash(into hasher: inout Hasher) {
        defaultValue.hash(into: &hasher)
    }

    /// The hash value.
    ///
    /// Hash values are not guaranteed to be equal across different executions of
    /// your program. Do not save hash values to use during a future execution.
    ///
    /// - Important: `hashValue` is deprecated as a `Hashable` requirement. To
    ///   conform to `Hashable`, implement the `hash(into:)` requirement instead.
    public var hashValue: Int {
        defaultValue.hashValue
    }
}
