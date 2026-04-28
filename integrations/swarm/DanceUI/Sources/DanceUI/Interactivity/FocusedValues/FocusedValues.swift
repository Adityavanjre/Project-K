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

/// A protocol for identifier types used when publishing and observing focused
/// values.
///
/// Unlike `EnvironmentKey`, `FocusedValueKey` has no default value requirement,
/// because the default value for a key is always `nil`.
///
@available(iOS 13.0, *)
public protocol FocusedValueKey {
    
    associatedtype Value
    
}

/// A collection of state exported by the focused view and its ancestors.
@available(iOS 13.0, *)
public struct FocusedValues {
    
    internal private(set) var plist: PropertyList

    internal var storageOptions: StorageOptions

    internal var version: DisplayList.Version
    
    @usableFromInline
    internal init() {
        plist = PropertyList()
        storageOptions = StorageOptions()
        version = .zero
    }
    
    internal init(_ focusedValueList: FocusedValueList) {
        self.init()
        focusedValueList.forEach { eachItem in
            eachItem.update(&self)
        }
        version = focusedValueList.version
    }
    
    /// Reads and writes values associated with a given focused value key.
    public subscript<Key: FocusedValueKey>(key: Key.Type) -> Key.Value? {
        get {
            var viewEntryOrNil: FocusedValues.Entry<Key>?
            
            var sceneEntryOrNil: FocusedValues.Entry<Key>?
            
            plist.forEach(keyType: FocusedValuePropertyKey<Key>.self) { entryOrNil, shouldStop in
                guard let r14_entry = entryOrNil else {
                    return
                }
                
                if r14_entry.scope == .scene, sceneEntryOrNil == nil {
                    sceneEntryOrNil = r14_entry
                    return
                }
                
                if r14_entry.scope == .view, r14_entry.inFocusedViewHierarchy {
                    viewEntryOrNil = r14_entry
                    return
                }
            }
            
            return viewEntryOrNil?.value ?? sceneEntryOrNil?.value
        }
        set {
            guard let newValue = newValue else {
                return
            }
            
            let scope = storageOptions.contains(.scene) ? FocusedValueScope.scene : FocusedValueScope.view
            
            let entry = FocusedValues.Entry<Key>(scope: scope, value: newValue, inFocusedViewHierarchy: storageOptions.contains(.isFocused))
            
            plist[FocusedValuePropertyKey<Key>.self] = entry
        }
    }
    
    @inline(__always)
    internal func mayNotBeEqual(to other: FocusedValues) -> Bool {
        plist.mayNotBeEqual(to: other.plist)
    }
    
    fileprivate struct Entry<Key: FocusedValueKey> {

        internal let scope: FocusedValueScope

        internal let value: Key.Value

        internal let inFocusedViewHierarchy: Bool
        
    }
    
    internal struct StorageOptions: OptionSet {
        
        internal let rawValue: UInt8
        
        @inlinable
        internal init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        internal static let isFocused = StorageOptions(rawValue: 0x1)
        
        internal static let scene = StorageOptions(rawValue: 0x2)
        
        @inlinable
        internal init(isFocused: Bool, isScene: Bool) {
            self.init()
            if isFocused { self.insert(.isFocused) }
            if isScene { self.insert(.scene) }
        }
        
    }
    
}

@available(iOS 13.0, *)
extension FocusedValues : Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: FocusedValues, rhs: FocusedValues) -> Bool {
        lhs.version == rhs.version
    }
    
}

@available(iOS 13.0, *)
fileprivate struct FocusedValuePropertyKey<Key: FocusedValueKey>: PropertyKey {
    
    fileprivate typealias Value = FocusedValues.Entry<Key>?
    
    fileprivate static var defaultValue: Value {
        nil
    }
    
}

@available(iOS 13.0, *)
internal struct FocusedValuesInputKey: ViewInput {
    
    internal typealias Value = OptionalAttribute<FocusedValues>
    
    internal static var defaultValue: Value {
        OptionalAttribute()
    }
    
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    internal var focusedValues: OptionalAttribute<FocusedValues> {
        get {
            self[FocusedValuesInputKey.self]
        }
        set {
            self[FocusedValuesInputKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension _GraphInputs {
    
    internal var focusedValues: OptionalAttribute<FocusedValues> {
        get {
            self[FocusedValuesInputKey.self]
        }
        set {
            self[FocusedValuesInputKey.self] = newValue
        }
    }
    
}
