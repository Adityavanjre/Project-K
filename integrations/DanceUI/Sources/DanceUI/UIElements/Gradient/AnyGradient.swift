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
internal import DanceUIRuntime


/// A color gradient.
///
/// When used as a ``ShapeStyle``, this type draws a linear gradient
/// with start-point [0.5, 0] and end-point [0.5, 1].
@frozen
@available(iOS 13.0, *)
public struct AnyGradient: Equatable, ShapeStyle {
    
    internal var provider: AnyGradientBox
    
    /// Creates a new instance from the specified gradient.
    public init(_ gradient: Gradient) {
        self.provider = GradientBox(gradient)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        provider.apply(to: &shape)
    }
    
    public static func == (lhs: AnyGradient, rhs: AnyGradient) -> Bool {
        lhs.provider.isEqual(to: rhs.provider)
    }
}

// swift-format-ignore: UseSynthesizedInitializer
@frozen
@available(iOS 13.0, *)
public struct _AnyLinearGradient: Paint {
    
    @usableFromInline
    internal var gradient: AnyGradient
    
    @usableFromInline
    internal var startPoint: UnitPoint
    
    @usableFromInline
    internal var endPoint: UnitPoint
    
    @inlinable internal init(gradient: AnyGradient, startPoint: UnitPoint, endPoint: UnitPoint) {
        self.gradient = gradient
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    internal func resolvePaint(in environment: EnvironmentValues) -> LinearGradient._Paint {
        let resolvedGradient = gradient.provider.resolve(in: environment)
        return LinearGradient._Paint(gradient: resolvedGradient,
                                     startPoint: startPoint,
                                     endPoint: endPoint)
    }
}

// swift-format-ignore: UseSynthesizedInitializer
@frozen
@available(iOS 13.0, *)
public struct _AnyRadialGradient: Paint {
    
    @usableFromInline
    internal var gradient: AnyGradient
    
    @usableFromInline
    internal var center: UnitPoint
    
    @usableFromInline
    internal var startRadius: CGFloat
    
    @usableFromInline
    internal var endRadius: CGFloat
    
    @inlinable
    internal init(gradient: AnyGradient, center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat) {
        self.gradient = gradient
        self.center = center
        self.startRadius = startRadius
        self.endRadius = endRadius
    }
    
    internal func resolvePaint(in environment: EnvironmentValues) -> RadialGradient._Paint {
        let resolvedGradient = gradient.provider.resolve(in: environment)
        return RadialGradient._Paint(gradient: resolvedGradient,
                                     center: center,
                                     startRadius: startRadius,
                                     endRadius: endRadius)
    }
}

// swift-format-ignore: UseSynthesizedInitializer
@frozen
@available(iOS 13.0, *)
public struct _AnyAngularGradient: Paint {
    
    @usableFromInline
    internal var gradient: AnyGradient
    
    @usableFromInline
    internal var center: UnitPoint
    
    @usableFromInline
    internal var startAngle: Angle
    
    @usableFromInline
    internal var endAngle: Angle
    
    @usableFromInline
    internal init(gradient: AnyGradient, center: UnitPoint, startAngle: Angle, endAngle: Angle) {
        self.gradient = gradient
        self.center = center
        self.startAngle = startAngle
        self.endAngle = endAngle
    }
    
    internal func resolvePaint(in environment: EnvironmentValues) -> AngularGradient._Paint {
        let resolvedGradient = gradient.provider.resolve(in: environment)
        return AngularGradient._Paint(gradient: resolvedGradient,
                                      center: center,
                                      startAngle: startAngle,
                                      endAngle: endAngle)
    }
}

@frozen
@available(iOS 13.0, *)
public struct _AnyEllipticalGradient: Paint {
    @usableFromInline
    internal var gradient: AnyGradient
    
    @usableFromInline
    internal var center: UnitPoint
    
    @usableFromInline
    internal var startRadiusFraction: CGFloat
    
    @usableFromInline
    internal var endRadiusFraction: CGFloat
    
    @inlinable
    internal init(gradient: AnyGradient, center: UnitPoint = .center, startRadiusFraction: CGFloat, endRadiusFraction: CGFloat) {
        self.gradient = gradient
        self.center = center
        self.startRadiusFraction = startRadiusFraction
        self.endRadiusFraction = endRadiusFraction
    }
    
    internal func resolvePaint(in environment: EnvironmentValues) -> EllipticalGradient._Paint {
        let resolvedGradient = gradient.provider.resolve(in: environment)
        return EllipticalGradient._Paint(gradient: resolvedGradient,
                                         center: center,
                                         startRadiusFraction: startRadiusFraction, 
                                         endRadiusFraction: endRadiusFraction)
    }
}

@available(iOS 13.0, *)
internal protocol GradientProvider: Paint {
    func resolve(in environment: EnvironmentValues) -> ResolvedGradient
}

@usableFromInline
@available(iOS 13.0, *)
internal class AnyGradientBox: AnyShapeStyleBox {
    
    internal func resolve(in environment: EnvironmentValues) -> ResolvedGradient {
        _abstract(self)
    }
}

@available(iOS 13.0, *)
private final class GradientBox<Provider: GradientProvider>: AnyGradientBox {
    
    fileprivate let base: Provider
    
    fileprivate init(_ base: Provider) {
        self.base = base
    }
    
    fileprivate override func resolve(in environment: EnvironmentValues) -> ResolvedGradient {
        self.base.resolve(in: environment)
    }
    
    fileprivate override func apply(to: inout _ShapeStyle_Shape) {
        self.base._apply(to: &to)
    }
    
    fileprivate override func isEqual(to: AnyShapeStyleBox) -> Bool {
        guard let rhsBox = to as? GradientBox else {
            return false
        }
        
        let isEqual = DGCompareValues(lhs: base, rhs: rhsBox.base)
        return isEqual
    }
}
