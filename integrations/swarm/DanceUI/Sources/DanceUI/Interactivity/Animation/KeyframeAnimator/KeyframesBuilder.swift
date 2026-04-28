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
@resultBuilder
public struct KeyframesBuilder<Value> {
    
    public static func buildExpression<K: KeyframeTrackContent>(_ expression: K) -> K where Value == K.Value {
        KeyframeTrackContentBuilder.buildExpression(expression)
    }
    
    public static func buildArray(_ components: [some KeyframeTrackContent<Value>]) -> some KeyframeTrackContent<Value> {
        KeyframeTrackContentBuilder.buildArray(components)
    }
  
    public static func buildEither<First: KeyframeTrackContent,
                                   Second: KeyframeTrackContent>(first component: First) -> KeyframeTrackContentBuilder<Value>.Conditional<Value, First, Second> where Value == First.Value, First.Value == Second.Value {
        KeyframeTrackContentBuilder.buildEither(first: component)
    }
    
    public static func buildEither<First: KeyframeTrackContent,
                                   Second: KeyframeTrackContent>(second component: Second) -> KeyframeTrackContentBuilder<Value>.Conditional<Value, First, Second> where Value == First.Value, First.Value == Second.Value {
        KeyframeTrackContentBuilder.buildEither(second: component)
    }
    
    public static func buildPartialBlock<K: KeyframeTrackContent>(first: K) -> K where Value == K.Value {
        KeyframeTrackContentBuilder.buildPartialBlock(first: first)
    }
    public static func buildPartialBlock(accumulated: some KeyframeTrackContent<Value>, 
                                         next: some KeyframeTrackContent<Value>) -> some KeyframeTrackContent<Value> {
        KeyframeTrackContentBuilder.buildPartialBlock(accumulated: accumulated, next: next)
    }
  
    public static func buildBlock() -> some KeyframeTrackContent<Value> where Value: Animatable {
        KeyframeTrackContentBuilder.buildBlock()
    }
  
    public static func buildFinalResult<Content: KeyframeTrackContent>(_ component: Content) -> KeyframeTrack<Value, Value, Content> where Value == Content.Value {
        KeyframeTrack {
            component
        }
    }
    
    public static func buildExpression<Content: Keyframes>(_ expression: Content) -> Content where Value == Content.Value {
        expression
    }
    
    public static func buildPartialBlock<Content: Keyframes>(first: Content) -> Content where Value == Content.Value {
        first
    }
    
    public static func buildPartialBlock(accumulated: some Keyframes<Value>, 
                                         next: some Keyframes<Value>) -> some Keyframes<Value> {
        CombinedKeyframes(first: accumulated, second: next)
    }
  
    public static func buildBlock() -> some Keyframes<Value> {
        EmptyKeyframes<Value>()
    }
  
    public static func buildFinalResult<Content: Keyframes>(_ component: Content) -> Content where Value == Content.Value {
        component
    }
}

