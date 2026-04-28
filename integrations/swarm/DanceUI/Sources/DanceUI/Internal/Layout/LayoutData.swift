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
internal final class LayoutData {
    
    private var _placement: [_Placement]?
    
    internal var geometries: [ViewGeometry]?
    
    internal var placement: [_Placement] {
        _placement ?? []
    }
    
    internal init(at size: ViewSize,
                  origin: CGPoint,
                  subviews: LayoutSubviews) {
        self._placement = _defaultLayoutPlacement(at: size,
                                                  origin: origin,
                                                  subviews: subviews)
        self.geometries = []
    }
    
    private init(placement: [_Placement]? = nil,
                  geometries: [ViewGeometry]? = nil) {
        self._placement = placement
        self.geometries = geometries
    }
    
    @inline(__always)
    internal static var current: LayoutData {
        if let data = _threadLayoutData() {
            let layoutData = unsafeBitCast(data, to: LayoutData.self)
            return layoutData
        } else {
            return LayoutData()
        }
    }
    
    internal func appendPlacement(_ placement: _Placement, at index: Int) {
        guard index < (_placement?.count ?? 0) else {
            return
        }
        _placement?[index] = placement
    }
    
    private func _defaultLayoutPlacement(at size: ViewSize,
                                         origin: CGPoint,
                                         subviews: LayoutSubviews) -> [_Placement] {
        var placements: [_Placement] = []
        var origin = origin
        let defaultOffset = CGSize(width: size.value.width * 0.5, height: size.value.height * 0.5)
        origin.apply(defaultOffset)
        let placement = _Placement(proposedSize: _ProposedSize(size: size._proposal), anchor: .center, at: origin)
        for _ in (0..<subviews.count) {
            placements.append(placement)
        }
        return placements
    }
}

@available(iOS 13.0, *)
internal func withLayoutData<Result>(_ layoutData: LayoutData,
                                    _ body: () throws -> Result) rethrows -> Result {
    return try withExtendedLifetime(layoutData, {
        let oldData = _threadLayoutData()
        let pointer = Unmanaged.passUnretained(layoutData).toOpaque()
        
        _setThreadLayoutData(pointer)
        
        let retVal = try body()
        
        _setThreadLayoutData(oldData)
        
        return retVal
    })
}

@_silgen_name("_DanceUISetThreadLayoutData")
@inline(__always)
@available(iOS 13.0, *)
internal func _setThreadLayoutData(_: UnsafeMutableRawPointer?)

@_silgen_name("_DanceUIThreadLayoutData")
@inline(__always)
@available(iOS 13.0, *)
internal func _threadLayoutData() -> UnsafeMutableRawPointer?
