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
public protocol ExtensionAsyncImageInner : AsyncImageInner {
    
    associatedtype Binder: AsyncImageBinder
}

@available(iOS 13.0, *)
extension ExtensionAsyncImageInner {
    
    public static func _makeView<Content>(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewInputs) -> _ViewOutputs where Content : View {
        let options = inputs.asyncImageOptions?.value
        let cancelOnDisappear = inputs.asyncImageCancelControl?.value
        let decrypt = inputs.asyncImageDecrypt?.value
        let reload = inputs.asyncImageReload?.value
        
        let body = ExtensionAsyncImageChild<Content, Binder>(options: options,
                                                             cancelOnDisappear: cancelOnDisappear,
                                                             decrypt: decrypt,
                                                             reload: reload,
                                                             asyncImage: view.value)
        
        return ExtensionAsyncImageChild<Content, Binder>.Value._makeView(view: _GraphValue(body), inputs: inputs)
    }

    public static func _makeViewList<Content>(view: _GraphValue<AsyncImage<Content>>, inputs: _ViewListInputs) -> _ViewListOutputs where Content : View {
        let options = inputs.asyncImageOptions?.value
        let cancelOnDisappear = inputs.asyncImageCancelControl?.value
        let decrypt = inputs.asyncImageDecrypt?.value
        let reload = inputs.asyncImageReload?.value
        
        let body = ExtensionAsyncImageChild<Content, Binder>(options: options,
                                                             cancelOnDisappear: cancelOnDisappear,
                                                             decrypt: decrypt,
                                                             reload: reload,
                                                             asyncImage: view.value)
        
        return ExtensionAsyncImageChild<Content, Binder>.Value._makeViewList(view: _GraphValue(body), inputs: inputs)
    }
}

@available(iOS 13.0, *)
private struct ExtensionAsyncImageChild<Content, Binder> : Rule where Content : View, Binder : AsyncImageBinder {

    fileprivate typealias Value = _UnaryViewAdaptor<_ExtensionAsyncImage<Content, Binder>>
    
    @OptionalAttribute
    fileprivate var options: Set<AsyncImageOption>?

    @OptionalAttribute
    fileprivate var cancelOnDisappear: Bool?

    @OptionalAttribute
    fileprivate var decrypt: AsyncImageDecrypt?
    
    @OptionalAttribute
    fileprivate var reload: Int?

    @Attribute
    fileprivate var asyncImage: AsyncImage<Content>

    fileprivate init(options: Attribute<Set<AsyncImageOption>>?,
                     cancelOnDisappear: Attribute<Bool>?,
                     decrypt: Attribute<AsyncImageDecrypt>?,
                     reload: Attribute<Int>?,
                     asyncImage: Attribute<AsyncImage<Content>>) {
        self._options = OptionalAttribute(options)
        self._cancelOnDisappear = OptionalAttribute(cancelOnDisappear)
        self._decrypt = OptionalAttribute(decrypt)
        self._reload = OptionalAttribute(reload)
        self._asyncImage = asyncImage
    }


    fileprivate var value: Value {
        _UnaryViewAdaptor(
            _ExtensionAsyncImage(context: AsyncImageContext(url: asyncImage.url,
                                                            alternativeURLs: asyncImage.alternativeURLs,
                                                            scale: asyncImage.scale,
                                                            options: options ?? []),
                                 cancelOnDisappear: cancelOnDisappear ?? false,
                                 transaction: asyncImage.transaction,
                                 progress: asyncImage.progress,
                                 decrypt: decrypt,
                                 reload: reload ?? 0,
                                 content: asyncImage.content)
        )
    }
}

@available(iOS 13.0, *)
private struct _ExtensionAsyncImage<Content, Binder> : View where Content : View, Binder : AsyncImageBinder {
    
    fileprivate var context: AsyncImageContext

    fileprivate var cancelOnDisappear: Bool

    fileprivate var progress: AsyncImageProgress?

    fileprivate var decrypt: AsyncImageDecrypt?
    
    fileprivate var reload: Int
    
    @State
    fileprivate var lastReload: Int = 0

    fileprivate var content: (AsyncImagePhaseContext) -> Content

    fileprivate var transaction: Transaction

    @State
    fileprivate var phaseContext: AsyncImagePhaseContext = .empty
    
    @StateObject
    fileprivate var binderContext = AsyncImageBinderContext()

    @State
    fileprivate var progressValue = AsyncImageProgressValue()
    
    @State
    fileprivate var imageTriggering = false
    
    @Environment(\.imageBinderType)
    fileprivate var imageBinderType: AsyncImageBinder.Type?

    fileprivate init(context: AsyncImageContext,
                     cancelOnDisappear: Bool,
                     transaction: Transaction,
                     progress: AsyncImageProgress?,
                     decrypt: AsyncImageDecrypt?,
                     reload: Int,
                     content: @escaping (AsyncImagePhase, AsyncImageEventContext?) -> Content) {
        self.context = context
        self.cancelOnDisappear = cancelOnDisappear
        self.progress = progress
        self.decrypt = decrypt
        self.reload = reload
        self.transaction = transaction
        self.content = { context in
            content(context.phase, context.event)
        }
    }

    fileprivate func load(_ context: AsyncImageContext) {
        switch phaseContext.phase {
        case .success(_), .empty:
            if binderContext.canReuse(context), reload == lastReload {
                LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load reuse", info: logContext)
                return
            }
        default: break
        }

        lastReload = reload
        if binderContext.needReset {
            LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load cancel by view reuse", info: binderLogContext)
            binderContext.cancelRequest()
            binderContext.reset()
            progressValue = AsyncImageProgressValue()
            phaseContext = .empty
        }
        if context.url != nil {
            var delegate = _AsyncImageDelegate { image, event in
                binderContext.makeIdentity()
                withTransaction(transaction) {
                    phaseContext = AsyncImagePhaseContext(event: event, phase: .success(image))
                    imageTriggering = true
                }
                LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load image success") {
                    ["from": event.from, "image_size": event.imageSize, "file_size": event.fileSize]
                    logContext
                }
            } onFailureDelegate: { error, event in
                binderContext.makeIdentity()
                withTransaction(transaction) {
                    phaseContext = AsyncImagePhaseContext(event: event, phase: .failure(error ?? LoadingError()))
                    imageTriggering = true
                }
                LogService.warning(module: .image, keyword: .loadImage, "AsyncImage load image failure", info: logContext)
            } onResetDelegate: {
                binderContext.reset()
                withTransaction(transaction) {
                    phaseContext = .empty
                }
            }

            if let progress = progress {
                delegate.onProgressDelegate = { downloaded, total in
                    let step = max(Int64(Double(total) * progress.skipDistance / 100), 1)
                    if downloaded - step >= progressValue.receivedSize || downloaded >= total {
                        progressValue.receivedSize = downloaded
                        progressValue.totalSize = total
                    }
                }
            }
            if let onDecrypt = decrypt?.onDecrypt {
                delegate.onDecryptDelegate = {
                    onDecrypt($0)
                }
            }

            let binderType = imageBinderType ?? Binder.self
            let imageBinder = binderType.init()
            LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load start", info: logContext)
            imageBinder.start(context: context, delegate: delegate)
            binderContext.setup(context, binder: imageBinder)
        }
    }

    internal var body: some View {
        content(phaseContext)
            .onAppear {
                LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load by view appear", info: logContext)
                load(context)
            }
            .onDisappear {
                if cancelOnDisappear {
                    LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load cancel by view disappear", info: binderLogContext)
                    binderContext.cancelRequest()
                }
            }
            .onChange(of: context) { _, new in
                LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load by context Changed", info: logContext)
                load(new)
            }
            .onChange(of: reload) { _, new in
                guard new > lastReload else {
                    return
                }
                LogService.debug(module: .image, keyword: .loadImage, "AsyncImage load by reload", info: logContext)
                load(context)
            }
            .onChange(of: progressValue) {
                guard let progress = progress else {
                    return
                }
                progress.onProgress($0.receivedSize, $0.totalSize)
            }
            .imageTriggering(loadEvent)
    }
    
    private var loadEvent: AsyncImageLoadEvent {
        binderContext.createLoadEvent($imageTriggering, phaseContext: phaseContext)
    }
    
    @DictionaryBuilder<String, Any>
    var logContext: [String: Any] {
        ["phase": phaseContext.phase]
        context.logContext
    }
    
    @DictionaryBuilder<String, Any>
    var binderLogContext: [String: Any] {
        ["phase": phaseContext.phase]
        binderContext.logContext
    }
}

@available(iOS 13.0, *)
private final class AsyncImageBinderContext: OpenCombine.ObservableObject {
    
    private var context: AsyncImageContext?

    private var imageBinder: AsyncImageBinder?
    
    private var identity: AsyncImageLoadEvent.Identity = .zero
    
    fileprivate func canReuse(_ ctx: AsyncImageContext) -> Bool {
        context == ctx
    }
    
    fileprivate var needReset: Bool {
        imageBinder != nil
    }
    
    fileprivate func reset() {
        context = nil
        imageBinder = nil
        identity = .zero
    }
    
    fileprivate func setup(_ ctx: AsyncImageContext, binder: AsyncImageBinder) {
        context = ctx
        imageBinder = binder
    }
    
    fileprivate func cancelRequest() {
        imageBinder?.cancel()
    }
    
    fileprivate func makeIdentity() {
        identity = .make()
    }
    
    fileprivate func createLoadEvent(_ isTriggered: Binding<Bool>, phaseContext: AsyncImagePhaseContext) -> AsyncImageLoadEvent {
        .init(isTriggered, url: context?.url, phaseContext: phaseContext, identity: identity)
    }
    
    @DictionaryBuilder<String, Any>
    fileprivate var logContext: [String: Any] {
        context?.logContext
        ["identity": identity]
    }
}

@available(iOS 13.0, *)
extension AsyncImageContext {
    
    @_spi(DanceUIExtension)
    @DictionaryBuilder<String, Any>
    public var logContext: [String: Any] {
        if let urlStr = url?.absoluteString {
            ["url": urlStr]
        }
        if options.count > 0 {
            ["options": options]
        }
    }
}

@_spi(DanceUIExtension)
public enum ImageKeyword: String, LogKeyword {
    
    case resolveInner
    case loadImage
    case imageBinder
    case asyncCoverImage
    
    public static var moduleName: String { "Image" }
}

@available(iOS 13.0, *)
@_spi(DanceUIExtension)
extension LogService.Module where K == ImageKeyword {
    
    public static let image: Self = .init()
}
