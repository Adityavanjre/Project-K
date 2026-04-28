//
//  CrashReporter.hpp
//  RxFoundation
//
//  Created by closure on 5/9/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef CrashReporter_hpp
#define CrashReporter_hpp

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/String.hpp>

namespace Rx {
    class CrashReporter {
    public:
        static void HALT(String log = "") __attribute__((noreturn));
    private:
        CrashReporter();
    };
    
    #define CRASH(string, errcode) do { char msg[256]; snprintf(msg, 256, string, errcode); CrashReporter::HALT(msg); } while (0)
    
    RxPrivate void __THE_SYSTEM_HAS_NO_PORTS_AVAILABLE__(kern_return_t ret) __attribute__((noinline));
    RxPrivate void __NO_SPACE__(kern_return_t ret) __attribute__((noinline));
    RxPrivate void __RESOURCE_SHORTAGE__(kern_return_t ret) __attribute__((noinline));
    RxPrivate void __THE_SYSTEM_HAS_NO_PORT_SETS_AVAILABLE__(kern_return_t ret) __attribute__((noinline));
}

#endif /* CrashReporter_hpp */
