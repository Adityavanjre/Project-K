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
extension Bundle {
    
    fileprivate static func getResourcesPath(in bundle: Bundle) -> Bundle? {
        guard let bundlePath = bundle.resourceURL?.appendingPathComponent("DanceUIResources.bundle") else {
            return nil
        }
        return Bundle(url: bundlePath)
    }

    internal static let DanceUI: Bundle = {
        if let bundle = getResourcesPath(in: Bundle.main) {
            return bundle
        }
        if let bundle = getResourcesPath(in: Bundle(for: AnyLayoutEngineBox.self)) {
            return bundle
        }
        _danceuiPreconditionFailure("Missing DanceUIResources Bundle")
    }()
    
    
    internal func localizedAttributedStringForKey(key: String, value: String?, table: String?, localization: String?, locale: Locale) -> NSAttributedString {
        let tableInUse: CFString
        if let table = table, !table.isEmpty {
            tableInUse = table as CFString
        } else {
            tableInUse = "Localizable" as CFString
        }
        let newKey = CFBundleCopyLocalizedStringForLocalizationAndTableURL(bundle: self._cfBundle, key: key, value: value as CFString?, table: tableInUse, localization: localization as CFString?)
        let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.languageIdentifierForDanceUI: locale.identifier]
        return NSAttributedString(string: newKey, attributes: attributes)
    }
    
    internal var _cfBundle: CFBundle {
        CFBundleCreate(nil, CFURLCreateWithFileSystemPath(nil, self.bundlePath as CFString, CFURLPathStyle(rawValue: .zero)!, true))
    }
}

// same as __CFBundleCopyLocalizedStringForLocalizationTableURLAndMarkdownOption
@available(iOS 13.0, *)
internal func CFBundleCopyLocalizedStringForLocalizationAndTableURL(
    bundle: CFBundle,
    key: String,
    value: CFString?, // not used
    table: CFString,
    localization: CFString?)  -> String {
        let translatedStringFromStrings: String? = getResultFromSpecificBundle(key: key, bundle: bundle, table: table, resourceType: "strings" as CFString, subDirName: "" as CFString, localizationName: localization)
        if let translatedStringFromStrings = translatedStringFromStrings {
            return translatedStringFromStrings
        }
        let translatedStringFromStringsDict: String? = getResultFromSpecificBundle(key: key, bundle: bundle, table: table, resourceType: "stringsdict" as CFString, subDirName: "" as CFString, localizationName: localization)
        return translatedStringFromStringsDict ?? key
    }

@inline(__always)
@available(iOS 13.0, *)
internal func getResultFromSpecificBundle(key: String, bundle: CFBundle, table: CFString, resourceType: CFString, subDirName: CFString, localizationName: CFString?) -> String? {
    let resultString: String?
    if let localizationName = localizationName {
        if let bundleURL = CFBundleCopyResourceURLForLocalization(bundle, table, resourceType, subDirName, localizationName),
           let stringsDic = NSDictionary(contentsOf: bundleURL as URL) {
            resultString = stringsDic[key] as? String ?? nil
        } else {
            resultString = nil
        }
    } else {
        if let bundleURL = CFBundleCopyResourceURL(bundle, table, resourceType, subDirName),
           let stringsDic = NSDictionary(contentsOf: bundleURL as URL) {
            resultString = stringsDic[key] as? String ?? nil
        } else {
            resultString = nil
        }
    }
    
    return resultString
}
