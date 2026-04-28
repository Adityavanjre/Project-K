//
//  ObjectMeta.hpp
//  RxFoundation
//
//  Created by Closure on 7/21/17.
//  Copyright © 2017 Closure. All rights reserved.
//

#ifndef ObjectMeta_hpp
#define ObjectMeta_hpp

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/String.hpp>

namespace Rx {
    class String;
    template<typename T>
    String getClassName() {
        const char *name = typeid(T).name();
        int status = -1;
        std::unique_ptr<char, void(*)(void*)> result {
            __cxxabiv1::__cxa_demangle(name, NULL, NULL, &status),
            std::free
        };
        return (status == 0) ? result.get() : name;
    }
    
    template<typename T>
    String getClassName(const T *instance) {
        const char *name = typeid(instance).name();
        int status = -1;
        std::unique_ptr<char, void(*)(void*)> result {
            __cxxabiv1::__cxa_demangle(name, NULL, NULL, &status),
            std::free
        };
        return (status == 0) ? result.get() : name;
    }
    
    String getClassName(const void *instance);
}

#endif /* ObjectMeta_hpp */
