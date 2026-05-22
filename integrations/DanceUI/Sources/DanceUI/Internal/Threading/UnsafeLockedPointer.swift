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

import MyShims

@propertyWrapper
@available(iOS 13.0, *)
internal struct UnsafeLockedPointer<Data>: Destroyable {
    
    private var base: MyLockedPointer
    
    @inline(__always)
    internal init(wrappedValue: Data) {
        base = .create(bodyType: Data.self) { bodyPtr in
            bodyPtr.initialize(to: wrappedValue)
        }
    }
    
    @_transparent
    internal var wrappedValue: Data {
        nonmutating _read {
            base.lock()
            defer {
                base.unlock()
            }
            yield base.withUnsafeMutablePointerToBody(Data.self).pointee
        }
        nonmutating _modify {
            base.lock()
            defer {
                base.unlock()
            }
            yield &base.withUnsafeMutablePointerToBody(Data.self).pointee
        }
    }
    
    @inlinable
    internal var projectedValue: UnsafeLockedPointer<Data> {
        self
    }
    
    @inline(__always)
    internal func withMutableData<Result>(_ body: (inout Data) -> Result) -> Result {
        body(&wrappedValue)
    }
    
    internal func destroy() {
        base.withUnsafeMutablePointerToBody(Data.self) { dataPtr in
            _ = dataPtr.deinitialize(count: 1)
        }
        base.destroy()
    }
    
}
