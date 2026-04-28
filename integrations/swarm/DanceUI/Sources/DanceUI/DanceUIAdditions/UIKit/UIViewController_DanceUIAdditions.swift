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

@available(iOS 13.0, *)
extension UIViewController {
    

    internal var ancestors: AnySequence<UIViewController> {
        var vcOrNil = parent
        return AnySequence {
            AnyIterator {
                guard let vc = vcOrNil else {
                    return nil
                }
                vcOrNil = vc.parent
                return vc
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension AncestorsPrinter {
    
    internal static func make(viewController: UIViewController) -> AncestorsPrinter {
        var printerNode: AncestorsPrinter
        printerNode = .leaf(this: _typeName(type(of: viewController)))
        for ancestor in viewController.ancestors {
            printerNode = .child(this: _typeName(type(of: ancestor)), child: printerNode)
        }
        printerNode = .root(child: printerNode)
        return printerNode
    }
    
}
