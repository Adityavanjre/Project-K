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

import Foundation

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public struct Stack<Element> {
    
    @usableFromInline
    internal var _storage: ContiguousArray<Element>
    
    internal typealias Index = Int
    
    internal init() {
        _storage = ContiguousArray<Element>()
    }
    
    @_spi(DanceUICompose)
    public init(capacity: Int) {
        _storage = ContiguousArray<Element>()
        _storage.reserveCapacity(capacity)
    }
    
    @inlinable
    internal var count: Int {
        _storage.count
    }
    
    @inlinable
    internal var capacity: Int {
        _storage.capacity
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public mutating func push(_ element: Element) {
        _storage.append(element)
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public mutating func pop() -> Element? {
        _storage.popLast()
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public var isEmpty: Bool {
        count == 0
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public mutating func reset() {
        _storage.removeAll(keepingCapacity: true)
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public var top: Element? {
        get {
            _storage.last
        }
        set {
            guard let newValue = newValue else {
                _storage.removeLast()
                return
            }
            guard !isEmpty else {
                push(newValue)
                return
            }
            _storage.removeLast()
            push(newValue)
        }
    }
    
}

@available(iOS 13.0, *)
extension Stack: Sequence {
    
    public typealias Iterator = _Iterator
    
    @_spi(DanceUICompose)
    public struct _Iterator: IteratorProtocol {
        
        @usableFromInline
        internal init(stack: ContiguousArray<Element>) {
            self.stack = stack
        }
        
        @usableFromInline
        internal var stack: ContiguousArray<Element>
        
        @usableFromInline
        internal var idx = 0
        
        @inlinable
        @_spi(DanceUICompose)
        public mutating func next() -> Element? {
            guard stack.count != 0 else {
                return nil
            }
            guard idx < stack.count else {
                return nil
            }
            let element = stack[stack.count - idx - 1]
            idx += 1
            return element
        }
        
    }
    
    @inlinable
    @_spi(DanceUICompose)
    __consuming public func makeIterator() -> Iterator {
        .init(stack: _storage)
    }
}

@available(iOS 13.0, *)
extension Stack {
    
    @usableFromInline
    internal subscript(index: Int) -> Element {
        get {
            _storage[count - 1 - index]
        }
        set {
            _storage[count - 1 - index] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension Stack: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var desc = ""
        for element in self {
            desc.append("<StackElement: \(element)>")
        }
        return desc
    }
}
