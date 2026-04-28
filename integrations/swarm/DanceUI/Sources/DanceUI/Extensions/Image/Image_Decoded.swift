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

import OpenCombine
internal import Resolver

@available(iOS 13.0.0, *)
extension Image.Resolved {
    
    @ViewBuilder
    internal func decodeFeature() -> some View {
        modifier(DecodedImageModifier(self), require: DanceUIFeature.imageDecodeForDisplay)
    }
}

@available(iOS 13.0, *)
internal struct DecodedImageModifier: ViewModifier {
    
    internal let image: Image.Resolved
    
    @StateObject
    private var decoder = DecodedViewModel()
    
    init(_ image: Image.Resolved) {
        self.image = image
    }
    
    internal func body(content: Content) -> some View {
        ZStack {
            switch decoder.phase {
            case .empty:
                if let placeholder = decoder.placeholder(image) {
                    placeholder
                } else {
                    Color.clear
                }
            case .decoded(let decodedImage):
                decodedImage
            case .source:
                image
            }
        }
        .onAppear {
            decoder.decode(image)
        }
        .onChange(of: image) { oldValue, newValue in
            decoder.decode(newValue)
        }
    }
    
    fileprivate enum Phase {
        case empty
        case decoded(Image.Resolved)
        case source
    }
    
    private final class DecodedViewModel: OpenCombine.ObservableObject {
        
        private static let decodeQueue: DispatchQueue = DispatchQueue(label: "com.bytedance.DanceUI.image.decoder")
        
        @OpenCombine.Published
        fileprivate var phase: Phase = .empty
        
        private var future: AnyCancellable?
        
        private var lastImage: Image.Resolved? = nil
        
        private lazy var decoder = Resolver.services.optional(ImageDecoder.self)
        
        fileprivate func placeholder(_ image: Image.Resolved) -> Image.Resolved? {
            guard let decoder = decoder else {
                return image
            }
            
            guard let source = image.uiImage?.cgImage,
                  let cgImage = decoder.decodedImage(for: source.decodedKey) else {
                return nil
            }
            var newImage = image
            newImage.image.contents = .cgImage(cgImage)
            return newImage
        }
        
        fileprivate func decode(_ image: Image.Resolved) {
            guard image != lastImage else {
                return
            }
            
            reset()
            lastImage = image
            
            guard let source = image.uiImage?.cgImage, !source.isDecoded else {
                phase = .source
                return
            }
            
            guard let decoder = decoder else {
                phase = .source
                return
            }
            future = OpenCombine.Future<CGImage, Error> { promise in
                Self.decodeQueue.async {
                    guard let decodedSource = decoder.decodeForDisplay(source, key: source.decodedKey) else {
                        promise(.failure(ImageDecodeError()))
                        return
                    }
                    decodedSource.isDecoded = true
                    promise(.success(decodedSource))
                }
            }
            .receive(on: RunLoop.main.ocombine)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.phase = .source
                default:
                    break
                }
            } receiveValue: { [weak self] cgImage in
                var newImage = image
                newImage.image.contents = .cgImage(cgImage)
                self?.phase = .decoded(newImage)
            }
        }
        
        struct ImageDecodeError: Error { }
        
        private func reset() {
            phase = .empty
            future?.cancel()
            future = nil
        }
        
        deinit {
            reset()
        }
    }
}

extension CGImage: DanceUIExtended {
    
    internal var decodedKey: String {
        "DanceUI_Image_\(ObjectIdentifier(self))"
    }
    
    private static var isDecodedForDisplayKey: Void?
    
    internal var isDecoded: Bool {
        get {
            objc_getAssociatedObject(self, &Self.isDecodedForDisplayKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &Self.isDecodedForDisplayKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

@available(iOS 13.0, *)
extension ExtensionWrapper where Wrapped == CGImage {
    
    @_spi(DanceUIExtension)
    public func markDecoded() {
        wrapped.isDecoded = true
    }
}

@available(iOS 13.0, *)
public protocol ImageDecoder: ServiceRegister {
    
    func decodeForDisplay(_ cgImage: CGImage, key: String) -> CGImage?
    
    func decodedImage(for key: String) -> CGImage?
    
    func decodedImage(with data: Data) -> UIImage?
        
    func decodedImage(with path: String) -> UIImage?

}
