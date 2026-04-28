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
internal final class LeafViewResponder<T: ContentResponder>: ViewResponder {
    
    internal var helper: ContentResponderHelper<T>!
    
    internal override init() {
        super.init()
        helper = ContentResponderHelper<T>(identifier: ObjectIdentifier(self))
    }
    
    internal override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        helper.addContentPath(to: &path, in: coordinateSpace, observer: observer)
    }
    
    internal override func extendPrintTree(string: inout String) {
        // DEBUG only
//        let globalPos = helper.globalPosition
//        string.append("[\(globalPos.x), \(globalPos.y)]")
    }
    
    internal override func containsGlobalPoints(_ globalPoints: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        helper.containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: cacheKey, children: [])
    }
    
    // MARK: Responder Node Debug
    
    internal override var visualDebugID: ObjectIdentifier {
        ObjectIdentifier(self)
    }
    
    internal override var visualDebugGeometries: [VisualDebugGeometry] {
        [helper.globalGeometry]
    }
    
    override var description: String {
        "<\(type(of: self)), \(Unmanaged.passUnretained(self).toOpaque()); Data = \"\(helper.data.map({"\($0)"}) ?? "nil")\">"
    }
    
}
