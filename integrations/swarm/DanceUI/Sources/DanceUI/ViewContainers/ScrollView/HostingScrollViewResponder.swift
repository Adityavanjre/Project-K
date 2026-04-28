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

/// Converging the differences between `HostingScrollViewResponder` &
/// `HostingScrollViewResponder_FeatureGestureContainer`.
@available(iOS 13.0, *)
internal protocol AnyHostingScrollViewResponder: ViewResponder, AnyUIViewResponder {
    
    var scrollView: (UIScrollView & AnyPlatformViewHost)? { get set }
    
    var child: ViewResponder? { get set }
    
    var helper: ContentResponderHelper<TrivialContentResponder>! { get set }
    
}

@available(iOS 13.0, *)
internal func makeAnyHostingScrollViewResponder(layoutResponder: DefaultLayoutViewResponder) -> AnyHostingScrollViewResponder {
    if DanceUIFeature.gestureContainer.isEnable {
        return HostingScrollViewResponder_FeatureGestureContainer(layoutResponder: layoutResponder)
    } else {
        return HostingScrollViewResponder()
    }
}

@available(iOS 13.0, *)
internal final class HostingScrollViewResponder: UIViewResponder, AnyHostingScrollViewResponder {
    
    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) -> () {
        observer.map {
            helper.observers.add(observer: $0)
        }
        guard helper.data != nil else {
            return
        }
        
        var contentPath = Path(CGRect(origin: .zero, size: helper.size))
        guard !contentPath.isEmpty else {
            return
        }
        contentPath.convert(to: coordinateSpace, transform: helper.transform)
        path.union(path: contentPath)
    }
    
    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        helper.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey, children: [])
    }
    
    internal var scrollView: (UIScrollView & AnyPlatformViewHost)? {
        get {
            hostView as? (UIScrollView & AnyPlatformViewHost)
        }
        set {
            newValue?.responder = self
            hostView = newValue
        }
    }
    
    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        return [helper.globalGeometry] + (child?.visualDebugGeometries ?? [])
    }
    
    internal var preferredFocusableView: UIView? {
        representedView
    }
}

@available(iOS 13.0, *)
internal final class HostingScrollViewResponder_FeatureGestureContainer: PlatformUnaryViewResponder, AnyHostingScrollViewResponder {
    
    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        observer.map {
            helper.observers.add(observer: $0)
        }
        guard helper.data != nil else {
            return
        }
        
        var contentPath = Path(CGRect(origin: .zero, size: helper.size))
        guard !contentPath.isEmpty else {
            return
        }
        contentPath.convert(to: coordinateSpace, transform: helper.transform)
        path.union(path: contentPath)
    }
    
    internal override func containsGlobalPoints(_ points: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        if DanceUIFeature.unifiedHitTesting.isEnable {
            return super.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey)
        } else {
            return helper.containsGlobalPoints(points, isDerived: isDerived, cacheKey: cacheKey, children: [layoutResponder])
        }
    }
    
    internal var scrollView: (UIScrollView & AnyPlatformViewHost)? {
        get {
            nil
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        return [helper.globalGeometry] + (children.reduce([], { partial, child in
            partial + child.visualDebugGeometries
        }))
    }
    
    internal override var preferredFocusableView: UIView? {
        get {
            representedView
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    

    // HostingScrollViewResponder and
    // HostingScrollViewResponder_FeatureGestureContainer
    internal var child: ViewResponder? {
        get {
            layoutResponder
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
}
