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
public struct RasterizationOptions: Equatable {

    @ProxyCodable
    internal var colorMode: ColorRenderingMode

    internal var rbColorMode: Int32?

    @CodableRawRepresentable
    internal var flags: Flags

    internal var maxDrawableCount: Int8

    internal init(colorMode: ColorRenderingMode = .nonLinear,
                  rbColorMode: Int32? = nil,
                  flags: RasterizationOptions.Flags = Flags(),
                  maxDrawableCount: Int8) {
        self.colorMode = colorMode
        self.rbColorMode = rbColorMode
        self.flags = flags
        self.maxDrawableCount = maxDrawableCount
    }

    internal struct Flags: OptionSet, Equatable {

        internal let rawValue: UInt8

        internal static let enableRenderBox: Flags = .init(rawValue: 0x1)
    }

    @inline(__always)
    internal var isEnableRenderBox: Bool {
        flags.contains(.enableRenderBox)
    }
}

@propertyWrapper
@available(iOS 13.0, *)
internal struct CodableRawRepresentable<T: Equatable>: Equatable {

    internal var wrappedValue: T

    internal init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}
