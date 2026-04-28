//
//  CallStackArray.hpp
//  RxFoundation
//
//  Created by closure on 6/7/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef CallStackArray_hpp
#define CallStackArray_hpp

#include <RxFoundation/String.hpp>
#include <RxFoundation/Array.hpp>

namespace Rx {
    void getBacktrace(void **stack, int *size);
}

namespace Rx {
    class CallStackArray : public Array<String> {
    public:
        CallStackArray(void **stack, UInt32 frames);
        ~CallStackArray();
        const String getDescription() const;
        
    private:
        UInt32 _frames;
        std::unique_ptr<void *, void(*)(void *)> _stack;
    };
    
}

#endif /* CallStackArray_hpp */
