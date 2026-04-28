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
public protocol GestureObserverKey {
    
    associatedtype Value: UIGestureRecognizer & AnyHostedGestureObserving
    
}

/// A collection of `UIGestureRecognizer` instances and propagated through a
/// view hierarchy. Instances in the collection can be accessed with
/// `@GestureObserver` dynamic property in DanceUI and used as gesture
/// observer with `Gesture.observed(by:, body:)` modifier.
///
@available(iOS 13.0, *)
public struct GestureObservers {
    
    private struct KeyWrapper<Key: GestureObserverKey>: PropertyKey {
        
        fileprivate typealias Value = Key.Value?
        
        fileprivate static var defaultValue: Value { nil }
        
    }
    
    private var plist: PropertyList
    
    public init() {
        self.init(plist: PropertyList())
    }
    
    @inline(__always)
    internal init(plist: PropertyList) {
        self.plist = plist
    }
    
    public subscript<Key: GestureObserverKey>(key: Key.Type) -> Key.Value? {
        get {
            plist[KeyWrapper<Key>.self]
        }
        mutating set {
            plist[KeyWrapper<Key>.self] = newValue
        }
    }
    
    @inline(__always)
    internal func mayNotBeEqual(to another: GestureObservers) -> Bool {
        plist.mayNotBeEqual(to: another.plist)
    }
    
    @inline(__always)
    internal var isEmpty: Bool {
        return plist.elements == nil
    }
    
    @inline(__always)
    internal func merged(with another: GestureObservers) -> GestureObservers {
        GestureObservers(plist: plist.merged(another.plist))
    }
    
}

@available(iOS 13.0, *)
private struct GestureObserversKey: ViewInput {
    
    fileprivate typealias Value = OptionalAttribute<GestureObservers>
    
    fileprivate static var defaultValue: Value {
        return OptionalAttribute(nil)
    }
    
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var gestureObservers: OptionalAttribute<GestureObservers> {
        get {
            self[GestureObserversKey.self]
        }
        set {
            self[GestureObserversKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension _GraphInputs {
    
    @inline(__always)
    internal var gestureObservers: OptionalAttribute<GestureObservers> {
        get {
            self[GestureObserversKey.self]
        }
        set {
            self[GestureObserversKey.self] = newValue
        }
    }
    
}
