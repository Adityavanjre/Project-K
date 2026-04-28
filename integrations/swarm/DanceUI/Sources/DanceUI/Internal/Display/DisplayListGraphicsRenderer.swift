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
    public final class GraphicsRenderer {

        internal var oldCache: Cache

        internal var newCache:Cache

        internal var index: Index

        internal var archiveID: Identity

        internal var time:Time

        internal var nextTime: Time

        internal var platformViewMode: PlatformViewMode

        internal init(oldCache: Cache,
                      newCache: Cache,
                      index: Index,
                      archiveID: Identity,
                      time: Time,
                      nextTime: Time,
                      platformViewMode: PlatformViewMode) {
            self.oldCache = oldCache
            self.newCache = newCache
            self.index = index
            self.archiveID = archiveID
            self.time = time
            self.nextTime = nextTime
            self.platformViewMode = platformViewMode
        }

        internal func renderDisplayList(_ list: DisplayList,
                                        at time: Time,
                                        in context: inout GraphicsContext) {
            _notImplemented()
        }

        internal func renderPlatformView(_ view: AnyObject?,
                                         in context: GraphicsContext,
                                         size: CGSize,
                                         viewType: Any.Type) {
            _notImplemented()
        }

        internal func render(list: DisplayList,
                             in context: inout GraphicsContext) {
            _notImplemented()
        }

        internal enum PlatformViewMode {

            case rendered(Bool)

            case ignored

            case unsupported

        }
    }
}

@available(iOS 13.0, *)
extension DisplayList.GraphicsRenderer {

    internal struct Cache {

        internal struct CallbackKey {

            internal var index: DisplayList.Index

            internal var archive: DisplayList.Identity

            internal var seed: DisplayList.Seed

            internal var scale: CGFloat

        }

        internal struct AnimatorKey {

            internal var index: DisplayList.Index

            internal var archive: DisplayList.Identity

        }
    }

}
