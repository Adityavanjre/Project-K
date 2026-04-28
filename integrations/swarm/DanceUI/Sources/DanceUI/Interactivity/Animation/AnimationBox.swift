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
internal class AnimationBox<AnimationType: CustomAnimation>: AnimationBoxBase {
    
    internal var _base: AnimationType
    
    @inlinable
    internal init(_base: AnimationType) {
        self._base = _base
    }
    
    internal override var animation: any CustomAnimation {
        _base
    }
    
    @inlinable
    internal override func isEqual(to other: AnimationBoxBase) -> Bool {
        let box = other as? AnimationBox<AnimationType>
        return box.map { (box) -> Bool in
            return self._base == box._base
        } ?? false
    }
    
    override func modifier<M>(_ modifier: M) -> any CustomAnimation where M : CustomAnimationModifier {
        CustomAnimationModifiedContent(base: _base, modifier: modifier)
    }
    
}

@available(iOS 13.0, *)
internal class InternalAnimationBox<AnimationType: CustomAnimation>: AnimationBox<AnimationType> {
    
    override func modifier<M>(_ modifier: M) -> any CustomAnimation where M : CustomAnimationModifier {
        InternalCustomAnimationModifiedContent(_base: CustomAnimationModifiedContent(base: _base, modifier: modifier))
    }
}
