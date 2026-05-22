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

/// A color gradient represented as an array of color stops, each having a
/// parametric location value.
@frozen
@available(iOS 13.0, *)
public struct Gradient : Equatable {

    /// One color stop in the gradient.
    @frozen
    public struct Stop : Equatable {

        /// The color for the stop.
        public var color: Color

        /// The parametric location of the stop.
        ///
        /// This value must be in the range `[0, 1]`.
        public var location: CGFloat

        /// Creates a color stop with a color and location.
        public init(color: Color, location: CGFloat) {
            self.color = color
            self.location = location
        }

        /// Returns a Boolean value indicating whether two values are equal.
        ///
        /// Equality is the inverse of inequality. For any values `a` and `b`,
        /// `a == b` implies that `a != b` is `false`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func == (a: Stop, b: Stop) -> Bool {
            let sameColor = a.color._box.isEqual(to: b.color._box)
            let sameLocation = a.location == b.location
            return sameColor && sameLocation
        }
    }

    /// The array of color stops.
    // 0x0
    public var stops: [Stop]

    /// Creates a gradient from an array of color stops.
    public init(stops: [Stop]) {
#if DEBUG || DANCE_UI_INHOUSE
        if isLocationUnOrdered(stops: stops) {
            runtimeIssue(type: .warning, "Gradient stop locations must be ordered.")
        }
#endif
        self.stops = stops
    }

    /// Creates a gradient from an array of colors.
    ///
    /// The gradient synthesizes its location values to evenly space the colors
    /// along the gradient.
    public init(colors: [Color]) {
        
        let elementCount = colors.count
        
        if elementCount > 0 {
            
            let stopsValue: [Stop] = colors.enumerated().map { item -> Stop in
                if elementCount == 1 {
                    return Stop.init(color: item.element, location: 0)
                } else {
                    let base = 1.0 / CGFloat(elementCount - 1)
                    let location = CGFloat(item.offset) * base
                    return Stop.init(color: item.element, location: location)
                }
            }
            
            self.stops = stopsValue
        } else {
            self.stops = []
        }
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Gradient, rhs: Gradient) -> Bool {
        lhs.stops == rhs.stops
    }
    
    internal func resolve(in environment: EnvironmentValues) -> ResolvedGradient {
        
        guard self.stops.count > 0 else {
            return ResolvedGradient(stops: [], colorSpace: .perceptual)
        }
        
        let resolvedColorStops = self.stops.map({
            ResolvedGradient.Stop(color: $0.color._box.resolve(in: environment),
                                  location: $0.location)
        })
        
        return ResolvedGradient(stops: resolvedColorStops, colorSpace: .perceptual)
    }
}

@available(iOS 13.0, *)
private func isLocationUnOrdered(stops: [Gradient.Stop]) -> Bool {
    stops.indices.contains { index in
        if index == 0 {
            return false
        }
        return stops[index - 1].location > stops[index].location
    }
}

@available(iOS 13.0, *)
extension Gradient: GradientProvider {
    internal func resolvePaint(in environment: EnvironmentValues) -> LinearGradient._Paint {
        LinearGradient._Paint(gradient: self.resolve(in: environment),
                              startPoint: .top,
                              endPoint: .bottom)
    }
}

@available(iOS 13.0, *)
extension Gradient : Hashable {
}

@available(iOS 13.0, *)
extension Gradient.Stop : Hashable {
}
