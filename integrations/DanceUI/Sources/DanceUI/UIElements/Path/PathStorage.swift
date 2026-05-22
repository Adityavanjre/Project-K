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
    @frozen
    internal enum Storage: Equatable, PathValuable {
        
        case rect(_ rect: CGRect)
        case ellipse(_ rect: CGRect)
        indirect case roundedRect(_ fixedRoundedRect: FixedRoundedRect)
        indirect case stroked(_ storked: StrokedPath)
        indirect case trimmed(_ trimmed: TrimmedPath)
        case path(_ path: PathBox)
        case empty
        
        @inline(__always)
        internal var cgPath: CGPath {
            switch self {
            case .empty:
                return CGPath(rect: .null, transform: nil)
            case .rect(let rect):
                return CGPath(rect: rect, transform: nil)
            case .ellipse(let rect):
                return CGPath(ellipseIn: rect, transform: nil)
            case .roundedRect(let rect):
                return rect.cgPath
            case .stroked(let stroked):
                return stroked.cgPath
            case .trimmed(let trimmed):
                return trimmed.cgPath
            case .path(let path):
                return path.cgPath
            }
        }
        
        @inline(__always)
        internal func contains(_ p: CGPoint, eoFill: Bool) -> Bool {
            switch self {
            case .empty:
                return false
            case .rect(let rect):
                return rect.contains(p)
            case .ellipse:
                return cgPath.contains(p)
            case .roundedRect(let rect):
                return rect.cgPath.contains(p)
            case .stroked(let path):
                return path.contains(p, eoFill: eoFill)
            case .trimmed(let path):
                return path.contains(p, eoFill: eoFill)
            case .path(let path):
                return path.contains(p, eoFill: eoFill)
            }
        }
        
        @inline(__always)
        internal var boundingRect: CGRect {
            switch self {
            case .empty:
                return .null
            case .rect(let rect):
                return rect
            case .ellipse(let rect):
                return rect
            case .roundedRect(let rect):
                return rect.boundingRect
            case .stroked(let path):
                return path.boundingRect
            case .trimmed(let path):
                return path.boundingRect
            case .path(let path):
                return path.boundingRect
            }
        }
        
        @inline(__always)
        internal var isEmpty: Bool {
            switch self {
            case .empty:
                return true
            case .rect(let rect):
                return rect.isNull
            case .ellipse(let rect):
                return rect.isNull
            case .roundedRect(let rect):
                return rect.rect.isNull
            case .stroked(let path):
                return path.isEmpty
            case .trimmed(let path):
                return path.isEmpty
            case .path(let path):
                return path.isEmpty
            }
        }
        
    }
}
