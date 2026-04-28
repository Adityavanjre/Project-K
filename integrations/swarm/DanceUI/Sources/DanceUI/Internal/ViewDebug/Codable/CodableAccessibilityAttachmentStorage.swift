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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
internal struct CodableAccessibilityAttachmentStorage {

    internal var label: ResolvedStyledText?

    internal var value: ResolvedStyledText?

    internal var hint: ResolvedStyledText?

    internal var identifier: String?

    internal var visibility: _AccessibilityVisibility?

    internal var traits: AccessibilityTraitStorage

    internal var sortPriority: Double?

    internal var _automationType: UInt64?

    internal var _roleDescription: CodableAttributedString?

    internal var dataSeriesConfiguration: CodableAccessibilityDataSeriesConfiguration?

    internal var linkDestination: LinkDestination.Configuration?

    internal var customAttributes: AccessibilityCustomAttributes?
    
}

#endif
