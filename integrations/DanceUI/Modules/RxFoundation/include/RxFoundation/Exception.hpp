//
//  Exception.hpp
//  RxFoundation
//
//  Created by closure on 3/6/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef Exception_hpp
#define Exception_hpp

#include <RxFoundation/String.hpp>
#include <RxFoundation/Array.hpp>

namespace Rx {
    class Exception {
    public:
        Exception(const String &name, const String reason) RX_NOEXCEPT;
        virtual ~Exception() RX_NOEXCEPT;
        virtual const char* what() const RX_NOEXCEPT;
    public:
        const String &getName() const { return _name; }
        const String &getReason() const { return _reason; }
        const Array<String> getCallStackSymbols() const;
    private:
        
        const String &_name;
        const String _reason;
    };
}

#endif /* Exception_hpp */
