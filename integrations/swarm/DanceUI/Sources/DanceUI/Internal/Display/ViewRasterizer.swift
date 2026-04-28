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
    internal final class ViewRasterizer {

        internal weak var host: ViewRendererHost?

        internal var drawingView: UIView?

        internal var options: RasterizationOptions

        internal var seed: Seed

        internal var lastContentsScale: CGFloat

        var exportedObject: AnyObject?

        internal init(host:ViewRendererHost?, rootView: UIView, options: _RendererConfiguration.RasterizationOptions) {
            self.host = host
            self.drawingView = rootView
            self.options = .init(maxDrawableCount: 0)
            self.seed = .zero
            self.lastContentsScale = 1.0
            self.exportedObject = nil
        }

        internal func updateOptions(_ options: _RendererConfiguration.RasterizationOptions) {
        }

        internal func render(rootView: UIView, from displayList: DisplayList, time: Time, version: DisplayList.Version, maxVersion: DisplayList.Version, contentsScale: CGFloat) -> Time {
            return .zero
        }

        func destroy(rootView: UIView) {
        }

    }
}
