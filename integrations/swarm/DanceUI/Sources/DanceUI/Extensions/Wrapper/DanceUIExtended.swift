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

@available(iOS 13.0, *)
public protocol DanceUIExtended {
    
}

/// DanceUI extended type's namespace property wrapper.
///
/// - Note: To make the compiler can eliminate copies of this type's instance
/// as much as possible, this type's `init` function shall be `@inlinable`.
@frozen
@available(iOS 13.0, *)
public struct ExtensionWrapper<Wrapped> {
    
    @usableFromInline
    internal let wrapped: Wrapped
    
    @inlinable
    public init(_ wrapped: Wrapped) {
        self.wrapped = wrapped
    }
    
}

@available(iOS 13.0, *)
extension DanceUIExtended {
    
    /// DanceUI extended members namespace.
    ///
    /// - Note: To make the compiler can eliminate unnecessary function calls
    /// as much as possible, this property shall be `@inlinable`.
    @inlinable
    public static var danceUI: ExtensionWrapper<Self>.Type {
        ExtensionWrapper<Self>.self
    }
    
    /// DanceUI extended members namespace.
    ///
    /// - Note: To make the compiler can eliminate the result's copy as much as
    /// possible, this property shall be `@inlinable`.
    @inlinable
    public var danceUI: ExtensionWrapper<Self> {
        ExtensionWrapper(self)
    }
    
}

@available(iOS 13.0, *)
extension NSAttributedString: DanceUIExtended {
    
}

@available(iOS 13.0, *)
extension NSAttributedString.Key: DanceUIExtended {
    
}
