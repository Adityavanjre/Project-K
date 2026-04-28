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

/// A type-erased shape value.
///
/// You can use this type to dynamically switch between shape types:
///
///     struct MyClippedView: View {
///         var isCircular: Bool
///
///         var body: some View {
///             OtherView().clipShape(isCircular ?
///                 AnyShape(Circle()) : AnyShape(Capsule()))
///         }
///     }
///
@frozen
@available(iOS 13.0, *)
public struct AnyShape: Shape {
    
    public typealias AnimatableData = _AnyAnimatableData
    
    public typealias Body = _ShapeView<AnyShape, ForegroundStyle>
    
    internal var storage: AnyShapeBox
    
    /// Create an any shape instance from a shape.
    public init<S>(_ shape: S) where S : Shape {
        self.storage = _AnyShapeBox(shape: shape)
    }
    
    public func path(in rect: CGRect) -> Path {
        self.storage.path(in: rect)
    }
    
    public var animatableData: AnimatableData {
        get {
            .zero
        }

        set {
            _intentionallyLeftBlank()
        }
    }
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        storage.sizeThatFits(proposal)
    }
}

@usableFromInline
@available(iOS 13.0, *)
internal class AnyShapeBox {
    
    @objc
    @usableFromInline
    deinit {
        
    }
    
    internal func path(in rect: CGRect) -> Path {
        _abstractFunction()
    }
    
    internal func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        _abstractFunction()
    }
}

@available(iOS 13.0, *)
private final class _AnyShapeBox<ShapeType: Shape>: AnyShapeBox {
    
    fileprivate var shape: ShapeType
    
    fileprivate init(shape: ShapeType) {
        self.shape = shape
    }
    
    fileprivate override func path(in rect: CGRect) -> Path {
        self.shape.path(in: rect)
    }
    
    fileprivate override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        self.shape.sizeThatFits(proposal)
    }
}
