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
extension Path {
    
    @usableFromInline
    final internal class PathBox: Equatable {
        
        @usableFromInline
        internal static func == (lhs: PathBox, rhs: PathBox) -> Bool {
            lhs.cgPath == rhs.cgPath
        }
        
        internal let cgPath: CGMutablePath
        
        internal var bounds: UnsafeAtomicLazy<CGRect>
        
        internal var boundingRect: CGRect {
            cgPath.boundingBoxOfPath
        }
        
        internal init(_ value: CGPath) {
            self.cgPath = value.mutableCopy()!
            self.bounds = .init(cache: nil)
        }
        
        internal init(_ value: CGMutablePath) {
            self.cgPath = value
            self.bounds = .init(cache: nil)
        }
        
        deinit {
            bounds.destroy()
        }
        
        internal func copy() -> PathBox {
            PathBox(self.cgPath.mutableCopy()!)
        }
        
        internal var isEmpty: Bool {
            cgPath.isEmpty
        }
        
        internal func contains(_ p: CGPoint, eoFill: Bool) -> Bool {
            cgPath.contains(p, using: eoFill ? .evenOdd : .winding, transform: .identity)
        }
        
        internal func clearCaches() {
            bounds.cache = nil
        }
    }
}
