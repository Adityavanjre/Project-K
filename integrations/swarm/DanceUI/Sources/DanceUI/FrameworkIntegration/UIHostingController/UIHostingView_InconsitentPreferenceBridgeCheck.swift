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

@available(iOS 13.0, *)
extension _UIHostingView {
    

    fileprivate final class PreferenceBridgeConsistencyCheckInfo {
        
        fileprivate var inherited: UnsafeMutableRawPointer?
        
        fileprivate var override: UnsafeMutableRawPointer?
        
        fileprivate var resolved: UnsafeMutableRawPointer?
        
        fileprivate var hostingViewHierarchy: AncestorsPrinter
        
        fileprivate var hostingControllerHierarchy: AncestorsPrinter?
        
        @inline(__always)
        fileprivate init<T>(_ host: _UIHostingView<T>) {
            @inline(__always)
            func toPtr(_ bridge: PreferenceBridge) -> UnsafeMutableRawPointer {
                Unmanaged.passUnretained(bridge).toOpaque()
            }
            inherited = host.traitCollection.baseEnvironment.preferenceBridge.map(toPtr)
            override = host.environmentOverride?.preferenceBridge.map(toPtr)
            resolved = host.overridenMasterEnvironmentAndViewPhase.environmentValues.preferenceBridge.map(toPtr)
            hostingViewHierarchy = .make(view: host)
            hostingControllerHierarchy = host.pairedHostingController.map(AncestorsPrinter.make)
        }
        
    }
    

    /// Potential inconsistent preference bridge reason for nested
    /// `_UIHostingView` or `UIHostingController`
    fileprivate enum InconsistentPreferenceBridgeError: Error {

        case inheirtedPreferenceBridgeIsNilInNestedHost(
            hostingView: _UIHostingView<Content>,
            info: PreferenceBridgeConsistencyCheckInfo
        )
        
        case inconsistentPreferenceBridge(
            hostingView: _UIHostingView<Content>,
            initialInfo: PreferenceBridgeConsistencyCheckInfo,
            latestInfo: PreferenceBridgeConsistencyCheckInfo
        )
        
        fileprivate var issue: String {
            switch self {
            case .inheirtedPreferenceBridgeIsNilInNestedHost:
                return "[CRITICAL] Nested _UIHostingView was detected and the preference bridge inheirted from UITraitCollection is nil. This may cause potential runtime crashes."
            case .inconsistentPreferenceBridge(_, let initial, let latest):
                return "[CRITICAL] The latest preference bridge (\(makePtrDescription(latest.resolved))) resolved from environment is inconsistent with the initial one (\(makePtrDescription(initial.resolved))). This may cause potential runtime crashes."
            }
        }
        
        fileprivate var solutions: [String] {
            let hostingView = hostingView
            if let vc = hostingView.pairedHostingController {
                return [
                    "[SOLUTION] This may be cuased by you called methods on \(_typeName(type(of: vc))) or its paired view instance before adding its view to the view hierarchy.",
                    "[SOLUTION] If adding the view to the view hierarchy is not an available option, you can try set the preferenceBridge of UIViewControllerRepresentableContext to _UIHostingView's environmentOverride"
                ]
            } else {
                return [
                    "[SOLUTION] This may be cuased by you called methods on \(_typeName(type(of: hostingView))) before adding its view to the view hierarchy.",
                    "[SOLUTION] If adding the view to the view hierarchy is not an available option, you can try set the preferenceBridge of UIViewRepresentableContext to _UIHostingView's environmentOverride"
                ]
            }
        }
        
        fileprivate var infos: [String] {
            infoAndTiming.flatMap(makeInfoAndTimingDescriptions)
        }
        
        private var hostingView: _UIHostingView<Content> {
            switch self {
            case .inheirtedPreferenceBridgeIsNilInNestedHost(let host, _):
                return host
            case .inconsistentPreferenceBridge(let host, _, _):
                return host
            }
        }
        
        private var infoAndTiming: [(PreferenceBridgeConsistencyCheckInfo, String)] {
            switch self {
            case .inheirtedPreferenceBridgeIsNilInNestedHost(_, let info):
                return [(info, "Current")]
            case .inconsistentPreferenceBridge(_, let initial, let latest):
                return [
                    (initial, "Initial"),
                    (latest, "Latest")
                ]
            }
        }
        
        @inline(__always)
        private func makeInfoAndTimingDescriptions(_ infoAndTiming: (PreferenceBridgeConsistencyCheckInfo, String)) -> [String] {
            let (info, timing) = infoAndTiming
            var results: [String] = []
            results.append(contentsOf: [
                "[INFO] \(timing) inherited preference bridge extracted from UITraitCollection: \(makePtrDescription(info.inherited))",
                "[INFO] \(timing) override preference bridge extracted from _UIHostingView.environmentOverride: \(makePtrDescription(info.override))",
                "[INFO] \(timing) resolved preference bridge: \(makePtrDescription(info.resolved))"
            ])
            if let vch = info.hostingControllerHierarchy {
                results.append(contentsOf: [
                    "[INFO] Current view controller hierarchy",
                    vch.description
                ])
            }
            results.append(contentsOf: [
                "[INFO] Current view hierarchy",
                info.hostingViewHierarchy.description
            ])
            return results
        }
        
        @inline(__always)
        private func makePtrDescription(_ ptr: UnsafeMutableRawPointer?) -> String {
            return ptr?.debugDescription ?? "nil"
        }
        
    }
    

    private var initialPreferenceBridgeInfo: PreferenceBridgeConsistencyCheckInfo? {
        get {
            objc_getAssociatedObject(self, &preferenceBridgeConsistencyCheckInfoKey) as? PreferenceBridgeConsistencyCheckInfo
        }
        set {
            objc_setAssociatedObject(self, &preferenceBridgeConsistencyCheckInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var isInNestedHost: Bool {
        if let vc = pairedHostingController {
            return !vc.ancestors.filter({$0 is AnyHostingController}).isEmpty
        } else {
            return !ancestors.filter({$0 is AnyUIHostingView}).isEmpty
        }
    }
    
    /// Nested `_UIHostingView` or `UIHostingController` brought by
    /// `UIViewRepresentable` or `UIViewControllerRepresentable` needs
    /// preference bridge derived by `UITraitCollection` to "return" preference
    /// values computed by the nested hosting view/view-controller to the
    /// nesting hosting view/view-controller.
    ///
    ///
    @inline(__always)
    private func checkUpdateEnvironmentForInconsistentPreferenceBridge() throws {
        let info = PreferenceBridgeConsistencyCheckInfo(self)
        
        defer {
            if initialPreferenceBridgeInfo == nil {
                initialPreferenceBridgeInfo = info
            }
        }
        
        if isInNestedHost && info.inherited == nil {
            throw InconsistentPreferenceBridgeError
                .inheirtedPreferenceBridgeIsNilInNestedHost(
                    hostingView: self,
                    info: info
                )
        }
        
        if let initialInfo = initialPreferenceBridgeInfo,
           initialInfo.resolved != info.resolved {
            throw InconsistentPreferenceBridgeError
                .inconsistentPreferenceBridge(
                    hostingView: self,
                    initialInfo: initialInfo,
                    latestInfo: info
                )
        }
    }
    

    internal func checkInconsistentPreferenceBridge() {
        do {
            if EnvValue.isHostingViewInconsistentPreferenceBridgeCheckEnabled {
                try checkUpdateEnvironmentForInconsistentPreferenceBridge()
            }
        } catch let error as InconsistentPreferenceBridgeError {
            print(error.issue)
            for each in error.solutions {
                print(each)
            }
            for each in error.infos {
                print(each)
            }
            InconsistentPreferenceBridgeWarning()
        } catch let error {
            print("Unexpected error: \(error)")
        }
    }
    
}

private var preferenceBridgeConsistencyCheckInfoKey: Void?


// swift-format-ignore: AlwaysUseLowerCamelCase
@_silgen_name("DanceUIInconsistentPreferenceBridgeWarning")
@inline(never)
@available(iOS 13.0, *)
public func InconsistentPreferenceBridgeWarning() {
#if DEBUG
    inconsistentPreferenceBridgeCheckResultCount += 1
#endif
}

#if DEBUG
internal var inconsistentPreferenceBridgeCheckResultCount = 0
#endif

@available(iOS 13.0, *)
extension EnvValue where K == UIHostingViewInconsistentPreferenceBridgeCheckKey {
    
    private static let singleton: Self = .init()
    

    @inline(__always)
    internal static var isHostingViewInconsistentPreferenceBridgeCheckEnabled: Bool {
        singleton.value
    }
    
}

@available(iOS 13.0, *)
internal struct UIHostingViewInconsistentPreferenceBridgeCheckKey: DefaultFalseBoolEnvKey {
    

    internal static var raw: String {
        "DANCEUI_INCONSISTENT_PREFERENCE_BRIDGE_CHECK"
    }
    
}
