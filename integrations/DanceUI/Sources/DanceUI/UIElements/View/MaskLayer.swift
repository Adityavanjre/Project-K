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
internal final class MaskLayer: CAShapeLayer {
    
    internal var clips: [DisplayList.ViewUpdater.Model.Clip] = []
    
    internal var clipTransform: CGAffineTransform = .init(a: 0, b: 0, c: 0, d: 0, tx: 0, ty: 0)
    
    override init() {
        super.init()
        anchorPoint = .zero
        _myShims_setNoAnimationDelegate()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        _danceuiFatalError("init(coder:) has not been implemented")
    }
    
    internal func setClips(_ clips: [DisplayList.ViewUpdater.Model.Clip], transform: CGAffineTransform) {
        var newSublayers: [CALayer] = []
        
        self.clips = clips
        self.clipTransform = transform
        
        guard !clips.isEmpty else {
            path = nil
            sublayers = newSublayers
            setNeedsLayout()
            return
        }
        
        guard clips.count != 1 else {
            update(clip: clips[0])
            sublayers = newSublayers
            return
        }

        self.reset()
        var sublayers = self.sublayers ?? []
        newSublayers = sublayers
        var shouldChangeSublayers: Bool = false
        for (index, clip) in clips.enumerated() {
            guard !clip.style.isEOFilled else {
                break
            }
            let maskLayer: MaskLayer
            if index >= sublayers.count {
                maskLayer = MaskLayer()
                newSublayers.append(maskLayer)
                shouldChangeSublayers = true
            } else {
                maskLayer = sublayers[index] as! MaskLayer
            }
            maskLayer.bounds = self.bounds
            maskLayer.clipTransform = transform
            maskLayer.update(clip: clip)
            
            if index == 0 {
                maskLayer.compositingFilter = nil
            } else {
                maskLayer.compositingFilter = "sourceIn"
            }
        }
        
        if clips.count >= sublayers.count {
            if shouldChangeSublayers {
                self.sublayers = newSublayers
            }
        } else {
            sublayers.replaceSubrange(clips.count..<sublayers.count, with: [])
            self.sublayers = sublayers
        }
    }
    
    private func reset() {
        self.path = nil
        self.setAffineTransform(.identity)
        self.position = .zero
        self.bounds = .zero
        self.cornerRadius = 0
        self.borderWidth = 0
        self.backgroundColor = nil
        self.fillRule = .nonZero
    }
    
    internal func update(clip: DisplayList.ViewUpdater.Model.Clip) {
        let shapeType = ShapeType(clip.path)
        switch shapeType {
        case .rect(let rect, let radius, let style):
            self.position = rect.origin
            self.bounds = .init(origin: .zero, size: rect.size)
            self.path = nil
            self.cornerRadius = radius
            if #available(iOS 13.0, *) {
                self.cornerCurve = style.cornerCurve
            } else {
                // Fallback on earlier versions
            }
            self.borderWidth = 0
            self.backgroundColor = self.borderColor
        case .empty:
            guard !clip.path.isEmpty else {
                self.path = nil
                self.borderWidth = 0
                self.backgroundColor = nil
                return
            }
            self.position = .zero
            self.borderWidth = 0
            self.backgroundColor = nil
            self.path = clip.path.cgPath
            self.fillRule = clip.style.fillRule
        default:
            self.position = .zero
            self.borderWidth = 0
            self.backgroundColor = nil
            self.path = clip.path.cgPath
            self.fillRule = clip.style.fillRule
        }
        if let clipTransform = clip.transform {
            self.affineTransform()
            self.clipTransform = self.clipTransform.concatenating(clipTransform)
        }
        if DanceUIFeature.gestureContainer.isEnable {
            if clip.gestureContrainerTransform != .identity {
                self.clipTransform = self.clipTransform.concatenating(clip.gestureContrainerTransform.inverted())
            }
        }
        self.setAffineTransform(clipTransform)
    }

}
