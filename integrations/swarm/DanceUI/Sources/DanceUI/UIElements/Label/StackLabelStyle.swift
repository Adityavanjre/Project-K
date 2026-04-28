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
internal struct StackLabelStyle: LabelStyle {

    internal func makeBody(configuration: Configuration) -> some View {
        // 0x5af760 iOS14.3
        /*
        typealias Body =
        HStack<
            TupleView<
                (LabelStyleConfiguration.Icon, LabelStyleConfiguration.Title)
            >
        >
        */
        HStack {
            LabelStyleConfiguration.Icon()
            LabelStyleConfiguration.Title()
        }
    }
}
