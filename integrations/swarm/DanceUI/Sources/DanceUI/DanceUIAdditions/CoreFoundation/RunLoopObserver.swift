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

import MyShims
@available(iOS 13.0, *)
extension RunLoop {
    
    private static func schedule(_ body: @escaping () -> Void) {
        addObserver(body)
        if #available(iOS 16.0, *) {
            if UIKitUpdateCycle.isEnabled {
                UIKitUpdateCycle.addPreCommitObserver(body)
            }
        }
    }
    
    // use `RunLoop.performOnMainThread` when caller check Thread.isMain.
    private static func addObserver(_ body: @escaping () -> Void) {

#if DEBUG || DANCE_UI_INHOUSE
        if !isMainThread {
            runtimeIssue(type: .error, "Running an observer off main-thread to flush DanceUI is not allowed.")
        }
#endif


        let current = CFRunLoopGetCurrent()
        
        if observer == nil {
            let observerOrNil = CFRunLoopObserverCreate(
                nil,
                CFRunLoopActivity([.beforeWaiting, .exit]).rawValue,
                true,
                0,
                { (self: CFRunLoopObserver?, activity: CFRunLoopActivity, context: UnsafeMutableRawPointer?) in
                    autoreleasepool {
                        RunLoop.flushObservers()
                    }
                },
                nil
            )
            
            guard let _observer = observerOrNil else {
                _danceuiPreconditionFailure("observer is nil")
            }
            
            CFRunLoopAddObserver(current, _observer, .commonModes)
            
            if DanceUIFeature.gestureContainer.isEnable,
               Update.hasEnqueuedActionsInTargetedActionOfUIGestureRecognizer {
                // Wake up the run loop in case that the run loop observer
                // is added during a somewhat run loop observer callback.
                // This could happen when RunLoop.addObserver is triggered
                // by gesture callbacks.
                CFRunLoopWakeUp(current)
            }
            
            observer = _observer
        }
        
        if let currentMode = CFRunLoopCopyCurrentMode(current) {
            guard let observer = observer else {
                _danceuiPreconditionFailure("observer is nil")
            }
            
            if !CFRunLoopContainsObserver(current, observer, currentMode) {
                CFRunLoopAddObserver(current, observer, currentMode)
            }
        }
        
        observerActions.append(body)
    }
    
    // DanceUI modification: for introducing call root tracing tool
    internal static func flushObservers() {
        // PerThreadOSCallback.traceInterval("flushObservers") {
            _flushObservers()
        // }
    }
    
    // DanceUI modification: for introducing call root tracing tool
    @inline(__always)
    internal static func _flushObservers() {
        while !observerActions.isEmpty {
            let flushed = observerActions
            observerActions = []
            
            Update.perform {
                flushed.forEach {
                    $0()
                }
            }
        }
    }
    
    /// Remove the coverage exclusion mark if it is used.
    ///
    private static func runUntilFinished(_ body: () -> Bool) {
        runModes([.common], untilFinished: body)
    }
    
    /// Remove the coverage exclusion mark if it is used.
    ///
    private static func runModes(_ modes: [RunLoop.Mode], untilFinished body: () -> Bool) {
        for eachMode in modes {
            repeat {
                if !current.run(mode: eachMode, before: Date(timeIntervalSinceNow: 0.001)) {
                    Thread.sleep(forTimeInterval: 0.001)
                }
                if body() {
                    return
                }
            } while true
        }
    }
    
    @inline(__always)
    internal static func performOnMainThread(body: @escaping () -> Void) {
        if Thread.isMainThread {
            RunLoop.schedule(body)
        } else {
            RunLoop.main.perform(inModes: [.common], block: body)
        }
    }
}

@available(iOS 13.0, *)
private var observer: CFRunLoopObserver?
@available(iOS 13.0, *)
private var observerActions: [() -> Void] = []

@available(iOS 16.0, *)
internal enum UIKitUpdateCycle {
    
    private static var token: UInt64 = 0
    
    @inline(__always)
    internal static var isEnabled: Bool {
        _MyShims_UIUpdateCycleEnabled()
    }
    

    @available(iOS 16.0, *)
    internal static func addPreCommitObserver(_ action: @escaping () -> Void) {
        if token == 0 {
            let item = _MyShims_UIUpdateSequenceCATransactionCommitItem()
            token = _MyShims_UIUpdateSequenceInsertItem(item, 0, "DanceUIFlush", 0, 0) { _, _, _, _ in
                // Apple's implementaiton flushes `updateSequenceItemActions` here.
                flushObservers()
            }
        }
        // Watch out. This is not DanceUI.observerActions but DanceUI.UIKitUpdateCycle.observerActions
        observerActions.append(action)
    }

    private static var observerActions: [() -> Void] = []
    

    internal static func flushObservers() {
        // Watch out. This is not DanceUI.observerActions but DanceUI.UIKitUpdateCycle.observerActions
        while !observerActions.isEmpty {
            let flushed = observerActions
            observerActions = []
            
            Update.perform {
                flushed.forEach {
                    $0()
                }
            }
        }
    }
    
}

#if DEBUG

internal func addUpdateSequenceDebugPrints() {
    @available(iOS 16.0, *)
    struct Static {
        // Fill your name for a better log-filtering experience.
        static let whoYouAre = ""
        
        static let runLoopObserver: Bool = {
            return true
        }()
        static let scheduledItem: Bool = {
            let item = _MyShims_UIUpdateSequenceScheduledItem()
            _MyShims_UIUpdateSequenceInsertItem(item, 0, "DanceUIUpdateCycleDebugScheduledItem", 0, 0) { _, _, _, _ in
                print("[\(whoYouAre)DBG] [UIUpdateSequence] [ScheduledItem]")
            }
            return true
        }()
        static let hidEventsItem: Bool = {
            let item = _MyShims_UIUpdateSequenceHIDEventsItem()
            _MyShims_UIUpdateSequenceInsertItem(item, 0, "DanceUIUpdateCycleDebugHIDEventsItem", 0, 0) { _, _, _, _ in
                print("[\(whoYouAre)DBG] [UIUpdateSequence] [HIDEventsItem]")
            }
            return true
        }()
        static let animationsItem: Bool = {
            let item = _MyShims_UIUpdateSequenceAnimationsItem()
            _MyShims_UIUpdateSequenceInsertItem(item, 0, "DanceUIUpdateCycleDebugAnimationsItem", 0, 0) { _, _, _, _ in
                print("[\(whoYouAre)DBG] [UIUpdateSequence] [AnimationsItem]")
            }
            return true
        }()
        static let caTransactionItem: Bool = {
            let item = _MyShims_UIUpdateSequenceCATransactionCommitItem()
            _MyShims_UIUpdateSequenceInsertItem(item, 0, "DanceUIUpdateCycleDebugCATransactionCommitItem", 0, 0) { _, _, _, _ in
                print("[\(whoYouAre)DBG] [UIUpdateSequence] [CATransactionCommitItem]")
            }
            return true
        }()
        static let doneItem: Bool = {
            let item = _MyShims_UIUpdateSequenceDoneItem()
            _MyShims_UIUpdateSequenceInsertItem(item, 0, "DanceUIUpdateCycleDebugDoneItem", 0, 0) { _, _, _, _ in
                print("[\(whoYouAre)DBG] [UIUpdateSequence] [DoneItem]")
            }
            return true
        }()
    }
    if #available(iOS 16.0, *) {
        let _ = Static.scheduledItem
        let _ = Static.hidEventsItem
        let _ = Static.animationsItem
        let _ = Static.caTransactionItem
        let _ = Static.doneItem
    }
}
#endif // DEBUG
