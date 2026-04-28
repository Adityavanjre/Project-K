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
extension Anchor.Source where Value == CGRect {
    /// Returns an anchor source rect defined by `r` in the current view.
    public static func rect(_ r: CGRect) -> Anchor<Value>.Source {
        let box = AnchorBox<CGRect>(value: r)
        return .init(box: box)
    }
    
    /// An anchor source rect defined as the entire bounding rect of the current
    /// view.
    public static var bounds: Anchor<CGRect>.Source {
        
        let unitRect = UnitRect(x: 0, y: 0, width: 1, height: 1)
        
        let value = AnchorBox<UnitRect>(value: unitRect)
        
        return .init(box: value)
    }
}

@available(iOS 13.0, *)
extension Anchor.Source where Value == CGPoint {
    
    public static func point(_ p: CGPoint) -> Anchor<Value>.Source {
        let box = AnchorBox<CGPoint>(value: p)
        return .init(box: box)
    }
    
    public static func unitPoint(_ p: UnitPoint) -> Anchor<Value>.Source {
        let box = AnchorBox<UnitPoint>(value: p)
        return .init(box: box)
    }
    
    public static var topLeading: Anchor<CGPoint>.Source {
        return unitPoint(.topLeading)
    }

    public static var top: Anchor<CGPoint>.Source {
        return unitPoint(.top)
    }
    
    public static var topTrailing: Anchor<CGPoint>.Source {
        return unitPoint(.topTrailing)
    }
    
    public static var leading: Anchor<CGPoint>.Source {
        return unitPoint(.leading)
    }
    
    public static var center: Anchor<CGPoint>.Source {
        return unitPoint(.center)
    }
    
    public static var trailing: Anchor<CGPoint>.Source {
        return unitPoint(.trailing)
    }
    
    public static var bottomLeading: Anchor<CGPoint>.Source {
        return unitPoint(.bottomLeading)
    }
    
    public static var bottom: Anchor<CGPoint>.Source {
        return unitPoint(.bottom)
    }
    
    public static var bottomTrailing: Anchor<CGPoint>.Source {
        return unitPoint(.bottomTrailing)
    }
}

@available(iOS 13.0, *)
extension Anchor.Source {
    
    public init<T: Equatable>(_ array: [Anchor<T>.Source]) where Value == [T] {
        let box = ArrayAnchorBox(value: array)
        self.init(box: box)
    }
}

@available(iOS 13.0, *)
extension Anchor.Source {
    
    public init<T: Equatable>(_ anchor: Anchor<T>.Source?) where Value == T? {
        let box = OptionalAnchorBox(value: anchor)
        self.init(box: box)
    }
}
