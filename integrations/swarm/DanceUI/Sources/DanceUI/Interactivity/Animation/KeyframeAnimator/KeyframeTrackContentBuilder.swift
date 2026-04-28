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

/// A group of keyframes that define an interpolation curve of an animatable
/// value.
@available(iOS 13.0, *)
public protocol KeyframeTrackContent<Value> {

    associatedtype Value: Animatable = Self.Body.Value

    associatedtype Body: KeyframeTrackContent

    /// The composition of content that comprise the keyframe track.
    @KeyframeTrackContentBuilder<Self.Value>
    var body: Self.Body { get }
    
    func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<Self.Value>)
}

@available(iOS 13.0, *)
internal protocol PrimitiveKeyframeTrackContent: KeyframeTrackContent where Body == Self {
    
}

@available(iOS 13.0, *)
extension PrimitiveKeyframeTrackContent {

    public var body: Body {
        self.body
    }
}

/// The builder that creates keyframe track content from the keyframes
/// that you define within a closure.
@available(iOS 13.0, *)
@resultBuilder
public struct KeyframeTrackContentBuilder<Value: Animatable> {
    public static func buildExpression<K: KeyframeTrackContent>(_ expression: K) -> K where Value == K.Value {
        expression
    }
    
    public static func buildArray(_ components: [some KeyframeTrackContent<Value>]) -> some KeyframeTrackContent<Value> {
        ArrayKeyframeTrackContent(content: components)
    }
  
    public static func buildEither<First: KeyframeTrackContent,
                                   Second: KeyframeTrackContent>(first component: First) -> Conditional<Value, First, Second> where Value == First.Value, First.Value == Second.Value {
        Conditional(storage: .first(component))
    }
    
    public static func buildEither<First: KeyframeTrackContent,
                                   Second: KeyframeTrackContent>(second component: Second) -> Conditional<Value, First, Second> where Value == First.Value, First.Value == Second.Value {
        Conditional(storage: .second(component))
    }
    
    public static func buildPartialBlock<K: KeyframeTrackContent>(first: K) -> K where Value == K.Value {
        first
    }
    
    public static func buildPartialBlock(accumulated: some KeyframeTrackContent<Value>, 
                                         next: some KeyframeTrackContent<Value>) -> some KeyframeTrackContent<Value> {
        MergedKeyframeTrackContent(first: accumulated, second: next)
    }
  
    public static func buildBlock() -> some KeyframeTrackContent<Value> {
        EmptyKeyframeTrackContent<Value>()
    }
  
}

@available(iOS 13.0, *)
extension KeyframeTrackContentBuilder {
    
    @available(iOS 13.0, *)
    public struct Conditional<ConditionalValue,
                              First: KeyframeTrackContent,
                              Second: KeyframeTrackContent>: PrimitiveKeyframeTrackContent where ConditionalValue == First.Value, First.Value == Second.Value {
        
        public typealias Value = ConditionalValue
        
        fileprivate var storage: Storage
        
        public func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<ConditionalValue>) {
            switch storage {
            case .first(let first):
                first._resolve(into: &resolved)
            case .second(let second):
                second._resolve(into: &resolved)
            }
        }
        
        fileprivate enum Storage {
            case first(First)
            case second(Second)
        }
    }
}

@available(iOS 13.0, *)
internal struct ArrayKeyframeTrackContent<V: Animatable, Content: KeyframeTrackContent>: PrimitiveKeyframeTrackContent where Content.Value == V {

    internal typealias Value = V
    
    internal var content: [Content]

    internal func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<V>) {
        for c in content {
            c._resolve(into: &resolved)
        }
    }

}

@available(iOS 13.0, *)
internal struct MergedKeyframeTrackContent<V: Animatable,
                                           First: KeyframeTrackContent,
                                           Second: KeyframeTrackContent>: PrimitiveKeyframeTrackContent where First.Value == V, Second.Value == V {
    internal typealias Value = V
    
    internal var first: First

    internal var second: Second

    internal func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<V>) {
        first._resolve(into: &resolved)
        second._resolve(into: &resolved)
    }
}

@available(iOS 13.0, *)
internal struct EmptyKeyframeTrackContent<V: Animatable>: PrimitiveKeyframeTrackContent {
    
    internal typealias Value = V
    
    internal typealias Body = Self
    
    internal func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<V>) {
        _intentionallyLeftBlank()
    }

}
