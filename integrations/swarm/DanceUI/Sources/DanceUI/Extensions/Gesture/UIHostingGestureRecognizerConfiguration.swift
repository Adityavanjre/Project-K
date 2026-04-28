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

import UIKit

@available(iOS 13.0, *)
public struct UIHostingGestureRecognizerConfiguration {
    
    /// We cannot use a set to store these weak gesture recognizer
    /// instances. The gesture recognizer instances may vanish. This shall
    /// be reflected in the equatable comparison. However, the hash value
    /// shall not change if we want to implement a better insertion
    /// performance with duplicate detection.
    ///
    private var _gestureRecognizersShouldBeRequiredToFailBy: [ObjectIdentifier: WeakBox<UIGestureRecognizer>]
    
    private var _gestureRecognizersShouldRequireFailureOf: [ObjectIdentifier: WeakBox<UIGestureRecognizer>]
    
    private var _gestureRecognizersShouldRecognizeSimultaneouslyWith: [ObjectIdentifier: WeakBox<UIGestureRecognizer>]
    
    public init() {
        _gestureRecognizersShouldBeRequiredToFailBy = [:]
        _gestureRecognizersShouldRequireFailureOf = [:]
        _gestureRecognizersShouldRecognizeSimultaneouslyWith = [:]
    }
    
    public var gestureRecognizersShouldBeRequiredToFailBy: [UIGestureRecognizer] {
        _gestureRecognizersShouldBeRequiredToFailBy.values.compactMap(\.base)
    }
    
    public var gestureRecognizersShouldRequireFailureOf: [UIGestureRecognizer] {
        _gestureRecognizersShouldRequireFailureOf.values.compactMap(\.base)
    }
    
    public var gestureRecognizersShouldRecognizeSimultaneouslyWith: [UIGestureRecognizer] {
        _gestureRecognizersShouldRecognizeSimultaneouslyWith.values.compactMap(\.base)
    }
    
    // MARK: Setting Up Gesture Dependency with Single UIGestureRecognizer Instance
    
    public func shouldBeRequiredToFail(by gestureRecognizer: UIGestureRecognizer) -> UIHostingGestureRecognizerConfiguration {
        // Removing this API may cause client code build failure.
        // Jojo has a bug that not invalidate the cached built object
        // files linked against a framework in binary form.
        // This bug requires upgrading a binary framework may not
        // introduce ABI break change.
        var copied = self
        let key = ObjectIdentifier(gestureRecognizer)
        copied._gestureRecognizersShouldBeRequiredToFailBy[key] = WeakBox(gestureRecognizer)
        return copied
    }
    
    public func shouldRequireFailure(of gestureRecognizer: UIGestureRecognizer) -> UIHostingGestureRecognizerConfiguration {
        // Removing this API may cause client code build failure.
        // Jojo has a bug that not invalidate the cached built object
        // files linked against a framework in binary form.
        // This bug requires upgrading a binary framework may not
        // introduce ABI break change.
        var copied = self
        let key = ObjectIdentifier(gestureRecognizer)
        copied._gestureRecognizersShouldRequireFailureOf[key] = WeakBox(gestureRecognizer)
        return copied
    }
    
    public func shouldRecognizeSimultaneously(with gestureRecognizer: UIGestureRecognizer) -> UIHostingGestureRecognizerConfiguration {
        // Removing this API may cause client code build failure.
        // Jojo has a bug that not invalidate the cached built object
        // files linked against a framework in binary form.
        // This bug requires upgrading a binary framework may not
        // introduce ABI break change.
        var copied = self
        let key = ObjectIdentifier(gestureRecognizer)
        copied._gestureRecognizersShouldRecognizeSimultaneouslyWith[key] = WeakBox(gestureRecognizer)
        return copied
    }
    
    // MARK: Setting Up Gesture Dependency with Multiple UIGestureRecognizers
    
    public func shouldBeRequiredToFail<S: Sequence>(by gestureRecognizers: S) -> UIHostingGestureRecognizerConfiguration where S.Element : UIGestureRecognizer {
        return self.appendingGestureRecognizers(gestureRecognizers, toDependencyRecordsAt: \._gestureRecognizersShouldBeRequiredToFailBy)
    }
    
    public func shouldRequireFailure<S: Sequence>(of gestureRecognizers: S) -> UIHostingGestureRecognizerConfiguration where S.Element : UIGestureRecognizer {
        return self.appendingGestureRecognizers(gestureRecognizers, toDependencyRecordsAt: \._gestureRecognizersShouldRequireFailureOf)
    }
    
    public func shouldRecognizeSimultaneously<S: Sequence>(with gestureRecognizers: S) -> UIHostingGestureRecognizerConfiguration where S.Element : UIGestureRecognizer {
        return self.appendingGestureRecognizers(gestureRecognizers, toDependencyRecordsAt: \._gestureRecognizersShouldRecognizeSimultaneouslyWith)
    }
    
    // MARK: Setting Up Gesture Dependency with Variadic UIGestureRecognizers
    
    public func shouldBeRequiredToFail(by gestureRecognizers: UIGestureRecognizer?...) -> UIHostingGestureRecognizerConfiguration {
        let nonNilGestureRecognizers = gestureRecognizers.compactMap({$0})
        return self.appendingGestureRecognizers(nonNilGestureRecognizers, toDependencyRecordsAt: \._gestureRecognizersShouldBeRequiredToFailBy)
    }
    
    public func shouldRequireFailure(of gestureRecognizers: UIGestureRecognizer?...) -> UIHostingGestureRecognizerConfiguration {
        let nonNilGestureRecognizers = gestureRecognizers.compactMap({$0})
        return self.appendingGestureRecognizers(nonNilGestureRecognizers, toDependencyRecordsAt: \._gestureRecognizersShouldRequireFailureOf)
    }
    
    public func shouldRecognizeSimultaneously(with gestureRecognizers: UIGestureRecognizer?...) -> UIHostingGestureRecognizerConfiguration {
        let nonNilGestureRecognizers = gestureRecognizers.compactMap({$0})
        return self.appendingGestureRecognizers(nonNilGestureRecognizers, toDependencyRecordsAt: \._gestureRecognizersShouldRecognizeSimultaneouslyWith)
    }
    
    // MARK: Setting Up Gesture Dependency with Optional UIGestureRecognizer
    
    public func shouldBeRequiredToFail(by gestureRecognizer: UIGestureRecognizer?) -> UIHostingGestureRecognizerConfiguration {
        guard let gestureRecognizer else {
            return self
        }
        return shouldBeRequiredToFail(by: gestureRecognizer)
    }
    
    public func shouldRequireFailure(of gestureRecognizer: UIGestureRecognizer?) -> UIHostingGestureRecognizerConfiguration {
        guard let gestureRecognizer else {
            return self
        }
        return shouldRequireFailure(of: gestureRecognizer)
    }
    
    public func shouldRecognizeSimultaneously(with gestureRecognizer: UIGestureRecognizer?) -> UIHostingGestureRecognizerConfiguration {
        guard let gestureRecognizer else {
            return self
        }
        return shouldRecognizeSimultaneously(with: gestureRecognizer)
    }
    
    private mutating func appendGestureRecognizers<S: Sequence>(_ gestureRecognizers: S, toDependencyRecordsAt keyPath: WritableKeyPath<UIHostingGestureRecognizerConfiguration, [ObjectIdentifier: WeakBox<UIGestureRecognizer>]>) where S.Element : UIGestureRecognizer {
        let keyValues = gestureRecognizers.map({(ObjectIdentifier($0), $0)})
        let wantedCapacity = self[keyPath: keyPath].count + keyValues.count
        self[keyPath: keyPath].reserveCapacity(wantedCapacity)
        for (key, value) in keyValues {
            self[keyPath: keyPath][key] = WeakBox(value)
        }
    }
    
    private func appendingGestureRecognizers<S: Sequence>(_ gestureRecognizers: S, toDependencyRecordsAt keyPath: WritableKeyPath<UIHostingGestureRecognizerConfiguration, [ObjectIdentifier: WeakBox<UIGestureRecognizer>]>) -> UIHostingGestureRecognizerConfiguration where S.Element : UIGestureRecognizer {
        var copied = self
        copied.appendGestureRecognizers(gestureRecognizers, toDependencyRecordsAt: keyPath)
        return copied
    }
    
    // MARK: Deprecated APIs
    
    @inlinable
    @_disfavoredOverload
    @available(*, deprecated, message: "Initialize UIHostingGestureRecognizerConfiguration with no parameters directly.")
    public init(shouldBeRequiredToFailBy: Set<UIGestureRecognizer> = [],
                shouldRequireFailureOf: Set<UIGestureRecognizer> = [],
                shouldRecognizeSimultaneouslyWith: Set<UIGestureRecognizer> = []) {
        self = UIHostingGestureRecognizerConfiguration()
            .shouldBeRequiredToFail(by: shouldBeRequiredToFailBy)
            .shouldRequireFailure(of: shouldRequireFailureOf)
            .shouldRecognizeSimultaneously(with: shouldRecognizeSimultaneouslyWith)
    }
    
    @available(*, deprecated, message: "Use gestureRecognizersShouldBeRequiredToFailBy instead.")
    public var shouldBeRequiredToFailBy: Set<ObjectIdentifier> {
        Set(_gestureRecognizersShouldBeRequiredToFailBy.values.compactMap(\.base).map(ObjectIdentifier.init))
    }
    
    @available(*, deprecated, message: "Use gestureRecognizersShouldRequireFailureOf instead.")
    public var shouldRequireFailureOf: Set<ObjectIdentifier> {
        Set(_gestureRecognizersShouldRequireFailureOf.values.compactMap(\.base).map(ObjectIdentifier.init))
    }
    
    @available(*, deprecated, message: "Use gestureRecognizersShouldRecognizeSimultaneouslyWith instead.")
    public var shouldRecognizeSimultaneouslyWith: Set<ObjectIdentifier> {
        Set(_gestureRecognizersShouldRecognizeSimultaneouslyWith.values.compactMap(\.base).map(ObjectIdentifier.init))
    }
    
}
