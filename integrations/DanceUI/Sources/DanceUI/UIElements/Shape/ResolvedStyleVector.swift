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
internal enum ResolvedStyleVector: VectorArithmetic {
    
    case color(AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, Float>>>)

    case linearGradient(AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>)

    case radialGradient(AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>)

    case ellipticalGradient(AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>)

    case angularGradient(AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<Double, Double>>)

    indirect case scalar((Double, ResolvedStyleVector))

    case array([ResolvedStyleVector])

    case zero
    
    fileprivate mutating func negate() {
        switch self {
        case .color(let animatableData):
            let pairTwo = AnimatablePair(-animatableData.second.second.first, -animatableData.second.second.second)
            self = .color(AnimatablePair(-animatableData.first, AnimatablePair(-animatableData.second.first, pairTwo)))
        case .linearGradient(let animatableData):
            let pairOne = AnimatablePair(-animatableData.first.first, -animatableData.first.second)
            let pairTwo = AnimatablePair(-animatableData.second.first, -animatableData.second.second)
            self = .linearGradient(AnimatablePair(pairOne, pairTwo))
        case .radialGradient(let animatableData):
            let pairOne = AnimatablePair(-animatableData.first.first, -animatableData.first.second)
            let pairTwo = AnimatablePair(-animatableData.second.first, -animatableData.second.second)
            self = .radialGradient(AnimatablePair(pairOne, pairTwo))
        case .ellipticalGradient(let animatableData):
            let pairOne = AnimatablePair(-animatableData.first.first, -animatableData.first.second)
            let pairTwo = AnimatablePair(-animatableData.second.first, -animatableData.second.second)
            self = .ellipticalGradient(AnimatablePair(pairOne, pairTwo))
        case .angularGradient(let animatableData):
            let pairOne = AnimatablePair(-animatableData.first.first, -animatableData.first.second)
            let pairTwo = AnimatablePair(-animatableData.second.first, -animatableData.second.second)
            self = .angularGradient(AnimatablePair(pairOne, pairTwo))
        case .scalar((let value, let style)):
            var newStyle = style
            newStyle.negate()
            self = .scalar((-value, newStyle))
        case .array(let vectorArray):
            let newVectorArray = vectorArray.map { vector in
                var newVector: ResolvedStyleVector = .zero
                newVector -= vector
                return newVector
            }
            self = .array(newVectorArray)
        default:
            break
        }
    }
    
    internal init(style: _ShapeStyle_Shape.ResolvedStyle) {
        switch style {
        case .color(let color):
            self = .color(color.animatableData)
        case .paint(let resolvedPaint):
            var emptyVector: ResolvedStyleVector = .zero
            let pointer = withUnsafeMutablePointer(to: &emptyVector) { ptr in
                ptr
            }
            var paintInitVisitor = PaintInitVisitor(result: pointer)
            resolvedPaint.visit(&paintInitVisitor)
            self = paintInitVisitor.result.pointee
//        case .foregroundMaterial((let color, _)):
//            self = .color(color.animatableData)
//        case .backgroundMaterial(_):
//            self = .zero
        case .array(let styles):
            guard !styles.isEmpty else {
                self = .array([])
                return
            }
            self = .array(styles.map({.init(style: $0)}))
//        case .blend((_, let resolvedStyle)):
//            self = .init(style: resolvedStyle)
        case .opacity((let opacity, let style)):
            self = .scalar((Double(opacity * 128),
                            ResolvedStyleVector(style: style)))
//        case .multicolor(_):
//            self = .zero
        }
    }
    
    internal func set(style: inout _ShapeStyle_Shape.ResolvedStyle) {
        switch style {
        case .color(let resolvedColor):
            if case .color(let animatedData) = self {
                var newColor = resolvedColor
                newColor.animatableData = animatedData
                style = .color(newColor)
            } else {
                style = .color(Color.Resolved.init())
            }
        case .paint(let resolvedPaint):
            switch self {
            case .linearGradient(let animatableData):
                var paintSetVisitor = PaintSetVisitor<LinearGradient._Paint>(data: animatableData, result: style)
                resolvedPaint.visit(&paintSetVisitor)
                style = paintSetVisitor.result
            case .radialGradient(let animatableData):
                var paintSetVisitor = PaintSetVisitor<RadialGradient._Paint>(data: animatableData, result: style)
                resolvedPaint.visit(&paintSetVisitor)
                style = paintSetVisitor.result
            case .ellipticalGradient(let animatableData):
                var paintSetVisitor = PaintSetVisitor<EllipticalGradient._Paint>(data: animatableData, result: style)
                resolvedPaint.visit(&paintSetVisitor)
                style = paintSetVisitor.result
            case .angularGradient(let animatableData):
                var paintSetVisitor = PaintSetVisitor<AngularGradient._Paint>(data: animatableData, result: style)
                resolvedPaint.visit(&paintSetVisitor)
                style = paintSetVisitor.result
            default:
                style = .color(Color.Resolved.init())
            }
//        case .foregroundMaterial((let resolvedColor, _)):
//            switch self {
//            case .color(let animatableData):
//                var newColor = resolvedColor
//                newColor.animatableData = animatableData
//                style = .color(newColor)
//            case .zero:
//                break
//            default:
//                style = .color(Color.Resolved.init())
//            }
        case .array(let styles):
            switch self {
            case .array(let vectors):
                guard !styles.isEmpty else {
                    return
                }
                
                if vectors.isEmpty {
                    let zeroVector: ResolvedStyleVector = .zero
                    let resolvedStyles = styles.map { style in
                        var copyStyle = style
                        zeroVector.set(style: &copyStyle)
                        return copyStyle
                    }
                    style = .array(resolvedStyles)
                } else {
                    guard styles.count == vectors.count else {
                        _danceuiFatalError("Styles count is not equal to vectors count.")
                    }
                    
                    var copyStyles = styles
                    for (index, vector) in vectors.enumerated() {
                        vector.set(style: &copyStyles[index])
                    }
                    style = .array(copyStyles)
                }
            case .zero:
                let resolvedStyles = styles.map { style in
                    var copyStyle = style
                    self.set(style: &copyStyle)
                    return copyStyle
                }
                style = .array(resolvedStyles)
            default:
                style = .color(Color.Resolved.init())
            }
            
        case .opacity((_, let nestedStyle)):
            var resolvedStyle = nestedStyle
            if case .scalar((let value, let vector)) = self {
                vector.set(style: &resolvedStyle)
                style = .opacity((Float(value * 0.0078125), resolvedStyle))
            } else {
                style = .color(Color.Resolved.init())
            }
//        case .multicolor(_):
//             .backgroundMaterial(_),
//            break
        }
    }
    
    internal mutating func scale(by scaleValue: Double) {
        guard scaleValue != 1 else {
            return // BDCOV_EXCL_LINE 覆盖率抖动
        }
        
        switch self {
        case .color(let animatableData):
            var newAnimatableData = animatableData
            newAnimatableData.scale(by: scaleValue)
            self = .color(newAnimatableData)
        case .linearGradient(let animatableData):
            var newAnimatableData = animatableData
            newAnimatableData.scale(by: scaleValue)
            self = .linearGradient(newAnimatableData)
        case .radialGradient(let animatableData):
            var newAnimatableData = animatableData
            newAnimatableData.scale(by: scaleValue)
            self = .radialGradient(newAnimatableData)
        case .ellipticalGradient(let animatableData):
            var newAnimatableData = animatableData
            newAnimatableData.scale(by: scaleValue)
            self = .ellipticalGradient(newAnimatableData)
        case .angularGradient(let animatableData):
            var newAnimatableData = animatableData
            newAnimatableData.scale(by: scaleValue)
            self = .angularGradient(newAnimatableData)
        case .scalar((let value, let vector)):
            var newVector = vector
            newVector.scale(by: scaleValue)
            self = .scalar((value * scaleValue, newVector))
        case .array(let array):
            guard !array.isEmpty else {
                self = .array([])
                return
            }
            
            let newVectors = array.map { vector -> ResolvedStyleVector in
                var newVector = vector
                newVector.scale(by: scaleValue)
                return newVector
            }
            self = .array(newVectors)
        case .zero:
            break
        }
    }
    
    internal var magnitudeSquared: Double {
        switch self {
        case .color(let animatableData):
            return animatableData.magnitudeSquared
        case .linearGradient(let animatableData),
             .radialGradient(let animatableData),
             .ellipticalGradient(let animatableData):
            return animatableData.magnitudeSquared
        case .angularGradient(let animatableData):
            return animatableData.magnitudeSquared
        case .scalar((let value, let vector)):
            return value.magnitudeSquared + vector.magnitudeSquared
        case .array(let array):
            guard !array.isEmpty else {
                return 0
            }
            
            let result = array.reduce(0) { partialResult, nextVector in
                partialResult + nextVector.magnitudeSquared
            }
            return result
        case .zero:
            return 0
        }
    }
    
#if DEBUG
    internal var _descriptionComponents: [String] {
        switch self {
        case .color(let animatableData):
            return animatableData._descriptionComponents
        case .linearGradient(let animatableData),
             .radialGradient(let animatableData),
             .ellipticalGradient(let animatableData):
            return animatableData._descriptionComponents
        case .angularGradient(let animatableData):
            return animatableData._descriptionComponents
        case .scalar((let value, let vector)):
            return value._descriptionComponents + vector._descriptionComponents
        case .array(let array):
            guard !array.isEmpty else {
                return []
            }
            
            let result = array.reduce([]) { partialResult, nextVector in
                partialResult + nextVector._descriptionComponents
            }
            return result
        case .zero:
            return []
        }
    }
    
    internal static var _typeDescriptionComponents: [String] {
        return ["\(Self.self)"]
    }
#endif
    
    internal static func += (lhs: inout ResolvedStyleVector, rhs: ResolvedStyleVector) {
        guard rhs != .zero else {
            return
        }
        
        switch lhs {
        case .color(let lhsAnimatableData):
            switch rhs {
            case .color(let rhsAnimatableData):
                lhs = .color(lhsAnimatableData + rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs += firstVector
            default:
                break
            }
        case .linearGradient(let lhsAnimatableData):
            switch rhs {
            case .linearGradient(let rhsAnimatableData):
                lhs = .linearGradient(lhsAnimatableData + rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs += firstVector
            default:
                break
            }
        case .radialGradient(let lhsAnimatableData):
            switch rhs {
            case .radialGradient(let rhsAnimatableData):
                lhs = .radialGradient(lhsAnimatableData + rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs += firstVector
            default:
                break
            }
        case .ellipticalGradient(let lhsAnimatableData):
            switch rhs {
            case .ellipticalGradient(let rhsAnimatableData):
                lhs = .ellipticalGradient(lhsAnimatableData + rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs += firstVector
            default:
                break
            }
        case .angularGradient(let lhsAnimatableData):
            switch rhs {
            case .angularGradient(let rhsAnimatableData):
                lhs = .angularGradient(lhsAnimatableData + rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs += firstVector
            default:
                break
            }
        case .scalar((var lhsScale, var lhsStyle)):
            switch rhs {
            case .scalar((let rhsScale, let rhsStyle)):
                lhsStyle += rhsStyle
                lhsScale += rhsScale
                lhs = .scalar((lhsScale, lhsStyle))
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs += firstVector
            default :
                break
            }
            
        case .array(let lhsArray):
            switch rhs {
            case .array(let rhsArray):
                guard !rhsArray.isEmpty,
                      !lhsArray.isEmpty,
                      lhsArray.count == rhsArray.count else {
                    return
                }
                
                var newItem: [ResolvedStyleVector] = []
                for (index, item) in lhsArray.enumerated() {
                    var leftItem = item
                    let rightItem = rhsArray[index]
                    leftItem += rightItem
                    newItem.append(leftItem)
                }
                lhs = .array(newItem)
                
            default:
                let newArray: [ResolvedStyleVector] = lhsArray.map { item in
                    var newItem = item
                    newItem += rhs
                    return newItem
                }
                lhs = .array(newArray)
            }
        case .zero:
            lhs = rhs
        }
    }
    
    
    internal static func -= (lhs: inout ResolvedStyleVector, rhs: ResolvedStyleVector) {
        guard rhs != .zero else {
            return
        }
        
        switch lhs {
        case .color(let lhsAnimatableData):
            switch rhs {
            case .color(let rhsAnimatableData):
                lhs = .color(lhsAnimatableData - rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs -= firstVector
            default:
                break
            }
        case .linearGradient(let lhsAnimatableData):
            switch rhs {
            case .linearGradient(let rhsAnimatableData):
                lhs = .linearGradient(lhsAnimatableData - rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs -= firstVector
            default:
                break
            }
        case .radialGradient(let lhsAnimatableData):
            switch rhs {
            case .radialGradient(let rhsAnimatableData):
                lhs = .radialGradient(lhsAnimatableData - rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs -= firstVector
            default:
                break
            }
        case .ellipticalGradient(let lhsAnimatableData):
            switch rhs {
            case .ellipticalGradient(let rhsAnimatableData):
                lhs = .ellipticalGradient(lhsAnimatableData - rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs -= firstVector
            default:
                break
            }
        case .angularGradient(let lhsAnimatableData):
            switch rhs {
            case .angularGradient(let rhsAnimatableData):
                lhs = .angularGradient(lhsAnimatableData - rhsAnimatableData)
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs -= firstVector
            default:
                break
            }
        case .scalar((var lhsScale, var lhsStyle)):
            switch rhs {
            case .scalar((let rhsScale, let rhsStyle)):
                lhsStyle -= rhsStyle
                lhsScale -= rhsScale
                lhs = .scalar((lhsScale, lhsStyle))
            case .array(let array):
                guard let firstVector = array.first else {
                    return
                }
                
                lhs -= firstVector
            default :
                break
            }

        case .array(let lhsArray):
            switch rhs {
            case .array(let rhsArray):
                guard !rhsArray.isEmpty,
                      !lhsArray.isEmpty,
                      lhsArray.count == rhsArray.count else {
                    return
                }
                
                var newItem: [ResolvedStyleVector] = []
                for (index, item) in lhsArray.enumerated() {
                    var leftItem = item
                    let rightItem = rhsArray[index]
                    leftItem -= rightItem
                    newItem.append(leftItem)
                }
                lhs = .array(newItem)
                
            default:
                let newArray: [ResolvedStyleVector] = lhsArray.map { item in
                    var newItem = item
                    newItem -= rhs
                    return newItem
                }
                lhs = .array(newArray)
            }
        case .zero:
            guard rhs != .zero else {
                break
            }
            var result = rhs
            result.negate()
            lhs = result
        }
    }
    
    internal static func == (lhs: ResolvedStyleVector, rhs: ResolvedStyleVector) -> Bool {
        switch lhs {
        case .color(let lhsAnimatableData):
            guard case .color(let rhsAnimatableData) = rhs else {
                return false
            }

            return lhsAnimatableData == rhsAnimatableData
        case .linearGradient(let lhsAnimatableData):
            guard case .linearGradient(let rhsAnimatableData) = rhs else {
                return false
            }

            return lhsAnimatableData == rhsAnimatableData
        case .radialGradient(let lhsAnimatableData):
            guard case .radialGradient(let rhsAnimatableData) = rhs else {
                return false
            }

            return lhsAnimatableData == rhsAnimatableData
        case .ellipticalGradient(let lhsAnimatableData):
            guard case .ellipticalGradient(let rhsAnimatableData) = rhs else {
                return false
            }
            
            return lhsAnimatableData == rhsAnimatableData
        case .angularGradient(let lhsAnimatableData):
            guard case .angularGradient(let rhsAnimatableData) = rhs else {
                return false
            }
            
            return lhsAnimatableData == rhsAnimatableData
        case .scalar((let lhsValue, let lhsVector)):
            guard case .scalar((let rhsValue, let rhsVector)) = rhs else {
                return false
            }
            
            return lhsValue == rhsValue && lhsVector == rhsVector
        case .array(let lhsArray):
            guard case .array(let rhsArray) = rhs else {
                return false
            }
            
            return lhsArray == rhsArray
        case .zero:
            guard case .zero = rhs else {
                return false
            }
            
            return true
        }
    }
    
    internal static func + (lhs: ResolvedStyleVector, rhs: ResolvedStyleVector) -> ResolvedStyleVector {
        var ret = lhs
        ret += rhs
        return ret
    }
    
    internal static func - (lhs: ResolvedStyleVector, rhs: ResolvedStyleVector) -> ResolvedStyleVector {
        var ret = lhs
        ret -= rhs
        return ret
    }
    
    fileprivate struct PaintInitVisitor: ResolvedPaintVisitor {
        
        fileprivate var result: UnsafeMutablePointer<ResolvedStyleVector>
        
        fileprivate mutating func visitPaint<PaintType>(_ paint: PaintType) where PaintType : ResolvedPaint {
            if let resolvedColor = paint as? Color.Resolved {
                result.pointee = .color(resolvedColor.animatableData)
            } else if let linearGradient = paint as? LinearGradient._Paint {
                result.pointee = .linearGradient(linearGradient.animatableData)
            } else if let radialGradient = paint as? RadialGradient._Paint {
                result.pointee = .radialGradient(radialGradient.animatableData)
            } else if let angularGradient = paint as? AngularGradient._Paint {
                result.pointee = .angularGradient(angularGradient.animatableData)
            } else if let ellipticalGradient = paint as? EllipticalGradient._Paint {
                result.pointee = .ellipticalGradient(ellipticalGradient.animatableData)
            } else {
                
            }
        }
    }
    
    fileprivate struct PaintSetVisitor<P: ResolvedPaint>: ResolvedPaintVisitor {
        
        fileprivate var data: P.AnimatableData
        
        fileprivate var result: _ShapeStyle_Shape.ResolvedStyle
        
        fileprivate mutating func visitPaint<PaintType>(_ paint: PaintType) where PaintType : ResolvedPaint {
            if var realPaint = paint as? P {
                realPaint.animatableData = self.data
                let anyResolvedPaint = _AnyResolvedPaint(realPaint)
                result = .paint(anyResolvedPaint)
            }
        }
    }
}
