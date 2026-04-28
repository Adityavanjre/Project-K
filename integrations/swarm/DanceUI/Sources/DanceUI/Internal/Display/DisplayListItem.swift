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
extension DisplayList {
    
    @_spi(DanceUICompose)
    public struct Item: Equatable {
        
        public init(frame: CGRect, version: DisplayList.Version, value: DisplayList.Item.Value, identity: DisplayList.Identity) {
            self.frame = frame
            self.version = version
            self.value = value
            self.identity = identity
        }

        public var frame: CGRect

        public var version: DisplayList.Version

        public var value: Value

        public var identity: Identity
        
        @inlinable
        internal var features: Features {
            switch self.value {
            case .content(let content):
                return content.features
            case .effect(let effect, let contentList):
                return effect.features(contentList)
            case .empty:
                return Features()
            }
        }
        
        @inlinable
        public static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.version == rhs.version &&
            lhs.identity == rhs.identity
        }
        
        @_spi(DanceUICompose)
        @inlinable
        public mutating func canonicalize() {
            switch value {
            case .content(let content):
                if frame.isEmpty {
                    self.value = content.canonicalizeForFrameIsEmpty()
                } else {
                    self.value = content.canonicalize()
                }
                
            case .effect(let effect, let displaylist):
                self.value = effect.canonicalize(displaylist, item: &self)
            case .empty:
                self.value = .empty
            }
        }
        
        @inline(__always)
        @usableFromInline
        internal func canonicalized() -> DisplayList.Item {
            var canonicalized = self
            canonicalized.canonicalize()
            return canonicalized
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Item {
    
    @_spi(DanceUICompose)
    public enum Value: DisplayListSExpPrintable {

        case content(DisplayList.Content)
        
        case effect(DisplayList.Effect, DisplayList)
        
        case empty
        
        internal func print(_ printer: inout DisplayList._SExpPrinter) {
            switch self {
            case .content(let content):
                printer.push("(content-seed \(content.seed.value))")
                printer.pop()
                content.print(&printer)
            case .effect(let effect, let contentList):
                printer.push("(effect")
                effect.print(&printer)
                contentList.print(&printer)
                printer.pop(true)
            case .empty:
                printer.push("(empty)")
                printer.pop()
            }
        }
        
        internal func minimalPrint(_ printer: inout DisplayList._SExpPrinter) {
            switch self {
            case .content(let content):
                printer.push("(S \(content.seed.value))")
                printer.pop()
                content.minimalPrint(&printer)
            case .effect(let effect, let contentList):
                printer.push("(E")
                effect.minimalPrint(&printer)
                contentList.minimalPrint(&printer)
                printer.pop(true)
            case .empty:
                printer.push("()")
                printer.pop()
            }
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Item: DisplayListSExpPrintable {
    
    internal func print(_ printer: inout DisplayList._SExpPrinter) {
        printer.push("(item #:identity \(self.identity.value) #:version \(self.version.value)")
        printer.push("(frame \(frame))")
        printer.pop()
        value.print(&printer)
        printer.pop(true)
    }
    
    internal func minimalPrint(_ printer: inout DisplayList._SExpPrinter) {
        printer.push("(item #:I \(self.identity.value) #:V \(self.version.value) #:F \(frame)")
        value.minimalPrint(&printer)
        printer.pop(true)
    }
}

internal struct CodableRect: Encodable {
    
    internal var base: CGRect
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(base.origin.x)
        try container.encode(base.origin.y)
        try container.encode(base.size.width)
        try container.encode(base.size.height)
    }
}

extension CGRect {
    
    @inline(__always)
    var codable: CodableRect {
        CodableRect(base: self)
    }
}
