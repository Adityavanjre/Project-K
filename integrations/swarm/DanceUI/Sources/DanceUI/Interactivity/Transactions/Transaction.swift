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

/// The context of the current state-processing update.
///
/// Use a transaction to pass an animation between views in a view hierarchy.
///
/// The root transaction for a state change comes from the binding that changed,
/// plus any global values set by calling ``withTransaction(_:_:)`` or
/// ``withAnimation(_:_:)``.
@frozen
@available(iOS 13.0, *)
public struct Transaction: Equatable {

    internal static func currentUIViewTransaction(canDisableAnimations: Bool) -> Transaction? {
        return nil
    }

    @usableFromInline
    internal var plist: PropertyList
    
    @inlinable
    internal init(plist: PropertyList) {
        self.plist = plist
    }
    
    /// Creates a transaction.
    public init() {
        self.plist = PropertyList()
    }
    
    /// This subscript shall be internal due to there are uses in tests.
    @inline(__always)
    internal subscript<Key: TransactionKey>(_ key: Key.Type) -> Key.Value {
        get {
            plist[TransactionPropertyKey<Key>.self]
        }
        
        set {
            plist[TransactionPropertyKey<Key>.self] = newValue
        }
    }
    
    @inline(__always)
    internal func byOverriding(with transaction: Transaction?) -> Transaction {
        var copiedPlist = plist
        copiedPlist.override(with: transaction?.plist ?? PropertyList())
        return Transaction(plist: copiedPlist)
    }
    
    @inline(__always)
    internal mutating func merge(_ transaction: Transaction) {
        plist.merge(transaction.plist)
    }
    
    @inline(__always)
    internal func merged(_ transaction: Transaction) -> Transaction {
        Transaction(plist: plist.merged(transaction.plist))
    }

    internal func mayConcatenate(with transaction: Transaction) -> Bool {
        !plist.mayNotBeEqual(to: transaction.plist)
    }
    
    internal var isEmpty: Bool {
        plist.elements == nil
    }
    
    public static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        !lhs.plist.mayNotBeEqual(to: rhs.plist)
    }
    
    @inline(__always)
    internal static var current: Transaction {
        if let data = _threadTransactionData() {
            let root = unsafeBitCast(data, to: PropertyList.Element.self)
            return Transaction(plist: PropertyList(elements: root))
        } else {
            return Transaction()
        }
    }
    
    #if DEBUG
    
    internal static var currentForTest: Transaction {
        current
    }
    
    #endif
}

/// Executes a closure with the specified transaction and returns the result.
///
/// - Parameters:
///   - transaction : An instance of a transaction, set as the thread's current
///     transaction.
///   - body: A closure to execute.
///
/// - Returns: The result of executing the closure with the specified
///   transaction.
@available(iOS 13.0, *)
public func withTransaction<Result>(_ transaction: Transaction,
                                    _ body: () throws -> Result) rethrows -> Result {
    return try withExtendedLifetime(transaction, {
        let oldData = _threadTransactionData()

        let mergedTransaction = Transaction.current.merged(transaction)
        let pointer = mergedTransaction.plist.elements.map({Unmanaged.passUnretained($0).toOpaque()})
        
        _setThreadTransactionData(pointer)
        
        let retVal = try body()
        
        _setThreadTransactionData(oldData)
        return retVal
    })
}

@available(iOS 13.0, *)
extension Transaction {
    
    @inline(__always)
    internal var listener: AnimationListener? {
        get {
            self[Transaction.AnimationListenerKey.self]
        }
        
        set {
            self[Transaction.AnimationListenerKey.self] = newValue
        }
    }
    
    fileprivate struct AnimationListenerKey: TransactionKey {
        
        internal typealias Value = AnimationListener?
        
        @inline(__always)
        internal static var defaultValue: AnimationListener? { nil }

    }
    
}

@available(iOS 13.0, *)
extension Transaction {
    
    /// A Boolean value that indicates whether views should disable animations.
    ///
    /// This value is `true` during the initial phase of a two-part transition
    /// update, to prevent ``View/animation(_:)-3bh5`` from inserting new animations
    /// into the transaction.
    @inline(__always)
    public var disablesAnimations: Bool {
        get {
            self[DisablesAnimationsKey.self]
        }
        
        set {
            self[DisablesAnimationsKey.self] = newValue
        }
    }
    
    fileprivate struct DisablesAnimationsKey: TransactionKey {
        
        internal typealias Value = Bool
        
        @inline(__always)
        internal static var defaultValue: Bool { false }
        
    }
    
}

@available(iOS 13.0, *)
extension Transaction {
    
    /// Creates a transaction and assigns its animation property.
    ///
    /// - Parameter animation: The animation to perform when the current state
    ///   changes.
    @inline(__always)
    public init(animation: Animation?) {
        self.plist = PropertyList()
        self.animation = animation
    }
    
    /// The animation, if any, associated with the current state change.
    @inline(__always)
    public var animation: Animation? {
        get {
            self[Transaction.AnimationKey.self]
        }
        
        set {
            self[Transaction.AnimationKey.self] = newValue
        }
    }
    
    fileprivate struct AnimationKey: TransactionKey {
        
        internal typealias Value = Animation?
        
        @inline(__always)
        internal static var defaultValue: Animation? { nil }
    }
    
}

@available(iOS 13.0, *)
extension Transaction {
    
    @inline(__always)
    internal var animationIgnoringTransitionPhase: Animation? {
        get {
            guard disablesAnimations else {
                return animation
            }
            var value: Animation? = nil
            plist.forEach(keyType: TransactionPropertyKey<AnimationKey>.self) { animation, stop in
                guard let animation = animation else {
                    return
                }
                stop = true
                value = animation
            }
            return value
        }
        
    }
    
}

@available(iOS 13.0, *)
extension Transaction {
    
    @inline(__always)
    public var fromScrollView: Bool {
        get {
            self[FromScrollViewKey.self]
        }
        
        set {
            self[FromScrollViewKey.self] = newValue
        }
    }
    
    
    fileprivate struct FromScrollViewKey: TransactionKey {
        
        typealias Value = Bool
        
        static var defaultValue: Bool { false }
        
    }
    
}

@available(iOS 13.0, *)
extension Transaction { // iOS 15
    
    @inline(__always)
    internal var animationFrameInterval: Double? {
        get {
            self[AnimationFrameIntervalKey.self]
        }
        
        set {
            self[AnimationFrameIntervalKey.self] = newValue
        }
    }
    
    fileprivate struct AnimationFrameIntervalKey: TransactionKey {
        typealias Value = Double?
        
        static var defaultValue: Double? { nil }
    }
}

@available(iOS 13.0, *)
extension Transaction { // iOS 15
    
    @inline(__always)
    internal var animationReason: UInt32? {
        get {
            self[AnimationReasonKey.self]
        }
        
        set {
            self[AnimationReasonKey.self] = newValue
        }
    }
    
    fileprivate struct AnimationReasonKey: TransactionKey {
        typealias Value = UInt32?
        
        static var defaultValue: UInt32? { nil }
    }
}

@available(iOS 13.0, *)
extension Transaction {
    
    @inline(__always)
    internal var collectionViewLayoutUpdate: CollectionViewLayoutUpdate {
        get {
            self[CollectionViewLayoutUpdateKey.self]
        }
        
        set {
            self[CollectionViewLayoutUpdateKey.self] = newValue
        }
    }
    
    private struct CollectionViewLayoutUpdateKey: TransactionKey {
        
        fileprivate typealias Value = CollectionViewLayoutUpdate
        
        fileprivate static var defaultValue: CollectionViewLayoutUpdate {
            CollectionViewLayoutUpdate(needUpdateCollectionViewLayout: false, isAnimated: false)
        }
    }
    
    internal struct CollectionViewLayoutUpdate {
        internal let needUpdateCollectionViewLayout: Bool
        internal let isAnimated: Bool
    }
}

@_silgen_name("_DanceUISetThreadTransactionData")
@inline(__always)
@available(iOS 13.0, *)
internal func _setThreadTransactionData(_: UnsafeMutableRawPointer?)

@_silgen_name("_DanceUIThreadTransactionData")
@inline(__always)
@available(iOS 13.0, *)
internal func _threadTransactionData() -> UnsafeMutableRawPointer?
