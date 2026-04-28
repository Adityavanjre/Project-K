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

@_spi(DanceUICompose) import DanceUI

internal class ComposePathOpsImpl: NSObject, ComposePathOps {
    
    internal static let sharedInstance = ComposePathOpsImpl()
    
    internal func union(_ sourcePath: CGPath, maskPath: CGPath, evenOdd: Bool) -> CGPath {
        sourcePath.danceui.union(maskPath, using: evenOdd ? .evenOdd : .winding)
    }
    
    internal func intersect(_ sourcePath: CGPath, maskPath: CGPath, evenOdd: Bool) -> CGPath {
        sourcePath.danceui.intersection(maskPath, using: evenOdd ? .evenOdd : .winding)
    }
    
    internal func subtract(_ sourcePath: CGPath, maskPath: CGPath, evenOdd: Bool) -> CGPath {
        sourcePath.danceui.subtracting(maskPath, using: evenOdd ? .evenOdd : .winding)
    }
    
    internal func xorPath(_ sourcePath: CGPath, maskPath: CGPath, evenOdd: Bool) -> CGPath {
        sourcePath.danceui.symmetricDifference(maskPath, using: evenOdd ? .evenOdd : .winding)
    }
}
