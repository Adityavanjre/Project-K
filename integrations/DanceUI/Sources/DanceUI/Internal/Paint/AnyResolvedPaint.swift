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
@_spi(DanceUICompose)
public class AnyResolvedPaint: Equatable {
    
    public static func == (lhs: AnyResolvedPaint, rhs: AnyResolvedPaint) -> Bool {
        lhs.isEqual(to: rhs)
    }
    
    internal func fill(_: Path, style: FillStyle, in: GraphicsContext, bounds: CGRect?) {
        _intentionallyLeftBlank()
    }

    internal func visit<Visitor: ResolvedPaintVisitor>(_ visitor: inout Visitor) {
        _intentionallyLeftBlank()
    }

    internal var isOpaque: Bool {
        false
    }

    internal func isEqual(to: AnyResolvedPaint) -> Bool {
        false
    }

    internal func `as`<A: ResolvedPaint>(type: A.Type) -> A? {
        let anyResolvedPaint = self as? _AnyResolvedPaint<A>
        return anyResolvedPaint?.paint
    }

    internal var isClear: Bool {
        false
    }
}

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public final class _AnyResolvedPaint<PaintType: ResolvedPaint>: AnyResolvedPaint {
    
    internal let paint: PaintType
    
    @_spi(DanceUICompose)
    public init(_ paint: PaintType) {
        self.paint = paint
    }
    
    override internal func fill(_ path: Path, style: FillStyle, in context: GraphicsContext, bounds: CGRect?) {
        paint.fill(path, style: style, in: context, bounds: bounds)
    }
    
    override internal func visit<Visitor: ResolvedPaintVisitor>(_ visitor: inout Visitor) {
        visitor.visitPaint(paint)
    }
    
    override internal var isOpaque: Bool {
        paint.isOpaque
    }
    
    override var isClear: Bool {
        paint.isClear
    }
    
    override func isEqual(to: AnyResolvedPaint) -> Bool {
        guard let value = to as? _AnyResolvedPaint else {
            return false
        }
        
        return value.paint == self.paint
    }
}
