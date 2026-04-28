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

internal import Resolver

// MARK: - CompliantInfo

@available(iOS 13.0, *)
@frozen
public struct CompliantInfoName: RawRepresentable, Equatable {
    
    public typealias RawValue = String
    
    public let rawValue: RawValue
    
    @inlinable
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    @inlinable
    public init(_ value: RawValue) {
        self.init(rawValue: value)
    }
    
}

@available(iOS 13.0, *)
public enum CompliantInfo {
    
    case string(name: CompliantInfoName, value: String)
    
    case cgFloat(name: CompliantInfoName, value: CGFloat)
    
    case double(name: CompliantInfoName, value: Double)
    
    case float(name: CompliantInfoName, value: Float)
    
    case int(name: CompliantInfoName, value: Int)
    
    case bool(name: CompliantInfoName, value: Bool)
    
    // Time interval since reference date
    case date(name: CompliantInfoName, value: Date)
    
    case formattedDate(name: CompliantInfoName, value: Date, formatter: DateFormatter)
    
    case formattedNumber(name: CompliantInfoName, value: NSNumber, formatter: NumberFormatter)
    
    /// Helps build log info dictionary.
    internal func dump(into info: inout [String : Any]) {
        switch self {
        case .string(let name, let value):
            info[name.rawValue] = value
        case .cgFloat(let name, let value):
            info[name.rawValue] = value
        case .double(let name, let value):
            info[name.rawValue] = value
        case .float(let name, let value):
            info[name.rawValue] = value
        case .int(let name, let value):
            info[name.rawValue] = value
        case .bool(let name, let value):
            info[name.rawValue] = value
        case .date(let name, let value):
            info[name.rawValue] = value.timeIntervalSinceReferenceDate as Double
        case .formattedDate(let name, let value, let formatter):
            info[name.rawValue] = formatter.string(from: value)
        case .formattedNumber(let name, let value, let formatter):
            info[name.rawValue] = formatter.string(from: value)
        }
    }
    
}

// MARK: - CompliantInfoTransforming

@available(iOS 13.0, *)
public enum UITouchTransformableProperty {
    
    case majorRadius(CGFloat)
    
}

/// Transform info that might involve compliant issue into compliant.
///
@available(iOS 13.0, *)
public protocol CompliantInfoTransforming {
    
    /// Transform properties from UITouch that might involve compliant
    /// issue into compliant.
    ///
    /// Return nil if the property is not used in the log.
    ///
    func transformUITouchProperty(_ property: UITouchTransformableProperty) -> CompliantInfo?
    
}

@available(iOS 13.0, *)
extension CompliantInfoTransforming {
    
    /// Default implementation. Always returns nil.
    ///
    public func transformUITouchProperty(_ property: UITouchTransformableProperty) -> CompliantInfo? {
        nil
    }
    
    internal func collectCompliantInfo(
        requiring collectRequiredInfo: (_ transformer: Self) -> [CompliantInfo?],
        supplementary collectSupplementaryInfo: () -> [CompliantInfo?],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) -> [CompliantInfo]? {
        let requiredInfo = collectRequiredInfo(self).compactMap({$0})
        guard !requiredInfo.isEmpty else {
            LogService.debug(module: .compliance, keyword: .transform, "No required info found. Check your implementation of the compliant info transformer class.", info: ["class": type(of: self)], file: file, function: function, line: line)
            return nil
        }
        let supplementaryInfo = collectSupplementaryInfo().compactMap({$0})
        var info = [CompliantInfo]()
        info.reserveCapacity(requiredInfo.count + supplementaryInfo.count)
        info.append(contentsOf: requiredInfo)
        info.append(contentsOf: supplementaryInfo)
        return info
    }
    
    internal func buildLogInfo(with compliantInfo: [CompliantInfo]) ->  [String : Any] {
        var info = [String : Any]()
        info.reserveCapacity(compliantInfo.count)
        for each in compliantInfo {
            each.dump(into: &info)
        }
        return info
    }
    
}

#if DEBUG
@available(iOS 13.0, *)
private class DebugCompliantInfoTransformer: CompliantInfoTransforming {
    
    fileprivate static let shared = DebugCompliantInfoTransformer()
    
    private init() {
        
    }
    
    fileprivate func transformUITouchProperty(_ property: UITouchTransformableProperty) -> CompliantInfo? {
        switch property {
        case .majorRadius(let radius):
            return CompliantInfo.cgFloat(name: .majorRadiius, value: radius)
        }
    }
    
}
#endif

@available(iOS 13.0, *)
extension CompliantInfoName {
    
    fileprivate static let majorRadiius = CompliantInfoName("majorRadius")
    
}

#if DEBUG
@available(iOS 13.0, *)
internal func testableResetResolvedCompliantInfoTransformer() {
    clientCompliantInfoTransformer = nil
    guard let transformer = Resolver.services.optional(CompliantInfoTransforming.self) else {
        return
    }
    clientCompliantInfoTransformer = transformer
}
#endif

@available(iOS 13.0, *)
private var clientCompliantInfoTransformer: CompliantInfoTransforming? = {
    guard let transformer = Resolver.services.optional(CompliantInfoTransforming.self) else {
        LogService.info(module: .compliance, keyword: .resolve, "CompliantInfoTransformer resolve failed")
        return nil
    }
    LogService.info(module: .compliance, keyword: .resolve, "CompliantInfoTransformer resolve success", info: ["class": type(of: transformer)])
    return transformer
}()

/// Gets the compliant info transformer to transform info that needs
/// compliance.
///
@inline(__always)
@available(iOS 13.0, *)
internal func withCompliantInfoTransformer<R>(_ body: (_ transformer: CompliantInfoTransforming) -> R?, file: String = #file, function: String = #function, line: UInt = #line) -> R? {
    let debugTransformer: CompliantInfoTransforming?
#if DEBUG
    debugTransformer = DebugCompliantInfoTransformer.shared
#else
    debugTransformer = nil
#endif
    guard let transformer = clientCompliantInfoTransformer ?? debugTransformer else {
        return nil
    }
    guard let result = body(transformer) else {
        return nil
    }
    return result
}

@available(iOS 13.0, *)
private enum ComplianceLogKeyword: String, LogKeyword {
    
    case resolve
    
    case transform
    
    fileprivate static var moduleName: String {
        "Compliance"
    }
    
}

@available(iOS 13.0, *)
extension LogService.Module where K == ComplianceLogKeyword {
    
    fileprivate static let compliance: Self = .init()
    
}
