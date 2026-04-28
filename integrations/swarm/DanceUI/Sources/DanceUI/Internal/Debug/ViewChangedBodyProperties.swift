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
@_spi(DanceUI) import DanceUIObservation
internal import os.log

// BDCOV_EXCL_FUNC
@available(iOS 13.0, *)
internal func changedBodyProperties<A>(of type: A.Type) -> [String] {
    let options: [DanceUIGraphDescriptionOption : Any] = [DanceUIGraphDescriptionOption.format : "stack/frame",
                                                          DanceUIGraphDescriptionOption.stackFrameIndex : 0]
    guard let description = DanceUIGraphDescription(nil, options) else {
        return []
    }
    guard let stackDescDict = description as? [DanceUIGraphStackDescriptionKey: Any], !stackDescDict.isEmpty else {
        return []
    }
    
    guard let nodeID = stackDescDict[.nodeID] as? UInt32,
          let selfType = stackDescDict[.selfType] as? BodyAccessorRule.Type else {
        return []
    }
    
    guard selfType.container == type else {
        return []
    }
    
    var changedPropertyNames: [String] = []
    
    let attribute = DGAttribute(rawValue: nodeID)
    
    if attribute.valueState.contains(.wasModified) {
        
        let observationChanges = ObservationRegistrar.latestTriggers.map { keyPath -> String in
            if #available(iOS 16.4, *) {
                return keyPath.debugDescription
            } else {
                return "\(keyPath)"
            }
        }
        
        changedPropertyNames.append(contentsOf: observationChanges)
    }
    
    let metaProperties = selfType.metaProperties(as: type, attribute: attribute)
    if !metaProperties.isEmpty, let inputs = stackDescDict[.inputs] as? [[DanceUIGraphStackInputDescriptionKey: Any]] {
        for metaProperty in metaProperties {
            for input in inputs {
                guard let id = input[DanceUIGraphStackInputDescriptionKey.ID] as? UInt32 else {
                    continue
                }
                guard let changed = input[.changed] as? Bool, changed else {
                    continue
                }
                guard DGAttribute(rawValue: id) == metaProperty.1 else {
                    continue
                }
                changedPropertyNames.append(metaProperty.0)
            }
        }
    }
    
    if let buffer = selfType.buffer(as: type, attribute: DGAttribute(rawValue: nodeID)) {
        let fields = DynamicPropertyCache.fields(of: type)
        buffer.applyChanged { offset in
            switch fields.layout {
            case .product(let fields):
                guard let field = fields.first(where: { $0.offset == offset }),
                      let name = field.name,
                      let property = String(cString: name, encoding: .utf8)
                else {
                    changedPropertyNames.append("@\(offset)")
                    return
                }
                changedPropertyNames.append(property)
            case .sum:
                changedPropertyNames.append("@\(offset)")
            }
        }
    }
    
    return changedPropertyNames
}

@available(iOS 13.0, *)
internal func printChangedBodyProperties<A>(of type: A.Type) { // BDCOV_EXCL_BLOCK
    let result = changedBodyProperties(of: type)
    var changedContent = "\(DGTypeID(type).description)"
    if !result.isEmpty {
        changedContent.append(": \(result.joined(separator: ", ")) changed.")
    } else {
        changedContent.append(": unchanged.")
    }
    print(changedContent)
}

//@available(iOS 14.0, *)
//extension Logger {
//    static let changeBodyPropertiesLogger = Logger(subsystem: "com.bytedance.DanceUI", category: "Changed Body Properties")
//}

// swift-format-ignore: DontRepeatTypeInStaticProperties
extension OSLog {
    internal static let changeBodyPropertiesLogger = OSLog(subsystem: "com.bytedance.DanceUI", category: "Changed Body Properties") // BDCOV_EXCL_LINE
}

@available(iOS 13.0, *)
internal func logChangedBodyProperties<Body>(of type: Body.Type) { // BDCOV_EXCL_BLOCK
    let properties = changedBodyProperties(of: type)
    let changedContent = "\(DGTypeID(type).description)"
    if properties.isEmpty {
        // Logger.changeBodyPropertiesLogger.info("\(changedContent, privacy: .public): unchanged.")
        os_log("%{public}s: unchanged.", log: .changeBodyPropertiesLogger, type: .info, changedContent)
    } else {
        // Logger.changeBodyPropertiesLogger.info("\(result, privacy: .public): \(properties.joined(separator: ", "), privacy: .public) changed.")
        os_log("%{public}s: %{public}s changed.", log: .changeBodyPropertiesLogger, type: .info, changedContent, properties.joined(separator: ", "))
    }
}

// MARK: - printChanges

@available(iOS 13.0, *)
extension View {

    /// When called within an invocation of `body` of a view of this
    /// type, prints the names of the changed dynamic properties that
    /// caused the result of `body` to need to be refreshed. As well as
    /// the physical property names, "@self" is used to mark that the
    /// view value itself has changed, and "@identity" to mark that the
    /// identity of the view has changed (i.e. that the persistent data
    /// associated with the view has been recycled for a new instance
    /// of the same type).
    public static func _printChanges() { // BDCOV_EXCL_BLOCK
        printChangedBodyProperties(of: Self.self)
    }
}

@available(iOS 13.0, *)
extension ViewModifier {
    /// When called within an invocation of `body()` of a view modifier
    /// of this type, prints the names of the changed dynamic
    /// properties that caused the result of `body()` to need to be
    /// refreshed. As well as the physical property names, "@self" is
    /// used to mark that the modifier value itself has changed, and
    /// "@identity" to mark that the identity of the modifier has
    /// changed (i.e. that the persistent data associated with the
    /// modifier has been recycled for a new instance of the same
    /// type).
    public static func _printChanges() { // BDCOV_EXCL_BLOCK
        printChangedBodyProperties(of: Self.self)
    }
}

// MARK: - logChanges

@available(iOS 13.0, *)
extension View {
    
    /// When called within an invocation of `body` of a view of this type, logs
    /// the names of the changed dynamic properties that caused the result of
    /// `body` to need to be refreshed.
    ///
    ///     var body: some View {
    ///         let _ = Self._logChanges()
    ///         ... view content ...
    ///     }
    ///
    /// As well as the physical property names, "@self" is used to mark that the
    /// view value itself has changed, and "@identity" to mark that the identity
    /// of the view has changed (i.e. that the persistent data associated with
    /// the view has been recycled for a new instance of the same type).
    ///
    /// The information is logged at the info level to the "com.bytedance.DanceUI"
    /// subsystem with the category "Changed Body Properties".
    public static func _logChanges() { // BDCOV_EXCL_BLOCK
        logChangedBodyProperties(of: Self.self)
    }
}

@available(iOS 13.0, *)
extension ViewModifier {

    /// When called within an invocation of `body` of a view modifier of this
    /// type, logs the names of the changed dynamic properties that caused the
    /// result of `body` to need to be refreshed.
    ///
    ///     func body(content: Self.Content): Self.Body {
    ///         let _ = Self._logChanges()
    ///         ... view modifier content ...
    ///     }
    ///
    /// As well as the physical property names, "@self" is used to mark that the
    /// modifier value itself has changed, and "@identity" to mark that the
    /// identity of the modifier has changed (i.e. that the persistent data
    /// associated with the modifier has been recycled for a new instance of the
    /// same type).
    ///
    /// The information is logged at the info level to the "com.bytedance.DanceUI"
    /// subsystem with the category "Changed Body Properties".
    public static func _logChanges() { // BDCOV_EXCL_BLOCK
        logChangedBodyProperties(of: Self.self)
    }
}

//BDCOV_EXCL_STOP
