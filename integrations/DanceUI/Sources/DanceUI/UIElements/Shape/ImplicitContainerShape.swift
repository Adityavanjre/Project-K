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

@available(iOS 13.0, *)
internal struct ImplicitContainerShape: Shape {

    internal func path(in rect: CGRect) -> Path {
        if let proxyData = _threadGeometryProxyData() {
            let pointer = proxyData.assumingMemoryBound(to: GeometryProxy.self)
            let geoProxy = pointer.pointee
            let containerShapeData = geoProxy.environment.containerShapeData
            
            guard !containerShapeData.isSystemShape else {
                return rect.validPath
            }
            
            let shapeType = containerShapeData.type
            let path = shapeType.path(in: rect, proxy: geoProxy, shape: containerShapeData.shape, size: containerShapeData.size, id: containerShapeData.id)
            return path
        } else {
            return rect.validPath
        }
    }
}

@available(iOS 13.0, *)
extension CGRect {
    @inline(__always)
    internal var validPath: Path {
        isNull ? Path() : Path(self)
    }
}

@available(iOS 13.0, *)
internal protocol AnyContainerShapeType {
    static func path(in rect: CGRect, proxy: GeometryProxy, shape: DGWeakAttribute, size: WeakAttribute<ViewSize>, id: UniqueID) -> Path
}

@available(iOS 13.0, *)
private struct DefaultContainerShapeType: AnyContainerShapeType {
    fileprivate static func path(in rect: CGRect, proxy: GeometryProxy, shape: DGWeakAttribute, size: WeakAttribute<ViewSize>, id: UniqueID) -> Path {
        rect.validPath
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    @inline(__always)
    internal var containerShapeData: ContainerShapeData {
        get {
            self[ContainerShapeKey.self]
        }
        
        set {
            self[ContainerShapeKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct ContainerShapeKey: EnvironmentKey {
    fileprivate static var defaultValue: ContainerShapeData {
        ContainerShapeData(type: DefaultContainerShapeType.self,
                           shape: DGWeakAttribute(DGAttribute.current),
                           size: WeakAttribute<ViewSize>(nil),
                           id: .zero,
                           isSystemShape: false)
    }
}

@available(iOS 13.0, *)
internal struct ContainerShapeData {
    
    internal var type: AnyContainerShapeType.Type
    
    internal var shape: DGWeakAttribute
    
    internal var size: WeakAttribute<ViewSize>
    
    internal var id: UniqueID
    
    internal var isSystemShape: Bool
}
