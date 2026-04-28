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
extension DisplayList {

    @_spi(DanceUICompose)
    public struct Content {

        internal var value: Value

        internal var seed: DisplayList.Seed

        @_spi(DanceUICompose)
        public init(value: DisplayList.Content.Value, seed: DisplayList.Seed) {
            self.value = value
            self.seed = seed
        }

        @inline(__always)
        @usableFromInline
        internal func canonicalize() -> DisplayList.Item.Value {
            guard self.value.isEmpty else {
                return .content(self)
            }
            return .empty
        }

        @inline(__always)
        @usableFromInline
        internal func canonicalizeForFrameIsEmpty() -> DisplayList.Item.Value {
            switch value {
            case .text, .image:
                return .empty
            case .platformView:
                return .content(self)
            case .flattened:
                return .content(self)
            default:
                return .empty
            }
        }

    }
}

@available(iOS 13.0, *)
extension DisplayList.Content {

    @_spi(DanceUICompose)
    public enum Value {

        indirect case backdrop(Float, Color.Resolved)

        indirect case color(Color.Resolved)

        indirect case chameleonColor(Color.Resolved)

        indirect case image(GraphicsImage)

        indirect case animatedImage(GraphicsImage)

        indirect case shape(Path, AnyResolvedPaint, FillStyle)

        indirect case shadow(Path, ResolvedShadowStyle)

        indirect case platformView(PlatformViewFactory)

        indirect case platformLayer(PlatformLayerFactory)

        indirect case text(ResolvedStyledText, CGSize)

        indirect case flattened(DisplayList, CGPoint, RasterizationOptions)

        indirect case drawing(CGPoint, RasterizationOptions)

        indirect case view(_DisplayList_ViewFactory)

        case placeholder(DisplayList.Identity)

        @inline(__always)
        internal var isEmpty: Bool {
            switch self {
            case .color(let color):
                return (color == Color.Resolved.empty) ? true : false
            case .text(let resolvedText, _):
                return resolvedText.isEmpty
            case .shape(let path, _, _), .shadow(let path, _):
                return path.isEmpty
            case .image(let image), .animatedImage(let image):
                return image.contents == nil
            default:
                return false
            }
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Content {

    @inline(__always)
    public var features: DisplayList.Features {
        switch value {
        case .backdrop, .color, .chameleonColor, .image, .animatedImage, .shape, .shadow, .platformLayer, .drawing:
            return .empty
        case.platformView:
            return .isRequired
        case .text(let resolvedText, _):
            return resolvedText.updatesAsynchronously ? .updatesAsynchronously : .empty
        case .flattened(let list, _, _):
            return list.features
        case .view, .placeholder:
            return .isView
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Content: DisplayListSExpPrintable {

    internal func print(_ printer: inout DisplayList._SExpPrinter) {
        let desc: String
        switch self.value {
        case .backdrop(let arg0, let color):
            desc = "(backdrop \(arg0), \(color))"
        case .color(let color):
            desc = "(color \(color))"
        case .chameleonColor(let color):
            desc = "(chameleonColor \(color))"
        case .image(let image), .animatedImage(let image):
            desc = "(image \(image))"
        case .shape(let path, let paint, let style):
            desc = "(shape #:path \(path) #:paint \(paint) #:style \(style))"
        case .shadow(let path, let style):
            desc = "(shadow #:path \(path) #:style \(style))"
        case .platformView(let factory):
            desc = "(platformView \(factory))"
        case .platformLayer(let factory):
            desc = "(platformLayer \(factory))"
        case .text(let text, let size):
            desc = "(text \(text) #:size \(size))"
        case .flattened(let contentList, let point, let options):
            desc = "(flattened #:list \(contentList.print(&printer)) #:point \(point) #:options \(options))"
        case .drawing(let point, let options):
            desc = "(drawing #:point \(point) #:options \(options))"
        case .view(let factory):
            desc = "(view \(factory))"
        case .placeholder(let identity):
            desc = "(placeholder \(identity))"
        }
        printer.push(desc)
        printer.pop()
    }

    func minimalPrint(_ printer: inout DisplayList._SExpPrinter) {
        let desc: String
        switch self.value {
        case .backdrop(let arg0, let color):
            desc = "(backdrop \(arg0), \(color))"
        case .color(let color):
            desc = "(c \(color.description))"
        case .chameleonColor(let color):
            desc = "(cc \(color.description))"
        case .image(let image), .animatedImage(let image):
            desc = "(image)"
        case .shape(let path, let paint, let style):
            desc = "(shape #:path \(path) #:paint \(paint) #:style \(style))"
        case .shadow(let path, let style):
            desc = "(shadow #:path \(path) #:style \(style))"
        case .platformView(let factory):
            desc = "(platformView \(factory))"
        case .platformLayer(let factory):
            desc = "(platformLayer \(factory))"
        case .text(let text, let size):
            desc = "(text \(text) #:size \(size))"
        case .flattened(let contentList, let point, let options):
            desc = "(flattened #:list \(contentList.minimalPrint(&printer)) #:point \(point) #:options \(options))"
        case .drawing(let point, let options):
            desc = "(drawing #:point \(point) #:options \(options))"
        case .view(let factory):
            desc = "(view \(factory))"
        case .placeholder(let identity):
            desc = "(placeholder \(identity))"
        }
        printer.push(desc)
        printer.pop()
    }
}
