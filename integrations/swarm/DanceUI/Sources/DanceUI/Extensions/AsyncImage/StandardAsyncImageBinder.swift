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
public final class StandardAsyncImageBinder: AsyncImageBinder {
    
    private var task: StandardLoadingTask?
    private var canceled: Bool = false
    
    public required init() {}
    
    public func start(context: AsyncImageContext, delegate: _AsyncImageDelegate) {
        guard let downloadURL = context.url else {
            delegate.onResetDelegate?()
            return
        }
        
        let options = context.options
        
        guard !options.isSuperset(of: [.ignoreMemoryCache, .ignoreDiskCache, .ignoreNetworkImage]) else {
            return
        }
        
        let manager = StandardAsyncImageManager.shared
        let cacheKey = downloadURL.absoluteString
        let startTime = CACurrentMediaTime() * 1000
        let scale = context.scale
        
        if !options.contains(.ignoreMemoryCache),
           let cachedImage = manager.memoryImage(for: cacheKey),
           let cgImage = cachedImage.cgImage {
            let event = makeEventContext(startTime: startTime, from: .memory, image: cachedImage)
            let image = Image(decorative: cgImage, scale: scale, orientation: Image.Orientation(cachedImage.imageOrientation))
            delegate.onSuccessDelegate?(image, event)
            return
        }
        
        if options.contains(.ignoreNetworkImage) {
            let error = NSError(
                domain: "DanceUI.StandardAsyncImageBinder",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Image not found in cache and network is ignored"]
            )
            let event = makeEventContext(startTime: startTime, from: .none, image: nil)
            delegate.onFailureDelegate?(error, event)
            return
        }
        
        let loadingTask = StandardLoadingTask()
        loadingTask.start(downloadURL) { [weak self] cgImage, orientation in
            guard let self = self, !self.canceled else { return }
            self.task = nil
            
            let uiImage = UIImage(cgImage: cgImage)
            
            // 缓存到内存
            if !options.contains(.notCacheToMemery) {
                manager.setMemoryImage(uiImage, for: cacheKey)
            }
            
            let event = self.makeEventContext(startTime: startTime, from: .network, image: uiImage)
            let image = Image(decorative: cgImage, scale: scale, orientation: orientation ?? .up)
            
            DispatchQueue.main.async {
                delegate.onSuccessDelegate?(image, event)
            }
        } failureCallBack: { [weak self] error in
            guard let self = self, !self.canceled else { return }
            self.task = nil
            
            let event = self.makeEventContext(startTime: startTime, from: .none, image: nil)
            DispatchQueue.main.async {
                delegate.onFailureDelegate?(error, event)
            }
        }
        
        task = loadingTask
    }
    
    public func cancel() {
        task?.cancel()
        task = nil
        canceled = true
    }
    
    public static var imageManager: AsyncImageManager {
        StandardAsyncImageManager.shared
    }
    
    // MARK: - Private Methods
    
    private func makeEventContext(startTime: Double, from: AsyncImageFrom, image: UIImage?) -> AsyncImageEventContext {
        let duration = CACurrentMediaTime() * 1000 - startTime
        let imageSize = image?.size ?? .zero
        return AsyncImageEventContext(
            imageType: .unknown,
            imageSize: imageSize,
            fileSize: 0,
            from: from,
            loadDuration: duration,
            queueDuration: 0,
            cacheDuration: from == .memory ? duration : 0,
            downloadDuration: from == .network ? duration : 0,
            decodeDuration: 0,
            customInfo: [:]
        )
    }
}

// MARK: - StandardLoadingTask

@available(iOS 13.0, *)
internal final class StandardLoadingTask {
    
    internal var task: URLSessionDownloadTask?
    internal var canceled: Bool = false
    
    internal init() {}
    
    internal func cancel() {
        task?.cancel()
        canceled = true
    }
    
    internal func start(_ downloadURL: URL, 
                        successCallBack: @escaping (CGImage, Image.Orientation?) -> (), 
                        failureCallBack: @escaping (Error?) -> ()) {
        let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] url, urlResponse, error in
            guard let self = self, !self.canceled else {
                return
            }
            if let url = url,
               let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let image = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                let orientation = source.imageOrientation(at: 0)
                successCallBack(image, orientation)
            } else {
                failureCallBack(error)
            }
        }
        task.resume()
        self.task = task
    }
}

// MARK: - CGImageSource Extension

@available(iOS 13.0, *)
extension CGImageSource {
    internal func imageOrientation(at index: Int) -> Image.Orientation? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(self, index, nil),
              let orientationResult = CFDictionaryGetValue(
                properties,
                Unmanaged.passUnretained(kCGImagePropertyOrientation).toOpaque()
              ),
              let orientation = unsafeBitCast(orientationResult, to: NSNumber.self) as? Int
        else {
            return nil
        }
        return Image.Orientation(exifValue: orientation)
    }
}
