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
internal final class ThreadSpecific<Value> {
    
    internal var key : UInt

    internal let defaultValue : Value
    
    internal init(_ defaultValue: Value) {
        self.key = 0
        self.defaultValue = defaultValue
        // The destructor would not be called when a thread exited.
        pthread_key_create(&pthreadKey) { ptr in
            ptr.withMemoryRebound(to: AnyThreadSpecificBox.self, capacity: 1, {$0}).deinitialize(count: 1)
            ptr.withMemoryRebound(to: AnyThreadSpecificBox.self, capacity: 1, {$0}).deallocate()
        }
    }
    
    @inline(__always)
    private var pthreadKey: pthread_key_t {
        unsafeAddress {
            withUnsafePointer(to: &key, {$0}).withMemoryRebound(to: pthread_key_t.self, capacity: 1, {$0})
        }
        unsafeMutableAddress {
            withUnsafeMutablePointer(to: &key, {$0}).withMemoryRebound(to: pthread_key_t.self, capacity: 1, {$0})
        }
    }
    
    private var box: UnsafeMutablePointer<ThreadSpecificBox<Value>> {
        if let ptr = pthread_getspecific(pthreadKey) {
            return ptr.withMemoryRebound(to: ThreadSpecificBox<Value>.self, capacity: 1, {$0})
        }
        let ptr = UnsafeMutablePointer<ThreadSpecificBox<Value>>.allocate(capacity: 1)
        pthread_setspecific(pthreadKey, ptr)
        ptr.initialize(to: ThreadSpecificBox(value: defaultValue))
        return ptr
    }
    
    internal var value: Value {
        get {
            box.pointee.value
        }
        set {
            box.pointee.value = newValue
        }
    }
    
    @inline(__always)
    internal var wrappedValue: Value {
        get {
            value
        }
        set {
            value = newValue
        }
    }
    
    deinit {
#if DANCE_UI_INHOUSE || DEBUG
        NSException(
            name: .internalInconsistencyException,
            reason: "ThreadSpecifics are designed to be used as static variables which are always not get deinit."
        ).raise()
#endif
    }
    
}

/// `pthread_key_create` receives a `@convention(c)` closure which is unable
/// to capture generic constraints (particularity is the `Value` in
/// `ThreadSpecificBox`). Thus, here is a root class to erase the generic
/// environment.
///
/// This type also cannot be moved to the body of `ThreadSpecific`. Because
/// `ThreadSpecific` introduces a generic environment which prevents referring
/// `AnyThreadSpecificBox` in the closure received by `pthread_key_create`.
///
@available(iOS 13.0, *)
private class AnyThreadSpecificBox {
    
}

@available(iOS 13.0, *)
private final class ThreadSpecificBox<Value>: AnyThreadSpecificBox {
    
    fileprivate var value : Value
    
    @inline(__always)
    fileprivate init(value: Value) {
        self.value = value
    }
    
}
