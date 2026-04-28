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
internal protocol PresentationHostingControllerDelegate: AnyObject {

    func didDismissViewController()
    
    func adjustAnchorIfNeeded(_ controller: UIViewController, idealSize: CGSize)
}

@available(iOS 13.0, *)
internal final class PresentationHostingController<Content: View> : UIHostingController<Content> {

    fileprivate weak var delegate: PresentationHostingControllerDelegate?

    internal var dismissedProgramatically: Bool
    
    internal init(rootView: Content, delegate: PresentationHostingControllerDelegate, drawsBackground: Bool) {
        self.dismissedProgramatically = false
        self.delegate = delegate
        super.init(rootView: rootView)
        if !drawsBackground {
            self.host.viewController = self
        }
    }

    internal override init(rootView: Content) {
        _danceuiFatalError("init(rootView:) has not been implemented")
    }
    
    @objc
    internal required dynamic init?(coder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }
    
    internal override init?(coder: NSCoder, rootView: Content) {
        _danceuiFatalError("init(coder:rootView:) has not been implemented")
    }
    
    @objc
    internal override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isBeingDismissed else {
            return
        }
        guard !dismissedProgramatically else {
            return
        }
        guard let delegate = delegate else {
            return
        }
        LogService.debug(module: .popover,
                         keyword: .presentedVCDisappear, "PresentationHostingController viewDidDisappear")
        delegate.didDismissViewController()
    }
    
    internal override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DanceUIFeature.enablePopoverAutoAdjustAnchor.call {
            delegate?.adjustAnchorIfNeeded(self, idealSize: host.idealSize())
        } disabled: {
        }
    }
    
    internal func prepareModalPresentationStyle(_ style: UIModalPresentationStyle) {
        if style == .overFullScreen {
            self.modalPresentationCapturesStatusBarAppearance = true
        }
        self.modalPresentationStyle = style
    }
}
