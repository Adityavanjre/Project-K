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

@available(iOS 13.0, *)
fileprivate var hitTestKey: UInt32 = 0

@available(iOS 13.0, *)
internal class ViewResponder: ResponderNode, CustomStringConvertible {

    internal struct ContainsPointsOptions: OptionSet {
        internal let rawValue: Int

        internal static let allowDisabledViews: ContainsPointsOptions = .init(rawValue: 1 << 0)

        internal static let useZDistanceAsPriority: ContainsPointsOptions = .init(rawValue: 1 << 1)

        internal static let disablePointCloudHitTesting: ContainsPointsOptions = .init(rawValue: 1 << 2)

        internal static let allow3DResponders: ContainsPointsOptions = .init(rawValue: 1 << 3)

        internal static let crossingServerIDBoundary: ContainsPointsOptions = .init(rawValue: 1 << 4)

        internal static var platformDefault: ViewResponder.ContainsPointsOptions { [] }
    }

    internal struct ContainsPointsResult {

        internal var mask: BitVector64

        internal var priority: Double

        internal var children: [ViewResponder]

        @inlinable
        internal init() {
            self.init(mask: BitVector64(), priority: 0, children: [])
        }

        @inlinable
        internal init(mask: BitVector64, priority: Double, children: [ViewResponder]) {
            self.mask = mask
            self.priority = priority
            self.children = children
        }

        internal static func passthrough(to children: [ViewResponder]) -> ContainsPointsResult {
            ContainsPointsResult(mask: BitVector64(), priority: 0, children: children)
        }
    }

    private weak var _rendererHost: ViewRendererHost?

    private var realtimeRendererHost: ViewRendererHost? {
        if let host = _rendererHost {
            return host
        }
        _rendererHost = ViewGraph.viewRendererHost
        return _rendererHost
    }

    private weak var realtimeHost: ViewGraphDelegate? {
        if let host = _host {
            return host
        }
        _host = _viewGraph?.delegate
        return _host
    }

    private weak var _viewGraph: ViewGraph?

    private weak var _host: ViewGraphDelegate?

    internal weak var host: ViewGraphDelegate? {
        if DanceUIFeature.gestureContainer.isEnable {
            return realtimeHost
        } else {
            return realtimeRendererHost
        }
    }

    internal weak var parent: ViewResponder? {
        willSet(newValue) {
            guard parent != nil, newValue == nil else {
                return
            }
            host?.as(EventGraphHost.self)?.eventBindingManager.willRemoveResponder(self)
            resetGesture()
        }
    }
    
    internal override init() {
        if DanceUIFeature.gestureContainer.isEnable {
            _viewGraph = ViewGraph.current
            _host = ViewGraph.current.delegate
        } else {
            _rendererHost = ViewGraph.viewRendererHost
        }
    }
    
    internal override var nextResponder: ResponderNode? {
        parent
    }
    
    internal override func bindEvent(_: EventType) -> ResponderNode? {
        // intentionally returns nil
        nil
    }
    
    @inlinable
    internal override func makeGesture(gesture: _GraphValue<Void>, inputs: _GestureInputs) -> _GestureOutputs<Void> {
        guard let viewGraph = host?.as(ViewRendererHost.self)?.viewGraph else {
            _danceuiFatalError()
        }
        return .makeDefault(viewGraph: viewGraph, inputs: inputs)
    }
    
    internal override func resetGesture() {
        _intentionallyLeftBlank()
    }
    
    internal override func visit(applying body: (ResponderNode) -> ResponderVisitorResult) -> ResponderVisitorResult {
        body(self)
    }
    
    internal var gestureContainer: UIView? { nil }

    internal var opacity: Double { 1 }

    internal var allowsHitTesting: Bool {
        true
    }

    /// Check if the contents that the responder node represents contains the
    /// global points. Returns a `BitVector` that represents the hit points and
    /// the content hit-test priority.
    ///
    /// - Parameter globalPoints: The points to examine.
    /// - Parameter isDerived: A array of bool paired to the points that shows
    ///   if the point is derived by the hit-test radius.
    /// - Parameter cacheKey: The key used for caching.
    ///
    /// - Returns: A `BitVector` that represents the hit points and the content
    ///   hit-test priority.
    ///
    internal func containsGlobalPoints(_ globalPoints: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        return ContainsPointsResult(mask: BitVector64(), priority: 0, children: [])
    }

    internal func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        _intentionallyLeftBlank()
    }

    internal func addObserver(_ observer: ContentPathObserver) {

    }

    internal var children: [ViewResponder] {
        []
    }

    internal var descriptionName : String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())>"
    }

    internal var description : String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())>"
    }

    internal func extendPrintTree(string: inout String) {

    }
    
    internal final func hitTest(globalPoint: CGPoint, radius: CGFloat, cacheKey: UInt32? = nil) -> ViewResponder? {
        let (points, weights, isDerived) = hitPoints(point: globalPoint, radius: radius)
        return hitTest(globalPoints: points, weights: weights, isDerived: isDerived, mask: BitVector64(), cacheKey: cacheKey ?? ViewResponder.nextHitTestKey())?.viewResponder
    }
    
    internal final func hitTest(globalPoints: [CGPoint], weights: [Double], isDerived: [Bool], mask: BitVector64, cacheKey: UInt32?) -> (viewResponder: ViewResponder, double: Double, mask: BitVector64)? {
        if DanceUIFeature.gestureContainer.isEnable {
            return gestureContainerHitTest(globalPoints: globalPoints, weights: weights, isDerived: isDerived, mask: mask, cacheKey: cacheKey)
        } else {
            return defaultHitTest(globalPoints: globalPoints, weights: weights, isDerived: isDerived, mask: mask, cacheKey: cacheKey)
        }
    }
    
    /// - Parameter mask: Points in `mask` would not contribute to the content
    /// hit-point weight.
    ///
    internal final func defaultHitTest(globalPoints: [CGPoint],
                                       weights: [Double],
                                       isDerived: [Bool],
                                       mask: BitVector64,
                                       cacheKey: UInt32?) -> (ViewResponder, Double, BitVector64)? {
#if DEBUG
        printHitTest("mask = \(mask)")
        printHitTest("[\(_typeName(type(of: self), qualified: false))] - [\(#function)]")
#endif
        
        let opacity = self.opacity
        
        guard opacity >= 0.001 else {
#if DEBUG
            printHitTest("return nil")
#endif
            return nil
        }
        
        let guardedCacheKey = cacheKey ?? 0
        
#if DEBUG
        printHitTest("hit-test contents")
#endif
        
        // Step 1: check if the contents that the responder node represents
        // contains the global points.
        let contentHitTestResult = containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: guardedCacheKey)
        
        let contentMask = contentHitTestResult.mask
        let contentPriority = contentHitTestResult.priority
        
        typealias ContentHitTestResolution = (contentHitPointWeight: Double, contentMaskAll: BitVector64, childrenMaskAll: BitVector64)
        
        let initialContentHitTestResolution: ContentHitTestResolution = (0, mask, mask)
        
        let contentHitTestResolution = (0..<globalPoints.count).reduce(initialContentHitTestResolution) { (partialResult, pointIndex) -> ContentHitTestResolution in
            var (contentHitPointWeight, contentMaskAll, childrenMaskAll) = partialResult
            
            let pointBit: BitVector64
            if pointIndex < 64 {
                pointBit = BitVector64(rawValue: 0b1 << pointIndex)
                /// The `contentMaskAll` is initially the `mask` argument.
                /// This means that weight of the points in `mask` would not
                /// contribute to the `contentHitPointWeight`.
                if !contentMaskAll.contains(pointBit) && contentMask.contains(pointBit) {
                    
                    contentMaskAll = opacity <= 0.5
                        ? contentMaskAll.subtracting(pointBit)
                        : contentMaskAll.union(pointBit)
                    
                    contentHitPointWeight += weights[pointIndex]
                    
                } else {
                    childrenMaskAll.formUnion(pointBit)
                }
            } else { // corner case
                pointBit = BitVector64()
                childrenMaskAll.formUnion(pointBit)
            }
            
            return (contentHitPointWeight, contentMaskAll, childrenMaskAll)
        }
        
        /// contentMaskAll = contentMask | mask
        /// childrenMaskAll = (~contentMask) | mask
        let (contentHitPointWeight, contentMaskAll, childrenMaskAll) = contentHitTestResolution
        
        let contentHitTestWeight = contentPriority * opacity * contentHitPointWeight
        
        guard contentHitTestWeight != 0 else {
#if DEBUG
            printHitTest("return nil")
#endif
            return nil
            
        }
        
#if DEBUG
        printHitTest("hit-test children")
#endif
        
        // Step 2: check if there is any child responds to the global points.
        
        typealias ChildrenHitTestResolution = (hitChildOrNil: ViewResponder?, greatestHitTestWeight: Double, secondGreatestHitTestWeight: Double, childMask: BitVector64)
        
        let initialChildrenHitTestResolution: ChildrenHitTestResolution = (nil, 0, 0, childrenMaskAll)
        
        let childrenHitTestResolution = (0..<childCount).reversed().reduce(initialChildrenHitTestResolution) { (partialResult, index) -> ChildrenHitTestResolution in
            
            let (hitChildOrNil, greatestHitTestWeight, secondGreatestHitTestWeight, childMask) = partialResult
            
            guard let child = child(at: index),
                  child.allowsHitTesting else {
                // No child at the index, or child does not allow hit testing.
                // Continue by returning the `partialResult`.
                return partialResult
            }
            
            // Step 2.1: Recursively hit-test the child.
#if DEBUG
            printHitTest("hit-test child \(child)")
#endif
            
            guard let (childHitTestResponder, childHitTestWeight, childHitTestMask) = child.hitTest(globalPoints: globalPoints, weights: weights, isDerived: isDerived, mask: childMask, cacheKey: guardedCacheKey) else {
                // The child has no hit-test result.
                // Continue by returning the `partialResult`.
                return partialResult
            }
            
            guard childHitTestWeight > secondGreatestHitTestWeight else {
                // childHitTestWeight <= secondGreatestHitTestWeight.
                // Continue by returnning the `partialResult` with the following
                // elements updated:
                //  - `childMask` <- `childHitTestMask`
                return (hitChildOrNil, greatestHitTestWeight, secondGreatestHitTestWeight, childHitTestMask)
            }
            
            guard childHitTestWeight > greatestHitTestWeight else {
                // childHitTestWeight > secondGreatestHitTestWeight
                // childHitTestWeight <= greatestHitTestWeight
                // Continue by returnning the `partialResult` with the following
                // elements updated:
                //  - `secondGreatestHitTestWeight` <- `childHitTestWeight`
                //  - `childMask` <- `childHitTestMask`
                return (hitChildOrNil, greatestHitTestWeight, childHitTestWeight, childHitTestMask)
            }
            
            // PRECONDITION: childHitTestWeight >= greatestHitTestWeight
            if hitChildOrNil !== childHitTestResponder {
                // YES! The childHitTestResponder won all in this case.
                return (childHitTestResponder, childHitTestWeight, greatestHitTestWeight, childHitTestMask)
            } else {
                // PRECONDITION: hitChildOrNil === childHitTestResponder
                //
                // childHitTestResponder or hitChildOrNil is both OK here for
                // the first element in the returning tuple.
                //
                // However, since hitChildOrNil === childHitTestResponder, we
                // should also keep the secondGreatestHitTestWeight in this
                // case.
                return (childHitTestResponder, childHitTestWeight, secondGreatestHitTestWeight, childHitTestMask)
            }
        }
        
        let (hitChildOrNil, greatestHitTestWeight, secondGreatestHitTestWeight, _) = childrenHitTestResolution
        
        if let hitChild = hitChildOrNil {
            // 8 / 1.2 ~= 6.6 points hit
            let doesSignificantlyHit = greatestHitTestWeight >= max(secondGreatestHitTestWeight * 1.2, 8)
            if doesSignificantlyHit {
#if DEBUG
                printHitTest("return mask = \(contentMaskAll)")
#endif
                return (hitChild, contentHitTestWeight, contentMaskAll)
            }
        }
        
        if allowsHitTesting {
#if DEBUG
            printHitTest("return mask = \(contentMaskAll)")
#endif
            return (self, contentHitTestWeight, contentMaskAll)
        } else {
#if DEBUG
            printHitTest("return nil")
#endif
            return nil
        }
    }
    
    internal func gestureContainerHitTest(globalPoints: [CGPoint],
                                          weights: [Double],
                                          isDerived: [Bool],
                                          mask: BitVector64,
                                          cacheKey: UInt32?) -> (ViewResponder, Double, BitVector64)? {
#if DEBUG
        printHitTest("mask = \(mask)")
        printHitTest("[\(_typeName(type(of: self), qualified: false))] - [\(#function)]")
#endif
        
        let opacity = self.opacity
        
        guard opacity >= 0.001 else {
#if DEBUG
            printHitTest("return nil")
#endif
            return nil
        }
        
        let guardedCacheKey = cacheKey ?? 0
        
#if DEBUG
        printHitTest("hit-test contents")
#endif
        
        // Step 1: check if the contents that the responder node represents
        // contains the global points.
        let contentHitTestResult = containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: guardedCacheKey)
        
#if DEBUG
        printHitTest("content hit-test result: \(contentHitTestResult)")
#endif
        
        let contentMask = contentHitTestResult.mask
        let contentPriority = contentHitTestResult.priority
        let contentChildren = contentHitTestResult.children
        
        typealias ContentHitTestResolution = (contentHitPointWeight: Double, contentMaskAll: BitVector64, childrenMaskAll: BitVector64)
        
        let initialContentHitTestResolution: ContentHitTestResolution = (0, mask, mask)
        
        let contentHitTestResolution = (0..<globalPoints.count).reduce(initialContentHitTestResolution) { (partialResult, pointIndex) -> ContentHitTestResolution in
            var (contentHitPointWeight, contentMaskAll, childrenMaskAll) = partialResult
            
            let pointBit: BitVector64
            if pointIndex < 64 {
                pointBit = BitVector64(rawValue: 0b1 << pointIndex)
                /// The `contentMaskAll` is initially the `mask` argument.
                /// This means that weight of the points in `mask` would not
                /// contribute to the `contentHitPointWeight`.
                if !contentMaskAll.contains(pointBit) && contentMask.contains(pointBit) {
                    
                    contentMaskAll = opacity <= 0.5
                        ? contentMaskAll.subtracting(pointBit)
                        : contentMaskAll.union(pointBit)
                    
                    contentHitPointWeight += weights[pointIndex]
                    
                } else {
                    childrenMaskAll.formUnion(pointBit)
                }
            } else { // corner case
                pointBit = BitVector64()
                childrenMaskAll.formUnion(pointBit)
            }
            
            return (contentHitPointWeight, contentMaskAll, childrenMaskAll)
        }
        
        /// contentMaskAll = contentMask | mask
        /// childrenMaskAll = (~contentMask) | mask
        let (contentHitPointWeight, contentMaskAll, childrenMaskAll) = contentHitTestResolution
        
        let contentHitTestWeight = contentPriority * opacity * contentHitPointWeight
        
        guard contentHitTestWeight != 0 else {
#if DEBUG
            printHitTest("return nil")
#endif
            return nil
            
        }
        
#if DEBUG
        printHitTest("hit-test children")
#endif
        
        // Step 2: check if there is any child responds to the global points.
        
        typealias ChildrenHitTestResolution = (hitChildOrNil: ViewResponder?, greatestHitTestWeight: Double, secondGreatestHitTestWeight: Double, childMask: BitVector64)
        
        let initialChildrenHitTestResolution: ChildrenHitTestResolution = (nil, 0, 0, childrenMaskAll)
        
        let childrenHitTestResolution = contentChildren.reversed().reduce(initialChildrenHitTestResolution) { (partialResult, thisChild) -> ChildrenHitTestResolution in
            
            let (hitChildOrNil, greatestHitTestWeight, secondGreatestHitTestWeight, childMask) = partialResult
            
            guard thisChild.allowsHitTesting else {
                // No child at the index, or child does not allow hit testing.
                // Continue by returning the `partialResult`.
                return partialResult
            }
            
            // Step 2.1: Recursively hit-test the child.
#if DEBUG
            printHitTest("hit-test child \(thisChild)")
#endif
            
            guard let (childHitTestResponder, childHitTestWeight, childHitTestMask) = thisChild.hitTest(globalPoints: globalPoints, weights: weights, isDerived: isDerived, mask: childMask, cacheKey: guardedCacheKey) else {
                // The child has no hit-test result.
                // Continue by returning the `partialResult`.
                return partialResult
            }
            
            guard childHitTestWeight > secondGreatestHitTestWeight else {
                // childHitTestWeight <= secondGreatestHitTestWeight.
                // Continue by returnning the `partialResult` with the following
                // elements updated:
                //  - `childMask` <- `childHitTestMask`
                return (hitChildOrNil, greatestHitTestWeight, secondGreatestHitTestWeight, childHitTestMask)
            }
            
            guard childHitTestWeight > greatestHitTestWeight else {
                // childHitTestWeight > secondGreatestHitTestWeight
                // childHitTestWeight <= greatestHitTestWeight
                // Continue by returnning the `partialResult` with the following
                // elements updated:
                //  - `secondGreatestHitTestWeight` <- `childHitTestWeight`
                //  - `childMask` <- `childHitTestMask`
                return (hitChildOrNil, greatestHitTestWeight, childHitTestWeight, childHitTestMask)
            }
            
            // PRECONDITION: childHitTestWeight >= greatestHitTestWeight
            if hitChildOrNil !== childHitTestResponder {
                // YES! The childHitTestResponder won all in this case.
                return (childHitTestResponder, childHitTestWeight, greatestHitTestWeight, childHitTestMask)
            } else {
                // PRECONDITION: hitChildOrNil === childHitTestResponder
                //
                // childHitTestResponder or hitChildOrNil is both OK here for
                // the first element in the returning tuple.
                //
                // However, since hitChildOrNil === childHitTestResponder, we
                // should also keep the secondGreatestHitTestWeight in this
                // case.
                return (childHitTestResponder, childHitTestWeight, secondGreatestHitTestWeight, childHitTestMask)
            }
        }
        
        let (hitChildOrNil, greatestHitTestWeight, secondGreatestHitTestWeight, _) = childrenHitTestResolution
        
        if let hitChild = hitChildOrNil {
            // 8 / 1.2 ~= 6.6 points hit
            let doesSignificantlyHit = greatestHitTestWeight >= max(secondGreatestHitTestWeight * 1.2, 8)
            if doesSignificantlyHit {
#if DEBUG
                printHitTest("return hitChild = \(hitChild)")
                printHitTest("return contentHitTestWeight = \(contentHitTestWeight)")
                printHitTest("return mask = \(contentMaskAll)")
#endif
                return (hitChild, contentHitTestWeight, contentMaskAll)
            }
        }
        
        if allowsHitTesting {
#if DEBUG
            printHitTest("return self = \(self)")
            printHitTest("return contentHitTestWeight = \(contentHitTestWeight)")
            printHitTest("return mask = \(contentMaskAll)")
#endif
            return (self, contentHitTestWeight, contentMaskAll)
        } else {
#if DEBUG
            printHitTest("return nil")
#endif
            return nil
        }
        
    }
    
    internal final func printTree(depth: Int = 0) {
#if DEBUG
        simplePrintTree(depth: depth)
#endif
    }
    
    // MARK: Visual Debug
    
    internal var visualDebugID: ObjectIdentifier {
        ObjectIdentifier(self)
    }

    internal var visualDebugGeometries: [VisualDebugGeometry] {
        _abstract(self)
    }

    internal func printAncestors() {
        
        var nodes = [ViewResponder]()
        
        var currentOrNil: ViewResponder? = self
        
        while let current = currentOrNil {
            nodes.append(current)
            currentOrNil = current.parent
        }
        
        Swift.print(nodes.map({$0.description}).joined(separator: " -> "))
    }

    internal override var asUIViewResponder: AnyUIViewResponder? {
        nil
    }
    
    internal struct ContainsPointsCache {

        internal var storage: (key: UInt32?, value: ContainsPointsResult)?
        
        internal init() {
            self.storage = nil
        }
        
        @inlinable
        internal mutating func fetch(key: UInt32?, _ body: () -> ContainsPointsResult) -> ContainsPointsResult {
            if let storage, storage.key == key && key != nil {
                return storage.value
            } else {
                let result = body()
                self.storage = (key: key, value: result)
                return result
            }
        }
        
    }
    
#if DEBUG
    private func simplePrintTree(depth: Int) {
        // Print the current node with indentation
        let indentation = String(repeating: "  ", count: depth)
        print("\(indentation)- \(self.description)")
        
        // Recurse through children
        for index in 0..<childCount {
            if let child = child(at: index) {
                child.simplePrintTree(depth: depth + 1)
            }
        }
    }

    private var depth: Int {
        if DanceUIFeature.gestureContainer.isEnable {
            return sequenceFeatureGestureContainer.reduce(0) { partialResult, _ in
                partialResult + 1
            }
        } else {
            return sequence.reduce(0) { partialResult, _ in
                partialResult + 1
            }
        }
    }
    
    private func printHitTest(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if EnvValue.isPrintHitTestEnabled {
            let indent = String(repeating: "  ", count: depth)
            var string = indent
            for (index, each) in items.enumerated() {
                Swift.print(each, separator: "", terminator: "", to: &string)
                if index < items.count - 1 {
                    Swift.print(separator, separator: "", terminator: "", to: &string)
                }
            }
            Swift.print(terminator, separator: "", terminator: "", to: &string)
            Swift.print(string, separator: "", terminator: "")
        }
    }
#endif
    
    internal static var hitTestKey: UInt32 {
        return DanceUI.hitTestKey
    }
    
    internal static func nextHitTestKey() -> UInt32 {
        defer {
            DanceUI.hitTestKey &+= 1
        }
        return DanceUI.hitTestKey
    }
    
    // MARK: Deprecated
    
    @available(*, deprecated, message: "Refactored to `children`.")
    @inline(__always)
    internal final var childCount: Int {
        return children.count
    }

    @available(*, deprecated, message: "Refactored to `children`.")
    @inline(__always)
    internal final func child(at index: Int) -> ViewResponder? {
        return children[index]
    }

    @available(*, deprecated, message: "Removed.")
    internal var isEmptyResponder: Bool {
        false
    }
    
}

#if DEBUG
@available(iOS 13.0, *)
internal struct PrintHitTestKey: DefaultFalseBoolEnvKey {
    
    internal static var raw: String {
        "DANCEUI_PRINT_HIT_TEST"
    }
    
    internal static var availability: EnvKeyAvailability {
        .debugOnly
    }
    
}

@available(iOS 13.0, *)
extension EnvValue where K == PrintHitTestKey {
    
    private static let _isPrintHitTestEnabled: Self = .init()
    
    internal static var isPrintHitTestEnabled: Bool {
        _isPrintHitTestEnabled.value
    }
}
#endif

#if BINARY_COMPATIBLE_TEST
@available(iOS 13.0, *)
internal func test_hitPoints(point: CGPoint, radius: CGFloat) -> ([CGPoint], [Double]) {
    let (p, w, d) = hitPoints(point: point, radius: radius)
    return (p, w)
}

#endif
// swift-format-ignore: NoBlockComments
/// - Parameter derivesOutmostOnly: Only derives the out-most points.
/// - Note:
/// This function has a bug that the returned points does not fully cover
/// the circle of the given radius. The points of last stride are missing.
///
/// Due to this bug, given a 20 points radius, this function would return
/// points covering a circle of 16-point radius. We currently keep this
/// behavior.
///
@available(iOS 13.0, *)
internal /* private */ func hitPoints(point: CGPoint, radius: CGFloat, derivesOutmostOnly: Bool = false) -> ([CGPoint], [Double], [Bool]) {
    var resolvedRadius = max(abs(radius), 1)
    let radiusStepping: CGFloat
    
    if resolvedRadius <= 60 {
        radiusStepping = max(resolvedRadius / 6, 4)
    } else {
        radiusStepping = 10
        resolvedRadius = 60
    }
    
    let iterationCount = min(Int(ceil(resolvedRadius / radiusStepping)), 0x6)

    var perLoopPointsNumber = 4
    
    var currentLoopRadius = radiusStepping
    
    let countOfResult = (iterationCount - 1) * 4 + ((iterationCount - 1) * (iterationCount - 2) / 2) * 4 + 1
    var points: [CGPoint] = .init(unsafeUninitializedCapacity: countOfResult) { _, _  in }
    points.append(point)
    
    var weights: [Double] = .init(unsafeUninitializedCapacity: countOfResult) { _, _ in }
    weights.append(24)
    
    var isDerived: [Bool] = .init(unsafeUninitializedCapacity: countOfResult) { _, _ in }
    isDerived.append(false)
    
    for i in 1..<iterationCount {
        let weight = 24.0 / Double(perLoopPointsNumber)
                
        let sincos = __sincos_stret(Double.pi * 2 / Double(perLoopPointsNumber))
        let sinA = sincos.__sinval
        let cosA = sincos.__cosval

        // sin zero
        var sinθ = 0.0
        
        // cos zero
        var cosθ = 1.0
        
        for _ in 0..<perLoopPointsNumber {
            let x = point.x + currentLoopRadius * CGFloat(cosθ)
            let y = point.y + currentLoopRadius * CGFloat(sinθ)

            if !derivesOutmostOnly || (derivesOutmostOnly && i == iterationCount - 1) {
                points.append(CGPoint(x: x, y: y))
                weights.append(Double(weight))
                isDerived.append(true)
            }
            
            let newSinθ = sinθ * cosA + cosθ * sinA
            cosθ = cosθ * cosA - sinθ * sinA
            sinθ = newSinθ
        }
        
        currentLoopRadius += radiusStepping
        perLoopPointsNumber += 4
    }
    return (points, weights, isDerived)
}
