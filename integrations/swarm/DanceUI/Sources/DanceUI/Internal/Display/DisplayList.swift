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
@_spi(DanceUICompose)
public struct DisplayList: Equatable {
    
    public var items: [DisplayList.Item] = []
    
    public var features: Features
    
    @_spi(DanceUICompose)
    @inlinable
    public init(item: Item) {
        switch item.value {
        case .content, .effect:
            self.init(items: [item], features: item.features)
        case .empty:
            self.init(items: [], features: [])
        }
    }
    
    @usableFromInline
    internal init(items: [Item], features: Features) {
        self.items = items
        self.features = features
    }
    
    @_spi(DanceUICompose)
    @inlinable
    public static var empty: DisplayList {
        DisplayList(items: [], features: .empty)
    }
    
    @_spi(DanceUICompose)
    @inlinable
    public mutating func append(contentOf list: DisplayList) {
        for item in list.items {
            switch item.value {
            case .empty:
                continue
            default:
                items.append(item)
                features = features.union(item.features)
            }
        }
    }
    
    @_spi(DanceUICompose)
    public struct Features: OptionSet, CustomStringConvertible {
        
        public let rawValue: UInt32
        
        @inline(__always)
        @usableFromInline
        internal static var empty: Features {
            .init(rawValue: 0x0)
        }
        
        internal static let isRequired: Features = .init(rawValue: 0x1)
        
        internal static let isView: Features = .init(rawValue: 0x2)
        internal static let isDynamicContent: Features = .init(rawValue: 0x4)
        
        internal static let updatesAsynchronously: Features = .init(rawValue: 0x8)
        
        internal static var gesture: Features {
            Features(rawValue: 0x8000_0000)
        }

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public var description: String {
            var features: [String] = []
            if self.contains(.isRequired) {
                features.append("isRequired")
            }
            if self.contains(.isView) {
                features.append("isView")
            }
            if self.contains(.isDynamicContent) {
                features.append("isDynamicContent")
            }
            if self.contains(.updatesAsynchronously) {
                features.append("updatesAsynchronously")
            }
            return "<Features: features = \(features.joined(separator: ", ")) ; rawValue = \(rawValue) >"
        }
        
    }
    
    @_spi(DanceUICompose)
    public struct Seed: Hashable {
        
        internal private(set) var value: UInt16
        
        @inline(__always)
        internal static var zero: Seed {
            Seed(value: 0)
        }
        
        @inline(__always)
        internal init(value: UInt16) {
            self.value = value
        }
        
@inline(__always)
        @_spi(DanceUICompose)
        public init(version: Version) {
            var value: UInt32 = 0
            if version.value > 0 {
                value = UInt32(version.value >> 0x10)
                value &*= 0x21
                value ^= UInt32(version.value & 0xffff)
                value &*= 2
                value &+= 1
            }
            self.value = UInt16(value & 0xFFFF)
        }
        
        @inline(__always)
        internal func invalidate() -> Seed {
            return Seed(value: self.value ^ 0xfffe)
        }
    }
    
    internal struct Index: Equatable {
        
        internal var identity: Identity
        
        internal var serial: UInt32
        
        @inline(__always)
        internal static var zero: Index {
            
            Index(identity: .zero, serial: 0)
        }
        
        internal mutating func skipIfNeeded(item: DisplayList.Item) {
            switch item.value {
            case .effect(_, let contentList):
                skip(list: contentList)
            default:
                break
            }
        }
        
        internal mutating func skip(list: DisplayList) {
            for item in list.items {
                serial &+= 1
                if item.identity.isValid {
                    skip(item: item)
                }
            }
        }
        
        private mutating func skip(item: DisplayList.Item) {
            switch item.value {
            case .content(let content):
                let skipInfo = content.skipIfNeeded
                guard skipInfo.needSkip, let list = skipInfo.list else {
                    return
                }
                skip(list: list)
            case .effect(let effect, let list):
                skip(list: list)
                let skipInfo = effect.skipIfNeeded
                guard skipInfo.needSkip, let list = skipInfo.list else {
                    return
                }
                skip(list: list)
            case .empty:
                return
            }
        }
        
    }
    
    @_spi(DanceUICompose)
    public struct Identity: Encodable, Hashable {
        
        @_spi(DanceUICompose)
        public private(set) var value: UInt32
        
        @_spi(DanceUICompose)
        public init(value: UInt32) {
            self.value = value
        }
        
        @inline(__always)
        internal static var zero: Identity {
            Identity(value: 0)
        }
        
        @inlinable
        @_spi(DanceUICompose)
        public static func make() -> Identity {
            lastIdentity &+= 1
            return Identity(value: lastIdentity)
        }
        
        internal var isValid: Bool {
            value != 0
        }
        
        @_spi(DanceUICompose)
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
    
    @_spi(DanceUICompose)
    public struct Version: Comparable, Hashable, Codable {
        
        @usableFromInline
        internal var value: Int
        
        @usableFromInline
        internal static var lastValue = 0
        
        @inline(__always)
        @_spi(DanceUICompose) 
        public static var zero: Version {
            Version(value: 0)
        }
        
        @inlinable
        @_spi(DanceUICompose)
        public static func make() -> Version {
            lastValue &+= 1
            return Version(value: lastValue)
        }
        
        @inline(__always)
        @_spi(DanceUICompose)
        public init(value: Int) {
            self.value = value
        }
        
        #if DEBUG
        @inlinable
        internal static func forTest_make(value: Int) -> Version {
            return Version(value: value)
        }
        #endif
        
        @inlinable
        internal mutating func max(rhs: Version) {
            value = Swift.max(value, rhs.value)
        }
        
        @inlinable
        public static func < (lhs: Version, rhs: Version) -> Bool {
            return lhs.value < rhs.value
        }
        
    }
    
    @_spi(DanceUICompose)
    public struct Properties: OptionSet {
        
        @_spi(DanceUICompose)
        public let rawValue: UInt32
        
        @_spi(DanceUICompose)
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        internal static let empty: Properties = .init(rawValue: 0x0)
        
        internal static let isHitTestingDisabled: Properties = .init(rawValue: 0x2)
    }
}

@available(iOS 13.0, *)
extension DisplayList.Content {
    
    @inline(__always)
    fileprivate var skipIfNeeded: (needSkip: Bool, list: DisplayList?) {
        switch self.value {
        case .flattened(let list, _, _):
            return (true, list)
        default:
            return (false, nil)
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.Effect {
    
    @inline(__always)
    fileprivate var skipIfNeeded: (needSkip: Bool, list: DisplayList?) {
        switch self {
        case .mask(let list):
            return (true, list)
        default:
            return (false, nil)
        }
    }
}

@available(iOS 13.0, *)
@usableFromInline
internal var lastIdentity: UInt32 = 0
@available(iOS 13.0, *)
extension PreferencesInputs {
    
    @inlinable
    internal var requiresDisplayList: Bool {
        get {
            contains(DisplayList.Key.self)
        }
        set {
            if newValue {
                add(DisplayList.Key.self)
            } else {
                remove(DisplayList.Key.self)
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension _ViewOutputs {
    
    internal var displayList: Attribute<DisplayList>? {
        get {
            self[DisplayList.Key.self]
        }
        
        set {
            self[DisplayList.Key.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension DisplayList {
    
    internal struct Key: PreferenceKey {
        
        internal typealias Value = DisplayList
        
        internal static var defaultValue: DisplayList {
            DisplayList.empty
        }
        
        internal static func reduce(value: inout DisplayList, nextValue: () -> DisplayList) {
            let newValue = nextValue()
            value.append(contentOf: newValue)
        }
        
        internal static var _includesRemovedValues: Bool {
            true
        }
        
    }
}

@available(iOS 13.0, *)
extension DisplayList: CustomDebugStringConvertible, DisplayListSExpPrintable {
    @_spi(DanceUICompose)
    public var debugDescription: String {
        var desc = "(display-list"
        var printer = _SExpPrinter()
        print(&printer)
        desc += printer.print()
        desc += ")"
        return desc
    }
    
    @_spi(DanceUICompose)
    public var minimalDebugDescription: String {
        var desc = "(DL"
        var printer = _SExpPrinter()
        minimalPrint(&printer)
        desc += printer.print()
        desc += ")"
        return desc
    }
    
    internal func print(_ printer: inout DisplayList._SExpPrinter) {
        for item in items {
            item.print(&printer)
        }
    }
    
    internal func minimalPrint(_ printer: inout _SExpPrinter) {
        for item in items {
            item.minimalPrint(&printer)
        }
    }
}

@available(iOS 13.0, *)
internal protocol DisplayListSExpPrintable {
    func print(_ printer: inout DisplayList._SExpPrinter)
    
    func minimalPrint(_ printer: inout DisplayList._SExpPrinter)
}

@available(iOS 13.0, *)
extension DisplayListSExpPrintable {
    func minimalPrint(_ printer: inout DisplayList._SExpPrinter) {
        print(&printer)
    }
}

@available(iOS 13.0, *)
extension DisplayList {
    internal struct _SExpPrinter {
        
        private var value: String = ""
        
        private var depth: String = ""
        
        internal func print() -> String {
            value
        }
        
        internal mutating func push(_ string: String) {
            depth.append("  ")
            value.append("\n")
            value.append(depth)
            value.append(string)
        }
        
        internal mutating func pop(_ end: Bool = false) {
            if end {
                value.append(")")
            }
            depth.removeLast(2)
        }
    }
}

@available(iOS 13.0, *)
struct DisplayPrintEnabledKey: DefaultFalseBoolEnvKey {
    
    static var raw: String {
        "DANCEUI_PRINT_TREE"
    }
}

@available(iOS 13.0, *)
extension EnvValue where K == DisplayPrintEnabledKey {
    
    private static let displayPrintEnabledValue: Self = .init()
    
    internal static var isDisplayPrintEnabled: Bool {
        displayPrintEnabledValue.value
    }
}
