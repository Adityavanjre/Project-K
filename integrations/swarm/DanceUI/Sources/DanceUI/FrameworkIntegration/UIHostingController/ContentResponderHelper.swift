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
internal struct ContentResponderHelper<Data: ContentResponder> {
    internal var size: CGSize

    internal var data: Data?

    internal var transform: ViewTransform

    internal var observers: ContentPathObservers

    internal var cache: ViewResponder.ContainsPointsCache


    internal let identifier: ObjectIdentifier


    internal var hitTestInsets: EdgeInsets?
    
    init(identifier: ObjectIdentifier) {
        size = .zero
        transform = ViewTransform()
        observers = ContentPathObservers()
        cache = ViewResponder.ContainsPointsCache()
        self.identifier = identifier
    }
    
    internal mutating func update(data: (value: Data, changed: Bool),
                                  size: (value: ViewSize, changed: Bool),
                                  position: (value: ViewOrigin, changed: Bool),

                                  hitTestInsets: (value: EdgeInsets?, changed: Bool)?,

                                  transform: (value: ViewTransform, changed: Bool),
                                  parent: ViewResponder) {
        if position.changed || transform.changed {
            self.transform = transform.value
            self.transform.appendViewOrigin(position.value)
        }
        
        if size.changed {
            self.size = size.value.value
        }
        

        if let hitTestInsets = hitTestInsets, hitTestInsets.changed == true {
            self.hitTestInsets = hitTestInsets.value
        }

        
        let hasGeometricalChanges = position.changed || hitTestInsets?.changed == true || transform.changed || size.changed
        
        let needsUpdateData = data.changed || self.data == nil
        
        if needsUpdateData {
            self.data = data.value
        }
        
        if needsUpdateData || hasGeometricalChanges {
            observers.notify() // iOS 18.5 used `parent` here.
        }
        
    }
    
    @inline(__always)
    private var doesNonDerivedPointsDominatePointsContainingTest: Bool {
        hitTestInsets != nil
    }
    
    
    /// iOS 18.5 addition: `options: ViewResponder.ContainsPointsOptions`
    internal mutating func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?, children: [ViewResponder]) -> ViewResponder.ContainsPointsResult {
        
        guard let data = data else {
            return ViewResponder.ContainsPointsResult(mask: BitVector64(), priority: 0, children: children)
        }
        
        let cachedResult = cache.fetch(key: cacheKey) { [doesNonDerivedPointsDominatePointsContainingTest] in
            var localPoints = points
            transform.convert(.toGlobal, space: .local, points: &localPoints)
            
            let result = data.contains(points: localPoints, size: size, edgeInsets: hitTestInsets ?? .zero)
            

            if doesNonDerivedPointsDominatePointsContainingTest && isDerived.count == points.count {
                let hasAnyNonDerivedPointHit = isDerived.enumerated().reduce(false) { partialResult, pair in
                    let (index, isDerived) = pair
                    if !isDerived {
                        return partialResult || result[index]
                    } else {
                        return partialResult
                    }
                }
                
                if !hasAnyNonDerivedPointHit {
                    return ViewResponder.ContainsPointsResult(mask: BitVector64(), priority: 1, children: children)
                }
            }

            
            return ViewResponder.ContainsPointsResult(mask: result, priority: 1, children: children)
        }
        
        return cachedResult
    }
    
    // iOS 15.2 addition, currently forward to iOS 14's impl
    // internal mutating func addContentPath(to path: inout Path, kind: ContentShapeKinds, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?)
    
    internal mutating func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        observer.map {
            observers.add(observer: $0)
        }
        guard let data = data else {
            return
        }

        var contentPath = data.contentPath(size: size, edgeInsets: hitTestInsets ?? .zero)
        if !contentPath.isEmpty {
            contentPath.convert(to: coordinateSpace, transform: transform)
            path.union(path: contentPath)
        }
    }
    
    // iOS 15.2
    // internal var globalPosition: CGPoint, debug only, not implemented
    

    internal var globalGeometry: VisualDebugGeometry {
        var position = CGPoint(x: size.width / 2, y: size.height / 2)
        let size = size
        let bounds = CGRect(origin: .zero, size: size)//.inset(by: hitTestInsets ?? .zero)
        var transform3D = CATransform3DMakeAffineTransform(.identity)
        transform.convert(.toLocal, space: .named(HostingViewCoordinateSpace())) { (item) in
            switch item {
            case let .translation(t):
                position.apply(t)
            case let .affineTransform(t, inverse):
                let normalizedAffineTransform = inverse ? t.inverted() : t
                
                transform3D = transform3D
                    .concatenating(CATransform3DMakeAffineTransform(CGAffineTransform(translationX: size.width / 2, y: size.height / 2)))
                    .concatenating(CATransform3DMakeAffineTransform(normalizedAffineTransform))
                    .concatenating(CATransform3DMakeAffineTransform(CGAffineTransform(translationX: -size.width / 2, y: -size.height / 2)))
            default:
                break
            }
        }
        return VisualDebugGeometry(
            uuid: identifier,
            position: position,
            bounds: bounds,
            contentPath: data?.contentPath(size: size, edgeInsets: hitTestInsets ?? .zero),
            transform3D: transform3D
        )
    }
    
}

@available(iOS 13.0, *)
extension CATransform3D {
    
    @inline(__always)
    fileprivate func concatenating(_ t: CATransform3D) -> CATransform3D {
        CATransform3DConcat(self, t)
    }
    
}
