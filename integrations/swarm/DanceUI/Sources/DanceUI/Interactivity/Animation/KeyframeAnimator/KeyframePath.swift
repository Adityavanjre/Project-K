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

/// A type that defines changes to a value over time.
#if compiler(>=5.3) && $PrimaryAssociatedTypes2
@available(iOS 13.0, *)
public protocol Keyframes<Value> {
    
  associatedtype Value = Self.Body.Value
    
  associatedtype Body: Keyframes
    
  @KeyframesBuilder<Self.Value> var body: Self.Body { get }
    
  func _resolve(into resolved: inout _ResolvedKeyframes<Self.Value>,
                initialValue: Self.Value,
                initialVelocity: Self.Value?)
}
#else
@available(iOS 13.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public protocol Keyframes {
    
  associatedtype Value = Self.Body.Value
    
  associatedtype Body: Keyframes
    
  @KeyframesBuilder<Self.Value> var body: Self.Body { get }
    
  func _resolve(into resolved: inout _ResolvedKeyframes<Self.Value>,
                initialValue: Self.Value,
                initialVelocity: Self.Value?)
}
#endif

@available(iOS 13.0, *)
extension Swift.Never: PrimitiveKeyframes {
  public func _resolve(into resolved: inout _ResolvedKeyframes<Never>,
                       initialValue: Never,
                       initialVelocity: Never?) {

  }
}

@available(iOS 13.0, *)
internal protocol PrimitiveKeyframes: Keyframes where Body == Never {
    
    
}

@available(iOS 13.0, *)
extension PrimitiveKeyframes {
    public var body: Body {
        fatalError()
    }
}

@available(iOS 13.0, *)
public struct _ResolvedKeyframes<Root> {
    
    internal var tracks: [Track]
    
    internal struct Track {
        
        internal var duration: Double
        
        internal var update: (inout Root, Double) -> Void
        
        internal var updateVelocity: (inout Root, Double) -> Void
        
    }
    
    internal mutating func append<Value: Animatable>(keyPath: WritableKeyPath<Root, Value>,
                                                     animationPath: AnimationPath<Value>) {
        let track = Track(duration: animationPath.duration) { value, duration in
            guard !animationPath.elements.isEmpty else {
                return
            }
            let data = animationPath.animatableData(at: duration)
            value[keyPath: keyPath].animatableData = data
        } updateVelocity: { velocity, duration in
            velocity[keyPath: keyPath].animatableData = animationPath.velocity(at: duration)
        }
        tracks.append(track)
    }
}
