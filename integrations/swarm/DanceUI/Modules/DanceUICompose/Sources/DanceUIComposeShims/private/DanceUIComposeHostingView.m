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

#import "DanceUIComposeHostingView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DanceUIComposeHostingView

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    return [self pointInsideWithX:point.x y:point.y withEvent:event];
}

- (BOOL)pointInsideWithX:(CGFloat)x y:(CGFloat)y withEvent:(nullable UIEvent *)event {
    CGPoint point = CGPointMake(x, y);
    return [super pointInside:point withEvent: event];
}

- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
    return [self hitTestWithX:point.x y:point.y withEvent:event];
}

- (nullable UIView *)hitTestWithX:(CGFloat)x y:(CGFloat)y withEvent:(nullable UIEvent *)event {
    CGPoint point = CGPointMake(x, y);
    return [super hitTest:point withEvent: event];
}

- (CGFloat)frameX {
    return self.frame.origin.x;
}

- (CGFloat)frameY {
    return self.frame.origin.y;
}

- (CGFloat)frameWidth {
    return self.frame.size.width;
}

- (CGFloat)frameHeight {
    return self.frame.size.height;
}

@end

NS_ASSUME_NONNULL_END
