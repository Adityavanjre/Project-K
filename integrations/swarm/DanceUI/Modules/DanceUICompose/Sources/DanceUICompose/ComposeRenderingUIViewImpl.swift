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
import UIKit
internal import MyShims
@_spi(DanceUICompose) import DanceUI

internal import DanceUIRuntime

@available(iOS 13.0, *)
internal final class ComposeRenderingUIViewImpl: UIView, ComposeRenderingUIView {
    
    internal var onAttachedToWindow: (() -> Void)?
    internal var onRender: ((any ComposeCanvas, Double, Double, TimeInterval) -> Void)?
    
    var delegate: (any ComposeRenderDelegate)?
    
    @inline(__always)
    internal var isApplicationActive: Bool = false {
        didSet {
            displayLinkConditions.isApplicationActive = isApplicationActive
        }
    }
    
    @inline(__always)
    internal var isNeedHighFrequencyPolling: Bool {
        get {
            displayLinkConditions.needsToBeProactive
        }
        set {
            displayLinkConditions.needsToBeProactive = newValue
        }
    }
    internal var isPresentWithTransactionEveryFrame: Bool = false
    
    internal var disableRendering: Bool = false
    
    private let renderer: ViewRenderer = ViewRenderer()
    private var nextTime = Time.now
    
    private var pixelSize = CGSize.zero
    
    private var caDisplayLink: CADisplayLink? = nil
    
    private lazy var canvas = ComposeCanvasImpl()
    
    private var lastDisplayList = DisplayList.empty
    private var lastVersion = DisplayList.Version.zero
    private var refreshRate: Int = UIScreen.main.maximumFramesPerSecond
    private var frameStartTime: CFTimeInterval = 0
    
    private lazy var displayLinkConditions = DisplayLinkConditions { [weak self] paused in
        self?.caDisplayLink?.isPaused = paused
    }
    
    internal override init(frame: CGRect) {
        super.init(frame: frame)
        caDisplayLink = CADisplayLink(target: self, selector: #selector(ComposeRenderingUIViewImpl.handleDisplayLinkTick))
        caDisplayLink?.add(to: .main, forMode: .common)
    }
    
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var lastPositions = [Int: CGPoint]()
    private var currentPositions = [Int: CGPoint]()
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result is UIHookFreeView || result == self {
            return nil
        }
        return result
    }
    
    internal func onTouchesEvent(_ identity: Int, position: CGPoint, phase: ComposeTouchesEventPhase) {
        switch phase {
        case .began, .moved:
            currentPositions[identity] = position
        case .ended, .cancelled:
            currentPositions.removeAll(keepingCapacity: true)
            lastPositions.removeAll(keepingCapacity: true)
            displayLinkConditions.isTouchActive = false
        @unknown default:
            break
        }
    }
    
    internal func onTouchesCancelled() {
        currentPositions.removeAll(keepingCapacity: true)
        lastPositions.removeAll(keepingCapacity: true)
        displayLinkConditions.isTouchActive = false
    }
    
    internal override func didMoveToWindow() {
        Signpost.compose.tracePoi("RendereringUIView:didMoveToWindow", []) {
            super.didMoveToWindow()
            
            guard let window else { return }
            
            let screen = window.screen
            contentScaleFactor = screen.scale
            caDisplayLink?.preferredFramesPerSecond = screen.maximumFramesPerSecond
            
            onAttachedToWindow?()
            drawSynchronously()
        }
    }
    
    internal override func layoutSubviews() {
        Signpost.compose.tracePoi("RendereringUIView:layoutSubviews", []) {
            super.layoutSubviews()
            guard window != nil && !bounds.isEmpty else {
                return
            }
            pixelSize = bounds.size.pt2px
            drawSynchronously()
        }
    }
    
    private func drawSynchronously() {
        Signpost.compose.tracePoi("RendereringUIView:drawSynchronously", []) {
            guard caDisplayLink != nil else {
                return
            }
            
            render()
        }
    }
    
    internal func leftTimeNanos() -> Int {
        let now = CACurrentMediaTime()
        let frameDuration = 1.0 / Double(refreshRate)
        let time: Double = now - frameStartTime
        guard time <= frameDuration else {
            return Int(frameDuration * 1_000_000_000)
        }
        let left: Double = .maximum(0, frameDuration - time)
        return Int(left * 1_000_000_000)
    }
    
    @objc
    private func handleDisplayLinkTick() {
        self.frameStartTime = CACurrentMediaTime()
        guard let targetTimestamp = self.caDisplayLink?.targetTimestamp else { return }
        let isTouchChanged = currentPositions.count != lastPositions.count || currentPositions != lastPositions
        if isTouchChanged {
            displayLinkConditions.isTouchActive = true
            lastPositions = currentPositions
        } else {
            displayLinkConditions.isTouchActive = false
        }
        displayLinkConditions.onDisplayLinkTick {
            render(timestamp: targetTimestamp)
        }
    }
    
    internal func renderImmediately() {
        guard let targetTimestamp = self.caDisplayLink?.targetTimestamp else { return }
        render(timestamp: targetTimestamp)
    }
    
    internal func needRedraw() {
        guard !disableRendering else { return }
        displayLinkConditions.needRedraw()
    }
    
    internal func dispose() {
        caDisplayLink?.invalidate()
        caDisplayLink = nil
        delegate = nil
    }
    
    private var lastRenderTimestamp: TimeInterval = CACurrentMediaTime()
    
    private var isInteropActive = false {
        didSet {
            updateLayerOpacity()
            // TODO: When ViewUpdater supports AsyncRendering, we need to config to disable it if isInteropActive is set
            // renderer.configuration.disableAsync = isInteropActive
        }
    }
    
    override var isOpaque: Bool {
        didSet {
            updateLayerOpacity()
        }
    }
    
    private func updateLayerOpacity() {
        layer.isOpaque = !isInteropActive && isOpaque
    }
    
    internal func render(timestamp: CFTimeInterval = CACurrentMediaTime()) {
        guard !disableRendering else { return }
        guard let delegate else {
            return
        }
        
        lastRenderTimestamp = max(timestamp, lastRenderTimestamp)
        
        canvas.reset()
        canvas.resizeLayer(size: pixelSize)
        Signpost.compose.traceInterval("RenderingUIView:onRender") {
            Signpost.compose.tracePoi("onRender", []) {
                delegate
                    .onRender(
                        with: canvas,
                        width: pixelSize.width,
                        height: pixelSize.height,
                        nanoTime: lastRenderTimestamp
                    )
            }
        }
        delegate.retrieveInteropTransaction()
        isInteropActive = delegate.checkUIKitInteropStateBegan()
        
        let needUpdate: Bool
        let displayList = canvas.currentResult
        if !DGCompareValues(lhs: lastDisplayList, rhs: displayList) {
            lastVersion = .make()
            lastDisplayList = displayList
            needUpdate = true
        } else {
            needUpdate = false
        }
        
        guard needUpdate else {
            delegate.invokeActionIfNeeded()
            isInteropActive = delegate.checkUIKitInteropStateEnded()
            return
        }
        let scale = window?.screen.scale ?? 1
        nextTime = Signpost.compose.traceInterval("RenderingUIView:renderDisplayList") {
            Signpost.compose.tracePoi("renderDisplayList", []) {
                renderer.render(
                    rootView: self,
                    from: displayList,
                    time: Time.now,
                    nextTime: Time(seconds: timestamp),
                    version: lastVersion,
                    maxVersion: .make(),
                    contentsScale: scale
                )
            }
        }
        delegate.invokeActionIfNeeded()
        isInteropActive = delegate.checkUIKitInteropStateEnded()
    }
}


private class DisplayLinkConditions {
    private let setPausedCallback: (Bool) -> Void
    
    fileprivate var isTouchActive = false {
        didSet {
            if oldValue != isTouchActive {
                update()
            }
        }
    }
    
    fileprivate var needsToBeProactive: Bool = false {
        didSet {
            update()
        }
    }
    
    fileprivate var isApplicationActive: Bool = false {
        didSet {
            update()
        }
    }
    
    private var scheduledRedrawsCount = 0 {
        didSet {
            update()
        }
    }
    
    fileprivate init(setPausedCallback: @escaping (Bool) -> Void) {
        self.setPausedCallback = setPausedCallback
    }
    
    fileprivate func onDisplayLinkTick(draw: () -> Void) {
        if scheduledRedrawsCount > 0 {
            scheduledRedrawsCount -= 1
            draw()
        }
    }
    
    fileprivate func needRedraw() {
        scheduledRedrawsCount = DisplayLinkConditions.framesCountToScheduleOnNeedRedraw
    }
    
    private func update() {
        let isUnpaused = isApplicationActive && ((needsToBeProactive && isTouchActive) || scheduledRedrawsCount > 0)        
        setPausedCallback(!isUnpaused)
    }
    
    private static let framesCountToScheduleOnNeedRedraw = 2
}
