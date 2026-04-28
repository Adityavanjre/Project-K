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

internal protocol LookinViewDebug {
    func makeCustomProperties() -> [Any]
    func makeCustomSubviews() -> [Any]
    var title: String { get }
}

extension UIView {

    @objc
    internal func lookin_customDebugInfos() -> [String:Any]? {
        if let viewDebug = self as? LookinViewDebug {
            let ret: [String:Any] = [
                "properties": viewDebug.makeCustomProperties(),
                "subviews": viewDebug.makeCustomSubviews(),
                "title": viewDebug.title
            ]
            return ret
        }
        return nil
    }
}

@available(iOS 13.0, *)
extension _UIHostingView: LookinViewDebug {
     internal func makeCustomSubviews() -> [Any] {
        if let debugData = makeViewDebugData() {
            do {
                let decoder = JSONDecoder()
                let viewDebug = try decoder.decode([LookinDebugData].self, from: debugData)
                var visitor = LookinVisitor(rootTransform())
                viewDebug.visitData(&visitor)
                return visitor.lookinCustomSubviews
            } catch {
                runtimeIssue(type: .warning, "Failed to decode JSON")
            }
        }
        return []
    }

    internal func makeCustomProperties() -> [Any] {
        []
    }
    
    internal var title: String {
        "Hosting view"
    }
}

@available(iOS 13.0, *)
extension PlatformViewHost: LookinViewDebug {
    internal func makeCustomProperties() -> [Any] {
        []
    }
    
    internal func makeCustomSubviews() -> [Any] {
        []
    }
    
    internal var title: String {
        "View Host"
    }
}

#endif
