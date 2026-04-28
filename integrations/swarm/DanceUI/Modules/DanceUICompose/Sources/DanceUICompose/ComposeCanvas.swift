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

public enum Compose {}

// MARK: - Convenience Functions

@inline(__always)
public func withSave(_ canvas: ComposeCanvas, block: () -> Void) {
    canvas.save()
    block()
    canvas.restore()
}

@available(iOS 13, *)
@inline(__always)
public func withSaveLayer(_ canvas: ComposeCanvas, bounds: CGRect, paint: ComposePaint, block: () -> Void) {
    canvas.saveLayer(withBounds: bounds, paint: paint)
    block()
    canvas.restore()
}
