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
internal protocol ValueChangedExecutable {
    
    associatedtype Value: Equatable
    
    var executor: (Value) -> () { get }
    
}

@available(iOS 13.0, *)
internal struct ValueChangedExecutorRule<T, Modifier: ValueChangedExecutable>: Rule where Modifier.Value == T {
    
    internal typealias Value = Void
    
    @Attribute
    private var modifier: Modifier
    
    @Attribute
    private var object: T
    
    @inline(__always)
    internal init(modifier: Attribute<Modifier>, object: Attribute<T>) {
        self._modifier = modifier
        self._object = object
    }
    
    @inline(__always)
    internal var value: Void {
        let (object, changed) = $object.changedValue()
        guard changed else {
            return
        }
        let modifier = modifier
        Update.enqueueAction {
            modifier.executor(object)
        }
    }
    
}
