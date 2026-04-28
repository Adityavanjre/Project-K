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
internal enum ContentStyle {
    
    
    internal enum Primitive: Hashable {
        
        case fill

        case stroke

        case separator
    }
    
    internal struct Style: Hashable {
        
        internal var id: ID
        
        internal var primitive: Primitive
    }
    
    internal enum ID: Int8, _ColorProvider, RawRepresentable {
        
        internal typealias RawValue = Int8
                
        internal init(truncatingLevel: Int) {
            let value = min(truncatingLevel, Int(ID.max.rawValue))
            self.init(rawValue: Int8(value))!
        }
        
        internal static let max: ID = .quaternary // 0x3
        
        case primary

        case secondary

        case tertiary

        case quaternary

        case quinary
        
        internal func resolve(in environment: EnvironmentValues) -> Color.Resolved {
            let systemColorType = SystemColorType(self)
            return systemColorType.resolve(in: environment)
        }
        
        internal var staticColor: CGColor? {
            nil
        }
    }
}
