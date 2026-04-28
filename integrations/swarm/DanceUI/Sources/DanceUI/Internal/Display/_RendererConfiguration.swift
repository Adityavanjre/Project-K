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
public struct _RendererConfiguration {

    public var renderer: Renderer

    public var minFrameInterval: Double

    public init(renderer: Renderer) {
        self.renderer = renderer
        minFrameInterval = 0
    }

    public static func rasterized(_ options: RasterizationOptions) -> _RendererConfiguration {
        .init(renderer: .default)
    }

}

@available(iOS 13.0, *)
extension _RendererConfiguration {

    public enum Renderer {
        case `default`
        case rasterized(RasterizationOptions)
    }

    public struct RasterizationOptions {

        internal var colorMode: ColorRenderingMode

        internal var rbColorMode: Int32?

        internal var rendersAsynchronously: Bool

        internal var isOpaque: Bool

        internal var drawsPlatformViews: Bool

        internal var prefersDisplayCompositing: Bool

        internal var maxDrawableCount: Int

    }

}
