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
extension DisplayList.ViewUpdater.Platform {

    internal final class CGDrawingView: UIGraphicsView, PlatformDrawable {

        internal var options: RasterizationOptions

        internal var content: PlatformDrawableContent

        internal var renderer: DisplayList.GraphicsRenderer?

        internal var graphicsContext: GraphicsContext {
            GraphicsContext(cgContext: UIGraphicsGetCurrentContext()!,
                            environments: EnvironmentValues())
        }

        internal override init(frame: CGRect) {
            _unimplementedInitializer(className: "DanceUI.CGDrawingView")
        }

        required init?(coder: NSCoder) {
            _unimplementedInitializer(className: "DanceUI.CGDrawingView")
        }

        internal override func draw(_ rect: CGRect) {
            switch self.content {
            case .platformCallback(let callback):
                graphicsContext.withPlatformContext {
                    callback(self.bounds.size)
                }
            case .empty:
                break
            }
        }

        internal init(options: RasterizationOptions) {
            self.content = .empty
            self.renderer = nil
            self.options = options
            super.init(frame: .zero)
            updateOptions()
        }

        internal func update(content: PlatformDrawableContent?) -> Bool {
            if let contentValue = content {
                self.content = contentValue
            }
            setNeedsDisplay()
            return true
        }

        fileprivate func updateOptions() {
            var opaqueValue = options.flags.rawValue
            opaqueValue &= 0x8
            opaqueValue = UInt8(opaqueValue >> 0x1)
            isOpaque = opaqueValue > 0x0 ? true : false
        }
    }
}
