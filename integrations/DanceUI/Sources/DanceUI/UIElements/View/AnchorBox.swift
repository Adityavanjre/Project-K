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

@usableFromInline
@available(iOS 13.0, *)
internal class AnchorBoxBase<Value> {
    
    internal func prepare(size: CGSize, transform: ViewTransform) -> AnchorValueBoxBase<Value> {
        _abstractFunction()
    }
}

@available(iOS 13.0, *)
internal final class AnchorBox<P: AnchorProtocol>: AnchorBoxBase<P.AnchorValue> {
    
    internal let value: P
    
    internal init(value: P) {
        self.value = value
    }
    
    internal override func prepare(size: CGSize, transform: ViewTransform) -> AnchorValueBoxBase<P.AnchorValue> {
        let anchorValue = value.prepare(size: size, transform: transform)
        
        return AnchorValueBox<P>(value: anchorValue)
    }
}

@available(iOS 13.0, *)
internal final class ArrayAnchorBox<Value: Equatable>: AnchorBoxBase<[Value]> {
    
    internal let value: Array<Anchor<Value>.Source>
    
    internal init(value: Array<Anchor<Value>.Source>) {
        self.value = value
    }
    
    internal override func prepare(size: CGSize, transform: ViewTransform) -> AnchorValueBoxBase<[Value]> {
        let value = self.value.map { (element: Anchor<Value>.Source) -> Anchor<Value> in
            return element.prepare(size: size, transform: transform)
        }
        
        return ArrayAnchorValueBox(value: value)
    }
}

@available(iOS 13.0, *)
internal final class OptionalAnchorBox<Value: Equatable>: AnchorBoxBase<Value?> {
    
    internal var value: Anchor<Value>.Source?

    internal init(value: Anchor<Value>.Source?) {
        self.value = value
    }
    
    internal override func prepare(size: CGSize, transform: ViewTransform) -> AnchorValueBoxBase<Value?> {
        let value = self.value.map {
            $0.prepare(size: size, transform: transform)
        }
        
        return OptionalAnchorValueBox(value: value)
    }
}
