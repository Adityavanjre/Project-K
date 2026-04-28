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
@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
internal protocol ComposeGradient {
    
    func makePaint(edge: EdgeInsets, in environmentValues: EnvironmentValues) -> AnyResolvedPaint
}

@available(iOS 13.0, *)
extension ComposeGradient {
    fileprivate static func createGradient(colors: [UIColor], stops: [Double]? = nil) -> Gradient {
        if let stops, stops.count == colors.count {
            let colorStops = colors.indices.map { idx in
                Gradient.Stop(color: Color(uiColor: colors[idx]), location: stops[idx])
            }
            return Gradient(stops: colorStops)
        } else {
            return Gradient(colors: colors.map(Color.init(uiColor:)))
        }
    }
}

@available(iOS 13.0, *)
extension ComposeShader {
    internal var gradient: ComposeGradient? {
        switch Self.mode {
        case .gradient:
            return self as? ComposeGradient
        default:
            return nil
        }
    }
}

@available(iOS 13.0, *)
@objc(DanceUIComposeLinearGradient)
internal final class ComposeLinearGradient: NSObject, ComposeShader, ComposeGradient {
    
    private let from: CGPoint
    private let to: CGPoint
    private let gradient: Gradient
    private let tileMode: ComposeTileMode
    
    internal init(from: CGPoint, to: CGPoint, colors: [UIColor], stops: [Double]? = nil, tileMode: ComposeTileMode = .clamp) {
        self.from = from
        self.to = to
        self.gradient = ComposeLinearGradient.createGradient(colors: colors, stops: stops)
        self.tileMode = tileMode
    }
    
    internal static var mode: ComposeShaderMode {
        .gradient
    }
    
    internal func makePaint(edge: EdgeInsets, in environmentValues: EnvironmentValues) -> AnyResolvedPaint {
        
        Signpost.compose.tracePoi("LineaerGradient:makePaint", []) {
            let width = edge.trailing - edge.leading
            let height = edge.bottom - edge.top
            
            let start = UnitPoint(x: (from.x - edge.leading) / width, y: (from.y - edge.top) / height)
            let end = UnitPoint(x: (to.x - edge.leading) / width, y: (to.y - edge.top) / height)
            
            let linearGradient = LinearGradient(gradient: gradient, startPoint: start, endPoint: end)
            var resolvedPaint = linearGradient.resolvePaint(in: environmentValues)
            resolvedPaint.setUsePerceptualBlending(false)
            return _AnyResolvedPaint(resolvedPaint)
        }
    }
}

@available(iOS 13.0, *)
@objc(DanceUIComposeRadialGradient)
internal final class ComposeRadialGradient: NSObject, ComposeShader, ComposeGradient {
    
    private let center: CGPoint
    private let radius: CGFloat
    private let gradient: Gradient
    private let tileMode: ComposeTileMode
    
    internal init(center: CGPoint, radius: CGFloat, colors: [UIColor], stops: [Double]? = nil, tileMode: ComposeTileMode = .clamp) {
        self.center = center
        self.radius = radius
        self.gradient = ComposeRadialGradient.createGradient(colors: colors, stops: stops)
        self.tileMode = tileMode
    }
    
    internal static var mode: ComposeShaderMode {
        .gradient
    }
    
    internal func makePaint(edge: EdgeInsets, in environmentValues: EnvironmentValues) -> AnyResolvedPaint {
        Signpost.compose.tracePoi("RadialGradient:makePaint", []) {
            let centerPoint = UnitPoint(x: (center.x - edge.leading) / (edge.bottom - edge.leading), y: (center.y - edge.top) / (edge.bottom - edge.top))
            
            let radialGradient = RadialGradient(gradient: gradient, center: centerPoint, startRadius: 0, endRadius: radius)
            var resolvedPaint = radialGradient.resolvePaint(in: environmentValues)
            resolvedPaint.setUsePerceptualBlending(false)
            return _AnyResolvedPaint(resolvedPaint)
        }
    }
    
}

@available(iOS 13.0, *)
@objc(DanceUIComposeSweepGradient)
internal final class ComposeSweepGradient: NSObject, ComposeShader, ComposeGradient {
    
    private let center: CGPoint
    private let gradient: Gradient
    
    internal init(center: CGPoint, colors: [UIColor], stops: [Double]? = nil) {
        self.center = center
        self.gradient = ComposeSweepGradient.createGradient(colors: colors, stops: stops)
    }
    
    internal static var mode: ComposeShaderMode {
        .gradient
    }
    
    internal func makePaint(edge: EdgeInsets, in environmentValues: EnvironmentValues) -> AnyResolvedPaint {
        Signpost.compose.tracePoi("SweepGradient:makePaint", []) {
            let centerPoint = UnitPoint(x: (center.x - edge.leading) / (edge.trailing - edge.leading), y: (center.y - edge.top) / (edge.bottom - edge.top))
            
            let angularGradient = AngularGradient(gradient: gradient, center: centerPoint)
            var resolvedPaint = angularGradient.resolvePaint(in: environmentValues)
            resolvedPaint.setUsePerceptualBlending(false)
            return _AnyResolvedPaint(resolvedPaint)
        }
    }
}
