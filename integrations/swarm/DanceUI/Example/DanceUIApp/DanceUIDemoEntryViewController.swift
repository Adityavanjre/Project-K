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

import UIKit
import DanceUI

let pushTimes = 1

@available(iOS 13.0, *)
class DanceUIDemoEntryViewController: UIViewController {
    
    var flag: Bool = false
    var times: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Push",
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(push))
        
        // Do any additional setup after loading the view.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] (timer) in
            guard let self = self else {
                return
            }
            guard self.times < pushTimes else {
                timer.invalidate()
                return
            }
            if self.navigationController?.viewControllers.count ?? 0 < 2 {
                self.push()
                self.times &+= 1
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc
    func push() {
        let contentView = ContentView()
        
        let rootView = contentView
        
        let vc = UIHostingController(rootView: rootView)
        vc.view.frame = self.view.bounds
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
