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
internal struct LinearUIKitProgressView: UIViewRepresentable {
    
    internal typealias UIViewType = UIProgressView

    internal var fractionCompleted: Double

    internal var tint: Color?

    
    internal func makeUIView(context: Context) -> UIProgressView {
        UIProgressView(progressViewStyle: UIProgressView.Style.default)
    }
    
    internal func updateUIView(_ uiView: UIProgressView, context: Context) {
        var resolvedColor: UIColor? = nil
        if (context.transaction.animation != nil) {
            uiView.setProgress(Float(fractionCompleted), animated: true)
        } else {
            uiView.setProgress(Float(fractionCompleted), animated: false)
        }
        if let tintColor = self.tint {
            resolvedColor = tintColor.resolvedUIColor(in: context.environment)
            uiView.progressTintColor = resolvedColor
        }
    }
    
}
