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

@frozen
@available(iOS 13.0, *)
public struct _ColorMatrixEffect: RendererEffect {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public var matrix: _ColorMatrix
    
    @inlinable
    public init(matrix: _ColorMatrix) {
        self.matrix = matrix
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .filter(.colorMatrix(matrix))
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// apply effect to view by specified _ColorMatrix
    public func _colorMatrix(_ matrix: _ColorMatrix) -> some View {
        modifier(_ColorMatrixEffect(matrix: matrix))
    }
}
