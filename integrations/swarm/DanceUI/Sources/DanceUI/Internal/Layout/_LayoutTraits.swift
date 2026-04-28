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
public struct _LayoutTraits: Equatable {

    @inline(__always)
    internal var width: Dimension {
        willSet {
            newValue._checkInvariant()
        }
        didSet {
            flexibilityEstimate.h = FlexibilityEstimate(minLength: width.min, maxLength: width.max)
        }
    }

    @inline(__always)
    internal var height: Dimension {
        willSet {
            newValue._checkInvariant()
        }
        didSet {
            flexibilityEstimate.v = FlexibilityEstimate(minLength: height.min, maxLength: height.max)
        }
    }

    internal var spacing: Spacing

    internal var flexibilityEstimate: FlexibilityEstimate.InEachAxis
    
    internal init(width: Dimension, height: Dimension, spacing: Spacing) {
        self.width = width
        self.height = height
        self.spacing = spacing
        self.flexibilityEstimate = FlexibilityEstimate.InEachAxis(
            h: FlexibilityEstimate(minLength: width.min, maxLength: width.max),
            v: FlexibilityEstimate(minLength: height.min, maxLength: height.max)
        )
    }
    
    internal struct Dimension: Equatable {
        
        internal var min: CGFloat
        
        internal var ideal: CGFloat
        
        internal var max: CGFloat
        
        @inline(never)
        fileprivate func _checkInvariant() {
            _danceuiPrecondition(max >= min)
            _danceuiPrecondition(max >= ideal)
            _danceuiPrecondition(ideal >= min)
            _danceuiPrecondition(min >= min)
            _danceuiPrecondition(.infinity >= min)
            _danceuiPrecondition(.infinity >= ideal)
        }
        
    }
    
    internal struct FlexibilityEstimate: Equatable {
        
        internal struct InEachAxis: Equatable {
            
            internal var h: FlexibilityEstimate
            
            internal var v: FlexibilityEstimate
            
        }
        
        internal let minLength: CGFloat
        
        internal let maxLength: CGFloat
        
    }
}

@available(iOS 13.0, *)
extension _LayoutTraits : CustomStringConvertible {
    
    public var description: String {
        var components = [String]()
        components.append("width = (.min = \(width.min), .ideal = \(width.ideal), .max = \(width.max))")
        components.append("height = (.min = \(height.min), .ideal = \(height.ideal), .max = \(height.max))")
        if !spacing.minima.isEmpty {
            components.append("spacing:")
            let spacingDescriptionComponents = spacing.minima.map { (k, v) in
                "\t(.category = \(k.category.map {"\($0.description)"} ?? "nil"), .edge = \(k.edge)) = \(v)"
            }
            components.append(contentsOf: spacingDescriptionComponents)
        }
        components.append("flexibilityEstimate.h = (.minLength = \(flexibilityEstimate.h.minLength), .maxLength = \(flexibilityEstimate.h.maxLength))")
        components.append("flexibilityEstimate.v = (.minLength = \(flexibilityEstimate.v.minLength), .maxLength = \(flexibilityEstimate.v.maxLength))")
        return "\(type(of: self)):\n\t\(components.joined(separator: "\n\t"))"
    }
    
}
