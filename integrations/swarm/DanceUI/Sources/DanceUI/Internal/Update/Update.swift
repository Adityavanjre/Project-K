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

@available(iOS 13.0, *)
internal enum Update {
    
    private final class TraceHost {
        
    }
    
    internal typealias Action = () -> Void
    
    private static let lock = MovableLock()
    
    /// DanceUI imaginary
    internal static func withLock<R>(do body: () -> R) -> R {
        lock.withLock(body: body)
    }
    
    /// DanceUI imaginary
    internal static func withoutLock<R>(do body: () -> R) -> R {
        lock.unlock()
        let result = body()
        lock.lock()
        return result
    }
    
    /// DanceUI imaginary
    internal static func wait() {
        lock.wait()
    }
    
    /// DanceUI imaginary
    internal static func broadcast() {
        lock.broadcast()
    }
    
    @inlinable
    internal static func syncMain(_ body: () -> Void) {
        if Thread.isMainThread {
            body()
        } else {
            let attribute = AnyOptionalAttribute.current
            lock.syncMain {
                AnyRuleContext(attribute).update {
                    body()
                }
            }
        }
    }
    
    @inlinable
    internal static func syncMainWithoutUpdate<R>(_ body: () -> R) -> R {
        if Thread.isMainThread {
            return body()
        } else {
            return lock.withLock {
                var result: R? = nil
                lock.syncMain {
                    result = body()
                }
                guard let result else {
                    _danceuiPreconditionFailure("No syncMainWithoutUpdate result")
                }
                return result
            }
        }
    }
    
    private static var depth: Int = 0
    
    private static var actions: [Action] = []
    
    internal static var traceHost: AnyObject = TraceHost()
    
    @inlinable
    internal static func enqueueAction(_ action: @escaping () -> Void) {
        begin()
        actions.append(action)
        end()
    }
    
    @inlinable
    internal static func ensure172<A>(_ action: @escaping () throws -> A) rethrows -> A {
        return try lock.withLock {
            Update.begin()
            defer {
                Update.end()
            }
            return try action()
        }
    }
    
    @inlinable
    internal static func ensure<A>(_ action: @escaping () throws -> A) rethrows -> A {
        return try lock.withLock {
            let depth = Update.depth
            if depth == 0 {
                Update.begin()
            }
            defer {
                if depth == 0 {
                    Update.end()
                }
            }
            return try action()
        }
    }
    
    @inlinable
    internal static func dispatchActions() {
        while !actions.isEmpty {
            let actions: [Action]
            
            (actions, Update.actions) = (Update.actions, [])
            
            performOnMainThread {
                begin()

                for action in actions {
                    let depth = Update.depth
                    action()
                    _danceuiPrecondition(depth == Update.depth)
                }

                end()
            }
        }
    }
    
    /// Begins a root update
    internal static func begin() {
        lock.lock()

        depth &+= 1
    }
    
    /// Ends a root update
    internal static func end() {
        if depth == 1 {
            dispatchActions()
        }
        
        depth &-= 1
        
        lock.unlock()
    }
    
    /// Perform a closure immediately with guarded transaction. This function
    /// also flushes pending actions if it is the root transaction of nested
    /// `Update` transactions.
    ///
    /// - Note: Consider change the name into "asRoot", which means begin an
    /// immediate root update.
    ///
    @inlinable
    @discardableResult
    internal static func perform<R>(_ body: () -> R) -> R {
        Update.begin()
        defer {
            Update.end()
        }
        return body()
    }
    
    /// DanceUI imaginary
    @inline(__always)
    internal static var isInRoot: Bool {
        Update.depth == 1
    }
    
    /// DanceUI imaginary
    @inline(__always)
    internal static var hasActions: Bool {
        !Update.actions.isEmpty
    }

}
