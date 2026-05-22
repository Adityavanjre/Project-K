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

public typealias AsyncImageLoadingDecryptBlock = ((_ data: Data?) -> Data?)
@available(iOS 13.0, *)
internal struct AsyncImageProgressValue : Hashable {
    
    internal var receivedSize: Int64
    
    internal var totalSize: Int64
    
    internal init(receivedSize: Int64 = 0, totalSize: Int64 = 0) {
        self.receivedSize = receivedSize
        self.totalSize = totalSize
    }
}

@available(iOS 13.0, *)
extension AsyncImage {
    
    public func onProgress(_ step: Double = 1.0, _ block: @escaping AsyncImageLoadingProgressBlock) -> Self {
        var image = self
        image.progress = AsyncImageProgress(skipDistance: step >= 100 ? 1.0 : step, onProgress: block)
        return image
    }
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageCancelControlWriter : _GraphInputsModifier, ViewModifier {
    
    fileprivate typealias Body = Never
    
    fileprivate let cancelOnDisappear: Bool

    fileprivate static func _makeInputs(modifier: _GraphValue<AsyncImageCancelControlWriter>, inputs: inout _GraphInputs) {
        inputs.asyncImageCancelControl = _GraphValue(modifier[\.cancelOnDisappear].value)
    }
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageCancelControlInput : ViewInput {
    
    fileprivate typealias Value = _GraphValue<Bool>?
    
    @inline(__always)
    fileprivate static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension View {
    
    public func imageCancelOnDisappear(_ flag: Bool) -> some View {
        modifier(AsyncImageCancelControlWriter(cancelOnDisappear: flag))
    }
}

@available(iOS 13.0, *)
public struct AsyncImageDecrypt {
    
    public let onDecrypt: AsyncImageLoadingDecryptBlock
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageDecryptWriter : _GraphInputsModifier, ViewModifier {
    
    fileprivate typealias Body = Never

    fileprivate let block: AsyncImageDecrypt

    fileprivate static func _makeInputs(modifier: _GraphValue<AsyncImageDecryptWriter>, inputs: inout _GraphInputs) {
        inputs.asyncImageDecrypt = _GraphValue(modifier[\.block].value)
    }
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageDecryptInput : ViewInput {
    
    fileprivate typealias Value = _GraphValue<AsyncImageDecrypt>?
    
    @inline(__always)
    fileprivate static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension View {
    
    public func imageRequestDecrypt(_ block: @escaping AsyncImageLoadingDecryptBlock) -> some View {
        modifier(AsyncImageDecryptWriter(block: AsyncImageDecrypt(onDecrypt: block)))
    }
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageOptionsWriter : _GraphInputsModifier, ViewModifier {

    fileprivate typealias Body = Never
    
    fileprivate let options: Set<AsyncImageOption>

    fileprivate static func _makeInputs(modifier: _GraphValue<AsyncImageOptionsWriter>, inputs: inout _GraphInputs) {
        inputs.asyncImageOptions = _GraphValue(modifier[\.options].value)
    }
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageOptionsInput : ViewInput {
    
    fileprivate typealias Value = _GraphValue<Set<AsyncImageOption>>?
    
    @inline(__always)
    fileprivate static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension View {
    
    /// When ``AsyncImage`` loads images, it can be configured via ``AsyncImageOption`` in ``View/imageRequestOptions(_:)``,
    /// Implement image loading requirements for different scenarios.
    ///
    /// Example below uses ``View/imageRequestOptions(_:)`` for config, corresponding AsyncImage loading uses independent custom cache and custom tracking info.
    ///
    ///     AsyncImage(url: URL(string: "https://example.com/icon.png")) { phase in
    ///         if let image = phase.image {
    ///             image // Displays the loaded image.
    ///         } else if phase.error != nil {
    ///             Color.red // Indicates an error.
    ///         } else {
    ///             Color.blue // Acts as a placeholder.
    ///         }
    ///     }
    ///     .imageRequestOptions([.cacheName("FeedCache"), .customInfo(["biz":"feed"])])
    ///     .onImageLoad { loadEvents in
    ///         loadEvents.forEach {
    ///             if $0.successed && ($0.event.from == .disk || $0.event.from == .network) {
    ///                 print("[AsyncImage] [LoadImage] load success: [from=\($0.event.from)] [URL=\($0.url?.absoluteString ?? "")] [custom=\($0.event.customInfo["biz"])]")
    ///             }
    ///             if !$0.successed && $0.event.from == .none {
    ///                 print("[AsyncImage] [LoadImage] load fail: [URL=\($0.url?.absoluteString ?? "")] [custom=\($0.event.customInfo["biz"])]")
    ///             }
    ///         }
    ///     }
    ///
    public func imageRequestOptions<S: Sequence>(_ options: S) -> some View where S.Element == AsyncImageOption {
        let optionSet = Set(options)
#if DEBUG || DANCE_UI_INHOUSE
        if optionSet.isSuperset(of: [.ignoreMemoryCache, .ignoreDiskCache, .ignoreNetworkImage]) {
            runtimeIssue(type: .warning, "AsyncImage options ignore all image source (memory, disk, network)")
        }
#endif
        return modifier(AsyncImageOptionsWriter(options: optionSet))
    }
}

@available(iOS 13.0, *)
extension _GraphInputs {
    
    @inline(__always)
    internal var asyncImageCancelControl: _GraphValue<Bool>? {
        get {
            self[AsyncImageCancelControlInput.self]
        }
        set {
            self[AsyncImageCancelControlInput.self] = newValue
        }
    }
    
    @inline(__always)
    internal var asyncImageDecrypt: _GraphValue<AsyncImageDecrypt>? {
        get {
            self[AsyncImageDecryptInput.self]
        }
        set {
            self[AsyncImageDecryptInput.self] = newValue
        }
    }
    
    @inline(__always)
    internal var asyncImageOptions: _GraphValue<Set<AsyncImageOption>>? {
        get {
            self[AsyncImageOptionsInput.self]
        }
        set {
            self[AsyncImageOptionsInput.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var asyncImageCancelControl: _GraphValue<Bool>? {
        self[AsyncImageCancelControlInput.self]
    }
    
    @inline(__always)
    internal var asyncImageDecrypt: _GraphValue<AsyncImageDecrypt>? {
        self[AsyncImageDecryptInput.self]
    }
    
    @inline(__always)
    internal var asyncImageOptions: _GraphValue<Set<AsyncImageOption>>? {
        self[AsyncImageOptionsInput.self]
    }
}

@available(iOS 13.0, *)
extension _ViewListInputs {
    
    @inline(__always)
    internal var asyncImageCancelControl: _GraphValue<Bool>? {
        self[AsyncImageCancelControlInput.self]
    }
    
    @inline(__always)
    internal var asyncImageDecrypt: _GraphValue<AsyncImageDecrypt>? {
        self[AsyncImageDecryptInput.self]
    }
    
    @inline(__always)
    internal var asyncImageOptions: _GraphValue<Set<AsyncImageOption>>? {
        self[AsyncImageOptionsInput.self]
    }
}
