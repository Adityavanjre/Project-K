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
internal struct ViewTransform: Equatable, CustomStringConvertible {

    private var chunks: [Chunk]

    internal var positionAdjustment: CGSize

    @inlinable
    internal init() {
        chunks = []
        positionAdjustment = .zero
    }

    @inlinable
    internal mutating func applyPositionAdjustment(_ positionAdjustment: CGSize) {
        self.positionAdjustment = positionAdjustment
    }

    @inlinable
    internal func applyingPositionAdjustment(_ positionAdjustment: CGSize) -> ViewTransform {
        var copied = self
        copied.applyPositionAdjustment(positionAdjustment)
        return copied
    }

    @inlinable
    internal var containingScrollLayout: _ScrollLayout? {
        guard !chunks.isEmpty else {
            return nil
        }
        var stop = false
        var layout: _ScrollLayout? = nil
        for chunk in chunks {
            chunk.forEachNormal(&stop) { (item, subflag) in
                item.apply(to: &layout)
            }
            guard !stop else {
                break
            }
        }
        return layout
    }

    @inline(__always)
    fileprivate mutating func mutableChunk() -> Chunk {
        let lastIndex = chunks.count - 1
        if lastIndex >= 0, isKnownUniquelyReferenced(&chunks[lastIndex]) {
            return chunks[lastIndex]
        } else {
            let chunk = Chunk()
            chunks.append(chunk)
            return chunk
        }
    }

    @inlinable
    internal mutating func appendScrollLayout(_ layout: _ScrollLayout) {
        mutableChunk().appendScrollLayout(layout)
    }

    @inlinable
    internal mutating func appendCoordinateSpace(name: AnyHashable) {
        mutableChunk().appendCoordinateSpace(name: name)
    }

    @inlinable
    internal mutating func appendSizedSpace(name: AnyHashable, size: CGSize) {
        mutableChunk().appendSizedSpace(name: name, size: size)
    }

    @inlinable
    internal mutating func appendAffineTransform(_ affineTransform: CGAffineTransform, inverse: Bool) {
        guard affineTransform.a == 1.0 &&
                affineTransform.b == 0.0 &&
                affineTransform.c == 0.0 &&
                affineTransform.d == 1.0 else {
            let chunk = mutableChunk()
            chunk.appendAffineTransform(affineTransform, inverse: inverse)
            return
        }
        let tx = inverse ? -affineTransform.tx : affineTransform.tx
        let ty = inverse ? -affineTransform.ty : affineTransform.ty
        if tx != 0.0 || ty != 0.0 {
            let chunk = mutableChunk()
            chunk.appendTranslation(.init(width: tx, height: ty))
        }
    }

    @inlinable
    internal mutating func appendProjectionTransform(_ projectionTransform: ProjectionTransform, inverse: Bool) {
        if projectionTransform.isAffine {
            appendAffineTransform(projectionTransform.affineTransformValue, inverse: inverse)
        } else {
            let chunk = mutableChunk()
            chunk.appendProjectionTransform(projectionTransform, inverse: inverse)
        }
    }

    @inlinable
    internal mutating func appendViewOrigin(_ viewOrigin: ViewOrigin) {
        let position = viewOrigin.value
        var nextPositionAdjustment = CGSize(width: position.x, height: position.y)
        nextPositionAdjustment.width -= positionAdjustment.width
        nextPositionAdjustment.height -= positionAdjustment.height

        if nextPositionAdjustment != .zero {
            let chunk = mutableChunk()
            chunk.appendTranslation(CGSize(width: -nextPositionAdjustment.width, height: -nextPositionAdjustment.height))
        }

        positionAdjustment = CGSize(width: position.x, height: position.y)
    }

    @inlinable
    internal mutating func appendTranslation(_ size: CGSize) {
        if size != .zero {
            let chunk = mutableChunk()
            chunk.appendTranslation(size)
        }
    }

    @inlinable
    internal mutating func clearPositionAdjustment() {
        positionAdjustment = .zero
    }

    @inlinable
    internal func convert(_ conversion: Conversion, space: CoordinateSpace, point: CGPoint) -> CGPoint {
        var copiedPoint = point
        convert(conversion, space: space) { (item: ViewTransform.Item) -> Void in
            copiedPoint.applyTransform(item: item)
        }
        return copiedPoint
    }

    @inlinable
    internal func convert(_ conversion: Conversion, space: CoordinateSpace, points: inout [CGPoint]) {
        convert(conversion, space: space) { (item: ViewTransform.Item) -> Void in
            points.applyTransform(item: item)
        }
    }

    @inlinable
    internal func convert(_ conversion: Conversion, space: CoordinateSpace, _ body: (_ item: Item) -> Void) {

        var currentSpace = space

        if conversion.finished(at: currentSpace) {
            return
        }

        var shouldConvertNext = conversion.shouldConvert(at: currentSpace)

        forEach(inverted: shouldInvert(for: conversion)) { (item, shouldStop) in

            if let itemSpace = item.coordinateSpace {

                let shouldConvertCurrent = shouldConvertNext

                if itemSpace == space {

                    conversion.atSpace(coordinateSpace: &currentSpace)

                    if conversion.finished(at: currentSpace) {
                        shouldStop = true
                    } else {
                        shouldConvertNext = conversion.shouldConvert(at: currentSpace)
                    }

                }

                if shouldStop
                        ? shouldConvertCurrent
                        : (shouldConvertCurrent || shouldConvertNext) {
                    body(item)
                }

            } else {
                if shouldConvertNext {
                    body(item)
                }
            }

        }
    }

    @inline(__always)
    private func shouldInvert(for conversion: Conversion) -> Bool {
        switch conversion {
        case .toGlobal, .fromGlobal:
            return false
        case .fromLocal, .toLocal:
            return true
        }
    }

    @inlinable
    internal func forEach(inverted: Bool, _ body: (_ item: Item, _ flag: inout Bool) -> Void) {
        var shouldStop = false
        if inverted {
            for eachChunk in chunks.reversed() {
                eachChunk.forEachInverse(&shouldStop, body)
                if shouldStop {
                    return
                }
            }
        } else {
            for eachChunk in chunks {
                eachChunk.forEachNormal(&shouldStop, body)
                if shouldStop {
                    return
                }
            }
        }
    }

    internal var description: String {
        var itemDescs: [String] = []

        forEach(inverted: false) { (item, _) in
            itemDescs.append(item.description)
        }

        return "<ViewTransform; Chunks Count = \(chunks.count); positionAdjustment = \(positionAdjustment)>\n\tItems: \(itemDescs.joined(separator: "\n\t\t"))"
    }

    fileprivate final class Chunk: Equatable {

        internal var tags: [Tag] = []

        internal var values: [CGFloat] = []

        internal var spaces: [AnyHashable] = []

        @inlinable
        internal static func == (lhs: Chunk, rhs: Chunk) -> Bool {
            lhs.tags == rhs.tags &&
                lhs.values == rhs.values &&
                lhs.spaces == rhs.spaces
        }

        @inlinable
        internal func appendSizedSpace(name: AnyHashable, size: CGSize) {
            tags.append(.sized_space)
            values.append(size.width)
            values.append(size.height)
            spaces.append(name)
        }

        @inlinable
        internal func appendSizedTranslation(_ size: CGSize) {
            if tags.isEmpty || tags.first != .translation {
                tags.append(.translation)
            }
            values.append(size.width)
            values.append(size.height)
        }

        @inlinable
        internal func appendCoordinateSpace(name: AnyHashable) {
            tags.append(.space)
            spaces.append(name)
        }

        @inlinable
        internal func appendProjectionTransform(_ projectionTransform: ProjectionTransform, inverse: Bool) {
            tags.append(inverse ? .projection_inverse : .projection)
            values.append(contentsOf: [
                projectionTransform.m11,
                projectionTransform.m12,
                projectionTransform.m13,
                projectionTransform.m21,
                projectionTransform.m22,
                projectionTransform.m23,
                projectionTransform.m31,
                projectionTransform.m32,
                projectionTransform.m33,
            ])
        }

        @inlinable
        internal func appendAffineTransform(_ affineTransform: CGAffineTransform, inverse: Bool) {
            tags.append(inverse ? .affine_inverse : .affine)
            values.append(contentsOf: [
                affineTransform.a,
                affineTransform.b,
                affineTransform.c,
                affineTransform.d,
                affineTransform.tx,
                affineTransform.ty,
            ])
        }

        @inlinable
        internal func appendTranslation(_ size: CGSize) {
            tags.append(.translation)
            values.append(contentsOf: [
                size.width,
                size.height
            ])
        }

        @inlinable
        internal func appendScrollLayout(_ layout: _ScrollLayout) {
            tags.append(.scroll_layout)
            values.append(contentsOf: [
                layout.contentOffset.x,
                layout.contentOffset.y,
                layout.size.width,
                layout.size.height,
                layout.visibleRect.origin.x,
                layout.visibleRect.origin.y,
                layout.visibleRect.size.width,
                layout.visibleRect.size.height
            ])
        }

        @inlinable
        internal func forEachNormal(_ shouldStop: inout Bool, _ body: (_ item: Item, _ shouldStop: inout Bool) -> Void) {
            var valueIndex = values.startIndex
            var spaceIndex = spaces.startIndex
            for eachTag in tags {
                let valueCount = eachTag.valueElementsCount
                let sapceCount = eachTag.spaceElementsCount
                let item = eachTag.makeItem(
                    values: &values[valueIndex..<(valueIndex + valueCount)],
                    spaces: &spaces[spaceIndex..<(spaceIndex + sapceCount)],
                    inverted: false
                )
                body(item, &shouldStop)

                if shouldStop {
                    break
                }

                valueIndex += valueCount
                spaceIndex += sapceCount
            }
        }

        @inlinable
        internal func forEachInverse(_ shouldStop: inout Bool, _ body: (_ item: Item, _ shouldStop: inout Bool) -> Void) {
            var valueIndex = values.endIndex
            var spaceIndex = spaces.endIndex
            for eachTag in tags.reversed() {
                let valueCount = eachTag.valueElementsCount
                let sapceCount = eachTag.spaceElementsCount
                let item = eachTag.makeItem(
                    values: &values[(valueIndex - valueCount)..<valueIndex],
                    spaces: &spaces[(spaceIndex - sapceCount)..<spaceIndex],
                    inverted: true
                )
                body(item, &shouldStop)

                if shouldStop {
                    break
                }

                valueIndex -= valueCount
                spaceIndex -= sapceCount
            }
        }
        fileprivate enum Tag: Hashable {

            case translation
            case affine
            case affine_inverse
            case projection
            case projection_inverse
            case space
            case sized_space
            case scroll_layout

            @inlinable
            internal func makeItem(values: inout ArraySlice<CGFloat>, spaces: inout ArraySlice<AnyHashable>, inverted: Bool) -> ViewTransform.Item {
                let valueStartIndex = values.startIndex
                let spaceStartIndex = spaces.startIndex
                let factor: CGFloat = inverted ? -1 : 1
                switch self {
                case .translation:
                    return .translation(
                        CGSize(
                            width: factor * values[valueStartIndex &+ 0],
                            height: factor * values[valueStartIndex &+ 1]
                        )
                    )
                case .affine:
                    return .affineTransform(
                        CGAffineTransform(
                            a: values[valueStartIndex &+ 0],
                            b: values[valueStartIndex &+ 1],
                            c: values[valueStartIndex &+ 2],
                            d: values[valueStartIndex &+ 3],
                            tx: values[valueStartIndex &+ 4],
                            ty: values[valueStartIndex &+ 5]
                        ),
                        inverse: inverted
                    )
                case .affine_inverse:
                    return .affineTransform(
                        CGAffineTransform(
                            a: values[valueStartIndex &+ 0],
                            b: values[valueStartIndex &+ 1],
                            c: values[valueStartIndex &+ 2],
                            d: values[valueStartIndex &+ 3],
                            tx: values[valueStartIndex &+ 4],
                            ty: values[valueStartIndex &+ 5]
                        ),
                        inverse: !inverted
                    )
                case .projection:
                    return .projectionTransform(ProjectionTransform(m11: values[valueStartIndex &+ 0], m12: values[valueStartIndex &+ 1], m13: values[valueStartIndex &+ 2], m21: values[valueStartIndex &+ 3], m22: values[valueStartIndex &+ 4], m23: values[valueStartIndex &+ 5], m31: values[valueStartIndex &+ 6], m32: values[valueStartIndex &+ 7], m33: values[valueStartIndex &+ 8]), inverse: inverted)
                case .projection_inverse:
                    return .projectionTransform(ProjectionTransform(m11: values[valueStartIndex &+ 0], m12: values[valueStartIndex &+ 1], m13: values[valueStartIndex &+ 2], m21: values[valueStartIndex &+ 3], m22: values[valueStartIndex &+ 4], m23: values[valueStartIndex &+ 5], m31: values[valueStartIndex &+ 6], m32: values[valueStartIndex &+ 7], m33: values[valueStartIndex &+ 8]), inverse: !inverted)
                case .space:
                    return .coordinateSpace(name: spaces[spaceStartIndex &+ 0])
                case .sized_space:
                    return .sizedSpace(name: spaces[spaceStartIndex &+ 0], size: CGSize(width: values[valueStartIndex &+ 0], height: values[valueStartIndex &+ 1]))
                case .scroll_layout:
                    return .scrollLayout(_ScrollLayout(
                                            contentOffset: CGPoint(x: values[valueStartIndex &+ 0], y: values[valueStartIndex &+ 1]),
                                            size: CGSize(width: values[valueStartIndex &+ 2], height: values[valueStartIndex &+ 3]),
                                            visibleRect: CGRect(x: values[valueStartIndex &+ 4], y: values[valueStartIndex &+ 5], width: values[valueStartIndex &+ 6], height: values[valueStartIndex &+ 7])))
                }
            }

            @inlinable
            internal var valueElementsCount: Int {
                switch self {
                case .translation:          return 2
                case .affine:               return 6
                case .affine_inverse:       return 6
                case .projection:           return 9
                case .projection_inverse:   return 9
                case .space:                return 0
                case .sized_space:          return 2
                case .scroll_layout:        return 8
                }
            }

            @inlinable
            internal var spaceElementsCount: Int {
                switch self {
                case .translation:          return 0
                case .affine:               return 0
                case .affine_inverse:       return 0
                case .projection:           return 0
                case .projection_inverse:   return 0
                case .space:                return 1
                case .sized_space:          return 1
                case .scroll_layout:        return 0
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension ViewTransform {

    internal enum Item: CustomStringConvertible {

        case translation(CGSize)

        case affineTransform(CGAffineTransform, inverse: Bool)

        case projectionTransform(ProjectionTransform, inverse: Bool)

        case coordinateSpace(name: AnyHashable)

        case sizedSpace(name: AnyHashable, size: CGSize)

        case scrollLayout(_ScrollLayout)
        internal var description: String {
            switch self {
            case let .translation(translation):
                return "Translation = (x: \(translation.width), y: \(translation.height))"
            case let .affineTransform(transform, inverse):
                return "AffineTransform = \(transform); Inverse = \(inverse)"
            case let .projectionTransform(transform, inverse):
                return "ProjectionTransform = \(transform); Inverse = \(inverse)"
            case let .coordinateSpace(name):
                return "CoordinateSpace = \(name)"
            case let .sizedSpace(name, size):
                return "SizedSpace = (name: \(name), size: \(size)"
            case let .scrollLayout(layout):
                return "ScrollLayout = \(layout)"
            }
        }
        @inlinable
        internal var name: AnyHashable {
            switch self {
            case let .translation(size):
                return AnyHashable(size)
            case let .affineTransform(transform, _):
                return AnyHashable(transform.a)
            case let .projectionTransform(transform, _):
                return AnyHashable(transform.m11)
            case let .coordinateSpace(name):
                return name
            case let .sizedSpace(name, _):
                return name
            case let .scrollLayout(layout):
                return AnyHashable(layout.contentOffset.x)
            }
        }
        @inlinable
        internal var coordinateSpace: CoordinateSpace? {
            switch self {
            case .translation, .affineTransform, .projectionTransform, .scrollLayout:
                return nil
            case let .coordinateSpace(name):
                return .named(name)
            case let .sizedSpace(name, _):
                return .named(name)
            }
        }

        @inlinable
        internal func apply(to layout: inout _ScrollLayout?) {
            switch self {
            case .translation(let size):
                guard var scrollLayout = layout else {
                    return
                }
                scrollLayout.contentOffset.apply(size)
                scrollLayout.visibleRect.origin.apply(size)
                layout = scrollLayout
            case .affineTransform(var transform, let inverse):
                if (transform.b != 0 || transform.c != 0) && (transform.a != 0 || transform.d != 0) {
                    layout = nil
                } else {
                    guard var scrollLayout = layout else {
                        return
                    }
                    if inverse {
                        transform = transform.inverted()
                    }
                    scrollLayout.contentOffset = scrollLayout.contentOffset.applying(transform)
                    scrollLayout.size = scrollLayout.size.applying(transform)
                    scrollLayout.visibleRect = scrollLayout.visibleRect.applying(transform)
                    layout = scrollLayout
                }
            case .projectionTransform:
                layout = nil
            case .coordinateSpace, .sizedSpace:
                break
            case .scrollLayout(let scrollLayout):
                layout = scrollLayout
            }
        }
    }
}

@available(iOS 13.0, *)
extension ViewTransform {

    internal enum Conversion {

        case toGlobal

        case fromLocal

        case toLocal

        case fromGlobal

        fileprivate func shouldConvert(at coordinateSpace: CoordinateSpace) -> Bool {
            switch self {
            case .toGlobal:
                return coordinateSpace != .global
            case .fromLocal:
                return coordinateSpace == .local
            case .toLocal:
                return coordinateSpace != .local
            case .fromGlobal:
                return coordinateSpace == .global
            }
        }

        fileprivate func atSpace(coordinateSpace: inout CoordinateSpace) {
            switch self {
            case .fromLocal, .toLocal:
                coordinateSpace = .local
            case .fromGlobal, .toGlobal:
                coordinateSpace = .global
            }
        }

        fileprivate func finished(at coordinateSpace: CoordinateSpace) -> Bool {
            switch self {
            case .toGlobal:
                switch coordinateSpace {
                case .global:
                    return true
                case .local, .named:
                    return false
                }
            case .fromLocal:
                return false
            case .toLocal:
                switch coordinateSpace {
                case .global:
                    return false
                case .local:
                    return true
                case .named:
                    return false
                }
            case .fromGlobal:
                return false
            }
        }

        #if BINARY_COMPATIBLE_TEST
        internal func fileprivate_shouldConvert(at coordinateSpace: CoordinateSpace) -> Bool {
            shouldConvert(at: coordinateSpace)
        }
        internal func fileprivate_atSpace(coordinateSpace: inout CoordinateSpace) {
            atSpace(coordinateSpace: &coordinateSpace)
        }
        internal func fileprivate_finished(at coordinateSpace: CoordinateSpace) -> Bool {
            finished(at: coordinateSpace)
        }

        #endif

    }

}

@available(iOS 13.0, *)
protocol ApplyViewTransform {

    mutating func convert(from: CoordinateSpace, transform: ViewTransform)

    mutating func convert(to: CoordinateSpace, transform: ViewTransform)

}

@available(iOS 13.0, *)
extension Array /* : ApplyViewTransform */ where Element == CGPoint {

    @inline(__always)
    internal mutating func convert(from coordinateSpace: CoordinateSpace, transform: ViewTransform) {
        transform.convert(.fromGlobal, space: coordinateSpace, points: &self)
    }

    @inline(__always)
    internal mutating func convert(to coordinateSpace: CoordinateSpace, transform: ViewTransform) {
        transform.convert(.toLocal, space: coordinateSpace, points: &self)
    }

}

@available(iOS 13.0, *)
extension CGPoint: ApplyViewTransform {

    internal mutating func apply(_ translation: CGSize) {
        x += translation.width
        y += translation.height
    }

    internal mutating func convert(to coordinateSpace: CoordinateSpace, transform: ViewTransform) {
        self = transform.convert(.toLocal, space: coordinateSpace, point: self)
    }

    internal mutating func convert(from coordinateSpace: CoordinateSpace, transform: ViewTransform) {
        self = transform.convert(.fromGlobal, space: coordinateSpace, point: self)
    }
}
