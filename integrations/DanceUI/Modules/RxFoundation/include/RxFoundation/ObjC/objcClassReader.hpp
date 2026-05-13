//
//  objcClassReader.hpp
//  RxFoundation
//
//  Created by Closure on 2018/11/15.
//  Copyright © 2018 Closure. All rights reserved.
//

#ifndef objcClassReader_hpp
#define objcClassReader_hpp

#include <RxFoundation/RxBase.hpp>

#import <Foundation/Foundation.h>

namespace Rx {
namespace ObjC {
    NSArray<Class> *getClasses(bool (^predicate)(Class cls));
    NSArray<Class> *getSubclasses(Class cls);
    
    NSArray<Class> *getProtocols(Protocol *protocol);
}
}


#endif /* objcClassReader_hpp */
