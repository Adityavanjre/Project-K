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
public struct _ShapeStyle_Shape {
    
    internal var operation: Operation
    
    internal var result: Result
    
    internal var environment: EnvironmentValues
    
    internal var bounds: CGRect?
    
    internal var role: ShapeRole
    
    internal var inRecursiveStyle: Bool
    
    internal var needsStyledRendering: Bool = false
    
    @inline(__always)
    internal mutating func reset() {
        operation = .resolveStyle(0..<1)
        result = .none
    }
    
    internal enum Operation {
        
        case prepare((Text, level: Int))
        
        case resolveStyle(Range<Int>)
        
        case fallbackColor(Int)
        
        case multiLevel
        
        // TODO: _notImplemented enum-case _ShapeStyle_Shape.Operation.copyForeground unused
//        case copyForeground
        
        case primaryStyle
        
        // TODO: _notImplemented enum-case _ShapeStyle_Shape.Operation.modifyBackground unused
//        case modifyBackground
        
    }
    
    internal enum Result {
        
        case prepared(Text)
        
        case resolved(ResolvedStyle)
        
        case style(AnyShapeStyle)
        
        case color(Color)
        
        case bool(Bool)
        
        case none
        
    }
    
    internal enum ResolvedStyle: Animatable {
        
        case color(Color.Resolved)
        
        case paint(AnyResolvedPaint)
        
        // TODO: _notImplemented enum-case ResolvedStyle.foregroundMaterial unused
//        case foregroundMaterial((Color.Resolved, ContentStyle.MaterialStyle))
        
        // TODO: _notImplemented enum-case ResolvedStyle.backgroundMaterial unused
//        case backgroundMaterial(Material.Resolved)
        
        case array([ResolvedStyle])
        
        // TODO: _notImplemented enum-case ResolvedStyle.blend unused
//        indirect case blend((GraphicsBlendMode, ResolvedStyle))
        
        indirect case opacity((Float, ResolvedStyle))
        
        
        internal typealias AnimatableData = ResolvedStyleVector
        
        internal var animatableData: ResolvedStyleVector {
            get {
                ResolvedStyleVector(style: self)
            }
            
            set {
                newValue.set(style: &self)
            }
        }
        
        internal var baseColor: Color.Resolved {
            switch self {
            case .color(let colorResolved):
                return colorResolved
            case .array(let array):
                return array.first?.baseColor ?? .init(linearRed: 1, linearGreen: 1, linearBlue: 1, opacity: 1)
            case .opacity((_, let style)):
                return style.baseColor
            case .paint(_):
                return .init(linearRed: 1, linearGreen: 1, linearBlue: 1, opacity: 1)
            }
        }
        
        internal func fill(_ path: Path,
                           style: FillStyle,
                           in context :GraphicsContext,
                           bounds: CGRect?) {
            switch self {
            case .color(let color):
                context.fill(path, with: .color(color), style: style)
            case .paint(let anyResolvedPaint):
                anyResolvedPaint.fill(path,
                                      style: style,
                                      in: context,
                                      bounds: bounds)
            case .array(let array):
                guard !array.isEmpty,
                      let firstStyle = array.first else {
                    return
                }

                firstStyle.fill(path,
                                style: style,
                                in: context,
                                bounds: bounds)
//            case .blend(_):// 依赖 RB
//
            case .opacity(_):// 依赖 RB
//                 .multicolor(_):
                break
            }
        }
        
        internal var isClear: Bool {
            switch self {
            case .color(let color):
                return color.opacity == 0
            case .paint(let anyResolvedPaint):
                return anyResolvedPaint.isClear
            case .array(let array):
                guard !array.isEmpty else {
                    return true
                }

                return array.first?.isClear ?? false
            case .opacity((let opacity, let style)):
                guard opacity != 0 else {
                    return true
                }
                
                return style.isClear
//            case .multicolor(_):
//                return false
            }
        }
    }
}
