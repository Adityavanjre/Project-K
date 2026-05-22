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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal final class AccessibilityIncrementalLayoutNode: AccessibilityNode {

    internal var scrollableCollection: ScrollableCollection
    
    internal init(viewRendererHost: ViewRendererHost?, scrollableCollection: ScrollableCollection) {
        self.scrollableCollection = scrollableCollection
        super.init(viewRendererHost: viewRendererHost)
    }
    
    internal override var enclosingHostingScrollView: HostingScrollView? {
        if let parent = self.parent {
            return parent.enclosingHostingScrollView
        } else {
            return super.enclosingHostingScrollView
        }
    }
    
    internal override var impliedVisibility: _AccessibilityVisibility {
        let impliedVisibility = super.impliedVisibility
        if impliedVisibility == .element {
            return children.count == 0 ? .element : .container
        }
        return impliedVisibility
    }

}
