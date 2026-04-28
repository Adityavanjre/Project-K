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

import DanceUIObservation
import OpenCombine
internal import DanceUIGraph

@available(iOS 13.0, *)
extension View {
    
    /// Supplies an `ObservableObject` to a view subhierarchy.
    ///
    /// The object can be read by any child by using `EnvironmentObject`.
    ///
    /// - Parameter object: the object to store and make available to
    ///     the view's subhierarchy.
    @inlinable
    public func environmentObject<B>(_ bindable: B) -> some View where B : ObservableObject {
        return environment(B.environmentStore, bindable)
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets an object of the environment to the given value.
    ///
    /// - Important: This modifier only accepts objects conforming to the
    /// `Observable` protocol. For objects conforming to `ObservableObject` see
    /// ``Scene/environmentObject(_:)``.
    ///
    /// Use this modifier to set custom objects in a scene's environment. For
    /// example, you could set the environment object for a custom `Profile`
    /// class:
    ///
    ///     @Observable final class Profile { ... }
    ///
    ///     @main
    ///     struct MyApp: App {
    ///         var body: some View {
    ///             WindowGroup {
    ///                 ContentView()
    ///             }
    ///             .environment(ProfileService.currentProfile)
    ///         }
    ///     }
    ///
    /// You then read the object inside `ContentView` or one of its descendants
    /// using the ``Environment`` property wrapper:
    ///
    ///     struct ContentView: View {
    ///         @Environment(Account.self) private var currentAccount: Account
    ///
    ///         var body: some View { ... }
    ///     }
    ///
    /// This modifier affects the given scene, as
    /// well as that scene's descendant views. It has no effect outside the view
    /// hierarchy on which you call it.
    ///
    /// - Parameter object: The new object to set for this object's type in the
    ///   environment, or `nil` to clear the object from the environment.
    ///
    /// - Returns: A scene that has the given object set in its environment.
    public func environment<T>(_ object: T?) -> some View where T : AnyObject, T : Observable {
        environment(T.environmentKey, object)
    }
    
}

@available(iOS 13.0, *)
extension ObservableObject {
    
    @usableFromInline
    internal static var environmentStore: WritableKeyPath<EnvironmentValues, Self?> {
        \EnvironmentValues[EnvironmentObjectKey()]
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    fileprivate subscript<A: ObservableObject>(_ key: EnvironmentObjectKey<A>) -> A? {
        get {
            self[EnvironmentObjectKey<A>.self]
        }
        set {
            self[EnvironmentObjectKey<A>.self] = newValue
        }
    }
}


@available(iOS 13.0, *)
extension Environment {
    
    public init(_ object: Value.Type) where Value : AnyObject, Value : Observable {
        self.init(Value.forcelyUnwrappedEnvironmentKey)
    }
    
    public init<T>(_ objectType: T.Type) where Value == T?, T : AnyObject, T : Observable {
        self.init(T.environmentKey)
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    public subscript<T>(objectType: T.Type) -> T? where T : AnyObject, T : DanceUIObservation.Observable {
        get {
            self[EnvironmentObjectKey()]
        }
        set {
            self[EnvironmentObjectKey()] = newValue
        }
    }
    
    public subscript<T>(objectType: T.Type) -> T where T : AnyObject, T : DanceUIObservation.Observable {
        get {
            self[forceUnwrapping: EnvironmentObjectKey()]
        }
        set {
            self[forceUnwrapping: EnvironmentObjectKey()] = newValue
        }
    }
    
    fileprivate subscript<Object: Observable>(_ environmentObjectKey: EnvironmentObjectKey<Object>) -> Object? {
        get {
            self[EnvironmentObjectKey<Object>.self]
        }
        set {
            self[EnvironmentObjectKey<Object>.self] = newValue
        }
    }
    
    fileprivate subscript<Object: Observable>(forceUnwrapping environmentObjectKey: EnvironmentObjectKey<Object>) -> Object {
        get {
            guard let unwrapped = self[EnvironmentObjectKey<Object>.self] else {
                _danceuiPreconditionFailure("No Observable object of type \(Object.self) found. A View.environment(_:) for may be missing as an ancestor of this view.")
            }
            return unwrapped
        }
        set {
            // Not redundant. A writable key-path requires the setter
            self[EnvironmentObjectKey<Object>.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension Observable where Self: AnyObject {
    
    internal static var environmentKey: WritableKeyPath<EnvironmentValues, Self?> {
        \EnvironmentValues[EnvironmentObjectKey<Self>()]
    }
    
    internal static var forcelyUnwrappedEnvironmentKey: WritableKeyPath<EnvironmentValues, Self> {
        \EnvironmentValues[forceUnwrapping: EnvironmentObjectKey<Self>()]
    }
    
}

@available(iOS 13.0, *)
private struct EnvironmentObjectKey<A: AnyObject>: EnvironmentKey, Hashable {
    
    fileprivate typealias Value = A?
    
    fileprivate static var defaultValue: A? {
        nil
    }
    
    fileprivate func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(A.self))
    }
    
    fileprivate static func == (lhs: EnvironmentObjectKey, rhs: EnvironmentObjectKey) -> Bool {
        true
    }
    
}
