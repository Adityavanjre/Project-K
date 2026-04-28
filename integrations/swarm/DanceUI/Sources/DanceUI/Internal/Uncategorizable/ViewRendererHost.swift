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
internal protocol ViewRendererHost: ViewGraphDelegate {

    var viewGraph: ViewGraph { get }

    var eventBindingManager: EventBindingManager { get }

    var currentTimestamp: Time { get set }

    var propertiesNeedingUpdate: ViewRendererHostProperties { get set }

    func addImplicitPropertiesNeedingUpdate(to: inout ViewRendererHostProperties)

    /// Indicates that the view renderer host is rendering
    var isRendering: Bool { get set }

    var externalUpdateCount: Int { get set }

    var accessibilityVersion: DisplayList.Version { get set }

    func updateRootView()

    func updateEnvironment()

    func updateFocusedItem()

    func updateFocusedValues()

    func updateTransform()

    func updateSize()

    func updateSafeArea()

    func updateFocusStore()

    func updateGestureObservers()

    func requestUpdate(after: Double)

    func renderDisplayList(_ displayList: DisplayList,
                           asynchronously: Bool,
                           time: Time,
                           nextTime: Time,
                           version: DisplayList.Version,
                           maxVersion: DisplayList.Version) -> Time

    func didRender()

    func focusResponder(for: FocusItem) -> FocusResponder?

    func focus(item: FocusItem)

    var focusedItem: FocusItem? { get }

    var focusedValues: FocusedValues { get set }

    var focusedResponder: ResponderNode? { get }

    var uiViewController: UIViewController? { get }

}

@available(iOS 13.0, *)
extension ViewRendererHost where Self: PlatformAccessibilityElement {
    
    
}

@available(iOS 13.0, *)
extension ViewRendererHost {
    
    internal func initializeViewGraph() {
        viewGraph.delegate = self
    }
    
    // iOS 15.2 addition
    internal var isRootHost: Bool {
        viewGraph.parentHost == nil
    }
    
    /// Perform the `body` closure with an ensured predecessing `updateGraph`
    /// invocation.
    ///
    internal func updateViewGraph<R>(body: (ViewGraph) -> R) -> R {
#if DEBUG
        _danceuiPrecondition(!viewGraph.frozen)
#endif
        return Update.perform {
            DGGraphRef.withoutUpdate {
                updateGraph()
                return body(viewGraph)
            }
        }
    }
    
    internal func invalidate() {
        viewGraph.delegate = nil
    }
    
    internal func sendEvents(_ events: [EventID : any EventType], rootNode: ResponderNode, at time: Time) -> EventOutputs {
        updateViewGraph { viewGraph in
            viewGraph.sendEvents(events, rootNode: rootNode, at: time)
        }
    }
    
    internal func sendEvents(_ events: [EventID : EventType]) {
        eventBindingManager.send(events)
    }
    
    internal func renderAsync(interval: Double) -> Time? {
        guard !isRendering else {
            return nil
        }
        
        let properties = self.propertiesNeedingUpdate
        
        var additionProperties = ViewRendererHostProperties()
        self.addImplicitPropertiesNeedingUpdate(to: &additionProperties)
        
        guard !properties.isEmpty,
              !viewGraph.hasPendingTransactions else {
            return nil
        }
        
        return Update.perform {
            self.currentTimestamp.advancing(by: interval)
            let updateTime = self.currentTimestamp
            self.isRendering = true
            let result = viewGraph.updateOutputsAsync(at: updateTime)
            let renderedTime: Time?
            if let (list, version) = result {
                renderedTime = self.renderDisplayList(list,
                                                asynchronously: true,
                                                time: updateTime,
                                                nextTime: viewGraph.nextUpdate.views.time,
                                                version: version,
                                                maxVersion: .make())
            } else {
                renderedTime = nil
            }
            self.isRendering = false
            return renderedTime
        }
    }
    
    internal func resetEvents() {
        if DanceUIFeature.gestureContainer.isEnable {
            viewGraph.resetEvents()
        } else {
            eventBindingManager.reset()
        }
    }
    
#if DEBUG
    internal func resetTestEvents() {
        eventBindingManager.reset()
    }
#endif
    
    internal func updateGraph() {
        Update.syncMain {
            #if DEBUG
            defer {
                viewRendererHostUpdateGraphCount += 1
            }
            #endif
            
            var propertiesNeedingUpdate = self.propertiesNeedingUpdate
            self.addImplicitPropertiesNeedingUpdate(to: &propertiesNeedingUpdate)
            guard !self.propertiesNeedingUpdate.isEmpty else {
                return
            }
            
            if propertiesNeedingUpdate.contains(.rootView) {
                self.propertiesNeedingUpdate.remove(.rootView)
                updateRootView()
            }
            
            if propertiesNeedingUpdate.contains(.environment) {
                self.propertiesNeedingUpdate.remove(.environment)
                updateEnvironment()
            }
            
            if propertiesNeedingUpdate.contains(.focusedValues) {
                self.propertiesNeedingUpdate.remove(.focusedValues)
                updateFocusedValues()
            }
            
            if propertiesNeedingUpdate.contains(.transform) {
                self.propertiesNeedingUpdate.remove(.transform)
                updateTransform()
            }
            
            if propertiesNeedingUpdate.contains(.size) {
                self.propertiesNeedingUpdate.remove(.size)
                updateSize()
            }
            
            if propertiesNeedingUpdate.contains(.safeArea) {
                self.propertiesNeedingUpdate.remove(.safeArea)
                updateSafeArea()
            }
            
            if propertiesNeedingUpdate.contains(.focusStore) {
                self.propertiesNeedingUpdate.remove(.focusStore)
                updateFocusStore()
            }
            
            if propertiesNeedingUpdate.contains(.accessibilityFocusStore) {
                self.propertiesNeedingUpdate.remove(.accessibilityFocusStore)
                // update something
                // updateAccessibilityFocusStore()
            }
            
            if propertiesNeedingUpdate.contains(.focusedItem) {
                self.propertiesNeedingUpdate.remove(.focusedItem)
                updateFocusedItem()
            }
            
            if propertiesNeedingUpdate.contains(.accessibilityFocus) {
                self.propertiesNeedingUpdate.remove(.accessibilityFocus)
                // update something
                // updateAccessibilityFocus()
            }
            
            if propertiesNeedingUpdate.contains(.gestureObservers) {
                self.propertiesNeedingUpdate.remove(.gestureObservers)
                updateGestureObservers()
            }
        }
    }
    
    fileprivate var enclosingHost: [ViewRendererHost] {
        guard let preferenceBridge = viewGraph.preferenceBridge,
              let viewRendererHost = preferenceBridge.viewGraph as? ViewRendererHost else {
            return [self]
        }
        
        return viewRendererHost.enclosingHost + [self]
    }
    
    internal func graphDidChange() {
        Update.withLock {
            guard !isRendering else {
                return
            }
            requestUpdate(after: 0)
        }
    }
    
    // Removed from test coverage statistic for single line forwarding and
    // difficulties in building test cases.
    internal func updateTransform() {
        viewGraph.invalidateTransform()
    }
    
    internal var platformItemList: PlatformItemList {
        updateViewGraph { viewGraph in
            viewGraph.platformItemList()
        }
    }
    
#if DEBUG || DANCE_UI_INHOUSE
    internal func advanceTimeForTest(interval: Double) {
        assert(interval >= 0)
        let timestamp = self.currentTimestamp
        let time = timestamp.advanced(by: interval)
        guard time == timestamp else {
            self.currentTimestamp = time
            return
        }
        let newTimestamp = nextafter(timestamp.seconds, .infinity).toTime()
        self.currentTimestamp = newTimestamp
    }
#endif

    internal func invalidateProperties(_ properties: ViewRendererHostProperties, mayDeferUpdate: Bool = true ) {
        Update.withLock {
            guard !propertiesNeedingUpdate.contains(properties) else {
                return
            }
            
            propertiesNeedingUpdate.insert(properties)
            viewGraph.setNeedsUpdate(mayDeferUpdate: mayDeferUpdate)
            requestUpdate(after: 0)
        }
    }
    
    internal func performExternalUpdate(_ body: () -> Void) {
        let enclosingHost = enclosingHost
        
        for host in enclosingHost {
            host.externalUpdateCount += 1
        }
        
        body()
        
        for host in enclosingHost {
            host.externalUpdateCount -= 1
            assert(host.externalUpdateCount >= 0)
        }
    }
    
    internal func render(interval: Double = 0, updateDisplayList: Bool = true) {
        // Let's put the `{` at the next line of `Update.perform`. Then the
        // breakpoint set at either the line of `Update.perform` or `{` hits
        // only once.
        Update.perform
        {
            guard !isRendering else {
                return
            }
            
            // Signpost.renderUpdate
            
            { () -> Void in // closure #1
                
                currentTimestamp.advancing(by: interval)
                let nextUpdateTime = currentTimestamp
                
                viewGraph.flushTransactions()
                
                self.isRendering = true
                
                var displayList: DisplayList = .empty
                var version: DisplayList.Version = .zero
                
                var convergenceCount = 0
                
                repeat {
                    if Update.isInRoot {
                        Update.dispatchActions()
                    }
                    
                    viewGraph.updateOutput(at: nextUpdateTime)
                    
                    Update.dispatchActions()
                    viewGraph.flushTransactions()
                    
                    convergenceCount += 1
                    
                    if updateDisplayList {
                        (displayList, version) = viewGraph.displayList()
                    }
                    
                    if !Update.isInRoot || !Update.hasActions {
                        if !viewGraph.data.globalSubgraph.isDirty(0x1) {
                            break
                        }
                    }
                    
                } while convergenceCount < 2
                
                var time: Time = viewGraph.nextUpdate.views.time
                
                if updateDisplayList {
                    time = renderDisplayList(displayList,
                                             asynchronously: false,
                                             time: currentTimestamp,
                                             nextTime: time,
                                             version: version,
                                             maxVersion: .make())
                }
                
                self.isRendering = false
                
                if time != .distantFuture {
                    var delay = currentTimestamp
                    delay = max(delay, time) - delay
                    delay = max(delay, .microseconds(1))
                    self.requestUpdate(after: delay.seconds)
                }
                
            }()
        }
    }
    
    internal static func makeRootView<ViewType: View>(view: ViewType) -> ModifiedContent<ViewType, HitTestBindingModifier> {
        view.modifier(HitTestBindingModifier())
    }
    
}

@available(iOS 13.0, *)
@objc
protocol PlatformAccessibilityElement: NSObjectProtocol {
    
}

#if DEBUG
internal var viewRendererHostUpdateGraphCount = 0
#endif

#if DEBUG || DANCE_UI_INHOUSE
@available(iOS 13.0, *)
extension ViewRendererHost {
    internal func startProfiling() {
        viewGraph.graph.startProfiling()
    }
    
    internal func stopProfiling() {
        viewGraph.graph.stopProfiling()
    }
    
    internal func resetProfile() {
        viewGraph.graph.reset()
    }
    
    internal func archiveJSON(name: String? = nil) {
        viewGraph.graph.archiveJSON(name: name)
    }
}
#endif
