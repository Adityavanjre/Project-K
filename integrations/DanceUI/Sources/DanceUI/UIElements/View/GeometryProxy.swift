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

/// A proxy for access to the size and coordinate space (for anchor resolution)
/// of the container view.
@available(iOS 13.0, *)
public struct GeometryProxy {
    
    internal var owner: DGWeakAttribute

    internal var _size: WeakAttribute<ViewSize>

    internal var _environment: WeakAttribute<EnvironmentValues>

    internal var _transform: WeakAttribute<ViewTransform>

    internal var _position: WeakAttribute<ViewOrigin>

    internal var _safeAreaInsets: WeakAttribute<SafeAreaInsets>

    internal var _seed: UInt32
    
    // TODO: notImplemented: internal var environment: EnvironmentValues
    
    /// The size of the container view.
    public var size: CGSize {
        guard let owner = owner.attribute,
              let size = _size.attribute else {
            return .zero
        }
        return AnyRuleContext(owner)[size].value
    }

    /// Returns the container view's bounds rectangle, converted to a defined
    /// coordinate space.
    public func frame(in coordinateSpace: CoordinateSpace) -> CGRect {
        let rect = CGRect(origin: .zero, size: size)
        guard let context = self.placementContext else {
            return rect
        }
        
        guard rect.isValid else {
            return rect
        }
        
        var points = rect.cornerPoints
        points.convert(to: coordinateSpace, transform: context.transform)
        
        return CGRect(cornerPoints: points[...])
    }
    
    /// Resolves the value of `anchor` to the container view.
    public subscript<T>(anchor: Anchor<T>) -> T {
        let optinalValue = self.placementContext.map {
            anchor.`in`(context: $0)
        }
        
        return optinalValue ?? anchor.defaultValue
    }
    
    internal var environment: EnvironmentValues {
        guard let attribute = self._environment.attribute,
              let owner = owner.attribute else {
            return EnvironmentValues()
        }
        return AnyRuleContext(owner)[attribute]
    }
    
    /// The safe area inset of the container view.
    public var safeAreaInsets: EdgeInsets {
        guard let context = self.placementContext else {
            return .zero
        }
        
        return context.safeAreaInsets(matching: .all)
    }

    internal var placementContext: _PositionAwarePlacementContext? {
        guard let storngOwner = self.owner.attribute,
              let sizeAttribute = self._size.attribute,
              let environmentAttribute = self._environment.attribute,
              let transformAttribute = self._transform.attribute,
              let positionAttribute = self._position.attribute else {
            return nil
        }
        
        let context = DanceUIGraph.AnyRuleContext(storngOwner)
        return _PositionAwarePlacementContext(context: context,
                                              size: sizeAttribute,
                                              environment: environmentAttribute,
                                              transform: transformAttribute,
                                              position: positionAttribute,
                                              safeAreaInsets: .init(_safeAreaInsets))
    }
}

@_silgen_name("_DanceUISetThreadGeometryProxyData")
@inline(__always)
@available(iOS 13.0, *)
internal func _setThreadGeometryProxyData(_: UnsafeMutableRawPointer?)

@_silgen_name("_DanceUIThreadGeometryProxyData")
@inline(__always)
@available(iOS 13.0, *)
internal func _threadGeometryProxyData() -> UnsafeMutableRawPointer?

@inline(__always)
@available(iOS 13.0, *)
internal func withGeometryProxy<Result>(_ proxy: GeometryProxy,
                                        _ body: () -> Result) -> Result {
    let oldData = _threadGeometryProxyData()
    
    var pointer = proxy
    
    _setThreadGeometryProxyData(&pointer)
    
    let retVal = body()
    
    _setThreadGeometryProxyData(oldData)
    
    return retVal
}
