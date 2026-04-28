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

@propertyWrapper
@available(iOS 13.0, *)
internal final class Box<T> {
    
    internal var value: T
    
    @inlinable
    internal var wrappedValue: T {
        value
    }
    
    @inlinable
    internal init(_ value: T) {
        self.value = value
    }
}

@usableFromInline
@propertyWrapper
@available(iOS 13.0, *)
internal final class MutableBox<T> {
    
    @usableFromInline
    internal var value: T
    
    @inlinable
    internal var wrappedValue: T {
        get { value }
        set { value = newValue }
    }
    
    @inlinable
    internal var projectedValue: MutableBox<T> {
        self
    }
    
    @inline(__always)
    internal init(_ value: T) {
        self.value = value
    }
}

@propertyWrapper
@available(iOS 13.0, *)
internal struct HashableWeakBox<T: AnyObject>: Hashable {

    internal weak var base: T?

    internal let basePointer: UnsafeMutableRawPointer
    
    @inlinable
    internal var wrappedValue: T? {
        base
    }
    
    @inlinable
    internal init(_ base: T) {
        self.base = base
        self.basePointer = Unmanaged.passUnretained(base).toOpaque()
    }
    
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(basePointer)
    }
    
    internal static func == (lhs: HashableWeakBox, rhs: HashableWeakBox) -> Bool {
        return lhs.basePointer == rhs.basePointer
    }
    
}

@propertyWrapper
@available(iOS 13.0, *)
internal struct Indirect<T> {

    internal var box: MutableBox<T>
    
    @inlinable
    internal var wrappedValue: T? {
        box.wrappedValue
    }
    
    @inlinable
    internal init(_ value: T) {
        self.box = MutableBox(value)
    }
    
}
