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

/// A named value produced by a view.
///
/// A view with multiple children automatically combines its values for a given
/// preference into a single value visible to its ancestors.
@available(iOS 13.0, *)
public protocol PreferenceKey {
    
    /// The type of value produced by this preference.
    associatedtype Value

    /// The default value of the preference.
    ///
    /// Views that have no explicit value for the key produce this default
    /// value. Combining child views may remove an implicit value produced by
    /// using the default. This means that `reduce(value: &x, nextValue:
    /// {defaultValue})` shouldn't change the meaning of `x`.
    static var defaultValue: Value { get }

    /// Combines a sequence of values by modifying the previously-accumulated
    /// value with the result of a closure that provides the next value.
    ///
    /// This method receives its values in view-tree order. Conceptually, this
    /// combines the preference value from one tree with that of its next
    /// sibling.
    ///
    /// - Parameters:
    ///   - value: The value accumulated through previous calls to this method.
    ///     The implementation should modify this value.
    ///   - nextValue: A closure that returns the next value in the sequence.
    static func reduce(value: inout Value, nextValue: () -> Value)

    static var _includesRemovedValues: Bool { get }

    static var _isReadableByHost: Bool { get }
}

@available(iOS 13.0, *)
extension PreferenceKey where Value : ExpressibleByNilLiteral {

    /// Let nil-expressible values default-initialize to nil.
    public static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension PreferenceKey {
    
    public static var _includesRemovedValues: Bool { return false }
    
    public static var _isReadableByHost: Bool { return false }
    
    internal static func apply(indices: Range<Int>, values: (Int) -> Value) -> Value {
        guard indices.startIndex < indices.endIndex else {
            return defaultValue
        }
        var startIndex: Int = indices.startIndex
        let endIndex: Int = indices.endIndex
        var value: Value = values(indices.startIndex)
        startIndex &+= 1
        
        for index in startIndex..<endIndex {
            reduce(value: &value) { () -> Value in
                values(index)
            }
        }
        return value
    }
}
