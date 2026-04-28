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

#ifndef LottieCompottieProtocols_h
#define LottieCompottieProtocols_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: - Forward Declarations

@protocol CompottieLottieAnimation;
@protocol CompottieLottieAnimationView;
@protocol CompottieAnimationKeypath;
@protocol CompottieValueProvider;
@protocol CompottieAnimationImageDataProvider;

// MARK: - Animation Model Protocol

/**
 * Protocol representing a Lottie animation composition
 * Maps to Swift's LottieAnimation class
 */
@protocol CompottieLottieAnimation <NSObject>

@required

/**
 * Start frame of the animation
 */
@property (nonatomic, assign, readonly) CGFloat startFrame;

/**
 * End frame of the animation
 */
@property (nonatomic, assign, readonly) CGFloat endFrame;

/**
 * Frame rate (fps)
 */
@property (nonatomic, assign, readonly) CGFloat framerate;

/**
 * Animation width in points
 */
@property (nonatomic, assign, readonly) CGFloat width;

/**
 * Animation height in points
 */
@property (nonatomic, assign, readonly) CGFloat height;

/**
 * Animation duration in seconds
 */
@property (nonatomic, assign, readonly) CGFloat duration;

/**
 * All marker names in the animation
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *markerNames;

@property (nonatomic, strong, nullable) id<CompottieAnimationImageDataProvider> imageProvider;

/**
 * Create animation from JSON string
 */
+ (nullable id<CompottieLottieAnimation>)animationFromJSON:(NSString *)jsonString error:(NSError **)error;

/**
 * Create animation from JSON data
 */
+ (nullable id<CompottieLottieAnimation>)animationFromData:(NSData *)data error:(NSError **)error;

/**
 * Create animation from file URL
 */
+ (nullable id<CompottieLottieAnimation>)animationFromURL:(NSURL *)url error:(NSError **)error;

/**
 * Create animation from bundle resource
 */
+ (nullable id<CompottieLottieAnimation>)animationNamed:(NSString *)name bundle:(NSBundle *)bundle error:(NSError **)error;

@end

// MARK: - Animation View Protocol

/**
 * Protocol representing a Lottie animation view
 * Maps to Swift's LottieAnimationView class (UIView subclass)
 */
@protocol CompottieLottieAnimationView <NSObject>

@required

/**
 * Initialize with frame
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 * The animation backing this view
 */
@property (nonatomic, strong, nullable) id<CompottieLottieAnimation> animation;

/**
 * Current progress (0.0 - 1.0)
 */
@property (nonatomic, assign) CGFloat currentProgress;

/**
 * Current frame
 */
@property (nonatomic, assign) CGFloat currentFrame;

/**
 * Current time in seconds
 */
@property (nonatomic, assign) CGFloat currentTime;

/**
 * Whether the animation is currently playing
 */
@property (nonatomic, assign, readonly) BOOL isAnimationPlaying;

/**
 * Whether to loop the animation
 */
@property (nonatomic, assign) BOOL loopMode;

/**
 * Animation playback speed (1.0 = normal, 2.0 = double speed, etc.)
 */
@property (nonatomic, assign) CGFloat animationSpeed;

/**
 * Content mode for scaling animation
 */
@property (nonatomic, assign) UIViewContentMode contentMode;

/**
 * Whether the animation respects its intrinsic content size
 */
@property (nonatomic, assign) BOOL respectAnimationFrameRate;

// Playback control methods

/**
 * Play animation from current frame
 */
- (void)play;

/**
 * Play with completion callback
 */
- (void)playWithCompletion:(void (^ _Nullable)(BOOL finished))completion;

/**
 * Play from specific progress
 */
- (void)playFromProgress:(CGFloat)fromProgress 
              toProgress:(CGFloat)toProgress 
          withCompletion:(void (^ _Nullable)(BOOL finished))completion;

/**
 * Play from specific frame
 */
- (void)playFromFrame:(CGFloat)fromFrame 
              toFrame:(CGFloat)toFrame 
       withCompletion:(void (^ _Nullable)(BOOL finished))completion;

/**
 * Play marker
 */
- (void)playMarkerNamed:(NSString *)markerName 
         withCompletion:(void (^ _Nullable)(BOOL finished))completion;

/**
 * Pause animation
 */
- (void)pause;

/**
 * Stop animation and reset to beginning
 */
- (void)stop;

/**
 * Get the UIView instance (for adding to view hierarchy)
 */
- (UIView *)view;

/**
 * Set value provider for keypath
 */
- (void)setValueProvider:(id<CompottieValueProvider>)valueProvider 
              forKeypath:(id<CompottieAnimationKeypath>)keypath;

/**
 * Get snapshot image at current progress
 */
- (nullable UIImage *)currentImage;

@optional

/**
 * Force redraw/rerender
 */
- (void)setNeedsDisplay;

/**
 * Force layout update
 */
- (void)setNeedsLayout;

/**
 * Set external image data provider for resolving image assets.
 */
- (void)setImageDataProvider:(id<CompottieAnimationImageDataProvider>)provider;

@end

// MARK: - Image Data Providers (for asset bridging)

@protocol CompottieAnimationImageDataProvider <NSObject>

@property (nonatomic, strong, readonly) NSString *path;

@end

// MARK: - Animation Keypath Protocol

/**
 * Protocol for animation keypaths (layer/property paths)
 * Maps to Swift's AnimationKeypath
 */
@protocol CompottieAnimationKeypath <NSObject>

@required

/**
 * Keypath string (e.g., "layer.shape.fill.color")
 */
@property (nonatomic, strong, readonly) NSString *keypathString;

/**
 * Create keypath from string
 */
+ (id<CompottieAnimationKeypath>)keypathWithString:(NSString *)keypath;

/**
 * Create keypath from components
 */
+ (id<CompottieAnimationKeypath>)keypathWithKeys:(NSArray<NSString *> *)keys;

@end

// MARK: - Value Provider Protocol

/**
 * Protocol for providing dynamic values to animation properties
 * Maps to Swift's AnyValueProvider
 */
@protocol CompottieValueProvider <NSObject>

@required

/**
 * Whether this provider has updates
 */
@property (nonatomic, assign, readonly) BOOL hasUpdate;

@end

// MARK: - Color Value Provider

/**
 * Provides color values for animations
 */
@protocol CompottieColorValueProvider <CompottieValueProvider>

@required

/**
 * Set color value
 */
- (void)setColor:(UIColor *)color;

/**
 * Create with initial color
 */
+ (id<CompottieColorValueProvider>)providerWithColor:(UIColor *)color;

@end

// MARK: - Number Value Provider

/**
 * Provides numeric values for animations
 */
@protocol CompottieFloatValueProvider <CompottieValueProvider>

@required

/**
 * Set float value
 */
- (void)setFloatValue:(CGFloat)value;

/**
 * Create with initial value
 */
+ (id<CompottieFloatValueProvider>)providerWithFloat:(CGFloat)value;

@end

// MARK: - Point Value Provider

/**
 * Provides CGPoint values for animations (positions, etc.)
 */
@protocol CompottiePointValueProvider <CompottieValueProvider>

@required

/**
 * Set point value
 */
- (void)setPointValue:(CGPoint)point;

/**
 * Create with initial point
 */
+ (id<CompottiePointValueProvider>)providerWithPoint:(CGPoint)point;

@end

// MARK: - Size Value Provider

/**
 * Provides CGSize values for animations
 */
@protocol CompottieSizeValueProvider <CompottieValueProvider>

@required

/**
 * Set size value
 */
- (void)setSizeValue:(CGSize)size;

/**
 * Create with initial size
 */
+ (id<CompottieSizeValueProvider>)providerWithSize:(CGSize)size;

@end

// MARK: - Factory Protocol

/**
 * Factory for creating Lottie components
 * This will be the main entry point from Kotlin
 */
NS_SWIFT_NAME(CompottieLottieFactory)
@protocol CompottieLottieFactory <NSObject>

@required

/**
 * Create animation from JSON string
 */
- (nullable id<CompottieLottieAnimation>)createAnimationFromJSON:(NSString *)jsonString error:(NSError **)error;

/**
 * Create animation from data
 */
- (nullable id<CompottieLottieAnimation>)createAnimationFromData:(NSData *)data error:(NSError **)error;

/**
 * Create animation view
 */
- (id<CompottieLottieAnimationView>)createAnimationView;

/**
 * Create animation view with animation
 */
- (id<CompottieLottieAnimationView>)createAnimationViewWithAnimation:(id<CompottieLottieAnimation>)animation;

/**
 * Create color value provider
 */
- (id<CompottieColorValueProvider>)createColorValueProviderWithColor:(UIColor *)color;

/**
 * Create float value provider
 */
- (id<CompottieFloatValueProvider>)createFloatValueProviderWithValue:(CGFloat)value;

/**
 * Create point value provider
 */
- (id<CompottiePointValueProvider>)createPointValueProviderWithPoint:(CGPoint)point;

/**
 * Create size value provider
 */
- (id<CompottieSizeValueProvider>)createSizeValueProviderWithSize:(CGSize)size;

/**
 * Create keypath from string
 */
- (id<CompottieAnimationKeypath>)createKeypathWithString:(NSString *)keypath;

/**
 * Create image provider from path
 */
- (id<CompottieAnimationImageDataProvider>)createImageProviderWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END

#endif /* LottieCompottieProtocols_h */
