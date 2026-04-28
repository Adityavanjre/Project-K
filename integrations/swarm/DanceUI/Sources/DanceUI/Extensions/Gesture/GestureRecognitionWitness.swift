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

@available(iOS 13.0, *)
internal enum GestureID: Hashable {
    
    case namespaced(Namespace.ID)
    
    /// Since `Gesture` currently does not support dynamic properties, we cannot
    /// mark a `UIGestureRecognizer` object with a stable `Namespace.ID` with
    /// `Gesture` values. Thus there is `GestureID.identifier`. This is a case
    /// only for internal usages.
    case identifier(ObjectIdentifier)
    
}

@available(iOS 13.0, *)
internal struct GestureRecognitionWitness: Defaultable {
    
    internal typealias Value = GestureRecognitionWitness
    
    internal static var defaultValue: Value { GestureRecognitionWitness() }
    
    /// IDs of `UIGestureRecognizers` should be defered by DanceUI gesture.
    internal var shouldBeRequiredToFailBy: Set<GestureID>
    
    /// IDs of `UIGestureRecognizers` should defer DanceUI gesture.
    internal var shouldRequireFailureOf: Set<GestureID>
    
    /// IDs of `UIGestureRecognizers` should simultaneosly happen with DanceUI gesture.
    internal var shouldRecognizeSimultaneouslyWith: Set<GestureID>
    
    @inlinable
    internal init(shouldBeRequiredToFailBy: Set<GestureID> = Set(),
                  shouldRequireFailureOf: Set<GestureID> = Set(),
                  shouldRecognizeSimultaneouslyWith: Set<GestureID> = Set()) {
        self.shouldBeRequiredToFailBy = shouldBeRequiredToFailBy
        self.shouldRequireFailureOf = shouldRequireFailureOf
        self.shouldRecognizeSimultaneouslyWith = shouldRecognizeSimultaneouslyWith
    }
    
    @inlinable
    internal mutating func merge(with another: GestureRecognitionWitness) {
        shouldBeRequiredToFailBy.formUnion(another.shouldBeRequiredToFailBy)
        shouldRequireFailureOf.formUnion(another.shouldRequireFailureOf)
        shouldRecognizeSimultaneouslyWith.formUnion(another.shouldRecognizeSimultaneouslyWith)
    }
    
    @inlinable
    internal func merged(with another: GestureRecognitionWitness) -> GestureRecognitionWitness {
        var result = self
        result.merge(with: another)
        return result
    }
    
}

@available(iOS 13.0, *)
extension Optional where Wrapped == GestureRecognitionWitness {
    
    internal func merged(with another: GestureRecognitionWitness?) -> GestureRecognitionWitness? {
        switch (self, another) {
        case let (.some(lhs), .some(rhs)):
            return lhs.merged(with: rhs)
        case let (.some(lhs), nil):
            return lhs
        case let (nil, .some(rhs)):
            return rhs
        case (nil, nil):
            return nil
        }
    }
    
}
