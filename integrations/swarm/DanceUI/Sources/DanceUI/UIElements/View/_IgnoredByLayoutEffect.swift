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

@frozen
@available(iOS 13.0, *)
public struct _IgnoredByLayoutEffect<Base>: GeometryEffect where Base: GeometryEffect {
    
    public typealias AnimatableData = Base.AnimatableData
    
    public var base: Base
    
    public static var _affectsLayout: Bool {
        false
    }
    
    @inlinable
    public init(_ base: Base) {
        self.base = base
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        base.effectValue(size: size)
    }
    
    public var animatableData: Base.AnimatableData {
        get {
            base.animatableData
        }
        
        set {
            base.animatableData = newValue
        }
    }
}

@available(iOS 13.0, *)
extension _IgnoredByLayoutEffect: Equatable where Base: Equatable {
    
    public static func == (a: _IgnoredByLayoutEffect<Base>, b: _IgnoredByLayoutEffect<Base>) -> Bool {
        a.base == b.base
    }
}

@available(iOS 13.0, *)
extension GeometryEffect {
    
    /// Returns an effect that produces the same geometry transform as this
    /// effect, but only applies the transform while rendering its view.
    ///
    /// Use this method to disable layout changes during transitions. The view
    /// ignores the transform returned by this method while the view is
    /// performing its layout calculations.
    @inlinable
    public func ignoredByLayout() -> _IgnoredByLayoutEffect<Self> {
        _IgnoredByLayoutEffect(self)
    }
}
