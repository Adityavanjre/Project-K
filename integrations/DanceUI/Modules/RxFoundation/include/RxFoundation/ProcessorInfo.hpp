//
//  ProcessorInfo.hpp
//  RxFoundation
//
//  Created by closure on 3/9/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef ProcessorInfo_hpp
#define ProcessorInfo_hpp

#include <RxFoundation/RxBase.hpp>
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_IPHONEOS
#include <mach/mach.h>
#endif


namespace Rx {
    namespace OS {
        class ProcessorInfo {
        public:
            static UInteger activeProcessorCount() RX_NOEXCEPT;
        };
        
        typedef pid_t ProcessID;
        typedef pid_t ThreadID;
        
        ProcessID getPid();
        ThreadID getTidWithThread(pthread_t thread);
        ThreadID getTid();
    }
}

#endif /* ProcessorInfo_hpp */
