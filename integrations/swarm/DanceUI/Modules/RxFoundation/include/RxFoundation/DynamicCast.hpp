//
//  DynamicCast.hpp
//  GrindrCoreFoundation
//
//  Created by closure on 3/14/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef DynamicCast_hpp
#define DynamicCast_hpp

#ifdef __OBJC__

#include <Foundation/Foundation.h>

namespace Rx {
    template <typename T>
    RX_INLINE_VISIBILITY T *dynamicCast(id<NSObject> instance) {
        if ([instance isKindOfClass:[T class]]) {
            return static_cast<T*>(instance);
        }
        return nullptr;
    }
}

#endif

#endif /* DynamicCast_hpp */
