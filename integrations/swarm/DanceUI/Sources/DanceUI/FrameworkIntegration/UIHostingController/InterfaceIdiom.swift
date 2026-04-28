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

import UIKit

// MARK: InterfaceIdiomType

internal protocol InterfaceIdiomType {
    static func accepts<I>(_ type: I.Type) -> Bool where I: InterfaceIdiomType
}

extension InterfaceIdiomType {
    internal static func accepts(_ type: (some InterfaceIdiomType).Type) -> Bool {
        self.self == type
    }
}

internal enum InterfaceIdiom {}

extension InterfaceIdiom {
    internal struct TouchBar: InterfaceIdiomType {}
    internal struct Pad: InterfaceIdiomType {}
    internal struct Watch: InterfaceIdiomType {}
    internal struct TV: InterfaceIdiomType {}
    internal struct Phone: InterfaceIdiomType {}
    internal struct Mac: InterfaceIdiomType {}
    internal struct CarPlay: InterfaceIdiomType {}
}

// MARK: AnyInterfaceIdiomType

internal struct AnyInterfaceIdiomType {
    fileprivate let base: AnyInterfaceIdiomTypeBox.Type
}

extension AnyInterfaceIdiomType: Equatable {
    internal static func == (lhs: AnyInterfaceIdiomType, rhs: AnyInterfaceIdiomType) -> Bool {
        lhs.base.isEqual(to: rhs.base)
    }
}

extension AnyInterfaceIdiomType {
    @inline(__always)
    internal static var touchBar: AnyInterfaceIdiomType { AnyInterfaceIdiomType(base: InterfaceIdiomTypeBox<InterfaceIdiom.TouchBar>.self) }
    @inline(__always)
    internal static var pad: AnyInterfaceIdiomType { AnyInterfaceIdiomType(base: InterfaceIdiomTypeBox<InterfaceIdiom.Pad>.self) }
    @inline(__always)
    internal static var watch: AnyInterfaceIdiomType { AnyInterfaceIdiomType(base: InterfaceIdiomTypeBox<InterfaceIdiom.Watch>.self) }
    @inline(__always)
    internal static var tv: AnyInterfaceIdiomType { AnyInterfaceIdiomType(base: InterfaceIdiomTypeBox<InterfaceIdiom.TV>.self) }
    @inline(__always)
    internal static var phone: AnyInterfaceIdiomType { AnyInterfaceIdiomType(base: InterfaceIdiomTypeBox<InterfaceIdiom.Phone>.self) }
    @inline(__always)
    internal static var mac: AnyInterfaceIdiomType { AnyInterfaceIdiomType(base: InterfaceIdiomTypeBox<InterfaceIdiom.Mac>.self) }
    @inline(__always)
    internal static var carplay: AnyInterfaceIdiomType { AnyInterfaceIdiomType(base: InterfaceIdiomTypeBox<InterfaceIdiom.CarPlay>.self) }
}

// MARK: - InterfaceIdiomTypeBox

private struct InterfaceIdiomTypeBox<IdiomType>: AnyInterfaceIdiomTypeBox where IdiomType: InterfaceIdiomType {
    static func isEqual(to type: AnyInterfaceIdiomTypeBox.Type) -> Bool {
        type is InterfaceIdiomTypeBox<IdiomType>.Type
    }

    static func accepts(_ type: (some InterfaceIdiomType).Type) -> Bool {
        IdiomType.accepts(type)
    }
}

// MARK: - AnyInterfaceIdiomTypeBox

private protocol AnyInterfaceIdiomTypeBox {
    static func isEqual(to: AnyInterfaceIdiomTypeBox.Type) -> Bool
    static func accepts<I>(_ type: I.Type) -> Bool where I: InterfaceIdiomType
}

// MARK: - Internal API

extension InterfaceIdiom {
    internal struct Input: ViewInput {
        internal typealias Value = AnyInterfaceIdiomType?
        @inline(__always)
        internal static var defaultValue: AnyInterfaceIdiomType? { nil }
        internal static let targetValue: AnyInterfaceIdiomType = .phone
    }
}

extension UIUserInterfaceIdiom {
    internal var idiom: AnyInterfaceIdiomType? {
        switch rawValue {
        case UIUserInterfaceIdiom.unspecified.rawValue: return nil
        case UIUserInterfaceIdiom.phone.rawValue: return .phone
        case UIUserInterfaceIdiom.pad.rawValue: return .pad
        case UIUserInterfaceIdiom.tv.rawValue: return .tv
        case UIUserInterfaceIdiom.carPlay.rawValue: return .carplay
        // There is no UIUserInterfaceIdiom.watch exposed currently
        case 4: return .watch
        // UIUserInterfaceIdiom.mac.rawValue
        case 5: return .mac
        default: return nil
        }
    }
}
