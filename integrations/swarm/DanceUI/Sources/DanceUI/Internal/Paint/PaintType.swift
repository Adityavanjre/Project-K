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
internal enum PaintType {
    
    case color(Color.Resolved)
    
    case linearGradient(LinearGradient._Paint)
    
    case radialGradient(RadialGradient._Paint)
    
    case ellipticalGradient(EllipticalGradient._Paint)
    
    case angularGradient(AngularGradient._Paint)
    
    case other
    
    internal init<Paint: ResolvedPaint>(_ paint: Paint) {
        if let resolved = paint as? Color.Resolved {
            self = .color(resolved)
        } else if let resolved = paint as? LinearGradient._Paint {
            let colorResolved = resolved.gradient.constantColor
            if let color = colorResolved {
                self = .color(color)
            } else {
                self = .linearGradient(resolved)
            }
        } else if let resolved = paint as? RadialGradient._Paint {
            let colorResolved = resolved.gradient.constantColor
            if let color = colorResolved {
                self = .color(color)
            } else {
                self = .radialGradient(resolved)
            }
        } else if let resolved = paint as? AngularGradient._Paint {
            let colorResolved = resolved.gradient.constantColor
            if let color = colorResolved {
                self = .color(color)
            } else {
                self = .angularGradient(resolved)
            }
        } else if let resolved = paint as? EllipticalGradient._Paint {
            let colorResolved = resolved.gradient.constantColor
            if let color = colorResolved {
                self = .color(color)
            } else {
                self = .ellipticalGradient(resolved)
            }
        } else {
            self = .other
        }
    }
    
}
