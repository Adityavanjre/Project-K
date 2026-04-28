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

private final class AtomicBuffer<Value>: ManagedBuffer<os_unfair_lock_s, Value> {
    internal static func allocate(value: Value) -> AtomicBuffer<Value> {
        let buffer = AtomicBuffer.create(minimumCapacity: 1) { buffer in
            os_unfair_lock_s()
        }
        buffer.withUnsafeMutablePointerToElements { pointer in
            pointer.initialize(to: value)
        }
        return unsafeDowncast(buffer, to: AtomicBuffer<Value>.self)
    }
    
    deinit {
        withUnsafeMutablePointerToElements {
            _ = $0.deinitialize(count: 1)
        }
    }
}

@propertyWrapper
internal struct AtomicBox<Value> {
    private let buffer: AtomicBuffer<Value>

    internal init(wrappedValue: Value) {
        buffer = AtomicBuffer.allocate(value: wrappedValue)
    }

    @inline(__always)
    internal var wrappedValue: Value {
        get {
            buffer.withUnsafeMutablePointerToHeader { os_unfair_lock_lock($0) }
            defer { buffer.withUnsafeMutablePointerToHeader { os_unfair_lock_unlock($0) } }
            return buffer.withUnsafeMutablePointerToElements { $0.pointee }
        }
        nonmutating _modify {
            buffer.withUnsafeMutablePointerToHeader { os_unfair_lock_lock($0) }
            defer { buffer.withUnsafeMutablePointerToHeader { os_unfair_lock_unlock($0) } }
            yield &buffer.withUnsafeMutablePointerToElements { $0 }.pointee
        }
    }

    @discardableResult
    @inline(__always)
    internal func access<T>(_ body: (inout Value) throws -> T) rethrows -> T {
        try body(&wrappedValue)
    }

    internal var projectedValue: AtomicBox<Value> { self }
}

extension AtomicBox: @unchecked Sendable where Value: Sendable {}

extension AtomicBox where Value: ExpressibleByNilLiteral {
    internal init() {
        self.init(wrappedValue: nil)
    }
}
