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

/// A type-erased transition.
@frozen
@available(iOS 13.0, *)
public struct AnyTransition {

    internal let box: AnyTransitionBox
    
    internal init(_ box: AnyTransitionBox) {
        self.box = box
    }
    
    internal init<T: Transition>(_ transition: T) {
        self.box = TransitionBox(transition)
    }
    
    /// A transition that inserts by moving in from the leading edge, and
    /// removes by moving out towards the trailing edge.
    ///
    /// - SeeAlso: `AnyTransition.move(edge:)`
    public static var slide : AnyTransition {
        let transition1 = AnyTransition.move(edge: .leading)
        let transition2 = AnyTransition.move(edge: .trailing)
        
        return AnyTransition.asymmetric(insertion: transition1, removal: transition2)
    }
    
    public static var scale : AnyTransition {
        let box = TransitionBox<ModifierTransition<_ScaleEffect>>(.init(activeModifier: .init(scale: minScale, anchor: .center), identityModifier: .init(scale: identityScale, anchor: .center)))
        return .init(box)
    }
    
    public static func scale(scale: CGFloat, anchor: UnitPoint = .center) -> AnyTransition {
        let box = TransitionBox<ModifierTransition<_ScaleEffect>>(.init(activeModifier: .init(scale: .init(width: scale, height: scale), anchor: anchor), identityModifier: .init(scale: .init(width: 1, height: 1), anchor: .center)))
        return .init(box)
    }
    
    /// A transition from transparent to opaque on insertion, and from opaque to
    /// transparent on removal.
    public static var opacity: AnyTransition {
        let box = TransitionBox<ModifierTransition<_OpacityEffect>>(.init(activeModifier: .init(opacity: 0), identityModifier: .init(opacity: 1)))
        return .init(box)
    }
    
    public static func offset(x: CGFloat, y: CGFloat) -> AnyTransition {
        let box = TransitionBox<ModifierTransition<_OffsetEffect>>(.init(activeModifier: .init(offset: CGSize(width: x, height: y)), identityModifier: .init(offset: .zero)))
        return .init(box)
    }
    
    public static func offset(_ offset: CGSize) -> AnyTransition {
        let box = TransitionBox<ModifierTransition<_OffsetEffect>>(.init(activeModifier: .init(offset: offset), identityModifier: .init(offset: .zero)))
        return .init(box)
    }
    
    /// Returns a transition that moves the view away, towards the specified
    /// edge of the view.
    public static func move(edge: Edge) -> AnyTransition {
        let box = TransitionBox<MoveTransition>(.init(edge: edge))
        return .init(box)
    }
    
    /// Returns a transition defined between an active modifier and an identity
    /// modifier.
    public static func modifier<Modifier: ViewModifier>(active: Modifier, identity: Modifier) -> AnyTransition {
        let box = TransitionBox<ModifierTransition<Modifier>>(.init(activeModifier: active, identityModifier: identity))
        return .init(box)
    }
    
    /// A transition that returns the input view, unmodified, as the output
    /// view.
    public static var identity : AnyTransition {
        let box = TransitionBox<ModifierTransition<EmptyModifier>>(.init(activeModifier: EmptyModifier(), identityModifier: EmptyModifier()))
        return .init(box)
    }
    
    /// Provides a composite transition that uses a different transition for
    /// insertion versus removal.
    public static func asymmetric(insertion: AnyTransition, removal: AnyTransition) -> AnyTransition {
        var visitor = InsertionVisitor(removal: removal, result: nil)
        insertion.box.visitBase(applying: &visitor)
        return visitor.result!
    }
    
    /// Combines this transition with another, returning a new transition that
    /// is the result of both transitions being applied.
    public func combined(with other: AnyTransition) -> AnyTransition {
        var visitor = FirstVisitor(second: other)
        visitBase(applying: &visitor)
        return visitor.result!
    }
    
    /// Attaches an animation to this transition.
    public func animation(_ animation: Animation?) -> AnyTransition {
       transaction { (transaction, _) in
           transaction.animation = animation
       }
    }
    
    internal func visitBase<Visitor: TransitionVisitor>(applying visitor: inout Visitor) -> () {
        box.visitBase(applying: &visitor)
    }
    
    internal func transaction(_ filter: @escaping (inout Transaction, TransitionPhase) -> ()) -> AnyTransition {
        var visitor = FilterVisitor(filter: filter, result: nil)
        visitBase(applying: &visitor)
        return visitor.result!
    }
    
    internal func base<T: Transition>(as type: T.Type) -> T? {
        guard let transitionBox = box as? TransitionBox<T> else {
            return nil
        }
        return transitionBox.base
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Associates a transition with the view.
    @inlinable
    public func transition(_ t: AnyTransition) -> some View {
        return _trait(TransitionTraitKey.self, t)
    }
  
}
