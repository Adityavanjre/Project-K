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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
extension DisplayList.Content: Encodable {
    
    private enum CodingKind: UInt8 {
        
        case color
        
        case image
        
        case shape
        
        case text
        
        case shadow
        
        case flattened
        
        case view
        
        case placeholder
        
        case platformView
        
        case platformLayer
        
        case backdrop
        
        case chameleonColor
        
        case drawing
    }
    
    private enum CodingKeys: CodingKey, Hashable {
        
        case kind
        
        case value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self.value {
        case .backdrop(let arg0, let color):
            let backdrop = CodableBackdrop(scale: arg0, color: color)
            try container.encode(CodingKind.backdrop.rawValue, forKey: .kind)
            try container.encode(backdrop, forKey: .value)
        case .color(let color):
            try container.encode(CodingKind.color.rawValue, forKey: .kind)
            try container.encode(color, forKey: .value)
        case .chameleonColor(let color):
            try container.encode(CodingKind.chameleonColor.rawValue, forKey: .kind)
            try container.encode(color, forKey: .value)
        case .image(let image), .animatedImage(let image):
            try container.encode(CodingKind.image.rawValue, forKey: .kind)
            try container.encode(image, forKey: .value)
        case .shape(let path, let paint, let style):
            let shape = CodableShape(path: path, paint: paint, style: style)
            try container.encode(CodingKind.shape.rawValue, forKey: .kind)
            try container.encode(shape, forKey: .value)
        case .shadow(let path, let style):
            let shadow = CodableShadow(path: path, style: style)
            try container.encode(CodingKind.shadow.rawValue, forKey: .kind)
            try container.encode(shadow, forKey: .value)
        case .platformView(let factory):
            let platformView = CodableViewFactory(factory: factory)
            try container.encode(CodingKind.platformView.rawValue, forKey: .kind)
            try container.encode(platformView, forKey: .value)
        case .platformLayer(let factory):
            let platformLayer = CodableViewFactory(factory: factory)
            try container.encode(CodingKind.platformLayer.rawValue, forKey: .kind)
            try container.encode(platformLayer, forKey: .value)
        case .text(let text, let size):
            try container.encode(CodingKind.text.rawValue, forKey: .kind)
            try container.encode(CodableText(text: text, size: size), forKey: .value)
        case .flattened(let contentList, let point, let options):
            let flattened = CodableFlattenedData(list: contentList, origin: point, options: options)
            try container.encode(CodingKind.flattened.rawValue, forKey: .kind)
            try container.encode(flattened, forKey: .value)
        case .drawing(let point, let options):
            let drawing = CodableDrawingData(origin: point, options: options)
            try container.encode(CodingKind.drawing.rawValue, forKey: .kind)
            try container.encode(drawing, forKey: .value)
        case .view(let factory):
            let view = CodableViewFactory(factory: factory)
            try container.encode(CodingKind.view.rawValue, forKey: .kind)
            try container.encode(view, forKey: .value)
        case .placeholder(let identity):
            try container.encode(CodingKind.placeholder.rawValue, forKey: .kind)
            try container.encode(identity, forKey: .value)
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Content {
    
    private struct CodableDrawingData: Encodable {
        
        internal var origin : CGPoint
        
        internal var options : RasterizationOptions
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(origin, forKey: .origin)
            try container.encode(options, forKey: .options)
        }
        
        private enum CodingKeys: CodingKey, Hashable {
            
            case origin
            
            case options
        }
    }
    
    private struct CodableFlattenedData: Encodable {
        
        internal var list : DisplayList
        
        internal var origin : CGPoint
        
        internal var options : RasterizationOptions
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(list, forKey: .list)
            try container.encode(origin, forKey: .origin)
            try container.encode(options, forKey: .options)
        }
        
        internal enum CodingKeys: CodingKey, Hashable {
            
            case list
            
            case origin
            
            case options
        }
        
    }
    
    private struct CodableText: Encodable {
        
        internal var text : ResolvedStyledText
        
        internal var size : CGSize
        
        private enum CodingKeys: CodingKey, Hashable {
            case text
            case size
        }
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(text, forKey: .text)
            try container.encode(size, forKey: .size)
        }
    }
    
    private struct CodableShadow: Encodable {
        
        @ProxyCodable
        internal var path : Path
        
        internal var style : ResolvedShadowStyle
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(path.codingProxy, forKey: .path)
            try container.encode(style, forKey: .style)
        }
        
        internal enum CodingKeys: CodingKey, Hashable {
            
            case path
            
            case style
        }
    }
    
    private struct CodableShape: Encodable {
        
        @ProxyCodable
        private var path : Path
        
        private var _paint : CodableResolvedPaint
        
        @ProxyCodable
        private var style : FillStyle
        
        internal init(path: Path, paint: AnyResolvedPaint, style: FillStyle) {
            self.path = path
            self._paint = CodableResolvedPaint(wrappedValue: paint)
            self.style = style
        }
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(path.codingProxy, forKey: .path)
            try container.encode(_paint, forKey: .paint)
            try container.encode(style.codingProxy, forKey: .style)
        }
        
        internal enum CodingKeys: CodingKey, Hashable {
            
            case path
            
            case paint
            
            case style
        }
    }
    
    private struct CodableBackdrop: Encodable {
        
        internal var scale : Float
        
        internal var color : Color.Resolved
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(scale, forKey: .scale)
            try container.encode(color, forKey: .color)
        }
        
        private enum CodingKeys: CodingKey, Hashable {

          case scale

          case color
        }
    }
}

@available(iOS 13.0, *)
extension RasterizationOptions: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        
    }
    
    private enum CodingKeys: CodingKey, Hashable {
        
        case colorMode
        
        case rbColorMode
        
        case flags
        
        case maxDrawableCount
        
    }
}

#endif
