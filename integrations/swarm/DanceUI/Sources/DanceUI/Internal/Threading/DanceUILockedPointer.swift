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
@available(iOS 13.0, *)
extension MyLockedPointer {
    
    @_transparent
    private init<Body>(bodyType: Body.Type) {
        self = __MyLockedPointerCreate(MemoryLayout<Body>.size,
                                            MemoryLayout<Body>.alignmentMask)
    }
    
    /// Creates a locked pointer.
    ///
    /// - parameter bodyType: The type of body.
    ///
    /// - parameter factory: The factory of body.
    ///
    /// - warning: Use `UnsafeMutablePointer.<Body>initialize(to:)` in `factory`
    /// closure to set the initial value.
    ///
    @_transparent
    internal static func create<Body>(bodyType: Body.Type,
                                      makingBodyWith factory: (UnsafeMutablePointer<Body>) -> Void) -> MyLockedPointer {
        let ptr = MyLockedPointer(bodyType: bodyType)
        ptr.withUnsafeMutablePointerToBody(bodyType, body: factory)
        return ptr
    }
    
    @_transparent
    internal func withUnsafeMutablePointerToBody<Body, Result>(_ bodyType: Body.Type,
                                                               body: (UnsafeMutablePointer<Body>) -> Result) -> Result {
        return body(__MyLockedPointerGetTrailingContents(self)
                        .assumingMemoryBound(to: Body.self))
    }
    
    @_transparent
    internal func withUnsafeMutablePointerToBody<Body>(_ bodyType: Body.Type) -> UnsafeMutablePointer<Body> {
        return __MyLockedPointerGetTrailingContents(self)
            .assumingMemoryBound(to: Body.self)
    }
    
    @_transparent
    internal func lock() {
        __MyLockedPointerLock(self)
    }
    
    @_transparent
    @discardableResult
    internal func trylock() -> Bool {
        __MyLockedPointerTrylock(self)
    }
    
    @_transparent
    internal func unlock() {
        __MyLockedPointerUnlock(self)
    }
    
    @_transparent
    internal func destroy() {
        __MyLockedPointerDestroy(self)
    }
    
}

