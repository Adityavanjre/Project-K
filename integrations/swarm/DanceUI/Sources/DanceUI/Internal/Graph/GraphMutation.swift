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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal protocol GraphMutation {

    mutating func apply()

    /// Test and combine (if applicable) the next pending graph mutation.
    mutating func combine<Another: GraphMutation>(with another: Another) -> Bool

#if DEBUG || DANCE_UI_INHOUSE
    var file: StaticString { get }

    var line: UInt { get }

    var function: StaticString { get }
#endif

}

@available(iOS 13.0, *)
extension GraphMutation {

    @inline(__always)
    internal func traceGraphHostConcat(_ identifier: @autoclosure () -> AnyObject?) {
    }

    @inline(__always)
    internal func traceGraphHostAppend(_ identifier: @autoclosure () -> AnyObject?) {
    }

    @inline(__always)
    internal func traceApply() {
    }

}

@available(iOS 13.0, *)
internal struct EmptyGraphMutation: GraphMutation {

#if DEBUG || DANCE_UI_INHOUSE
    internal let file: StaticString

    internal let line: UInt

    internal let function: StaticString
#endif
    
    internal func apply() {
        _intentionallyLeftBlank()
    }
    
#if DEBUG || DANCE_UI_INHOUSE
    internal init(file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) {
        self.file = file
        self.line = line
        self.function = function
    }
#endif
    
    internal func combine<T>(with mutation: T) -> Bool where T : GraphMutation {
        return T.self == EmptyGraphMutation.self
    }
}

@available(iOS 13.0, *)
internal struct InvalidatingGraphMutation: GraphMutation {

    internal struct Seed {

        private static var next: UInt32 = 0

        internal let value: UInt32

        @inlinable
        internal init() {
            defer {
                Self.next &+= 1
            }
            self.value = Self.next
        }

    }

    internal var attribute: DGWeakAttribute

    internal let seed: Seed = Seed()

#if DEBUG || DANCE_UI_INHOUSE
    internal let file: StaticString

    internal let line: UInt

    internal let function: StaticString
#endif
    
#if DEBUG || DANCE_UI_INHOUSE
    @inlinable
    internal init(attribute: DGWeakAttribute, file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) {
        self.attribute = attribute
        self.file = file
        self.line = line
        self.function = function
    }
    
    @inlinable
    internal init<T>(attribute: WeakAttribute<T>, file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) {
        self.init(attribute: attribute.base, file: file, line: line, function: function)
    }
#else
    @inlinable
    internal init(attribute: DGWeakAttribute) {
        self.attribute = attribute
    }
    
    @inlinable
    internal init<T>(attribute: WeakAttribute<T>) {
        self.attribute = attribute.base
    }
#endif
    
    internal func apply() {
        guard let strongAttribute = attribute.attribute else {
#if DEBUG || DANCE_UI_INHOUSE
            Signpost.viewInfoTrace.traceEvent("will apply invalidating graph mutation: attribute= %{public}; seed = %{public}d; attribute-live-ness = %{public}d", [attribute.__attribute.rawValue, seed.value, 0])
#endif
            return
        }
#if DEBUG || DANCE_UI_INHOUSE
        Signpost.viewInfoTrace.traceEvent("will apply invalidating graph mutation: attribute= %{public}; seed = %{public}d; attribute-live-ness = %{public}d", [attribute.__attribute.rawValue, seed.value, 1])
#endif
        strongAttribute.invalidateValue()
    }
    
    internal func combine<T>(with mutation: T) -> Bool where T : GraphMutation {
        guard let another = mutation as? InvalidatingGraphMutation else {
            return false
        }
        
        return attribute == another.attribute
    }
}

@available(iOS 13.0, *)
internal struct CustomGraphMutation: GraphMutation {

    internal var body: () -> ()

#if DEBUG || DANCE_UI_INHOUSE
    internal let file: StaticString

    internal let line: UInt

    internal let function: StaticString
#endif
    
    internal func apply() {
        body()
    }
    
    internal func combine<T>(with mutation: T) -> Bool where T : GraphMutation {
        false
    }
    
#if DEBUG || DANCE_UI_INHOUSE
    internal init(body: @escaping () -> Void, file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) {
        self.body = body
        self.file = file
        self.line = line
        self.function = function
    }
#endif
}

@available(iOS 13.0, *)
internal enum _GraphMutation_Style: UInt8 {

    case ignoresFlushWhenUpdating

    case ignoresFlush
}
