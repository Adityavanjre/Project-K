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
    
    fileprivate func paint(in rect:CGRect) -> AnyResolvedPaint? {
        guard self.items.count == 1 else {
            return nil
        }
        
        return items.first?.paint(in: rect)
    }
    
    fileprivate func backdropFilter(size: CGSize) -> GraphicsFilter? {
        guard self.items.count == 1 else {
            return nil
        }
        
        return items.first?.backdropFilter(size: size)
    }
    
    fileprivate func opaqueContentPath() -> (Path, FillStyle)? {
        guard self.items.count == 1 else {
            return nil
        }
        
        return items.first?.opaqueContentPath()
    }
    
    fileprivate func colorMatrix(size: CGSize) -> (_ColorMatrix, DisplayList)? {
        guard self.items.count == 1 else {
            return nil
        }
        
        return items.first?.colorMatrix(size: size)
    }
    
    @_spi(DanceUICompose)
    public enum Effect {
        
        case backdropGroup(Bool)
        
        case properties(DisplayList.Properties)
        
        indirect case platformGroup(group: PlatformGroupFactory)
        
        case opacity(Float)
        
        case blendMode(GraphicsBlendMode)
        
        indirect case clip(Path, FillStyle)
        
        indirect case mask(DisplayList)
        
        indirect case affine(CGAffineTransform)
        
        indirect case projection(ProjectionTransform)
        
        indirect case filter(GraphicsFilter)
        
        indirect case animation(_DisplayList_AnyEffectAnimation)
        
        indirect case view(_DisplayList_ViewFactory)
        
        indirect case accessibility([AccessibilityNodeAttachment])
        
        case identity
        
        case geometryGroup
        
        case compositingGroup
        
        case archive
        
        case renderNodeLayer(Bool)
        
        case gestureRecognizers([UIGestureRecognizer])
        
        @inline(__always)
        @usableFromInline
        internal func canonicalize(_ contentList: DisplayList,
                                   item: inout DisplayList.Item) -> DisplayList.Item.Value {
            guard !contentList.items.isEmpty else {
                return canonicalizeForContentListIsEmpty(contentList, item: item)
            }
            switch self {
            case .opacity(let opacityValue):
                if opacityValue >= 1 {
                    var value: DisplayList.Item.Value = .effect(.identity, contentList)
                    if item.canonicalizeIdentityEffect(list: contentList) {
                        value = item.value
                    }
                    return value
                } else {
                    if opacityValue <= 0 && !contentList.features.contains(.isRequired) {
                        return .empty
                    }
                    
                    return .effect(self, contentList)
                }
            case .clip(let path, let fillStyle):
                
                guard contentList.features.contains(.isRequired) || !path.isEmpty else {
                    return .empty
                }
                
                if let resolvedPaint = contentList.paint(in: CGRect(x: 0, y: 0, width: item.frame.width, height: item.frame.height)) {
                    return .content(DisplayList.Content(value: .shape(path, resolvedPaint, fillStyle), seed: DisplayList.Seed(version: item.version)))
                }
                
                return .effect(self, contentList)
            case .mask(let maskDisplayList):
                return self.itemValueForMask(contentList, maskDisplayList: maskDisplayList, item: item)
            case .affine(let cGAffineTransform):
                
                guard cGAffineTransform == .identity else {
                    return .effect(self, contentList)
                }
                
                var value: DisplayList.Item.Value = .effect(.identity, contentList)
                if item.canonicalizeIdentityEffect(list: contentList) {
                    value = item.value
                }
                return value
            case .projection(let transform):
                guard transform.isIdentity else {
                    return .effect(self, contentList)
                }
                var value: DisplayList.Item.Value = .effect(.identity, contentList)
                if item.canonicalizeIdentityEffect(list: contentList) {
                    value = item.value
                }
                return value
            case .filter(let graphicsFilter):
                if graphicsFilter.isIdentity {
                    var value: DisplayList.Item.Value = .effect(.identity, contentList)
                    if item.canonicalizeIdentityEffect(list: contentList) {
                        value = item.value
                    }
                    return value
                } else {
                    if let colorMatrix = _ColorMatrix(graphicsFilter: graphicsFilter) {
                        
                        if let displayListColorMatrix = contentList.colorMatrix(size: item.frame.size) {
                            let mixColorMatrix = colorMatrix * displayListColorMatrix.0
                            return .effect(.filter(.colorMatrix(mixColorMatrix)), displayListColorMatrix.1)
                        }
                        
                        return .effect(self, contentList)
                    } else {
                        return .effect(self, contentList)
                    }
                }
            case .identity:
                var value: DisplayList.Item.Value = .effect(self, contentList)
                if item.canonicalizeIdentityEffect(list: contentList) {
                    value = item.value
                }
                return value
            default:
                return .effect(self, contentList)
            }
        }
        
        @inline(__always)
        private func itemValueForMask(_ contentList: DisplayList,
                                      maskDisplayList: DisplayList,
                                      item: DisplayList.Item) -> DisplayList.Item.Value {
            let filter = contentList.backdropFilter(size: item.frame.size)
            if let filterValue = filter {
                return .effect(.filter(filterValue), maskDisplayList)
            } else {
                if let opaqueContentPath = maskDisplayList.opaqueContentPath() {
                    var clipItem = item
                    clipItem.value = .effect(.clip(opaqueContentPath.0, opaqueContentPath.1), contentList)
                    clipItem.canonicalize()
                    return clipItem.value
                }
                return .effect(self, contentList)
            }
        }
        
        @inline(__always)
        internal func canonicalizeForContentListIsEmpty(_ contentList: DisplayList, item: DisplayList.Item) -> DisplayList.Item.Value {
            switch self {
            case .mask(let maskDisplayList):
                if contentList.features.contains(.isRequired) {
                    return self.itemValueForMask(contentList, maskDisplayList: maskDisplayList, item: item)
                } else {
                    return .empty
                }
            case .platformGroup:
                return .effect(self, contentList)
            default:
                return .empty
            }
        }
        
        @inline(__always)
        public func features(_ contentList: DisplayList) -> DisplayList.Features {
            var features = contentList.features
            switch self {
            case .backdropGroup, .properties, .accessibility, .identity,
                    .geometryGroup, .compositingGroup, .archive, .opacity,
                    .blendMode, .clip, .affine, .projection, .filter, .renderNodeLayer:
                break
            case .gestureRecognizers:
                if DanceUIFeature.gestureContainer.isEnable {
                    features.insert(.isRequired)
                }
            case .platformGroup:
                features.insert(.isRequired)
            case .view:
                features.insert(.isView)
            case .mask(let maskList):
                features = features.union(maskList.features)
            case .animation:
                features.insert(.isDynamicContent)
            }
            return features
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Item {
    
    fileprivate mutating func canonicalizeIdentityEffect(list: DisplayList) -> Bool {
        guard list.items.count == 1 else {
            return false
        }
        
        if DanceUIFeature.gestureContainer.isEnable {
            if case .effect(.gestureRecognizers, _) = list.items[0].value {
                return false
            }
        }
        
        if let firstItem = list.items.first {
            let newOrigin = CGPoint(x: firstItem.frame.origin.x + frame.origin.x,
                                    y: firstItem.frame.origin.y + frame.origin.y)
            frame = CGRect(x: newOrigin.x, y: newOrigin.y, width: firstItem.frame.width, height: firstItem.frame.height)
            version.max(rhs: firstItem.version)
            value = firstItem.value
            identity = firstItem.identity
            return true
        }
        
        return false
    }
    
    fileprivate func paint(in rect:CGRect) -> AnyResolvedPaint? {
        
        guard case .content(let content) = value else {
            return nil
        }
        
        switch content.value {
            
        case .color(let color):
            guard frame.equalTo(rect) else {
                return nil
            }
            
            return _AnyResolvedPaint(color)
        case .shape(let path, let paint, _):
            guard frame.equalTo(rect) else {
                return nil
            }
            
            let newRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
            let storage: Path.Storage = newRect.isNull ? .empty : .rect(newRect)
            if path.storage == storage {
                return paint
            }
            return nil
            
        default:
            return nil
        }
    }
    
    fileprivate func backdropFilter(size: CGSize) -> GraphicsFilter? {
        
        let newRect = CGRect(origin: .zero, size: size)
        
        guard frame.equalTo(newRect) else {
            return nil
        }
        
        guard case .effect(let effect, let contentList) = value,
              case .filter(let filter) = effect else {
                  return nil
              }
        
        let colorMartix = _ColorMatrix(graphicsFilter: filter)
        
        guard let filterColorMartix = colorMartix,
                contentList.items.count == 1,
              let contentListItem = contentList.items.first else {
            return nil
        }
        
        guard contentListItem.frame.equalTo(newRect) else {
            return nil
        }
        
        guard case .content(let content) = value,
              case .backdrop(let backdropValue, _) = content.value,
              backdropValue == 0 else {
            return nil
        }
        
        return .vibrantColorMatrix(filterColorMartix)
    }
    
    fileprivate func opaqueContentPath() -> (Path, FillStyle)? {
        
        switch value {
        case .content(let content):
            switch content.value {
            case .color(let color):
                guard color.opacity == 1 else {
                    return nil
                }
                
                let maskPath: Path = frame.isNull ? Path() : Path(frame)
                
                return (maskPath, FillStyle())
            case .shape(let path, let paint, let style):
                
                var maskPath = path
                
                guard paint.isOpaque else {
                    return nil
                }
                
                if frame.origin != .zero {
                    
                    let transform = CGAffineTransform(translationX: frame.origin.x, y: frame.origin.y)
                    
                    maskPath = maskPath.applying(transform)
                }
                
                return (maskPath,style)
                
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
    fileprivate func colorMatrix(size: CGSize) -> (_ColorMatrix, DisplayList)? {
        
        guard frame.equalTo(CGRect(x: 0, y: 0, width: size.width, height: size.height)) else {
            return nil
        }
        
        guard case .effect(let effect, let displayList) = value,
              case .filter(let filter) = effect,
              let colorMartix = _ColorMatrix(graphicsFilter: filter) else {
                  return nil
              }
        
        return (colorMartix, displayList)
    }
}

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public enum GraphicsBlendMode: Equatable, RendererEffect {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    case blendMode(GraphicsContext.BlendMode)
    
    case caFilter(AnyObject)
    
    internal static var normal: GraphicsBlendMode {
        self.init(blendMode: .normal)
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .blendMode(self)
    }
    
    public static func == (lhs: GraphicsBlendMode, rhs: GraphicsBlendMode) -> Bool {
        switch (lhs, rhs) {
        case (.blendMode(let lBlendMode), .blendMode(let rBlendMode)):
            return lBlendMode == rBlendMode
        case (.caFilter(let lFilter), .caFilter(let rFilter)):
            return lFilter === rFilter
        default:
            return false
        }
    }
    
    internal var caCompositingFilter: Any? {
        switch self {
        case .blendMode(let blendMode):
            guard blendMode != .normal && !GraphicsBlendMode.compositingFilterNames.isEmpty else {
                return nil
            }
            
            let filterName = GraphicsBlendMode.compositingFilterNames[blendMode.rawValue]
            return filterName
        case .caFilter(let filter):
            return filter
        }
    }
    
    @_spi(DanceUICompose)
    public init(blendMode: BlendMode) {
        self = .blendMode(GraphicsContext.BlendMode(blendMode: blendMode))
    }
    
    fileprivate static let compositingFilterNames: [Int32: String] = [
        GraphicsContext.BlendMode.multiply.rawValue: "multiplyBlendMode",
        GraphicsContext.BlendMode.screen.rawValue: "screenBlendMode",
        GraphicsContext.BlendMode.overlay.rawValue: "overlayBlendMode",
        GraphicsContext.BlendMode.darken.rawValue: "darkenBlendMode",
        GraphicsContext.BlendMode.lighten.rawValue: "lightenBlendMode",
        GraphicsContext.BlendMode.colorDodge.rawValue: "colorDodgeBlendMode",
        GraphicsContext.BlendMode.colorBurn.rawValue: "colorBurnBlendMode",
        GraphicsContext.BlendMode.softLight.rawValue: "softLightBlendMode",
        GraphicsContext.BlendMode.hardLight.rawValue: "hardLightBlendMode",
        GraphicsContext.BlendMode.difference.rawValue: "differenceBlendMode",
        GraphicsContext.BlendMode.exclusion.rawValue: "exclusionBlendMode",
        GraphicsContext.BlendMode.hue.rawValue: "hueBlendMode",
        GraphicsContext.BlendMode.saturation.rawValue: "saturationBlendMode",
        GraphicsContext.BlendMode.color.rawValue: "colorBlendMode",
        GraphicsContext.BlendMode.luminosity.rawValue: "luminosityBlendMode",
        GraphicsContext.BlendMode.sourceAtop.rawValue: "sourceAtop",
        GraphicsContext.BlendMode.destinationOver.rawValue: "destOver",
        GraphicsContext.BlendMode.destinationOut.rawValue: "destOut",
        GraphicsContext.BlendMode.plusDarker.rawValue: "plusD",
        GraphicsContext.BlendMode.plusLighter.rawValue: "plusL"
    ]
}

@available(iOS 13.0, *)
extension DisplayList.Effect: DisplayListSExpPrintable {
    
    internal func print(_ printer: inout DisplayList._SExpPrinter) {
        var ended = false
        switch self {
        case .backdropGroup(let bool):
            printer.push("(backdropGroup \(bool))")
        case .properties(let properties):
            printer.push("(properties \(properties))")
        case .platformGroup(let factory):
            printer.push("(platformGroup")
            printer.push("(factory \(factory))")
            printer.pop()
            ended = true
        case .opacity(let opacity):
            printer.push("(opacity \(opacity))")
        case .blendMode(let mode):
            printer.push("(blendMode \(mode))")
        case .clip(let path, let style):
            printer.push("(clip")
            printer.push("(path: \(path))")
            printer.pop()
            printer.push("(style: \(style))")
            printer.pop()
            ended = true
        case .mask(let list):
            printer.push("(mask")
            list.print(&printer)
            ended = true
        case .affine(let transform):
            printer.push("(affine \(transform))")
        case .projection(let transform):
            printer.push("(projection \(transform))")
        case .filter(let filter):
            printer.push("(filter \(filter))")
        case .animation(let animation):
            printer.push("(animation \(animation))")
        case .view(let factory):
            printer.push("(view \(factory))")
        case .accessibility:
            printer.push("(accessibility)")
        case .identity:
            printer.push("(identity)")
        case .geometryGroup:
            printer.push("(geometryGroup)")
        case .compositingGroup:
            printer.push("(compositingGroup)")
        case .archive:
            printer.push("(archive )")
        case .renderNodeLayer(let updateContent):
            printer.push("(renderNodeLayer \(updateContent)")
        case .gestureRecognizers(let gestureRecognizers):
            printer.push("(gestureRecognizers \(gestureRecognizers))")
        }
        printer.pop(ended)
    }
}
