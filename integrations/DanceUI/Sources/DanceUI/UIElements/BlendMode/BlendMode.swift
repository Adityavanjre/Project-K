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

import CoreGraphics

/// Modes for compositing a view with overlapping content.
@available(iOS 13.0, *)
public enum BlendMode : Hashable {

    case normal

    case multiply

    case screen

    case overlay

    case darken

    case lighten

    case colorDodge

    case colorBurn

    case softLight

    case hardLight

    case difference

    case exclusion

    case hue

    case saturation

    case color

    case luminosity

    case sourceAtop

    case destinationOver

    case destinationOut

    case plusDarker

    case plusLighter
    // swift-format-ignore: NoCasesWithOnlyFallthrough
    @_spi(DanceUICompose)
    public init(_ blendMode: CGBlendMode) {
        switch blendMode {
        case .normal: self = .normal
        case .multiply: self = .multiply
        case .screen: self = .screen
        case .overlay: self = .overlay
        case .darken: self = .darken
        case .lighten: self = .lighten
        case .colorDodge: self = .colorDodge
        case .colorBurn: self = .colorBurn
        case .softLight: self = .softLight
        case .hardLight: self = .hardLight
        case .difference: self = .difference
        case .exclusion: self = .exclusion
        case .hue: self = .hue
        case .saturation: self = .saturation
        case .color: self = .color
        case .luminosity: self = .luminosity
        case .sourceAtop: self = .sourceAtop
        case .destinationOver: self = .destinationOver
        case .destinationOut: self = .destinationOut
        case .plusDarker: self = .plusDarker
        case .plusLighter: self = .plusLighter
        case .clear: fallthrough
        case .copy: fallthrough
        case .sourceIn: fallthrough
        case .sourceOut: fallthrough
        case .destinationIn: fallthrough
        case .destinationAtop: fallthrough
        case .xor: fallthrough
        @unknown default:
            _danceuiFatalError("unsupported blendMode \(blendMode)")
        }
    }
}

@available(iOS 13.0, *)
extension CGBlendMode {
    init(_ blendMode: BlendMode) {
        switch blendMode {
        case .normal: self = .normal
        case .multiply: self = .multiply
        case .screen: self = .screen
        case .overlay: self = .overlay
        case .darken: self = .darken
        case .lighten: self = .lighten
        case .colorDodge: self = .colorDodge
        case .colorBurn: self = .colorBurn
        case .softLight: self = .softLight
        case .hardLight: self = .hardLight
        case .difference: self = .difference
        case .exclusion: self = .exclusion
        case .hue: self = .hue
        case .saturation: self = .saturation
        case .color: self = .color
        case .luminosity: self = .luminosity
        case .sourceAtop: self = .sourceAtop
        case .destinationOver: self = .destinationOver
        case .destinationOut: self = .destinationOut
        case .plusDarker: self = .plusDarker
        case .plusLighter: self = .plusLighter
        }
    }
}
