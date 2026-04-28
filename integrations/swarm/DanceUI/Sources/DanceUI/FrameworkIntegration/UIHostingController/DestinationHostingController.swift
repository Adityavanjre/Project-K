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
internal final class DestinationHostingController<Content: View>: UIHostingController<Content> {


    internal var didSendContentScrollViewUpdate: Bool
    
    internal override init(rootView: Content) {
        self.didSendContentScrollViewUpdate = false
        super.init(rootView: rootView)
    }
    
    @objc
    public required dynamic init?(coder: NSCoder) {
        self.didSendContentScrollViewUpdate = false
        super.init(coder: coder)
    }
    
    internal override init?(coder aDecoder: NSCoder, rootView: Content) {
        self.didSendContentScrollViewUpdate = false
        super.init(coder: aDecoder, rootView: rootView)
    }
    
    internal override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didSendContentScrollViewUpdate = false
    }
    
    internal override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didSendContentScrollViewUpdate,
              let _ = self.contentScrollView() else {
            return
        }
        
        let outermostNavVC = self.navigationController?.my__outermost()
        outermostNavVC?.my__updateBarsForCurrentInterfaceOrientation()
        self.didSendContentScrollViewUpdate = true
    }
    
    internal override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        didSendContentScrollViewUpdate = false
    }
    
}
