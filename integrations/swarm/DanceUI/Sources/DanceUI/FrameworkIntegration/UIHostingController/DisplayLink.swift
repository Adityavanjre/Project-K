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
import MyShims

import Foundation

@available(iOS 13.0, *)
internal final class DisplayLink: NSObject {
    
    internal enum ThreadName {
        
        case main
        
        case async
        
    }
    
    private static var asyncThread: Thread?
    
    private static var asyncRunLoop: RunLoop?
    
    private static var asyncCount: Int = 0
    
    private weak var host : AnyUIHostingView?

#if DEBUG
    internal var testableHost: AnyUIHostingView? {
        return host
    }
#endif
    
    private var link : CADisplayLink?

    private var nextUpdate : Time = .distantFuture

    private var currentUpdate : Time?

    private var interval : Double = 0

    private var reasons : Set<UInt32> = Set()

    private var currentThread : ThreadName = .main

    private var nextThread : ThreadName = .main
    
    internal override init() {
        _unimplementedInitializer(className: "DisplayLink")
    }
    
    internal init(host: AnyUIHostingView, window: UIWindow) {
        super.init()
        self.host = host
        self.link = window.screen.displayLink(withTarget: self, selector: #selector(displayLinkTimer))
        self.link?.add(to: .main, forMode: .common)
    }
    
    // Remove the coverage exclusion mark if async update is fully implemented.
    @objc(displayLinkTimer:)
    private func displayLinkTimer(link: CADisplayLink) {
        Update.withLock {
            let somewhatThread: ThreadName
            let wantedCurrentThread: ThreadName

            // Small negative delta for timestamp comparison (approximately -0.004 seconds)
            let delta = Time(seconds: Double(bitPattern: 0xbf71_1111_1111_1111))
            
            let needsUpdateDisplayLink: Bool
            
            switch (currentThread, nextThread) {
            case (.main, .main),
                 (.async, .async):
                if self.link != nil {
                    let timestamp = Time(seconds: link.timestamp)
                    if timestamp > nextUpdate + delta {
                        self.currentUpdate = timestamp
                        self.nextUpdate = .distantFuture
                        if let host = self.host {
                            // FIMXE: Use synchronous rendering during animation before async view renderer is ready
                            // host.displayLinkTimer(timestamp: timestamp, isAsyncThread: currentThread == .async)
                            host.displayLinkTimer(timestamp: timestamp, isAsyncThread: false)
                        }
                        self.currentUpdate = nil
                        if self.nextUpdate == .distantFuture {
                            if self.nextThread == .async {
                                self.nextThread = .main
                                self.nextUpdate = timestamp
                                somewhatThread = self.nextThread
                            } else {
                                somewhatThread = .main
                            }
                        } else {
                            somewhatThread = self.nextThread
                        }
                    } else {
                        somewhatThread = self.nextThread
                    }
                } else {
                    somewhatThread = self.nextThread
                }
                needsUpdateDisplayLink = (somewhatThread != self.currentThread)
                wantedCurrentThread = self.currentThread == .main ? .async : .main
            case (.main, .async):
                somewhatThread = .main
                wantedCurrentThread = .async
                needsUpdateDisplayLink = true
            case (.async, .main):
                somewhatThread = .main
                wantedCurrentThread = self.currentThread == .main ? .async : .main
                needsUpdateDisplayLink = (somewhatThread != self.currentThread)
            }
            
            if needsUpdateDisplayLink {
                if self.link != nil {
                    let targetRunLoop: RunLoop
                    if wantedCurrentThread == .main {
                        targetRunLoop = .main
                    } else {
                        targetRunLoop = Self.ensureAsyncRunLoop()
                    }
                    link.remove(from: RunLoop.current, forMode: .common)
                    guard let updatedLink = CADisplayLink(
                        my_display: link.display,
                        target: self,
                        selector: #selector(displayLinkTimer(link:))
                    ) else {
                        preconditionFailure()
                    }
                    updatedLink.add(to: targetRunLoop, forMode: .common)
                    self.link = updatedLink
                    let previousInterval = self.interval
                    let previousReaons = self.reasons
                    self.interval = 0
                    self.reasons = Set()
                    setFrameInterval(previousInterval, reasons: previousReaons)
                    if wantedCurrentThread == .async {
                        Self.asyncCount += 1
                    }
                }
                
                self.currentThread = wantedCurrentThread
            }
            
            if self.link != nil {
                if self.nextUpdate == .distantFuture {
                    if self.currentThread == self.nextThread {
                        link.isPaused = true
                    }
                }
            } else {
                link .invalidate()
            }
            
        }
    }
    
    internal func invalidate() {
        Update.withLock {
            if let link = self.link {
                if link.isPaused {
                    link.invalidate()
                }
            }
            self.link = nil
            // Remove the coverage exclusion mark if async update is fully implemented.
            if self.currentThread == .async {
                Self.asyncCount -= 1
            }
        }
    }
    
    internal var willRender: Bool {
        Time.distantFuture > nextUpdate
    }
    
    // Remove the coverage exclusion mark if async update is fully implemented.
    internal func setNextUpdate(delay: Double, interval: Double, reasons: Set<UInt32>) {
        let wantedNextUpdate: Time
        if 0.001 <= delay {
            let currentTime = currentUpdate?.seconds ?? CACurrentMediaTime()
            wantedNextUpdate = Time(seconds: currentTime + delay)
        } else {
            wantedNextUpdate = .zero
        }
        if nextUpdate >= wantedNextUpdate {
            nextUpdate = wantedNextUpdate
            link?.isPaused = false
        }
        setFrameInterval(interval, reasons: reasons)
    }
    
    // Remove the coverage exclusion mark if async update is fully implemented.
    internal func setFrameInterval(_ interval: Double, reasons: Set<UInt32>) {
        if self.interval != interval {
            self.interval = interval
            if #available(iOS 15.0, *) {
                link?.preferredFrameRateRange = CAFrameRateRange(interval: interval)
            }
        }
        if self.reasons != reasons {
            self.reasons = reasons
            let count = reasons.count
            if #available(iOS 15.0, *) {
                tupleWithBuffer(UInt32.self, count) { tuple in
                    let buffer = tuple.tuple.withMemoryRebound(to: UInt32.self, capacity: count, {$0})
                    for (index, reason) in reasons.enumerated() {
                        buffer[index] = reason
                    }
                    self.link?.my_setHighFrameReasons(buffer, count: count)
                }
            }
        }
    }
    
    // Remove the coverage exclusion mark if async update is fully implemented.
    @objc
    private static func asyncThread(arg: Any?) {
        typealias SchedulerTime = RunLoop.SchedulerTimeType
        typealias SchedulerTimeStride = RunLoop.SchedulerTimeType.Stride
        
        Update.withLock {
            let asyncRunLoop: RunLoop = .current
            self.asyncRunLoop = asyncRunLoop
            Update.broadcast()
            asyncRunLoop.schedule(
                after: SchedulerTime(Date(timeIntervalSinceNow: 10)),
                tolerance: SchedulerTimeStride(1),
                options: nil
            ) {
                _intentionallyLeftBlank()
            }
            
            repeat {
                Update.withoutLock {
                    asyncRunLoop.run()
                }
            } while asyncCount > 0
            
            self.asyncRunLoop = nil
            self.asyncThread = nil
            
            Update.broadcast()
        }
    }
    
    /// Remove the coverage exclusion mark if async update is fully implemented.
    internal func setBegan() {
        self.nextThread = .async
    }
    
    internal func setCancelled() {
        self.nextThread = .main
    }
    
    /// Remove the coverage exclusion mark if async update is fully implemented.
    private static func ensureAsyncRunLoop() -> RunLoop {
        while true {
            if let asyncRunLoop = self.asyncRunLoop {
                return asyncRunLoop
            }
            let thread = waitForAsyncThreadReady()
        }
    }
    
    /// Remove the coverage exclusion mark if async update is fully implemented.
    private static func waitForAsyncThreadReady() -> Thread {
        defer {
            Update.wait()
        }
        
        if let asyncThread = asyncThread {
            return asyncThread
        }
        
        let asyncThread = Thread(target: DisplayLink.self, selector: #selector(asyncThread(arg:)), object: nil)
        asyncThread.qualityOfService = .userInteractive
        asyncThread.start()
        self.asyncThread = asyncThread
        
        return asyncThread
    }
    
}

@available(iOS 15.0, *)
extension CAFrameRateRange {
    
    internal init(interval: Double) {
        guard interval != 0 else {
            self = .my_default
            return
        }
        let frameRate = round(1.0 / Float(interval))
        if frameRate <= 40.0 {
            self.init(minimum: frameRate, maximum: 60.0, preferred: frameRate)
        } else if frameRate < 80.0 {
            self = .my_default
        } else { // BDCOV_EXCL_BLOCK
            // NOTE: This line is covered but code coverage tool has bug
            self.init(minimum: 80.0, maximum: frameRate, preferred: frameRate)
        }
    }
    
    // swift-format-ignore: AlwaysUseLowerCamelCase
    private static var my_default: CAFrameRateRange {
        #if compiler(>=6.2)
        // We use this to workaround weak link issue of CAFrameRateRangeDefault symbol in Xcode 26 Beta temporary
        // TODO: Consider remove this after Apple fixed it in a comping up SDK.
        MyCAFrameRateRangeDefault()
        #else
        CAFrameRateRange.default
        #endif
    }
}
