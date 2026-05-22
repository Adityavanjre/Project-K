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

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public protocol PlatformGroupFactory {
    
    func makePlatformGroup() -> UIView
    
    func updatePlatformGroup(_ group: inout UIView)
    
    func platformGroupContainer(_ container: UIView) -> UIView
    
    func renderPlatformGroup(_ displayList: DisplayList, in context: GraphicsContext, size: CGSize, renderer: DisplayList.GraphicsRenderer)
}

@available(iOS 13.0, *)
@_spi(DanceUICompose)
extension PlatformGroupFactory where Self: UIView {
    
    private var customFactor: (any CustomPlatformGroupFactory)? {
        self as? CustomPlatformGroupFactory
    }
    
    public func makePlatformGroup() -> UIView {
        customFactor?._makePlatformGroup() ?? self
    }
    
    public func updatePlatformGroup(_ group: inout UIView) {
        customFactor?._updatePlatformGroup(&group)
    }
    
    public func platformGroupContainer(_ group: UIView) -> UIView {
        customFactor?._platformGroupContainer(group) ?? self
    }
    
    public func renderPlatformGroup(_ displayList: DisplayList, in context: GraphicsContext, size: CGSize, renderer: DisplayList.GraphicsRenderer) {
        customFactor?.renderPlatformGroup(displayList, in: context, size: size, renderer: renderer)
    }
    
}

@available(iOS 13.0, *)
internal protocol CustomPlatformGroupFactory: PlatformGroupFactory {
    
    func _makePlatformGroup() -> UIView
    
    func _updatePlatformGroup(_ group: inout UIView)
    
    func _platformGroupContainer(_ container: UIView) -> UIView
    
    func _renderPlatformGroup(_ displayList: DisplayList, in context: GraphicsContext, size: CGSize, renderer: DisplayList.GraphicsRenderer)
    
}

@available(iOS 13.0, *)
@_spi(DanceUICompose)
extension UIView: PlatformGroupFactory {
    
}
