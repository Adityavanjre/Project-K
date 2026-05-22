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
protocol AlignmentGuide: Equatable, CustomViewDebugValueConvertible {

    var key: AlignmentKey { get }

}

@available(iOS 13.0, *)
extension AlignmentGuide {

    internal var fraction: CGFloat {
        let dimension = ViewDimensions(guideComputer: .defaultValue, size: ViewSize(value: CGSize(width: 1, height: 1), _proposal: .zero))
        return key.id.defaultValue(in: dimension)
    }

}

@available(iOS 13.0, *)
public protocol FrameAlignment: AlignmentID {}

@available(iOS 13.0, *)
extension FrameAlignment {

    public static func _combineExplicit(childValue: CGFloat, _ seed: Int, into alignment: inout CGFloat?) {
        _intentionallyLeftBlank()
    }
}
