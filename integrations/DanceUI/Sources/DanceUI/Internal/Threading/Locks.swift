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

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#elseif os(Windows)
import WinSDK
#else
import Glibc
#endif
/// A threading lock based on `libpthread` instead of `libdispatch`.
///
/// This object provides a lock on top of a single `pthread_mutex_t`. This kind
/// of lock is safe to use with `libpthread`-based threading models, such as the
/// one used by NIO. On Windows, the lock is based on the substantially similar
/// `SRWLOCK` type.
@available(iOS 13.0, *)
internal final class Lock {
    #if os(Windows)
    fileprivate let mutex: UnsafeMutablePointer<SRWLOCK> =
        UnsafeMutablePointer.allocate(capacity: 1)
    #else
    fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t> =
        UnsafeMutablePointer.allocate(capacity: 1)
    #endif

    /// Create a new lock.
    internal init(_ type: Int32 = .init(PTHREAD_MUTEX_ERRORCHECK)) {
        #if os(Windows)
        InitializeSRWLock(self.mutex)
        #else
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, type)

        let err = pthread_mutex_init(self.mutex, &attr)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }

    deinit {
        #if os(Windows)
        // SRWLOCK does not need to be free'd
        #else
        let err = pthread_mutex_destroy(self.mutex)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
        self.mutex.deallocate()
    }

    /// Acquire the lock.
    ///
    /// Whenever possible, consider using `withLock` instead of this method and
    /// `unlock`, to simplify lock handling.
    internal func lock() {
        #if os(Windows)
        AcquireSRWLockExclusive(self.mutex)
        #else
        let err = pthread_mutex_lock(self.mutex)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }

    /// Release the lock.
    ///
    /// Whenever possible, consider using `withLock` instead of this method and
    /// `lock`, to simplify lock handling.
    internal func unlock() {
        #if os(Windows)
        ReleaseSRWLockExclusive(self.mutex)
        #else
        let err = pthread_mutex_unlock(self.mutex)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }
}

@available(iOS 13.0, *)
extension Lock {
    /// Acquire the lock for the duration of the given block.
    ///
    /// This convenience method should be preferred to `lock` and `unlock` in
    /// most situations, as it ensures that the lock will be released regardless
    /// of how `body` exits.
    ///
    /// - Parameter body: The block to execute while holding the lock.
    /// - Returns: The value returned by the block.
    @usableFromInline
    internal func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }

    // specialise Void return (for performance)
    @usableFromInline
    internal func withLockVoid(_ body: () throws -> Void) rethrows {
        try self.withLock(body)
    }
}

/// A reader/writer threading lock based on `libpthread` instead of `libdispatch`.
///
/// This object provides a lock on top of a single `pthread_rwlock_t`. This kind
/// of lock is safe to use with `libpthread`-based threading models, such as the
/// one used by NIO. On Windows, the lock is based on the substantially similar
/// `SRWLOCK` type.
@available(iOS 13.0, *)
internal final class ReadWriteLock {
    #if os(Windows)
    fileprivate let rwlock: UnsafeMutablePointer<SRWLOCK> =
        UnsafeMutablePointer.allocate(capacity: 1)
    fileprivate var shared: Bool = true
    #else
    fileprivate let rwlock: UnsafeMutablePointer<pthread_rwlock_t> =
        UnsafeMutablePointer.allocate(capacity: 1)
    #endif

    /// Create a new lock.
    internal init() {
        #if os(Windows)
        InitializeSRWLock(self.rwlock)
        #else
        let err = pthread_rwlock_init(self.rwlock, nil)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
        #endif
    }

    deinit {
        #if os(Windows)
        // SRWLOCK does not need to be free'd
        #else
        let err = pthread_rwlock_destroy(self.rwlock)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
        #endif
        self.rwlock.deallocate()
    }

    /// Acquire a reader lock.
    ///
    /// Whenever possible, consider using `withReaderLock` instead of this
    /// method and `unlock`, to simplify lock handling.
    internal func lockRead() {
        #if os(Windows)
        AcquireSRWLockShared(self.rwlock)
        self.shared = true
        #else
        let err = pthread_rwlock_rdlock(self.rwlock)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
        #endif
    }

    /// Acquire a writer lock.
    ///
    /// Whenever possible, consider using `withWriterLock` instead of this
    /// method and `unlock`, to simplify lock handling.
    internal func lockWrite() {
        #if os(Windows)
        AcquireSRWLockExclusive(self.rwlock)
        self.shared = false
        #else
        let err = pthread_rwlock_wrlock(self.rwlock)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
        #endif
    }

    /// Release the lock.
    ///
    /// Whenever possible, consider using `withReaderLock` and `withWriterLock`
    /// instead of this method and `lockRead` and `lockWrite`, to simplify lock
    /// handling.
    internal func unlock() {
        #if os(Windows)
        if self.shared {
            ReleaseSRWLockShared(self.rwlock)
        } else {
            ReleaseSRWLockExclusive(self.rwlock)
        }
        #else
        let err = pthread_rwlock_unlock(self.rwlock)
        _danceuiPrecondition(err == 0, "\(#function) failed in pthread_rwlock with error \(err)")
        #endif
    }
}

@available(iOS 13.0, *)
extension ReadWriteLock {
    /// Acquire the reader lock for the duration of the given block.
    ///
    /// This convenience method should be preferred to `lockRead` and `unlock`
    /// in most situations, as it ensures that the lock will be released
    /// regardless of how `body` exits.
    ///
    /// - Parameter body: The block to execute while holding the reader lock.
    /// - Returns: The value returned by the block.
    @usableFromInline
    internal func withReaderLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lockRead()
        defer {
            self.unlock()
        }
        return try body()
    }

    /// Acquire the writer lock for the duration of the given block.
    ///
    /// This convenience method should be preferred to `lockWrite` and `unlock`
    /// in most situations, as it ensures that the lock will be released
    /// regardless of how `body` exits.
    ///
    /// - Parameter body: The block to execute while holding the writer lock.
    /// - Returns: The value returned by the block.
    @usableFromInline
    internal func withWriterLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lockWrite()
        defer {
            self.unlock()
        }
        return try body()
    }

    // specialise Void return (for performance)
    @usableFromInline
    internal func withReaderLockVoid(_ body: () throws -> Void) rethrows {
        try self.withReaderLock(body)
    }

    // specialise Void return (for performance)
    @usableFromInline
    internal func withWriterLockVoid(_ body: () throws -> Void) rethrows {
        try self.withWriterLock(body)
    }
}
