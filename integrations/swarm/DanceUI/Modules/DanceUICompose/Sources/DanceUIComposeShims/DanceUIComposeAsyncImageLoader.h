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

#ifndef DanceUIComposeAsyncImageLoader_h
#define DanceUIComposeAsyncImageLoader_h

#import <Foundation/Foundation.h>
#import "DanceUIComposeImageBitmap.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, DanceUIComposeImageLoadOptions) {
    
    DanceUIComposeImageLoadDefaultPriority           ,
    DanceUIComposeImageLoadLowPriority               = 1 << 0,
    DanceUIComposeImageLoadHighPriority              = 1 << 1,
    
    DanceUIComposeImageLoadIgnoreMemoryCache         = 1 << 2,
    DanceUIComposeImageLoadIgnoreDiskCache           = 1 << 3,
    DanceUIComposeImageLoadIgnoreNetworkImage        = 1 << 4,
    DanceUIComposeImageLoadNotCacheToMemory          = 1 << 5,
    DanceUIComposeImageLoadNotCacheToDisk            = 1 << 6,
    DanceUIComposeImageLoadNoRetry                   = 1 << 7,
    
    DanceUIComposeImageLoadSmartCorp                 = 1 << 8,

    DanceUIComposeImageLoadDisableBackgroundDecode   = 1 << 9,
    DanceUIComposeImageLoadProgressiveDownload       = 1 << 10,
}NS_SWIFT_NAME(ComposeImageRequestOptions);

NS_SWIFT_NAME(ComposeImageLoadConfig)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeImageLoadConfig <NSObject>

@property (nonatomic, assign) CFTimeInterval timeoutInterval;

@property (nonatomic, strong, nullable) NSString *cacheName;

@property (nonatomic, assign) CGSize imageDownsampleSize;

@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *customInfo;

@property (nonatomic, strong, nullable) NSString *sceneTag;

@property (nonatomic, strong, nullable) NSString *bizTag;

@property (nonatomic, assign) NSInteger optionValue;

@end

typedef NS_ENUM(NSInteger, DanceUIComposeImageType) {
    DanceUIComposeImageTypeUnknown,
    DanceUIComposeImageTypeJPG,
    DanceUIComposeImageTypeGIF,
    DanceUIComposeImageTypePNG,
    DanceUIComposeImageTypeWEBP,
    DanceUIComposeImageTypeHEIC,
    DanceUIComposeImageTypeAVIF
} NS_SWIFT_NAME(ComposeImageType);

typedef NS_ENUM(NSInteger, DanceUIComposeImageLoadFrom) {
    DanceUIComposeImageLoadFromNone,
    DanceUIComposeImageLoadFromMemory,
    DanceUIComposeImageLoadFromDisk,
    DanceUIComposeImageLoadFromNetwork
} NS_SWIFT_NAME(ComposeImageLoadFrom);


NS_SWIFT_NAME(ComposeImageLoadEventParams)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeImageLoadEventParams <NSObject>

@property (nonatomic, assign) DanceUIComposeImageType imageType;

@property (nonatomic, assign) CGSize imageSize;

@property (nonatomic, assign) double fileSize;

@property (nonatomic, assign) DanceUIComposeImageLoadFrom from;

@property (nonatomic, assign) double loadDuration;
@property (nonatomic, assign) double queueDuration;
@property (nonatomic, assign) double cacheDuration;
@property (nonatomic, assign) double downloadDuration;
@property (nonatomic, assign) double decodeDuration;

@property (nonatomic, strong) NSDictionary<NSString *, id> *customInfo;

@end

typedef void(^DanceUIComposeImageLoadProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);

typedef NSData * _Nullable (^DanceUIComposeImageLoadDecryptBlock)(NSData * _Nullable data);

API_AVAILABLE(ios(13.0))
typedef void(^DanceUIComposeImageLoadCompletedBlock)(id<DanceUIComposeImageBitmap> _Nullable image,
                                                     NSError * _Nullable error,
                                                     id<DanceUIComposeImageLoadEventParams> _Nullable eventParams);

NS_SWIFT_NAME(ComposeAsyncImageLoader)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeAsyncImageLoader <NSObject>

- (void)requestImage:(NSArray<NSString *> * _Nullable)urls
             options:(DanceUIComposeImageLoadOptions)options
              config:(id<DanceUIComposeImageLoadConfig> _Nullable)config
        decryptBlock:(DanceUIComposeImageLoadDecryptBlock _Nullable)decryptBlock
            progress:(DanceUIComposeImageLoadProgressBlock _Nullable)progress
            complete:(DanceUIComposeImageLoadCompletedBlock)complete;

- (void)cancel;

@end

NS_SWIFT_NAME(ComposeAsyncImageManager)
API_AVAILABLE(ios(13.0)) @protocol DanceUIComposeAsyncImageManager <NSObject>

- (void)prefetchImage:(NSArray<NSString *> * _Nullable)urls;

@end

NS_ASSUME_NONNULL_END


#endif /* DanceUIComposeAsyncImageLoader_h */
