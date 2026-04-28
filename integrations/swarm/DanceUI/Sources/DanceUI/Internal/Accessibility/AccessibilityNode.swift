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
import ObjectiveC

@available(iOS 13.0, *)
internal class AccessibilityNode: NSObject, ContentPathObserver {
    
    internal var id: UniqueID
    
    internal var version: DisplayList.Version
    
    internal var children: [AccessibilityNode]
    
    internal weak var parent: AccessibilityNode?
    
    internal unowned let viewRendererHost: ViewRendererHost?
    
    private var oldAttachmentForNotification: AccessibilityAttachment?
    
    private var attachmentsStorage: [AccessibilityAttachmentStorage]
    
    private var cachedCombinedAttachment: AccessibilityAttachment?
    
    internal var isEnabled: Bool
    
    internal var needsUpdatePath: Bool
    
    private var needsGlobalFrameUpdate: Bool
    
    internal weak var focusableAncestor: AccessibilityNode?
    
    internal var relationshipScope: AccessibilityRelationshipScope?
    
    deinit {
        if case let .platform(_, target, _) = cachedCombinedAttachment {
            if let object = target as? NSObject {
                object.accessibilityNodeForPlatformElement = nil
            }
        }
        danceUI_accessibilityUnregister()        
    }
    
    internal init(viewRendererHost: ViewRendererHost?) {
        self.id = UniqueID()
        self.version = .zero
        self.children = []
        self.parent = nil
        self.oldAttachmentForNotification = nil
        self.attachmentsStorage = []
        self.cachedCombinedAttachment = nil
        self.isEnabled = true
        self.needsUpdatePath = true
        self.needsGlobalFrameUpdate = true
        self.focusableAncestor = nil
        self.relationshipScope = nil
        self.viewRendererHost = viewRendererHost
        
        super.init()
    }
    
    internal var properties: AccessibilityProperties {
        switch attachment {
        case .properties(let properties):
            return properties
        case .platform(let properties, _, _):
            guard let properties = properties else {
                return platformExternalProperties ?? AccessibilityProperties(plist: PropertyList(elements: nil))
            }

            guard let externalProperties = platformExternalProperties else {
                return properties
            }
            
            return properties.combined(with: externalProperties)
        }
    }
    
    internal var subgraph: DGSubgraphRef? {
        for storage in attachmentsStorage {
            switch storage.token {
            case .none:
                continue
            case .attribute(let attribute):
                return attribute.subgraph
            case .identifier(let id):
                return DGAttribute(rawValue: id).subgraph
            }
        }
        return nil
    }
    
    internal var sortedChildren: [AccessibilityNode] {
        children.sorted(with: environment?.layoutDirection)
    }
    
    internal var contentNodes: [AccessibilityNode] {
        guard let relationshipScope = relationshipScope else {
            return []
        }
        
        return relationshipScope.labeledPairNodes(for: self, role: .content)
    }
    
    internal var isLabel: Bool {
        !contentNodes.isEmpty
    }
    
    internal var isPlatformNode: Bool {
        switch attachment {
        case .properties:
            return false
        case .platform:
            return true
        }
    }
    
    internal var activationPoint: CGPoint? {
        guard let point = properties.activationPoint else {
            return nil
        }
        
        for storage in attachmentsStorage.reversed() {
            guard case let .properties(properties) = storage.attachment else {
                continue
            }
            
            guard let storageActivationPoint = properties.activationPoint else {
                continue
            }
            guard point == storageActivationPoint else {
                continue
            }
            
            if let p = storage.activationPointReference?.activationPoint {
                return p
            }
            
            let origin: CGPoint
            if impliedVisibility == .hidden, let globalFrame = globalFrame {
                origin = globalFrame.origin
            } else if let path = storage.path, let frame = path.standardizedBoundingRect {
                origin = frame.origin
            } else if let frame = storage.globalFrame {
                origin = frame.origin
            } else if let frame = globalFrame {
                origin = frame.origin
            } else {
                return nil
            }
            
            switch point {
            case .point(let point):
                return CGPoint(x: point.x + origin.x, y: point.y + origin.y)
            case .unitPoint(let unitPoint):
                return CGPoint(x: unitPoint.x * origin.x, y: unitPoint.y * origin.y)
            }
            
        }
        
        return nil
        
    }
    
    internal var globalFrame: CGRect? {
        if needsGlobalFrameUpdate {
            updateGlobalFrame()
        }
        needsGlobalFrameUpdate = false
        
        return attachmentsStorage.compactMap {
            $0.globalFrame
        }.last
    }
    
    internal var contentFrame: CGRect? {
        switch impliedVisibility {
        case .element, .hidden:
            if let contentFrameFromPath = contentFrameFromPath {
                return contentFrameFromPath
            }
        default:
            break
        }
        
        if let globalFrame = globalFrame {
            return globalFrame
        }
        
        return contentFrameFromChildren
    }
    
    private var contentFrameFromChildren: CGRect? {
        let childPaths = children.compactMap { child -> Path? in
            if let contentPath = child.contentPath {
                return contentPath
            }
            if let contentFrame = child.contentFrame {
                return Path(contentFrame)
            }
            return nil
        }
        
        var result = Path()
        childPaths.forEach { path in
            result.addPath(path)
        }
        return result.standardizedBoundingRect
    }
    
    internal var environment: EnvironmentValues? {
        attachmentsStorage.compactMap { $0.environment }.last ?? parent?.environment
    }

    internal var impliedVisibility: _AccessibilityVisibility {
        if let parent = parent {
            switch parent.impliedVisibility {
            case .element:
                if !parent.isPlatformNode {
                    return .hidden
                }
            case .hidden:
                return .hidden
            default:
                break
            }
        }
        
        if let visibility = properties.visibility {
            return visibility
        }
        
        if platformElement is HostingScrollView {
            return .container
        }
        
        return .element
    }
    
    internal var enclosingIncrementalLayoutContext: AccessibilityIncrementalLayoutContext? {
        properties.incrementalLayoutContext ?? parent?.enclosingIncrementalLayoutContext
    }
    
    internal var platformExternalProperties: AccessibilityProperties? {
        get {
            guard case let .platform(_, _, externalPlatformProperties) = attachment else {
                return nil
            }
            
            return externalPlatformProperties.properties ?? nil
        }
        
        set {
            guard case let .platform(_, _, externalPlatformProperties) = attachment, let attribute = externalPlatformProperties.$properties else {
                return
            }
            _ = attribute.setValue(newValue)
        }
    }
    
    internal var contentPath: Path? {
        
        #warning("Need To recheck")
        
        if needsUpdatePath {
            updatePath()
            needsUpdatePath = false
        }
        
        guard !attachmentsStorage.isEmpty else {
            return nil
        }
        
        for storage in attachmentsStorage.reversed() {
            
            guard case .properties(let properties) = storage.attachment else {
                continue
            }
            
            switch properties.outline {
            case .defaultFrame, .ignore:
                continue
            default:
                break
            }
        
            guard let path = storage.path, !path.isEmpty else {
                continue
            }
            let boundingRect = path.boundingRect.standardized
            guard !boundingRect.isEmpty else {
                continue
            }
            
            return path
        }
        
        return nil
    }
    
    private var contentFrameFromPath: CGRect? {
        guard let contentPath = contentPath else {
            return nil
        }

        return contentPath.standardizedBoundingRect
    }
    
    internal func hasPath(for token: AccessibilityAttachmentToken?) -> Bool {
        guard let index = attachmentIndex(of: token) else {
            return false
        }
        
        return attachmentsStorage[index].path != nil
    }
    
    @objc
    internal func accessibilityURL() -> URL? {
        properties.linkDestination?.url
    }
    
    internal var platformElement: AnyObject? {
        guard case let .platform(_, object, _) = attachment else {
            return nil
        }
        return object
    }
    
    private func childElements(sorted: Bool) -> [AnyObject] {
        let children = sorted ? sortedChildren : children
        
        return children.map {
            $0.platformElement as? NSObject ?? $0
        }
    }
    
    internal var namedActions: [AccessibilityNamedActionHandler] {
        var names: [Text] = []
        var result: [AccessibilityNamedActionHandler] = []
        
        for storage in attachmentsStorage.reversed() {
            guard case let .properties(properties) = storage.attachment else {
                continue
            }
            for action in properties.actions {
                guard let namedAction = action.namedAction(), !names.contains(namedAction.name) else {
                    continue
                }
                names.append(namedAction.name)
                result.append(namedAction)
            }
            
        }
        
        return result
    }
    
    internal func hasAction<Action: AccessibilityValueAction>(_ action: Action) -> Bool {
        for storage in attachmentsStorage.reversed() {
            guard case let .properties(properties) = storage.attachment else {
                continue
            }
            
            for storageAction in properties.actions where storageAction.matches(action: action) {
                return true
            }
        }
        
        return false
    }
    
    @objc
    internal func _internal_handleCustomAction(uiAction: UIAccessibilityCustomAction) -> Bool {
        sendAction(named: uiAction.name)
    }
    
    internal func sendAction(named: String) -> Bool {
        guard let action = namedActions.first(where: { resolvedPlainText($0.name) == named }) else {
            return false
        }
        
        Update.enqueueAction {
            action.handler()
        }
        return true
    }
    
    @discardableResult
    internal func sendAction<A: AccessibilityValueAction>(_ action: A, value: A.Value) -> Bool {
        for storage in attachmentsStorage {
            guard isEnabled else {
                return false
            }
            
            guard case let .properties(properties) = storage.attachment else {
                continue
            }
            
            for storageAction in properties.actions {
                if storageAction.perform(action: action, value: value) {
                    return true
                }
            }
        }
        
        return false
    }
    
    internal var attachment: AccessibilityAttachment {
        if let cachedCombinedAttachment = cachedCombinedAttachment {
            return cachedCombinedAttachment
        }
        
        let attachments = attachmentsStorage.map { $0.attachment }
        let combinedAttachment = AccessibilityAttachment.combine(attachments)
        cachedCombinedAttachment = combinedAttachment
        updatePlatformProperties(includingRelations: true)
        return combinedAttachment
    }
    
    internal func hasAttachment(token: AccessibilityAttachmentToken?) -> Bool {
        attachmentsStorage.contains { $0.token == token }
    }
    
    internal func attachmentIndex(of token: AccessibilityAttachmentToken?) -> Int? {
        guard let token = token else {
            return attachmentsStorage.count == 0 ? nil : 0
        }

        return attachmentsStorage.firstIndex { $0.token == token }
    }
    
    internal func addAttachment(_ attachment: AccessibilityAttachment, reference: [AccessibilityNode], isInPlatformItemList: Bool, token: AccessibilityAttachmentToken?) {
        let newReference: [AccessibilityNode]
        switch attachment {
        case .properties(let properties):
            if properties.activationPoint != nil {
                newReference = reference
            } else {
                newReference = []
            }
        case .platform:
            newReference = []
        }
        
        let storage = AccessibilityAttachmentStorage(attachment, token: token, reference: newReference)
        attachmentsStorage.append(storage)
        cachedCombinedAttachment = nil
        updateFocus(for: attachment, isInPlatformItemList: isInPlatformItemList)
    }
    
    internal func removeAttachment(isInPlatformItemList: Bool, token: AccessibilityAttachmentToken?) {
        scheduleNotify()
        var hasRemoved = false
        var firstAttachment: AccessibilityAttachment! = nil
        attachmentsStorage.removeAll(where: {
            let shouldRemove = $0.token == token
            if shouldRemove && !hasRemoved {
                hasRemoved = true
                firstAttachment = $0.attachment
            }
            return shouldRemove
        })
        if hasRemoved {
            cachedCombinedAttachment = nil
            updateFocus(for: firstAttachment, isInPlatformItemList: isInPlatformItemList)
        }
    }
    
    internal func removeAttachments(after token: AccessibilityAttachmentToken) {
        
        scheduleNotify()
        guard let index = attachmentIndex(of: token) else {
            return
        }
        
        attachmentsStorage = Array(attachmentsStorage[0..<(2 * index + 1)])
        cachedCombinedAttachment = nil
    }

    internal func needsUpdate(to attachment: AccessibilityAttachment, reference: [AccessibilityNode], token: AccessibilityAttachmentToken?) -> Bool {
        guard let index = attachmentIndex(of: token) else {
            return true
        }
        let storage = attachmentsStorage[index]
        guard storage.attachment == attachment else {
            return true
        }
        
        switch (storage.attachment, attachment) {
        case (.properties(let properties), _):
            if properties.activationPoint == nil {
                fallthrough
            }
        case (_, .properties(let properties)):
            if properties.activationPoint == nil {
                fallthrough
            }
        default:
            return false
        }
        return Set(reference.map { $0.id }) != Set(storage.reference.map { $0.id })
    }
    
    internal func updateAttachment(_ attachment: AccessibilityAttachment, reference: [AccessibilityNode], isInPlatformItemList: Bool, token: AccessibilityAttachmentToken?) {
        guard let index = attachmentIndex(of: token) else {
            return
        }
        
        if shouldNotify(from: attachmentsStorage[index].attachment, to: attachment) {
            scheduleNotify()
        }
        
        attachmentsStorage[index].attachment = attachment
        attachmentsStorage[index].reference = reference
        
        cachedCombinedAttachment = nil
    }
    
    internal func updatePlatformProperties(includingRelations: Bool) {
        for child in children {
            child.updatePlatformProperties(includingRelations: includingRelations)
        }

        if case let .platform(_, object, _) = attachment, let nsObj = object as? NSObject {
            nsObj.accessibilityNodeForPlatformElement = self
            applyProperties(to: nsObj, includingRelations: includingRelations)
        }
    }
    
    private func updateFocus(for attachment: AccessibilityAttachment, isInPlatformItemList: Bool) {
        guard viewRendererHost != nil, attachment.properties?.focusableDescendantNode != nil else {
            return
        }
        
        properties.focusableDescendantNode?.focusableAncestor = self
    }
    
    private func updateGlobalFrame() {
        for index in attachmentsStorage.indices {
            updateGlobalFrame(at: index)
        }
    }
    
    private func updateGlobalFrame(at index: Int) {
        
        func closure1(_ storage: AccessibilityAttachmentStorage) -> Bool {
            guard case let .properties(properties) = storage.attachment,
                    case .ignore = properties.outline else {
                return true
            }
            return false
        }
        
        let storage = attachmentsStorage[index]
        let shouldIgnore = closure1(storage)
        guard shouldIgnore else {
            return
        }
        
        guard let size = storage.size, let transform = storage.transform else {
            return
        }
        
        attachmentsStorage[index].globalFrame = CGRect(origin: .zero, size: size)
        attachmentsStorage[index].globalFrame?.convert(to: .global, transform: transform)
    }
    
    private func updatePath() {
        for index in attachmentsStorage.indices {
            updatePath(at: index)
        }
    }
    
    private func updatePath(at index: Int) {
        #warning("Need to recheck")
        let storage = attachmentsStorage[index]
        
        guard let viewResponders = Update.ensure({ storage.viewResponders.value }) else {
            return
        }
        
        var combinedPath: Path = Path()
        
        for responder in viewResponders {
            
            var responderPath = Path()
            responder.addContentPath(to: &responderPath, in: .global, observer: self)
            
            if !responderPath.isEmpty {
                   
                let rect = responderPath.boundingRect.standardized
                
                if !rect.isEmpty {
                    combinedPath.union(path: responderPath)
                } else {
                    continue
                }

            } else {
                
            }
        }
        
        let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
        var newPath = Path()
        newPath.addPath(combinedPath, transform: transform)
        
        attachmentsStorage[index].path = newPath

    }
    
    internal func updateEnvironment(_ values: EnvironmentValues, token: AccessibilityAttachmentToken?) {
        guard let index = attachmentIndex(of: token) else {
            return
        }
        if index == 0 {
            isEnabled = values.isEnabled
        }
        attachmentsStorage[index].environment = values
    }
    
    internal func updateSize(_ size: CGSize, token: AccessibilityAttachmentToken?) {
        guard let index = attachmentIndex(of: token) else {
            return
        }
        attachmentsStorage[index].size = size
        needsGlobalFrameUpdate = true
    }
    
    internal func updateTransform(_ viewTransform: ViewTransform, token: AccessibilityAttachmentToken?) {
        guard let index = attachmentIndex(of: token) else {
            return
        }
        attachmentsStorage[index].transform = viewTransform
        needsGlobalFrameUpdate = true
    }
    
    internal func updateViewResponders(_ responders: WeakAttribute<[ViewResponder]>, token: AccessibilityAttachmentToken?) {
        guard let index = attachmentIndex(of: token) else {
            return
        }
        attachmentsStorage[index].viewResponders = responders
    }

    internal var resolvedPlainTextLabel: String? {
        resolvedPlainText(properties.label)
    }
    
    internal var resolvedAttributedLabel: NSAttributedString? {
        resolvedAttributedText(properties.label)
    }
    
    internal var resolvedPlainTextHint: String? {
        resolvedPlainText(properties.hint)
    }
    
    internal var resolvedAttributedHint: NSAttributedString? {
        resolvedAttributedText(properties.hint)
    }
    
    internal var resolvedPlainTextValue: String? {
        resolvedAttributedValue?.string
    }
    
    internal var resolvedAttributedValue: NSAttributedString? {
        guard let typeValue = properties.typedValue, let environment = environment else {
            return nil
        }

        return typeValue.description?.resolveString(in: environment, includeDefaultAttributes: true, options: .zero)
    }
    
    internal func resolvedPlainText(_ text: Text?) -> String? {
        guard let text = text, let environment = environment else {
            return nil
        }
        
        switch text.storage {
        case .verbatim(let string):
            return string
        case .anyTextStorage:
            return text.resolveString(in: environment, includeDefaultAttributes: false, options: .showLabel)?.string
        }
    }
    
    internal func resolvedAttributedText(_ text: Text?) -> NSAttributedString? {
        guard let text = text, let environment = environment else {
            return nil
        }
        
        return text.resolveString(in: environment, includeDefaultAttributes: false, options: .showLabel)
    }
    
    private func applyAction<Action: AccessibilityValueAction>(_ action: Action, value: Action.Value, key: UInt32, to target: NSObject) {
        guard hasAction(action) else {
            return
        }
        
        target.danceUI_accessibilitySetActionBlock({ _ -> Bool in
            self.sendAction(action, value: value)
        }, withValue: nil, forKey: key)
    }
    
    private func applyCustomActions(to target: NSObject) {
        var selfCustomActions = accessibilityCustomActions ?? []
        
        let targetCustomActions = target.accessibilityCustomActions ?? []
        
        for targetAction in targetCustomActions {
            guard !selfCustomActions.contains(targetAction) else {
                continue
            }
            selfCustomActions.append(targetAction)
        }
        
        target.accessibilityCustomActions = selfCustomActions
    }
    
    internal func applyExternalProperties(to target: AnyObject) {
        let properties: AccessibilityProperties
        switch attachment {
        case .properties(let p):
            properties = p
        case .platform:
            properties = self.properties
        }
        guard let target = target as? NSObject, let element = target.accessibilityNodeForPlatformElement else {
            return
        }
        Update.enqueueAction {
            element.platformExternalProperties = properties
        }
    }
    
    internal func applyProperties(to target: AnyObject, includingRelations: Bool) {
        
        let properties: AccessibilityProperties
        switch attachment {
        case .properties:
            properties = self.properties
        case .platform(let p, _, _):
            properties = p ?? AccessibilityProperties()
        }
        
        guard let target = target as? NSObject else {
            return
        }
        applyProperties(properties, to: target)

        applyAction(
            AccessibilityVoidAction(kind: .default),
            value: (),
            key: AXActivateAction,
            to: target
        )
        applyAction(
            AccessibilityVoidAction(kind: .escape),
            value: (),
            key: AXEscapeAction,
            to: target
        )
        applyAction(
            AccessibilityVoidAction(kind: .magicTap),
            value: (),
            key: AXMagicTapAction,
            to: target
        )
        applyAction(
            AccessibilityAdjustableAction(),
            value: .increment,
            key: AXIncrementAction,
            to: target
        )
        applyAction(
            AccessibilityAdjustableAction(),
            value: .decrement,
            key: AXDecrementAction,
            to: target
        )
        
        applyCustomActions(to: target)
        
        if let hostingView = target as? HostingScrollView {
            hostingView.applyAccessibilityElements()
        }
        
        if includingRelations {
            applyRelations(to: target)
        }
    }
    
    private func applyProperties(_ properties: AccessibilityProperties, to target: NSObject) {
        let visibility = properties.visibility
        let isAccessibilityElement = self.isAccessibilityElement
        let accessibilityElementsHidden = self.accessibilityElementsHidden
        
        if target.respondsToSetIsAccessibilityElementBlock() {
            let block = visibility == nil ? nil : { isAccessibilityElement }
            target.danceUI_setIsAccessibilityElementBlock(block)
        } else {
            if visibility != nil {
                target.isAccessibilityElement = isAccessibilityElement
            }
        }
        
        if target.respondsToSetAccessibilityElementsHiddenBlock() {
            let block = visibility == nil ? nil : { accessibilityElementsHidden }
            target.danceUI_setAccessibilityElementsHiddenBlock(block)
        } else {
            if visibility != nil {
                target.accessibilityElementsHidden = accessibilityElementsHidden
            }
        }
        
        if let modal = properties.traits[.modal] {
            target.accessibilityViewIsModal = modal
        }
        
        if let label = accessibilityLabel {
            target.accessibilityLabel = label
        }
    
        if let value = accessibilityValue {
            target.accessibilityValue = value
        }
        
        if let hint = accessibilityHint {
            target.accessibilityHint = hint
        }
        
        if let language = accessibilityLanguage {
            target.accessibilityLanguage = language
        }
        
        if let point = activationPoint {
            target.accessibilityActivationPoint = point
        }
        
        if let identifier = accessibilityIdentifier {
            target.accessibilityIdentifier = identifier
        }
        
        target.accessibilityTraits = accessibilityTraits
    }
    
    private func applyRelations(to target: NSObject) {
        guard let userDefinedLinkedUIElements = danceUI_accessibilityUserDefinedLinkedUIElements else {
            return
        }
        
        guard target.respondsToSetAccessibilityLinkedUIElementsBlock() else {
            return
        }
        
        target.danceUI_setAccessibilityLinkedUIElementsBlock {
            userDefinedLinkedUIElements
        }
    }
    
    internal func shouldNotify(from fromAttachment: AccessibilityAttachment, to toAttachment: AccessibilityAttachment) -> Bool {
        guard !notifications(from: fromAttachment, to: toAttachment).isEmpty else {
            return true
        }
        
        return fromAttachment.properties?.visibility != toAttachment.properties?.visibility
    }
    
    internal func notifications(from fromAttachment: AccessibilityAttachment, to toAttachment: AccessibilityAttachment) -> [AccessibilityElementNotification.Type] {
        if case let .properties(fromProperties) = fromAttachment, case let .properties(toProperties) = toAttachment {
            return notifications(from: fromProperties, to: toProperties)
        }
        return []
    }
    
    internal func notifications(from fromProperties: AccessibilityProperties, to toProperties: AccessibilityProperties) -> [AccessibilityElementNotification.Type] {
        
        var result: [AccessibilityElementNotification.Type] = []
        
        if fromProperties.typedValue != toProperties.typedValue {
            result.append(Accessibility.Notification.ValueChanged.self)
        }
        
        if fromProperties.label != toProperties.label {
            result.append(Accessibility.Notification.LabelChanged.self)
        }
        
        return result
    }
    
    private func notify(from fromAttachment: AccessibilityAttachment, to toAttachment: AccessibilityAttachment) {
        for notification in notifications(from: fromAttachment, to: toAttachment) {
            notification.init(element: self).post()
        }
        
        if fromAttachment.properties?.visibility != toAttachment.properties?.visibility {
            Accessibility.Notification.LayoutChanged().post()
        }
    }
    
    private func notifyIfNeeded() {
        guard let oldAttachmentForNotification = oldAttachmentForNotification else {
            return
        }
        
        let current = attachment
        if shouldNotify(from: oldAttachmentForNotification, to: current) {
            notify(from: oldAttachmentForNotification, to: current)
        }
        self.oldAttachmentForNotification = nil
    }
    
    private func scheduleNotify() {
        guard oldAttachmentForNotification == nil else {
            return
        }
        self.oldAttachmentForNotification = attachment
        DispatchQueue.main.async { [weak self] in
            self?.notifyIfNeeded()
        }
    }
    
    internal var enclosingHostingScrollView: HostingScrollView? {
        ancestorHostingScrollView(allowingSelf: false)
    }
    
    internal func ancestorHostingScrollView(allowingSelf: Bool) -> HostingScrollView? {
        if allowingSelf, let scrollView = platformElement as? HostingScrollView {
            return scrollView
        }
        return parent?.ancestorHostingScrollView(allowingSelf: true)
    }
    
    private var scrollToVisibleAnchor: UnitPoint {
        guard let scrollView = enclosingHostingScrollView,
                let context = enclosingIncrementalLayoutContext else {
                    return .center
        }
        
        let scrollViewFrame = scrollView.platformAccessibilityFrame
        let selfFrame = platformAccessibilityFrame
        
        let axes = context.axes
        
        if selfFrame.maxY < scrollViewFrame.maxY && axes.contains(.vertical) {
            return .bottom
        }

        if scrollViewFrame.minY < selfFrame.minY && axes.contains(.vertical) {
            return .top
        }
        
        if selfFrame.minX < selfFrame.minX && axes.contains(.horizontal) {
            return .leading
        }
        
        if scrollViewFrame.maxX < selfFrame.maxX && axes.contains(.horizontal) {
            return .trailing
        }
        
        return .center
    }
    
    internal func scrollToVisible() -> Bool {
        guard let context = enclosingIncrementalLayoutContext,
                let scrollView = enclosingHostingScrollView else {
            return false
        }
        
        let scrollViewFrame = scrollView.platformAccessibilityFrame
        let selfFrame = platformAccessibilityFrame
        
        if selfFrame.onTheOutside(of: scrollViewFrame, axis: context.axes) {
            _ = context.scrollableCollection.scroll(
                toCollectionViewID: context.collectionViewID,
                anchor: scrollToVisibleAnchor
            )
            if let viewRendererHost = viewRendererHost {
                viewRendererHost.render()
            }
            return true
        }
        
        return false
    }
    
    internal func contentPathDidChange() {
        for index in attachmentsStorage.indices {
            attachmentsStorage[index].path = nil
        }
            
        needsUpdatePath = true
        Accessibility.Notification.Info(argument: nil).post(name: .layoutChanged)
    }
    
    internal override var description: String {
        let des: String
        switch attachment {
        case .properties:
            des = resolvedPlainTextLabel ?? ""
        case .platform(_, let target, _):
            des = "\(target)"
        }
        return "\(super.description) \(des)"
    }
    
}

@available(iOS 13.0, *)
extension AccessibilityNode {
    
    internal override var isAccessibilityElement: Bool {
        get {
            impliedVisibility == .element
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityLabel: String? {
        get {
            resolvedPlainTextLabel
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    @available(tvOS 11.0, *)
    internal override var accessibilityAttributedLabel: NSAttributedString? {
        get {
            resolvedAttributedLabel
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityHint: String? {
        get {
            resolvedPlainTextHint
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    @available(tvOS 11.0, *)
    internal override var accessibilityAttributedHint: NSAttributedString? {
        get {
            resolvedAttributedHint
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityValue: String? {
        get {
            if let resolvedPlainTextValue = resolvedPlainTextValue {
                return resolvedPlainTextValue
            }
            
            guard let typeValue = properties.typedValue else {
                return nil
            }
            
            return typeValue.platformValue
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    @available(tvOS 11.0, *)
    internal override var accessibilityAttributedValue: NSAttributedString? {
        get {
            resolvedAttributedValue
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityTraits: UIAccessibilityTraits {
        get {
            func accessibilityTraits(for traits: UIAccessibilityTraits) -> UIAccessibilityTraits {
                
                var result = traits
                
                func update(if contains: Bool?, _ traitsElement: UIAccessibilityTraits) {
                    if let contains = contains {
                        if contains {
                            result.insert(traitsElement)
                        }
                    } else {
                        if traits.contains(traitsElement) {
                            result.insert(traitsElement)
                        }
                    }
                }
                
                let traitsStorage = properties.traits
                update(if: traitsStorage[.button], .button)
                
                update(if: traitsStorage[.link], .link)
                update(if: traitsStorage[.searchField], .searchField)
                update(if: traitsStorage[.image], .image)
                
                update(if: traitsStorage[.selected], .selected)
                
                update(if: traitsStorage[.playsSound], .playsSound)
                update(if: traitsStorage[.keyboardKey], .keyboardKey)
                update(if: traitsStorage[.staticText], .staticText)
                update(if: traitsStorage[.summaryElement], .summaryElement)
                update(if: traitsStorage[.updatesFrequently], .updatesFrequently)
                update(if: traitsStorage[.startsMediaSession], .startsMediaSession)
                update(if: traitsStorage[.allowsDirectInteraction], .allowsDirectInteraction)
                update(if: traitsStorage[.causesPageTurn], .causesPageTurn)
                
                update(if: traitsStorage[.header], .header)

                if hasAction(AccessibilityAdjustableAction()) {
                    result.insert(.adjustable)
                }
                
                if !isEnabled {
                    result.insert(.notEnabled)
                }
                update(if: traitsStorage[.toggle], AXToggleTrait)

                return result
            }
            let traits: UIAccessibilityTraits
            
            switch attachment {
            case .properties:
                traits = .none
            case .platform(_, let object, _):
                traits = (object as! NSObject).accessibilityTraits
            }
            return accessibilityTraits(for: traits)
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityFrame: CGRect {
        get {
            contentFrame ?? super.accessibilityFrame
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityPath: UIBezierPath? {
        get {
            func shouldUseContentPath(_ path: Path) -> Bool {
                if case .path = path.storage {
                    return false
                }
                
                var count = 0
                var lastElement: Path.Element? = nil
                path.forEach { element in
                    defer {
                        lastElement = element
                    }
                
                    if case .move = lastElement {
                        return
                    }
                    count += 1
                }
                return count == 1
            }
            
            guard let contentPath = contentPath, !contentPath.isEmpty else {
                return nil
            }
            
            guard shouldUseContentPath(contentPath) else {
                return nil
            }
            return UIBezierPath(cgPath: contentPath.cgPath)
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityActivationPoint: CGPoint {
        get {
            activationPoint ?? super.accessibilityActivationPoint
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityLanguage: String? {
        get {
            environment?.locale.identifier
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityElementsHidden: Bool {
        get {
            impliedVisibility == .hidden
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityViewIsModal: Bool {
        get {
            properties.traits[.modal] ?? super.accessibilityViewIsModal
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var shouldGroupAccessibilityChildren: Bool {
        get {
            switch impliedVisibility {
            case .element, .containerElement:
                return true
            case .container, .hidden:
                return false
            }
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    internal override var accessibilityUserInputLabels: [String]? {
        get {
            properties.inputLabels.map {
                resolvedPlainText($0)!
            }
        }
        set {
            _intentionallyLeftBlank()
        }
    }

    @available(iOS 13.0, tvOS 13.0, *)
    internal override var accessibilityAttributedUserInputLabels: [NSAttributedString]? {
        get {
            properties.inputLabels.map {
                resolvedAttributedText($0)!
            }
        }
        set {
            _intentionallyLeftBlank()
        }
    }
     
    internal override func accessibilityElementDidBecomeFocused() {
        _intentionallyLeftBlank()
    }
    
    internal override func accessibilityElementDidLoseFocus() {
        _intentionallyLeftBlank()
    }
    
    internal override func accessibilityActivate() -> Bool {
        sendAction(AccessibilityVoidAction(kind: .default), value: Void())
    }

    internal override func accessibilityIncrement() {
        sendAction(AccessibilityAdjustableAction(), value: .increment)
    }
    
    internal override func accessibilityDecrement() {
        sendAction(AccessibilityAdjustableAction(), value: .decrement)
    }

    internal override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        guard sendAction(AccessibilityScrollAction(), value: Edge(direction)) else {
            return super.accessibilityScroll(direction)
        }
        return true
    }

    internal override func accessibilityPerformEscape() -> Bool {
        guard sendAction(AccessibilityVoidAction(kind: .escape), value: ()) else {
            return super.accessibilityPerformEscape()
        }
        return true
    }
    
    @available(macOS, unavailable)
    internal override func accessibilityPerformMagicTap() -> Bool {
        guard sendAction(AccessibilityVoidAction(kind: .magicTap), value: ()) else {
            return super.accessibilityPerformEscape()
        }
        return true
    }
    
    internal override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            namedActions.compactMap {
                guard let text = resolvedPlainText($0.name) else {
                    return nil
                }
                return UIAccessibilityCustomAction(self, text)
            }
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override var accessibilityElements: [Any]? {
        get {
            switch impliedVisibility {
            case .containerElement, .container:
                return childElements(sorted: true)
            default:
                return nil
            }
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    @available(tvOS 11.0, *)
    internal override var accessibilityContainerType: UIAccessibilityContainerType {
        get {
            if properties.dataSeriesConfiguration != nil {
                return UIAccessibilityContainerType(rawValue: 0xd)!
            }
            
            switch impliedVisibility {
            case .element, .hidden:
                return super.accessibilityContainerType
            case .container, .containerElement:
                if #available(iOS 13, *) {
                    return .semanticGroup
                } else {
                    return .list
                }
            }
        }
        set {
            _intentionallyLeftBlank()
        }
    }
    
    internal override func accessibilityElementCount() -> Int {
        
        guard impliedVisibility != .hidden else {
            return super.accessibilityElementCount()
        }
        
        let count = children.count
        return count > 0 ? count : super.accessibilityElementCount()
    }

    internal override var accessibilityIdentifier: String? {
        get {
            properties.identifier
        }
        set {
            _intentionallyLeftBlank()
        }
    }
}

@available(iOS 13.0, *)

extension AccessibilityNode {
    
    internal override func danceUI_accessibilityMaxValue() -> CGFloat {
        properties.typedValue?.platformMaxValue?.doubleValue ?? .nan
    }

    internal override func danceUI_accessibilityMinValue() -> CGFloat {
        properties.typedValue?.platformMinValue?.doubleValue ?? .nan
    }

    internal override var danceUI_accessibilityUserDefinedLinkedUIElements: [Any]? {
        guard let relationshipScope = relationshipScope else {
            return nil
        }

        let linkedNodes = relationshipScope.linkedNodes(for: self)
        let elements = relationshipScope.elements(for: linkedNodes)

        return elements.isEmpty ? nil : elements
    }
    
    internal override func danceUI_accessibilityScrollToVisible() -> Bool {
        scrollToVisible() ? true : super.danceUI_accessibilityScrollToVisible()
    }
    
    internal override func danceUI_accessibilityRoleDescription() -> String? {
        if let roleDescription = properties.roleDescription,
           let text = resolvedPlainText(roleDescription) {
            return text
        }
        return (platformElement as? NSObject)?.danceUI_accessibilityRoleDescription() ?? super.danceUI_accessibilityRoleDescription()
    }

}

@available(iOS 13.0, *)
fileprivate let AXActivateAction: UInt32 = 0x7da
@available(iOS 13.0, *)
fileprivate let AXIncrementAction: UInt32 = 0x7d4
@available(iOS 13.0, *)
fileprivate let AXDecrementAction: UInt32 = 0x7d5
@available(iOS 13.0, *)
fileprivate let AXMagicTapAction: UInt32 = 0x7db
@available(iOS 13.0, *)
fileprivate let AXEscapeAction: UInt32 = 0x7dd
@available(iOS 13.0, *)
fileprivate let AXToggleTrait = UIAccessibilityTraits(rawValue: 0x0020000000000000) 

@available(iOS 13.0, *)
fileprivate struct AccessibilityAttachmentStorage {
    
    fileprivate var environment: EnvironmentValues?
    
    fileprivate var transform: ViewTransform?
    
    fileprivate var size: CGSize?
    
    fileprivate var globalFrame: CGRect?
    
    fileprivate var attachment: AccessibilityAttachment
    
    fileprivate var weakReference: [WeakBox<AccessibilityNode>]
    
    fileprivate var viewResponders: WeakAttribute<[ViewResponder]>
    
    fileprivate var path: Path?
    
    fileprivate let token: AccessibilityAttachmentToken?
    
    fileprivate init(_ attachment: AccessibilityAttachment, token: AccessibilityAttachmentToken?, reference: [AccessibilityNode]) {
        self.environment = nil
        self.transform = nil
        self.size = nil
        self.globalFrame = nil
        self.attachment = attachment
        self.weakReference = reference.map { WeakBox(base: $0) }
        self.viewResponders = WeakAttribute(nil)
        self.path = nil
        self.token = token
    }
    
    internal var reference: [AccessibilityNode] {
        get {
            weakReference.compactMap { $0.base }
        }
        set {
            weakReference = newValue.map { WeakBox(base: $0) }
        }
    }
    
    fileprivate var activationPointReference: AccessibilityNode? {
        reference.first { $0.activationPoint != nil }
    }
    
}

#if BINARY_COMPATIBLE_TEST || DEBUG
@available(iOS 13.0, *)
internal struct Fileprivate_AccessibilityAttachmentStorage {
    
    fileprivate var storage: AccessibilityAttachmentStorage
    
    internal init(_ attachment: AccessibilityAttachment, token: AccessibilityAttachmentToken?, reference: [AccessibilityNode]) {
        self.storage = AccessibilityAttachmentStorage(attachment, token: token, reference: reference)
    }
    
    internal var reference: [AccessibilityNode] {
        get {
            storage.reference
        }
        set {
            storage.reference = newValue
        }
    }
    
}

#endif
@available(iOS 13.0, *)
extension Array where Element == AccessibilityNode {
    
    internal func sorted(with direction: LayoutDirection?) -> [AccessibilityNode] {
        sorted(stable: true) { lhs, rhs in
            let lhsSortPriority = lhs.attachment.properties?.sortPriority
            let rhsSortPriority = rhs.attachment.properties?.sortPriority
            
            guard lhsSortPriority == rhsSortPriority else {
                return (lhsSortPriority ?? 0) > (rhsSortPriority ?? 0)
            }
            
            guard let lhsFrame = lhs.contentFrame,
                    let rhsFrame = rhs.contentFrame else {
                return false
            }
            
            let lhsMinY = lhsFrame.minY
            let lhsMaxY = lhsFrame.maxY
            
            let rhsMinY = rhsFrame.minY
            let rhsMaxY = rhsFrame.maxY
            
            let lhsMidY = lhsFrame.midY
    
            if lhsMidY <= rhsMinY || rhsMaxY <= lhsMidY {
                let rhsMidY = rhsFrame.midY
                if rhsMidY <= lhsMinY || lhsMaxY <= rhsMidY {
                    if rhsMinY > lhsMinY {
                        return true
                    } else if lhsMinY > rhsMinY {
                        return false
                    } else if rhsMaxY > lhsMaxY {
                        return true
                    } else if lhsMaxY > rhsMaxY {
                        return false
                    } else {
                        return false
                    }
                }
            }
            
            guard let direction = direction else {
                return false
            }
            
            let lhsMinX = lhsFrame.minX
            let rhsMinX = rhsFrame.minX
            
            let lhsMaxX = lhsFrame.maxX
            let rhsMaxX = rhsFrame.maxX
            
            if lhsMinX <= rhsMinX || lhsMaxX <= rhsMaxX {
                if rhsMinX <= lhsMinX || rhsMaxX <= lhsMaxX {
                    if lhsFrame.midX == rhsFrame.midX && lhsFrame.midY == rhsFrame.midY {
                        return false
                    }
                    
                    if rhsMinY > lhsMinY {
                        return true
                    } else if lhsMinY > rhsMinY {
                        return false
                    } else if rhsMaxY > lhsMaxY {
                        return true
                    } else if lhsMaxY > rhsMaxY {
                        return false
                    } else {
                        return false
                    }
                    
                } else {
                    switch direction {
                    case .leftToRight:
                        return true
                    case .rightToLeft:
                        return false
                    }
                }
            } else {
                switch direction {
                case .leftToRight:
                    return false
                case .rightToLeft:
                    return true
                }
            }
            
        }
    }
    
}

@available(iOS 13.0, *)
extension Path {
    
#if BINARY_COMPATIBLE_TEST
    internal var fileprivate_standardizedBoundingRect: CGRect? {
        standardizedBoundingRect
    }
#endif
    
    fileprivate var standardizedBoundingRect: CGRect? {
        guard !isEmpty else {
            return nil
        }
        
        let standardRect = boundingRect.standardized
        
        return standardRect.isEmpty ? nil : standardRect
    }
    
}

@available(iOS 13.0, *)
extension UIAccessibilityCustomAction {
    
    convenience init(_ node: AccessibilityNode, _ text: String) {
        self.init(
            name: text,
            target: node,
            selector: #selector(AccessibilityNode._internal_handleCustomAction(uiAction:))
        )
    }

}
