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

internal struct _ManagedCriticalState<State> {
    
    final private class LockedBuffer: ManagedBuffer<State, UnsafeRawPointer> { }
    
    private let buffer: ManagedBuffer<State, UnsafeRawPointer>
    
    internal init(_ buffer: ManagedBuffer<State, UnsafeRawPointer>) {
        self.buffer = buffer
    }
    
    internal init(_ initial: State) {
        self.init(LockedBuffer.create(minimumCapacity: Swift.max(_lockSize() / MemoryLayout<UnsafeRawPointer>.size, 1)) { buffer in
            buffer.withUnsafeMutablePointerToElements { _lockInit(UnsafeMutableRawPointer($0)) }
            return initial
        })
    }
    
    internal func withCriticalRegion<R>(
        _ critical: (inout State) throws -> R
    ) rethrows -> R {
        try buffer.withUnsafeMutablePointers { header, lock in
            _lockLock(UnsafeMutableRawPointer(lock))
            defer {
                _lockUnlock(UnsafeMutableRawPointer(lock))
            }
            return try critical(&header.pointee)
        }
    }
}

internal protocol _Deinitializable {
    mutating func deinitialize()
}

extension _ManagedCriticalState where State: _Deinitializable {
    final private class DeinitializingLockedBuffer:
        ManagedBuffer<State, UnsafeRawPointer> {
        deinit {
            withUnsafeMutablePointers { header, lock in
                header.pointee.deinitialize()
            }
        }
    }
    
    internal init(managing initial: State) {
        self.init(DeinitializingLockedBuffer.create(minimumCapacity: Swift.max(_lockSize() / MemoryLayout<UnsafeRawPointer>.size, 1)) { buffer in
            buffer.withUnsafeMutablePointerToElements { _lockInit(UnsafeMutableRawPointer($0)) }
            return initial
        })
    }
}

extension _ManagedCriticalState: @unchecked Sendable where State: Sendable { }

extension _ManagedCriticalState: Identifiable {
    internal var id: ObjectIdentifier {
        ObjectIdentifier(buffer)
    }
}

import Darwin

private func _lockSize() -> Int {
    MemoryLayout<pthread_mutex_t>.size
}

/// The `mutex` parameter shall be `UnsafeMutableRawPointer`.
private func _lockInit(_ mutex: UnsafeMutableRawPointer) {
    pthread_mutex_init(mutex.withMemoryRebound(to: pthread_mutex_t.self, capacity: 1, {$0}), nil)
}

/// The `mutex` parameter shall be `UnsafeMutableRawPointer`.
private func _lockLock(_ mutex: UnsafeMutableRawPointer) {
    pthread_mutex_lock(mutex.withMemoryRebound(to: pthread_mutex_t.self, capacity: 1, {$0}))
}

/// The `mutex` parameter shall be `UnsafeMutableRawPointer`.
private func _lockUnlock(_ mutex: UnsafeMutableRawPointer) {
    pthread_mutex_unlock(mutex.withMemoryRebound(to: pthread_mutex_t.self, capacity: 1, {$0}))
}
