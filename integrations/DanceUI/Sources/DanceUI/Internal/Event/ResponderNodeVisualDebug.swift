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

import QuartzCore
import MyShims
@available(iOS 13.0, *)
internal struct VisualDebugGeometry {
    
    internal var uuid: ObjectIdentifier
    
    internal var position: CGPoint
    
    internal var bounds: CGRect
    
    internal var contentPath: Path?
    
    internal var transform3D: CATransform3D
    
    internal func canMakeUseOf(layer: CALayer) -> Bool {
        if contentPath != nil {
            return layer is CAShapeLayer
        }
        return true
    }
    
    internal func createLayer() -> CALayer {
        if contentPath != nil {
            return CAShapeLayer()
        }
        return CALayer()
    }
    
}

@available(iOS 13.0, *)
internal protocol ResponderNodeVisualDebug: AnyObject {
    
    var visualDebugID: ObjectIdentifier { get }
    
    /// Returns the geometry on the root hosting view of the contents correspond
    /// to the reponder node.
    ///
    /// - Note: Only leaf nodes knnows its global geometry (by requring
    ///  `ContentResponderHelper`).
    ///
    var visualDebugGeometries: [VisualDebugGeometry] { get }
    
}

@available(iOS 13.0, *)
extension ResponderNodeVisualDebug {
    
    internal var visualDebugID: ObjectIdentifier { ObjectIdentifier(self) }
    
    internal var visualDebugGeometries: [VisualDebugGeometry] {
        []
    }
    
}

@available(iOS 13.0, *)
internal final class ResponderVisualDebugView: UIHookFreeView {
    
    internal override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }
    
    internal required init?(coder: NSCoder) {
        return nil
    }
    
    internal override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
    
    internal var geometries: [VisualDebugGeometry] = [] {
        didSet {
            _needsUpdateGeoemtries = true
            setNeedsLayout()
        }
    }
    
    internal var boundResponderUUIDs: Set<ObjectIdentifier> = [] {
        didSet {
            _needsUpdateBoundResponderUUIDs = true
            setNeedsLayout()
        }
    }
    
    private var _needsUpdateGeoemtries: Bool = false
    
    private var _needsUpdateBoundResponderUUIDs: Bool = false
    
    private var _reusableLayers: Set<CALayer> = Set()
    
    private var _usedLayers: [ObjectIdentifier : CALayer] = [:]
    
    internal override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        if _needsUpdateGeoemtries {
            
            var unusedUUIDs = Set(_usedLayers.keys)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for eachGeometry in geometries {
                let geometryLayer: CALayer
                let needsInitialization: Bool
                if let existedLayer = _usedLayers[eachGeometry.uuid] {
                    if eachGeometry.canMakeUseOf(layer: existedLayer) {
                        geometryLayer = existedLayer
                        needsInitialization = false
                    } else {
                        existedLayer.removeFromSuperlayer()
                        geometryLayer = !_reusableLayers.isEmpty ? _reusableLayers.removeFirst() : eachGeometry.createLayer()
                        needsInitialization = true
                    }
                } else {
                    geometryLayer = !_reusableLayers.isEmpty ? _reusableLayers.removeFirst() : eachGeometry.createLayer()
                    needsInitialization = true
                }
                if needsInitialization {
                    _initLayer(geometryLayer, with: eachGeometry)
                }
                _configureLayer(geometryLayer, with: eachGeometry)
                _usedLayers[eachGeometry.uuid] = geometryLayer
                if needsInitialization {
                    layer.addSublayer(geometryLayer)
                }
                unusedUUIDs.remove(eachGeometry.uuid)
            }
            
            for eachUnusedUUID in unusedUUIDs {
                if let unusedLayer = _usedLayers.removeValue(forKey: eachUnusedUUID) {
                    _reusableLayers.insert(unusedLayer)
                    unusedLayer.removeFromSuperlayer()
                }
                
            }
            CATransaction.commit()
            
            _needsUpdateGeoemtries = false
        }
        
        if _needsUpdateBoundResponderUUIDs {
            
            CATransaction.begin()
            CATransaction.setDisableActions(false)
            
            for (uuid, layer) in _usedLayers {
                
                if boundResponderUUIDs.contains(uuid) {
                    if let shapeLayer = layer as? CAShapeLayer {
                        shapeLayer.fillColor = shapeLayer.strokeColor
                    } else {
                        layer.backgroundColor = layer.borderColor
                    }
                } else {
                    if let shapeLayer = layer as? CAShapeLayer {
                        shapeLayer.fillColor = nil
                    } else {
                        layer.backgroundColor = nil
                    }
                }
            }
            
            CATransaction.commit()
            
            _needsUpdateBoundResponderUUIDs = false
        }
    }
    
    private func _initLayer(_ layer: CALayer, with geometry: VisualDebugGeometry) {
        let tintColor = UIColor(
            hue: CGFloat((0...255).randomElement()!) / 255,
            saturation: 0.8,
            brightness: 0.6,
            alpha: 1
        ).cgColor
        if let shapeLayer = layer as? CAShapeLayer {
            shapeLayer.lineWidth = 0.5
            shapeLayer.strokeColor = tintColor
            shapeLayer.fillColor = nil
        } else {
            layer.borderWidth = 0.5
            layer.borderColor = tintColor
        }
    }
    
    private func _configureLayer(_ layer: CALayer, with geometry: VisualDebugGeometry) {
        layer.bounds = geometry.bounds
        layer.position = geometry.position
        layer.transform = geometry.transform3D
        if let shapeLayer = layer as? CAShapeLayer {
            shapeLayer.path = geometry.contentPath?.cgPath
        }
    }
    
}

@available(iOS 13.0, *)
struct ResponderNodeVisualDebugEnabledKey: DefaultFalseBoolEnvKey {
    
    static var raw: String {
        "RESPONDER_NODE_VISUAL_DEBUG_ENABLED"
    }
    
}

@available(iOS 13.0, *)
extension EnvValue where K == ResponderNodeVisualDebugEnabledKey {
    
    private static let responderNodeVisualDebugEnabledValue: Self = .init()
    
    internal static var isResponderNodeVisualDebugEnabled: Bool {
        responderNodeVisualDebugEnabledValue.value
    }
}
