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
import Foundation

@available(iOS 13.0, *)
internal protocol ShapeStyledLeafView: PrimitiveView, UnaryView, ContentResponder {
    
    static var animatesSize: Bool { get }
    
    func shape(size: CGSize, edgeInsets: EdgeInsets) -> (ShapeStyle_RenderedShape.Shape, CGRect)
    
    func isClear(style: _ShapeStyle_Shape.ResolvedStyle) -> Bool
}

@available(iOS 13.0, *)
extension ShapeStyledLeafView {
    
    internal static var animatesSize: Bool {
        true
    }
    
    internal func contains(points: [CGPoint], size: CGSize, edgeInsets: EdgeInsets) -> BitVector64 {
        let (renderedShape, shapeRect) = shape(size: size, edgeInsets: edgeInsets)
        // 此处会判断 ShapeStyle_RenderedShape.Shape 中一个成员（可能是 enum），但是目前该成员尚未探明，判断逻辑后续补上.
        guard !points.isEmpty else {
            return BitVector64()
        }
        
        guard points.first(where: { shapeRect.contains($0)}) != nil else {
            return BitVector64()
        }
        
        let translation = CGAffineTransform(translationX: shapeRect.origin.x, y: shapeRect.origin.y)
        
        let path = renderedShape.path
            // DanceUI addition began
            // We need to align the path used for hit-testing to the content
            // path. The later one is used in AX systems and responder node
            // visual debug. They should not be seperate logic.
            .applying(translation)
        
        let fillStyle = renderedShape.fillStyle
        
        return BitVector64().contained(points: points) { point in
            path.contains(point, eoFill: fillStyle.isEOFilled)
        }
    }
    
    internal func contentPath(size: CGSize, edgeInsets: EdgeInsets) -> Path {
        let (renderedShape, shapeRect) = shape(size: size, edgeInsets: edgeInsets)
        
        guard shapeRect.origin != .zero else {
            return renderedShape.path
        }
        
        let path = renderedShape.path
        
        let translation = CGAffineTransform(translationX: shapeRect.origin.x, y: shapeRect.origin.y)
        
        return path.applying(translation)
    }
    
    internal func isClear(style: _ShapeStyle_Shape.ResolvedStyle) -> Bool {
        style.isClear
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal static func makeLeafView(view: _GraphValue<Self>,
                                      inputs: _ViewInputs,
                                      style: Attribute<_ShapeStyle_Shape.ResolvedStyle>) -> _ViewOutputs {
        var outputs = _ViewOutputs()
        if inputs.preferences.requiresDisplayList {
            let shapeStyleDisplayList = ShapeStyledDisplayList(view: view.value,
                                                               style: style,
                                                               size: inputs.animatedSize,
                                                               position: inputs.animatedPosition,
                                                               containerPosition: inputs.containerPosition,
                                                               inputPosition: inputs.position,
                                                               inputSize: inputs.size,
                                                               transform: inputs.transform,
                                                               environment: inputs.environment,
                                                               pixelLength: inputs.environmentAttribute(keyPath: \.pixelLength),
                                                               identity: .make(),
                                                               contentSeed: .zero)
            let displayListAttribute = Attribute(shapeStyleDisplayList)
            outputs.displayList = displayListAttribute
        }
        
        let responderFilter = ShapeStyledResponderFilter(view: view.value,
                                                         style: style,
                                                         size: inputs.animatedSize,
                                                         position: inputs.animatedPosition,
                                                         transform: inputs.transform,
                                                         // We don't have to remove the `hitTestInsets` in the view
                                                         // inputs, because this is a leaf view.
                                                         hitTestInsets: inputs.hitTestInsets)
        outputs.makePreferenceWriter(inputs: inputs,
                                     key: ViewRespondersKey.self,
                                     value: Attribute(responderFilter))
        return outputs
    }
}

@available(iOS 13.0, *)
private struct ShapeStyledResponderFilter<ShapeView: ShapeStyledLeafView>: StatefulRule {
    
    fileprivate typealias Value = [ViewResponder]
    
    @Attribute
    fileprivate var view: ShapeView

    @Attribute
    fileprivate var style: _ShapeStyle_Shape.ResolvedStyle

    @Attribute
    fileprivate var size: ViewSize

    @Attribute
    fileprivate var position: ViewOrigin

    @Attribute
    fileprivate var transform: ViewTransform
    
    @OptionalAttribute
    fileprivate var hitTestInsets: EdgeInsets??

    fileprivate let responder: LeafViewResponder<ShapeStyledResponderData<ShapeView>> = .init()
    
    internal init(
        view: Attribute<ShapeView>,
        style: Attribute<_ShapeStyle_Shape.ResolvedStyle>,
        size: Attribute<ViewSize>,
        position: Attribute<ViewOrigin>,
        transform: Attribute<ViewTransform>,
        hitTestInsets: Attribute<EdgeInsets?>?
    ) {
        self._view = view
        self._style = style
        self._size = size
        self._position = position
        self._transform = transform
        self._hitTestInsets = OptionalAttribute(hitTestInsets)
    }
    
    fileprivate mutating func updateValue() {
        let (shapeView, viewChanged) = self._view.changedValue()
        let (resolvedStyle, styleChanged) = self._style.changedValue()
        let valueChanged = viewChanged || styleChanged
        let responsderData = ShapeStyledResponderData(view: shapeView,
                                                      style: resolvedStyle)
        self.responder.helper.update(data: (responsderData, valueChanged),
                                     size: self._size.changedValue(),
                                     position: self._position.changedValue(),
                                     hitTestInsets: $hitTestInsets?.changedValue(),
                                     transform: self._transform.changedValue(),
                                     parent: self.responder)
        
        guard !hasValue else {
            return
        }
        
        self.value = [responder]
    }
}

@available(iOS 13.0, *)
private struct ShapeStyledDisplayList<ShapeView: ShapeStyledLeafView>: StatefulRule {
    
    fileprivate typealias Value = DisplayList
    
    @Attribute
    fileprivate var view: ShapeView
    
    @Attribute
    fileprivate var style: _ShapeStyle_Shape.ResolvedStyle
    
    @Attribute
    fileprivate var size: ViewSize
    
    @Attribute
    fileprivate var position: ViewOrigin
    
    @Attribute
    fileprivate var containerPosition: ViewOrigin
    
    @Attribute
    fileprivate var inputPosition: ViewOrigin
    
    @Attribute
    fileprivate var inputSize: ViewSize
    
    @Attribute
    fileprivate var transform: ViewTransform
    
    @Attribute
    fileprivate var environment: EnvironmentValues
    
    @Attribute
    fileprivate var pixelLength: CGFloat
    
    @OptionalAttribute
    fileprivate var safeAreaInsets: SafeAreaInsets?
    
    fileprivate let identity: DisplayList.Identity

    fileprivate var contentSeed: DisplayList.Seed
    
    fileprivate var roundedSize: CGSize {
        var inputRect = CGRect(origin: self.inputPosition.value,size: self.inputSize.value)
        inputRect.roundCoordinatesToNearestOrUp(toMultipleOf: self.pixelLength)
        return inputRect.size
    }
    
    fileprivate mutating func updateValue() {
        
        let version = DisplayList.Version.make()
        
        let inputs: [DGAttribute] = [_inputPosition.identifier, _containerPosition.identifier, _position.identifier]
        if self.contentSeed == .zero || inputs.anyOtherInputsChanged {
            self.contentSeed = .init(version: version)
        }
        
        let geometryProxy = GeometryProxy(owner: DGWeakAttribute(DGAttribute.current),
                                          _size: WeakAttribute($size),
                                          _environment: WeakAttribute($environment),
                                          _transform: WeakAttribute($transform),
                                          _position: WeakAttribute($position),
                                          _safeAreaInsets: WeakAttribute($safeAreaInsets),
                                          _seed: UInt32(version.value))
        
        let size = ShapeView.animatesSize ? self.size : self.inputSize
        let view = self.view
        let (shapeValue, rect) = withGeometryProxy(geometryProxy) {
            view.shape(size: size.value, edgeInsets: .zero)
        }
        
        let origin = CGPoint(x: position.value.x + rect.origin.x - containerPosition.value.x,
                             y: position.value.y + rect.origin.y - containerPosition.value.y)
        
        let emptyDisplayListItem = DisplayList.Item(frame: CGRect(origin: origin,size: rect.size),
                                                    version: version,
                                                    value: .empty,
                                                    identity: identity)
        
        var resolvedStyleText: ShapeStyle_RenderedShape.ResolvedKeyedText? = nil
        
        var renderType: ShapeRenderType = .commonShape
        
        if let textContentView = view as? StyledTextContentView {
            renderType = .keyedText
            resolvedStyleText = .init(content: textContentView.resolvedStyledText, rect: rect)
        }
        
        var renderedShape = ShapeStyle_RenderedShape(renderedShape: shapeValue,
                                                     renderType: renderType,
                                                     size: size.value,
                                                     contentSeed: contentSeed,
                                                     displayListItem: emptyDisplayListItem,
                                                     resolvedText: resolvedStyleText)
        renderedShape.render {
            self.style
        }
        
        let displayListItem = renderedShape.displayListItem
        
        var item = displayListItem.canonicalized()
        
        if !ShapeView.animatesSize {
            let viewSize = self.size.value
            if !roundedSize.equalTo(viewSize) {
                let viewRect = CGRect(origin: .zero, size: viewSize)
                let path = viewRect.isNull ? Path() : Path(CGRect(origin: .zero, size: viewSize))
                let fillStyle = viewRect.isNull ? FillStyle(eoFill: true, antialiased: false) : FillStyle(eoFill: false, antialiased: false)
                var newItem = item
                newItem.frame.origin = .zero
                newItem.identity = .zero
                let displayList = DisplayList(item: newItem)
                item.value = .effect(.clip(path, fillStyle), displayList)
            }
        }
        
        self.value = DisplayList(item: item)
    }
}

@available(iOS 13.0, *)
private enum ShapeRenderType {
    
    case commonShape // 0x0
    
    case keyedText // 0x1
    
    // TODO: _notImplemented enum-case ShapeRenderType.multiLayerImage unused
//    case multiLayerImage // 0x2
}

@available(iOS 13.0, *)
internal struct ShapeStyle_RenderedShape {
    
    internal struct ResolvedKeyedText {
        internal let content: ResolvedStyledText
        internal let rect: CGRect
    }
    
    fileprivate let resolvedText: ResolvedKeyedText?
    
    fileprivate let size: CGSize
    
    fileprivate let renderedShape: Shape
    
    fileprivate let renderType: ShapeRenderType
    
    fileprivate let contentSeed: DisplayList.Seed
    
    fileprivate var displayListItem: DisplayList.Item
    
    fileprivate init(renderedShape: Shape,
                     renderType: ShapeRenderType,
                     size: CGSize,
                     contentSeed: DisplayList.Seed,
                     displayListItem: DisplayList.Item,
                     resolvedText: ResolvedKeyedText?) {
        self.renderedShape = renderedShape
        self.renderType = renderType
        self.size = size
        self.resolvedText = resolvedText
        self.displayListItem = displayListItem
        self.contentSeed = contentSeed
    }
    
    fileprivate mutating func render(style: () -> _ShapeStyle_Shape.ResolvedStyle) {
        let renderStyle = style()
        switch self.renderType {
        case .commonShape:
            switch renderStyle {
            case .color(let resolvedColor):
                render(color: resolvedColor)
            case .paint(let paint):
                render(paint: paint)
            case .array(let styles):
                guard !styles.isEmpty,
                      let firstStyle = styles.first else {
                    return
                }
                
                render {
                    firstStyle
                }
            case .opacity((let opacity, let nestedStyle)):
                render {
                    nestedStyle
                }
                
                var opacityItem = displayListItem
                opacityItem.frame.origin = .zero
                opacityItem.identity = .zero
                let opacityDisplayList = DisplayList(item: opacityItem)
                displayListItem.value = .effect(.opacity(opacity), opacityDisplayList)
                
//            case .multicolor(let multiColorStyle):
            }
        case .keyedText:
            guard let resolvedStyledText = resolvedText else {
                return
            }
            
            if resolvedStyledText.content.needsStyledRendering {
                renderKeyedText(text: resolvedStyledText, size: size, style: renderStyle)
            } else {
                displayListItem.value = .content(.init(value: .text(resolvedStyledText.content, size), seed: contentSeed))
            }
//        case .multiLayerImage:
        }
    }
    
    
    fileprivate mutating func render(paint: AnyResolvedPaint) {
        let path = renderedShape.path
        let fillStyle = renderedShape.fillStyle
        self.displayListItem.value = .content(.init(value: .shape(path, paint, fillStyle), seed: contentSeed))
    }
    
    fileprivate mutating func render(color: Color.Resolved) {
        let opacity = color.opacity
        guard opacity != 0 else {
            return
        }
        
        let path = renderedShape.path
        let fillStyle = renderedShape.fillStyle
        switch path.storage {
        case.rect(let rect):
            let newOrgin = rect.origin.addPoint(self.displayListItem.frame.origin)
            self.displayListItem.frame = CGRect(origin: newOrgin, size: rect.size)
            self.displayListItem.value = .content(.init(value: .color(color), seed: contentSeed))
        default:
            let resolvedPaint = _AnyResolvedPaint(color)
            self.displayListItem.value = .content(.init(value: .shape(path, resolvedPaint, fillStyle), seed: contentSeed))
        }
    }
    
    
//    fileprivate mutating func renderMultiLayerImage(image :GraphicsImage,
//                                                    style: _ShapeStyle_Shape.ResolvedStyle) {
//
//    }
    
    fileprivate mutating func renderKeyedText(text: ResolvedKeyedText,
                                              size: CGSize,
                                              style: _ShapeStyle_Shape.ResolvedStyle) {
        guard let (opacity, paint) = resolvedPaint(with: style) else {
            return
        }
        
        let textVersion: DisplayList.Version = .make()
        
        let textRect = text.rect
        let textContent = text.content
        let textItem = DisplayList.Item(frame: textRect,
                                        version: textVersion,
                                        value: .content(.init(value: .text(textContent, textRect.size),
                                                              seed: .init(version: textVersion))),
                                        identity: .make())
        
        let textDisplayList = DisplayList(item: textItem)
        
        let path = renderedShape.path
        
        let fillStyle = renderedShape.fillStyle
        
        let shapeVersion: DisplayList.Version = .make()
        
        let shapeItem = DisplayList.Item(frame: CGRect(origin: .zero, size: size),
                                         version: shapeVersion,
                                         value: .content(.init(value: .shape(path, paint, fillStyle),
                                                               seed: .init(version: shapeVersion))),
                                         identity: .make())
        
        var maskDisplayList = DisplayList(item: textItem)
        
        maskDisplayList.items.append(shapeItem)
        
        let maskVersion: DisplayList.Version = .make()
        
        let maskItem = DisplayList.Item(frame: CGRect(origin: .zero, size: size),
                                        version: maskVersion,
                                        value: .effect(.mask(textDisplayList), maskDisplayList),
                                        identity: .make())
        
        let opacityDisplay = DisplayList(item: maskItem)
        
        displayListItem.value = .effect(.opacity(opacity), opacityDisplay)
        
        let displayItemOrigin = displayListItem.frame.origin
        displayListItem.frame.origin = displayItemOrigin.insetBy(dx: textRect.origin.x, dy: textRect.origin.y)
    }
    
    @inline(__always)
    private func findResolvedPaint(with style: _ShapeStyle_Shape.ResolvedStyle, opacity: inout Float) -> AnyResolvedPaint? {
        switch style {
        case .paint(let paint):
            return paint
        case .opacity((let nestedOpacity, let nestedStyle)):
            opacity *= nestedOpacity
            return findResolvedPaint(with: nestedStyle, opacity: &opacity)
        case .color(let resolvedColor):
            return _AnyResolvedPaint(resolvedColor)

        default:
            return nil
        }
    }

    
    @inline(__always)
    private func resolvedPaint(with style: _ShapeStyle_Shape.ResolvedStyle) -> (Float, AnyResolvedPaint)? {
        switch style {
        case .array(let array):
            var result: (Float, AnyResolvedPaint)? = nil
            for value in array {
                if case .opacity((var opacity, let resolvedStyle)) = value,
                   let paint = findResolvedPaint(with: resolvedStyle, opacity: &opacity) {
                    result = (opacity, paint)
                    break
                }
            }
            return result
        case .opacity((var opacity, let resolvedStyle)):
            if let paint = findResolvedPaint(with: resolvedStyle, opacity: &opacity) {
                return (opacity, paint)
            } else {
                return nil
            }

        default:
            return nil
        }
    }

    
    internal struct Shape {
        
        internal var path: Path
        
        internal var fillStyle: FillStyle
    }
}

@available(iOS 13.0, *)
extension CGPoint {
    internal func insetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        CGPoint(x: x - dx, y: y - dy)
    }
}
