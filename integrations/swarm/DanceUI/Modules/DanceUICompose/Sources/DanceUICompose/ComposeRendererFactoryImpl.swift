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
public final class ComposeRendererFactoryImpl: NSObject, ComposeRendererFactory {
    
    @objc
    public static let sharedInstance = ComposeRendererFactoryImpl()
    
    public func getComposeLogService() -> ComposeLogService {
        ComposeLogServiceImpl.sharedInstance
    }
    
    public func getComposeAsyncImageManager() -> ComposeAsyncImageManager {
        ComposeAsyncImageLoadManager.sharedInstance
    }
    
    public func makeComposeAsyncImageLoader() -> ComposeAsyncImageLoader {
        ComposeAsyncImageLoadBinder()
    }
    
    public func makeComposeRenderingUIView(_ delegate: any ComposeRenderDelegate) -> any UIView & ComposeRenderingUIView {
        let view = ComposeRenderingUIViewImpl()
        view.delegate = delegate
        return view
    }
    
    public func makeComposeCanvas() -> any ComposeCanvas {
        ComposeCanvasImpl()
    }
    
    public func makeComposeCanvas(withVectorImage image: any ComposeImageBitmap) -> any ComposeCanvas {
        guard let vectorImage = image as? ComposeVectorImage else {
            return ComposeCanvasImpl()
        }
        return vectorImage.canvas
    }
    
    public func makeComposePaint() -> any ComposePaint {
        ComposePaintImpl()
    }
    
    public func makeComposeFontLoader() -> any ComposeFontLoader {
        ComposeFontLoaderImpl()
    }
    
    public func makeComposeParagraph(
        with intrinsics: any ComposeParagraphIntrinsics,
        minWidth: Int,
        maxWidth: Int,
        minHeight: Int,
        maxHeight: Int,
        maxLines: Int,
        ellipsis: Bool
    ) -> any ComposeParagraph {
        ComposeParagraphImpl(
            intrinsics: intrinsics,
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
            maxLines: maxLines,
            ellipsis: ellipsis
        )
    }
    
    public func makeComposeParagraphIntrinsics(
        withText text: String,
        spanStyleRanges: [any ComposeAnnotatedStringRangeWithSpanStyle],
        placeholderRanges: [any ComposeAnnotatedStringRangeWithPlaceholder],
        textStyle: any ComposeTextStyle,
        resourceLoader fontLoader: any ComposeFontLoader,
        maxLines: Int,
        ellipsis: Bool
    ) -> any ComposeParagraphIntrinsics {
        ComposeParagraphIntrinsicsImpl(
            text,
            style: ComposeParagraphAttributeStyle(
                spanStyleRanges: spanStyleRanges,
                textStyle: textStyle as! ComposeTextStyleImpl
            ),
            placeholderRanges: placeholderRanges,
            maxLines: maxLines,
            ellipsis: ellipsis
        )
    }
    
    public func makeComposeRenderNodeLayer(withIsItemRoot isItemRoot: Bool) -> any ComposeRenderNodeLayer {
        ComposeRenderNodeLayerImpl(isItemRoot: isItemRoot)
    }
    
    public func getComposePathOps() -> any ComposePathOps {
        ComposePathOpsImpl.sharedInstance
    }
    
    public func dispatchMainTasks(_ block: @escaping () -> Void) {
        autoreleasepool {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
