//
//  DanceUIFeatureDefinitions.swift
//  DanceUI
//
//  DO NOT EDIT MANUALLY!!!!!!!!!!
//  Auto created from features.yml
//
//  module: Foundation


/// DanceUI UIHookFreeView initWithFrame Hook Feature
///
/// use the Feature:
///
///     DanceUIFeature.enabledUIHookFreeViewInitHook
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(EnabledUIHookFreeViewInitHookKey.self, value: true)
///
/// - owner: @
/// - module: Foundation
@available(iOS 13.0, *)
internal struct EnabledUIHookFreeViewInitHookKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_EnabledUIHookFreeViewInitHook"
    
    internal static var defaultValue: Bool {
        true
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == EnabledUIHookFreeViewInitHookKey {
    internal static var enabledUIHookFreeViewInitHook: Self.Type {
        Self.self
    }
}


/// DanceUI Popover auto Adjust Anchor
///
/// use the Feature:
///
///     DanceUIFeature.enablePopoverAutoAdjustAnchor
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(EnablePopoverAutoAdjustAnchorKey.self, value: true)
///
/// - owner: @
/// - module: Popover
@available(iOS 13.0, *)
internal struct EnablePopoverAutoAdjustAnchorKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_EnablePopoverAutoAdjustAnchor"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == EnablePopoverAutoAdjustAnchorKey {
    internal static var enablePopoverAutoAdjustAnchor: Self.Type {
        Self.self
    }
}


/// DanceUI collection view async apply data
///
/// use the Feature:
///
///     DanceUIFeature.enableCollectionViewAsyncApplyData
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(EnableCollectionViewAsyncApplyDataKey.self, value: true)
///
/// - owner: @
/// - module: CollectionView
@available(iOS 13.0, *)
internal struct EnableCollectionViewAsyncApplyDataKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_EnableCollectionViewAsyncApplyData"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == EnableCollectionViewAsyncApplyDataKey {
    internal static var enableCollectionViewAsyncApplyData: Self.Type {
        Self.self
    }
}


/// DanceUI collection view info log for release
///
/// use the Feature:
///
///     DanceUIFeature.enableCollectionViewInfoLog
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(EnableCollectionViewInfoLogKey.self, value: true)
///
/// - owner: @
/// - module: CollectionView
@available(iOS 13.0, *)
internal struct EnableCollectionViewInfoLogKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_EnableCollectionViewInfoLog"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == EnableCollectionViewInfoLogKey {
    internal static var enableCollectionViewInfoLog: Self.Type {
        Self.self
    }
}


/// DanceUI loadable info log for release
///
/// use the Feature:
///
///     DanceUIFeature.enableLoadableInfoLog
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(EnableLoadableInfoLogKey.self, value: true)
///
/// - owner: @
/// - module: Loadable
@available(iOS 13.0, *)
internal struct EnableLoadableInfoLogKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_EnableLoadableInfoLog"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == EnableLoadableInfoLogKey {
    internal static var enableLoadableInfoLog: Self.Type {
        Self.self
    }
}


/// DanceUI UIHostingConfiguration support Popover
///
/// use the Feature:
///
///     DanceUIFeature.enableHostingConfigurationSupportPopover
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(EnableHostingConfigurationSupportPopoverKey.self, value: true)
///
/// - owner: @
/// - module: UIHostingConfiguration
@available(iOS 13.0, *)
internal struct EnableHostingConfigurationSupportPopoverKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_EnableHostingConfigurationSupportPopover"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == EnableHostingConfigurationSupportPopoverKey {
    internal static var enableHostingConfigurationSupportPopover: Self.Type {
        Self.self
    }
}


/// DanceUI Image support animated Image
///
/// use the Feature:
///
///     DanceUIFeature.enableAnimatedImage
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(EnableAnimatedImageKey.self, value: true)
///
/// - owner: @
/// - module: Image
@available(iOS 13.0, *)
internal struct EnableAnimatedImageKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_EnableAnimatedImage"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == EnableAnimatedImageKey {
    internal static var enableAnimatedImage: Self.Type {
        Self.self
    }
}


/// DanceUI image async decode before display
///
/// use the Feature:
///
///     DanceUIFeature.imageDecodeForDisplay
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(ImageDecodeForDisplayKey.self, value: true)
///
/// - owner: @
/// - module: Image
@available(iOS 13.0, *)
internal struct ImageDecodeForDisplayKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_ImageDecodeForDisplay"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == ImageDecodeForDisplayKey {
    internal static var imageDecodeForDisplay: Self.Type {
        Self.self
    }
}


/// HostingViewController for cell opt
///
/// use the Feature:
///
///     DanceUIFeature.hostingVCForCell
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(HostingVCForCellKey.self, value: true)
///
/// - owner: @
/// - module: Hosting
@available(iOS 13.0, *)
internal struct HostingVCForCellKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_HostingVCForCell"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == HostingVCForCellKey {
    internal static var hostingVCForCell: Self.Type {
        Self.self
    }
}


/// DanceUI monitor and settings
///
/// use the Feature:
///
///     DanceUIFeature.monitor
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(MonitorKey.self, value: true)
///
/// - owner: @
/// - module: Hosting
@available(iOS 13.0, *)
internal struct MonitorKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_Monitor"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == MonitorKey {
    internal static var monitor: Self.Type {
        Self.self
    }
}




/// Gesture Container
///
/// use the Feature:
///
///     DanceUIFeature.gestureContainer
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(GestureContainerKey.self, value: true)
///
/// - owner: @
/// - module: Gesture
@available(iOS 13.0, *)
internal struct GestureContainerKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_GestureContainer"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == GestureContainerKey {
    internal static var gestureContainer: Self.Type {
        Self.self
    }
}


/// Unified Hit-Testing
///
/// use the Feature:
///
///     DanceUIFeature.unifiedHitTesting
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(UnifiedHitTestingKey.self, value: true)
///
/// - owner: @
/// - module: Gesture
@available(iOS 13.0, *)
internal struct UnifiedHitTestingKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_UnifiedHitTesting"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == UnifiedHitTestingKey {
    internal static var unifiedHitTesting: Self.Type {
        Self.self
    }
}


/// Use fixed -[UITouch majorRadius] value instead of the system's.
///
/// use the Feature:
///
///     DanceUIFeature.fixedUITouchMajorRadius
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(FixedUITouchMajorRadiusKey.self, value: true)
///
/// - owner: @
/// - module: Gesture
@available(iOS 13.0, *)
internal struct FixedUITouchMajorRadiusKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_FixedUITouchMajorRadius"
    
    internal static var defaultValue: Bool {
        true
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == FixedUITouchMajorRadiusKey {
    internal static var fixedUITouchMajorRadius: Self.Type {
        Self.self
    }
}


/// DanceUI HostingConfigurationReader async computer size
///
/// use the Feature:
///
///     DanceUIFeature.hostingConfigurationReaderAsyncComputerSize
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(HostingConfigurationReaderAsyncComputerSizeKey.self, value: true)
///
/// - owner: @
/// - module: Layout
@available(iOS 13.0, *)
internal struct HostingConfigurationReaderAsyncComputerSizeKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_HostingConfigurationReaderAsyncComputerSize"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == HostingConfigurationReaderAsyncComputerSizeKey {
    internal static var hostingConfigurationReaderAsyncComputerSize: Self.Type {
        Self.self
    }
}


/// Fix DanceUI UIViewRepresentable no longer responds to size change on iOS 18.3.x
///
/// use the Feature:
///
///     DanceUIFeature.fixIOS18Dot3UIViewRepresentableNoLongerRespondsToSizeChange
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(FixIOS18Dot3UIViewRepresentableNoLongerRespondsToSizeChangeKey.self, value: true)
///
/// - owner: @
/// - module: ViewRepresentable
@available(iOS 13.0, *)
internal struct FixIOS18Dot3UIViewRepresentableNoLongerRespondsToSizeChangeKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_FixIOS18Dot3UIViewRepresentableNoLongerRespondsToSizeChange"
    
    internal static var defaultValue: Bool {
        true
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == FixIOS18Dot3UIViewRepresentableNoLongerRespondsToSizeChangeKey {
    internal static var fixIOS18Dot3UIViewRepresentableNoLongerRespondsToSizeChange: Self.Type {
        Self.self
    }
}


/// DanceUIObservation support
///
/// use the Feature:
///
///     DanceUIFeature.observation
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(ObservationKey.self, value: true)
///
/// - owner: @
/// - module: DataFlow
@available(iOS 13.0, *)
internal struct ObservationKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_Observation"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == ObservationKey {
    internal static var observation: Self.Type {
        Self.self
    }
}


/// Simplied Chinese IME on iOS sometimes may transform "we" into "w e" and then transform back to "we". If this happens in one run loop cycle, it will interrupt the pinyin stage of the Chinese inputting.
///
/// use the Feature:
///
///     DanceUIFeature.textFieldSupportsPinyinTransform
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(TextFieldSupportsPinyinTransformKey.self, value: true)
///
/// - owner: @
/// - module: TextField
@available(iOS 13.0, *)
internal struct TextFieldSupportsPinyinTransformKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_TextFieldSupportsPinyinTransform"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == TextFieldSupportsPinyinTransformKey {
    internal static var textFieldSupportsPinyinTransform: Self.Type {
        Self.self
    }
}


/// 
///
/// use the Feature:
///
///     DanceUIFeature.componentUsageTraceEnable
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(ComponentUsageTraceEnableKey.self, value: true)
///
/// - owner: @
/// - module: Foundation
@available(iOS 13.0, *)
internal struct ComponentUsageTraceEnableKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_ComponentUsageTraceEnable"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == ComponentUsageTraceEnableKey {
    internal static var componentUsageTraceEnable: Self.Type {
        Self.self
    }
}


/// Identify the DanceUI views from UIKit views
///
/// use the Feature:
///
///     DanceUIFeature.badge
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(BadgeKey.self, value: true)
///
/// - owner: @
/// - module: Hosting
@available(iOS 13.0, *)
internal struct BadgeKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_Badge"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == BadgeKey {
    internal static var badge: Self.Type {
        Self.self
    }
}


/// DanceUI View Info Trace
///
/// use the Feature:
///
///     DanceUIFeature.viewInfoTrace
///
/// mock the Feature Enable:
///
///     FeatureMock.mock(ViewInfoTraceKey.self, value: true)
///
/// - owner: @
/// - module: Foundation
@available(iOS 13.0, *)
internal struct ViewInfoTraceKey: SettingsKey {
    
    internal static let key: String = "DanceUI_Feature_ViewInfoTrace"
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension DanceUIFeature where K == ViewInfoTraceKey {
    internal static var viewInfoTrace: Self.Type {
        Self.self
    }
}



